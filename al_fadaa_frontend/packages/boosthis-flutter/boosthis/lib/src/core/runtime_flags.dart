import 'dart:io' show Platform;

/// Environment flags. Every one is read fresh (no caching) so an operator can
/// flip a flag without a restart.
///
/// `BOOSTHIS_DISABLED` is absolute: no network, no state writes, no meters. It
/// outranks every other setting including an active entitlement.
///
/// READING ORDER (frozen by the port contract): in a Flutter app these arrive
/// via `--dart-define`, so [env] reads `String.fromEnvironment` FIRST, then
/// falls back to `Platform.environment` (which is what the MCP binary and the
/// parity harness use). `dart:io` is guarded — a platform without a real
/// environment (e.g. Flutter web) must never throw here.
///
/// Env var names are identical to every sibling kit.
class RuntimeFlags {
  RuntimeFlags._();

  /// Read one env var, dart-define first, then the process environment.
  ///
  /// Returns null for an unset OR empty value.
  static String? env(String name) {
    // 1. Compile-time --dart-define (the Flutter path). fromEnvironment is a
    //    const constructor; the value must be a compile-time constant, so we
    //    resolve the known names explicitly.
    final defined = _fromDefine(name);
    if (defined != null && defined.isNotEmpty) return defined;

    // 2. Process environment (MCP binary / harness / CLI). Guarded: some
    //    platforms make Platform.environment throw.
    try {
      final v = Platform.environment[name];
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {
      // No filesystem/environment on this platform — degrade to unset.
    }
    return null;
  }

  /// `String.fromEnvironment` requires a compile-time-constant key, so the
  /// small set of names the kit actually reads is enumerated here.
  static String? _fromDefine(String name) {
    switch (name) {
      case 'BOOSTHIS_DISABLED':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_DISABLED'));
      case 'BOOSTHIS_DEBUG':
        return _orNull(const String.fromEnvironment('BOOSTHIS_DEBUG'));
      case 'BOOSTHIS_API_BASE':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_API_BASE'));
      case 'BOOSTHIS_STATE_DIR':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_STATE_DIR'));
      case 'BOOSTHIS_NO_BUBBLE':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_NO_BUBBLE'));
      case 'BOOSTHIS_FORCE_BUBBLE':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_FORCE_BUBBLE'));
      case 'BOOSTHIS_BUBBLE':
        return _orNull(const String.fromEnvironment('BOOSTHIS_BUBBLE'));
      case 'BOOSTHIS_INVITE_KEY':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_INVITE_KEY'));
      case 'BOOSTHIS_PROJECT_KEY':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_PROJECT_KEY'));
      case 'BOOSTHIS_PROJECT_KEY_FLUTTER':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_PROJECT_KEY_FLUTTER'));
      case 'BOOSTHIS_INSTALL_ID':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_INSTALL_ID'));
      case 'BOOSTHIS_APP_NAME':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_APP_NAME'));
      case 'BOOSTHIS_PROJECT_ROOT':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_PROJECT_ROOT'));
      case 'BOOSTHIS_TURBO':
        return _orNull(const String.fromEnvironment('BOOSTHIS_TURBO'));
      case 'BOOSTHIS_BUILD_TIME_MS':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_BUILD_TIME_MS'));
      case 'BOOSTHIS_BUILD_COMMIT':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_BUILD_COMMIT'));
      case 'BOOSTHIS_AI_ENDPOINTS':
        return _orNull(
            const String.fromEnvironment('BOOSTHIS_AI_ENDPOINTS'));
      default:
        return null;
    }
  }

  static String? _orNull(String v) => v.isEmpty ? null : v;

  static bool _flag(String name) {
    return parseBooleanDirective(env(name)) == true;
  }

  /// Parse an explicit boolean directive. Unknown and unset values do not
  /// override the next visibility source.
  static bool? parseBooleanDirective(String? value) {
    if (value == null) return null;
    final s = value.trim().toLowerCase();
    if (s == '1' || s == 'true' || s == 'yes' || s == 'on') return true;
    if (s == '0' || s == 'false' || s == 'no' || s == 'off') return false;
    return null;
  }

  /// Absolute off switch — no network, no state, no meters.
  static bool get disabled => _flag('BOOSTHIS_DISABLED');

  /// Extra logging to the host console. Off by default.
  static bool get debug => _flag('BOOSTHIS_DEBUG');

  /// Project / invite key (also accepted under its legacy name).
  static String? get projectKey =>
      env('BOOSTHIS_PROJECT_KEY') ?? env('BOOSTHIS_INVITE_KEY');

  static String? get appName => env('BOOSTHIS_APP_NAME');

  static String? get installId => env('BOOSTHIS_INSTALL_ID');

  static String? _apiBaseOverride;

  /// The host's own `apiBase:` argument (adapter → facade → here). A Flutter
  /// app has no process env at runtime, so an argument the host actually
  /// passed must win over the compile-time define; null clears it.
  static void setApiBase(String? value) {
    final v = value?.trim();
    _apiBaseOverride = (v == null || v.isEmpty) ? null : v;
  }

  /// Override the API base. Defaults to the hosted service. Trailing slashes
  /// trimmed so `${apiBase}/installs/consent` joins stay clean.
  /// Precedence: host argument → `--dart-define`/env → hosted default.
  static String get apiBase {
    final v = _apiBaseOverride ?? env('BOOSTHIS_API_BASE');
    if (v == null) return 'https://www.boosthis.com/api';
    return v.replaceAll(RegExp(r'/+$'), '');
  }

  /// Where cross-request state lives. Null falls back to the adapter-supplied
  /// documents dir, else a temp dir (resolved in Store).
  static String? get stateDir => env('BOOSTHIS_STATE_DIR');

  /// Explicit override of the host app root used for scope hashing.
  static String? get projectRoot => env('BOOSTHIS_PROJECT_ROOT');

  /// Primary, documented bubble visibility directive.
  static bool? get bubble => parseBooleanDirective(env('BOOSTHIS_BUBBLE'));

  /// Legacy alias that hides the bubble when truthy.
  static bool get noBubble => _flag('BOOSTHIS_NO_BUBBLE');

  /// Legacy alias that shows the bubble when truthy.
  static bool get forceBubble => _flag('BOOSTHIS_FORCE_BUBBLE');
}
