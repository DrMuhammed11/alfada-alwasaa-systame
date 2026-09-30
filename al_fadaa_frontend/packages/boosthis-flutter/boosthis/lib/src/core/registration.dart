import 'telemetry.dart';
import 'transmit.dart';
import 'runtime_flags.dart';

/// Four-way internal state for the server-authoritative registration answer.
enum RegistrationState { pending, registered, unregistered, unreachable }

/// Three outcomes display surfaces are allowed to show.
enum RegistrationVerdict { registered, unregistered, unknown }

class Registration {
  Registration._();

  static const int _recheckMs = 30000;
  static const int _probeTimeoutMs = 8000;
  static RegistrationState _state = RegistrationState.pending;
  static Future<void>? _inFlight;
  static int _lastAttemptAt = 0;

  static RegistrationState get state => _state;
  static RegistrationVerdict get verdict {
    if (_state == RegistrationState.registered) {
      return RegistrationVerdict.registered;
    }
    if (_state == RegistrationState.unregistered) {
      return RegistrationVerdict.unregistered;
    }
    return RegistrationVerdict.unknown;
  }

  static void markRegistrationConfirmed() {
    _state = RegistrationState.registered;
  }

  static void markRegistrationRefused() {
    _state = RegistrationState.unregistered;
  }

  static void markRegistrationUnreachable() {
    if (_state == RegistrationState.registered ||
        _state == RegistrationState.unregistered) {
      return;
    }
    _state = RegistrationState.unreachable;
  }

  /// Fire-and-forget entry point used by the panel.
  static void askRegistration() {
    checkRegistrationOnce(
      endpoint: RuntimeFlags.apiBase,
      installId: Telemetry.installId,
      projectKey: Telemetry.effectiveProjectKey,
    );
  }

  static Future<void> checkRegistrationOnce({
    required String? endpoint,
    required String? installId,
    required String? projectKey,
    int? nowMs,
  }) async {
    try {
      if (_state == RegistrationState.registered ||
          _state == RegistrationState.unregistered) return;
      final pending = _inFlight;
      if (pending != null) return pending;
      final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
      if (_lastAttemptAt != 0 && now - _lastAttemptAt < _recheckMs) return;
      if (endpoint == null ||
          endpoint.isEmpty ||
          installId == null ||
          installId.isEmpty ||
          projectKey == null ||
          projectKey.isEmpty) {
        markRegistrationRefused();
        return;
      }

      final future = _probe(endpoint, installId, projectKey);
      _inFlight = future;
      _lastAttemptAt = now;
      try {
        await future;
      } finally {
        _inFlight = null;
      }
    } catch (_) {
      _inFlight = null;
      markRegistrationUnreachable();
    }
  }

  static Future<void> _probe(
      String endpoint, String installId, String projectKey) async {
    final base = endpoint.replaceFirst(RegExp(r'/+$'), '');
    final id = Uri.encodeComponent(installId);
    final res = await Transmit.safeGet(
      '$base/installs/$id/registration',
      authToken: projectKey,
      timeoutMs: _probeTimeoutMs,
    );
    if (res.status == 200) {
      final answer = res.body?['registered'];
      if (answer == true) {
        markRegistrationConfirmed();
      } else if (answer == false) {
        markRegistrationRefused();
      } else {
        markRegistrationUnreachable();
      }
    } else if (res.status == 401 || res.status == 403) {
      markRegistrationRefused();
    } else {
      markRegistrationUnreachable();
    }
  }

  static void resetForTests() {
    _state = RegistrationState.pending;
    _inFlight = null;
    _lastAttemptAt = 0;
  }
}