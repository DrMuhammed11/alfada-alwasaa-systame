import 'dart:async';

import 'kit_version.dart';
import 'runtime_flags.dart';
import 'safe.dart';
import 'store.dart';
import 'telemetry.dart';
import 'transmit.dart';

/// The entitlement vault — gate 1, and the only gate that can turn the whole
/// kit off from the server side.
///
/// DEFAULT CLOSED. A project that has never had a successful `active` answer
/// measures nothing, uploads nothing and shows nothing. Deliberate: an install
/// that cannot reach the server on its very first run must not quietly behave
/// like a paid one.
///
/// Once a project HAS been activated, an offline patch is not punished: the last
/// `active` answer stays good for the grace window the server handed back. Any
/// non-active answer is sticky immediately.
///
/// The recovery request itself is never gated (only BOOSTHIS_DISABLED stops it),
/// or an install could never come back from `revoked`.
class KillSwitch {
  KillSwitch._();

  static const String key = 'entitlement';

  /// How often a healthy install re-checks (6 hours).
  static const int checkIntervalMs = 21600000;

  /// Fallback when the server does not state a grace window (7 days).
  static const int defaultGraceSeconds = 604800;

  static const String active = 'active';
  static const String revoked = 'revoked';
  static const String unpaid = 'unpaid';
  static const String tampered = 'tampered';
  static const String paused = 'paused';

  /// A lapsed offline grace window (and, at the callers, the env kill switch
  /// and a tampered install) — nothing readable, so draw nothing.
  static const String hidden = 'hidden';

  /// Running, but no check-in has ever succeeded. Deliberately NOT [hidden]:
  /// the bubble DRAWS and the panel renders its own "Not registered yet"
  /// notice. Nothing is measured or uploaded in this state.
  /// See docs/kit-bubble-draw-contract.md.
  static const String unregistered = 'unregistered';

  static final Set<void Function()> _listeners = <void Function()>{};
  static Timer? _chaseTimer;
  static int _chaseStep = 0;
  static bool _chasing = false;
  static int _chaseGeneration = 0;
  static bool _credentialOverrideSet = false;
  static String? _credentialOverride;
  static List<int> _chaseDelaysMs = const <int>[1500, 3000, 6000, 12000, 24000];
  static Timer Function(Duration, void Function()) _chaseScheduler =
      (delay, callback) => Timer(delay, callback);

  /// True once the server has answered at least once, including a refusal.
  static bool isActivated() {
    final status = state()['status'];
    return status == active ||
        status == revoked ||
        status == unpaid ||
        status == tampered ||
        status == paused;
  }

  /// Subscribe to entitlement answers/gate changes. Listener failures are
  /// isolated so a UI subscriber can never break the host or another listener.
  static void Function() subscribe(void Function() listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  static void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      Safe.fire(listener);
    }
  }

  static Map<String, Object?> state() {
    final v = Store.get(key, <String, Object?>{});
    return v is Map<String, Object?>
        ? v
        : (v is Map ? Map<String, Object?>.from(v) : <String, Object?>{});
  }

  /// Is the kit allowed to run right now? Everything visible or outbound asks
  /// this first. DEFAULT CLOSED.
  static bool isActive() {
    if (RuntimeFlags.disabled) return false;
    final s = state();
    if (s['status'] != active) return false;
    final lastSuccess = s['lastSuccessAt'];
    if (lastSuccess is! int) return false;
    var grace = s['graceSeconds'] is int
        ? s['graceSeconds'] as int
        : defaultGraceSeconds;
    if (grace < 0) grace = defaultGraceSeconds;
    return (Telemetry.nowMs() - lastSuccess) <= (grace * 1000);
  }

  /// What to show a developer: `unregistered` for a project that has never
  /// checked in (the bubble draws and says so), `hidden` only for the states
  /// with nothing readable — a lapsed offline grace window here, plus the env
  /// kill switch and a tampered install resolved by the caller — else the
  /// server's own word so the bubble can explain itself.
  static String visibleStatus() {
    final s = state();
    final status = s['status'];
    if (status is! String) return unregistered;
    if (status == active && !isActive()) return hidden;
    return status;
  }

  static String? message() {
    final m = state()['message'];
    return m is String && m.isNotEmpty ? m : null;
  }

  /// True only after registration has handed this install a non-empty
  /// credential. Getter/storage failures are treated as not registered.
  static bool hasInstallCredential() {
    if (_credentialOverrideSet) {
      return _credentialOverride != null && _credentialOverride!.isNotEmpty;
    }
    return Safe.run<bool>(false, () {
      final token = _entitlementCredential();
      return token != null && token.isNotEmpty;
    });
  }

  static String? _entitlementCredential() {
    // The check-in rides the install's WRITE credential whenever it has one.
    // The server refuses to stamp lastEntitlementCheckAt or the kit version
    // from a read-only token (that one is handed to AI clients), so a
    // read-first preference makes a live install read "never activated" for
    // ever. Uploads already use the delete token.
    return Telemetry.deleteToken ?? Telemetry.selfReadToken;
  }

  /// True when a fresh check is due (or none has ever succeeded).
  static bool checkDue() {
    final at = state()['checkedAt'];
    if (at is! int) return true;
    return (Telemetry.nowMs() - at) >= checkIntervalMs;
  }

  /// POST /entitlements/check. Returns the status string on success, null when
  /// the server could not be reached (which leaves the stored answer alone — an
  /// unreachable server is not a revocation).
  static Future<String?> check({
    Map<String, Object?>? integrity,
    bool force = false,
  }) {
    return _check(integrity: integrity, force: force);
  }

  static Future<String?> _check({
    Map<String, Object?>? integrity,
    bool force = false,
    int? chaseGeneration,
  }) async {
    if (RuntimeFlags.disabled) return null;

    if (!force && !checkDue()) {
      final status = state()['status'];
      return status is String ? status : null;
    }

    return Safe.runAsync<String?>(null, () async {
      final installId = Telemetry.installId;
      final token = _entitlementCredential();
      if (installId == null || token == null) return null;

      final payload = <String, Object?>{
        'installId': installId,
        'kitVersion': RUNTIME_VERSION,
      };
      if (integrity != null) payload['integrity'] = integrity;

      final res = await Transmit.safeTransmit(
        '${RuntimeFlags.apiBase}/entitlements/check',
        payload,
        authToken: token,
        timeoutMs: 4000,
      );
      if (chaseGeneration != null &&
          (!_chasing || chaseGeneration != _chaseGeneration)) {
        return null;
      }
      final status = res.status;
      final body = res.body;
      if (status != 200) {
        if (status == 401 &&
            body != null &&
            body['error'] == 'credentials_cut') {
          final serverReason = body['reason'];
          final reason = serverReason == revoked ||
                  serverReason == unpaid ||
                  serverReason == tampered ||
                  serverReason == paused
              ? serverReason as String
              : revoked;
          final detail =
              body['detail'] is String ? body['detail'] as String : null;
          _store(reason, detail, defaultGraceSeconds, false);
          return reason;
        }
        return null;
      }
      if (body == null) return null;
      final answer = body['status'] is String ? body['status'] as String : null;
      if (answer == null) return null;

      final grace = body['graceSeconds'] is int
          ? body['graceSeconds'] as int
          : defaultGraceSeconds;
      final msg = body['message'] is String ? body['message'] as String : null;
      _store(answer, msg, grace, answer == active);
      return answer;
    });
  }

  /// A bounded, idempotent ladder for the first entitlement answer. Each step
  /// waits for the preceding request, stops immediately on an answer/disable,
  /// and costs no request while registration has not minted a credential.
  static void chaseFirstActivation() {
    Safe.fire(() {
      if (RuntimeFlags.disabled || _chasing || isActivated()) return;
      _chasing = true;
      _chaseStep = 0;
      _chaseGeneration++;
      _scheduleChase();
    });
  }

  static void _scheduleChase() {
    if (RuntimeFlags.disabled ||
        isActivated() ||
        _chaseStep >= _chaseDelaysMs.length) {
      stopActivationChase();
      return;
    }
    final delay = _chaseDelaysMs[_chaseStep++];
    final generation = _chaseGeneration;
    try {
      _chaseTimer = _chaseScheduler(Duration(milliseconds: delay), () {
        if (!_chasing || generation != _chaseGeneration) return;
        _chaseTimer = null;
        Safe.fireAsync(() async {
          if (!_chasing || generation != _chaseGeneration) return;
          if (RuntimeFlags.disabled || isActivated()) {
            stopActivationChase();
            return;
          }
          // check() itself refuses to transmit without an install credential.
          await _check(force: true, chaseGeneration: generation);
          if (!_chasing || generation != _chaseGeneration) return;
          if (RuntimeFlags.disabled || isActivated()) {
            stopActivationChase();
          } else {
            _scheduleChase();
          }
        });
      });
    } catch (_) {
      stopActivationChase();
    }
  }

  static void stopActivationChase() {
    _chaseGeneration++;
    Safe.fire(() => _chaseTimer?.cancel());
    _chaseTimer = null;
    _chaseStep = 0;
    _chasing = false;
  }

  /// Test seam.
  static void seedForTests(
    String status, [
    int graceSeconds = defaultGraceSeconds,
  ]) {
    _store(status, null, graceSeconds, status == active);
  }

  static void clear() {
    final answered = isActivated();
    Store.delete(key);
    if (answered) _notify();
  }

  static void _store(
    String status,
    String? message,
    int graceSeconds,
    bool success,
  ) {
    final wasActivated = isActivated();
    final wasActive = isActive();
    final wasVisible = visibleStatus();
    Store.update(key, <String, Object?>{}, (cur) {
      final rec = cur is Map
          ? Map<String, Object?>.from(cur)
          : <String, Object?>{};
      rec['status'] = status;
      rec['message'] = message;
      rec['graceSeconds'] = graceSeconds;
      rec['checkedAt'] = Telemetry.nowMs();
      if (success) rec['lastSuccessAt'] = Telemetry.nowMs();
      return rec;
    }, true);
    if (!wasActivated ||
        isActive() != wasActive ||
        visibleStatus() != wasVisible) {
      _notify();
    }
  }

  static void setChaseTestHooks({
    List<int>? delaysMs,
    Timer Function(Duration, void Function())? scheduler,
  }) {
    if (delaysMs != null) _chaseDelaysMs = List<int>.of(delaysMs);
    if (scheduler != null) _chaseScheduler = scheduler;
  }

  /// Test-only stand-in for registration handing over (or failing to hand
  /// over) a credential. Pass null to represent no credential.
  static void setInstallCredentialForTests(String? token) {
    _credentialOverrideSet = true;
    _credentialOverride = token;
  }

  static void resetForTests() {
    stopActivationChase();
    _listeners.clear();
    _chaseDelaysMs = const <int>[1500, 3000, 6000, 12000, 24000];
    _chaseScheduler = (delay, callback) => Timer(delay, callback);
    _credentialOverrideSet = false;
    _credentialOverride = null;
    clear();
  }
}
