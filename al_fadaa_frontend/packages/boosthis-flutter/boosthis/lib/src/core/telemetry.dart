import 'dart:io';
import 'dart:math';

import 'device_facts.dart';
import 'drop_report.dart';
import 'coverage_inventory.dart';
import 'kit_version.dart';
import 'project_identity.dart';
import 'project_key.dart';
import 'registration.dart';
import 'runtime_flags.dart';
import 'safe.dart';
import 'store.dart';
import 'transmit.dart';
import '../integration/instrument.dart' show Instrument;
import '../integration/nav_tracker.dart' show NavTracker;

enum UploadFailReason { unauthorized, rejected, serverError, unreachable }

/// Identity + consent: who this install is, whether it has been turned on, and
/// how much it is allowed to share.
///
/// ONBOARDING CONTRACT (differs from the Ruby kit on purpose): the kit NEVER
/// invents an install id at [enable] time. [enable] REQUIRES a UUID `installId`
/// supplied by the host; a value that is not a UUID is refused. If the server
/// later reports the id is a 404 orphan, the kit STOPS (marks itself
/// disconnected) — it does NOT rotate on that route the way the Ruby kit does.
/// Re-onboarding out of a 404 is an explicit host action.
///
/// THE ONE SELF-HEAL (F1): when this install id is reused but this copy holds
/// none of its credentials the server does NOT answer 404 — it answers HTTP 200
/// carrying {"status":"already_registered_no_token"}. A kit that only reads the
/// status code files that as a success and can then never upload anything,
/// forever, in silence. So on THAT marker (and only that marker) the kit mints a
/// fresh id EXACTLY ONCE — persisting the old one as [keyPreviousInstallId] — and
/// re-registers. If the retry still returns the marker it is NOT persisted as a
/// registration: the kit warns once (F2) and stops. It never loops.
///
/// TWO GATES the rest of the kit reads through here:
///   1. entitlement — is this install registered + not disconnected (KillSwitch)
///   2. sharing      — [fullTelemetry] (screen-bearing uploads) / [issuesEnabled]
///
/// `runtime` is the frozen tag "flutter". `platform` is the REAL device platform
/// the adapter hands in ("ios"/"android"/…); it is never the runtime tag.
class Telemetry {
  Telemetry._();

  /// The frozen runtime tag on the wire.
  static const String runtime = 'flutter';

  static const String keyInstallId = 'install_id';
  static const String keyDeleteToken = 'delete_token';
  static const String keyAppName = 'app_name';
  static const String keyRegistered = 'registered';
  static const String keyFullTelemetry = 'full_telemetry';
  static const String keyIssues = 'issues_enabled';
  static const String keyDisconnected = 'disconnected';
  static const String keyEnabledAt = 'enabled_at';
  static const String keyConsentShare = 'consent_share';
  static const String keyReadToken = 'read_token';
  static const String keyConsentTry = 'consent_try';
  static const String keyRegistrationStatus = 'registration_status';
  static const String keyPreviousInstallId = 'previous_install_id';

  /// The host's PRE-CONTACT quiet opt-out (parity with the React Native kit's
  /// `issuesOnly: true`). When set, a brand-new install stays on issue
  /// signatures only in the window BEFORE the server has answered, instead of
  /// the pre-contact "share" default. It is NOT a veto: the server's directive
  /// still wins in BOTH directions once it lands, and the in-code share opt-in
  /// still layers on top of it. See .agents/memory/phone-kit-sharing-posture.md.
  static const String keyPreContactQuiet = 'precontact_quiet';

  /// The fixed, machine-readable rejection every kit reads the same way.
  static const String invalidInstallIdMarker = 'invalid_install_id';

  /// The server's orphan answer: HTTP 200 carrying this frozen marker in the
  /// body. It rides an ordinary success code, so it can ONLY be recognised by
  /// this marker — a kit that looks at the status alone walks straight past it.
  static const String orphanInstallMarker = 'already_registered_no_token';

  /// A keyless/tokenless project must not knock on every flush. One attempt
  /// per hour, unless the host just called enable() explicitly.
  static const int consentRetryMs = 60 * 60 * 1000;

  static bool _invalidIdWarned = false;

  /// Set true when a server directive of OFF was applied in memory but could
  /// NOT be confirmed durable (see [Store.setDurableVerified]). The session
  /// stays closed regardless — memory already holds the OFF — but the next
  /// launch would find no stored value and fall back to the pre-contact
  /// "share" default, silently re-opening a channel the owner turned off. So
  /// the failure is surfaced in [panelNotice] / [stored] rather than swallowed.
  static bool _offPersistFailed = false;

  /// One-shot guard for the F2 "stayed inactive" line: EXACTLY ONE line per
  /// launch when registration did not go through, on stderr, ungated. Reset by
  /// [resetForTests] so a test can assert it fires once.
  static bool _inactiveWarned = false;
  static List<String>? _inactiveHint;
  static bool _keyOverrideWarned = false;
  static int? _lastUploadFailAtMs;
  static UploadFailReason? _lastUploadFailReason;
  static int _droppedUploads = 0;
  static bool _lastAttemptFailed = false;
  static ResolvedProjectKey _projectKey = ProjectKeyResolver.resolve(
    environment: (_) => null,
  );
  static bool _projectKeyResolved = false;

  static Future<bool>? _inFlightConsent;
  static void Function(bool enabled)? _fullTelemetryListener;

  /// Coverage starts empty at consent time and gains evidence as the app runs.
  /// Re-use the uploader tick to re-consent only when that answer changes.
  static String? _lastCoverageSent;
  static int _coverageRefreshes = 0;
  static int _coverageCheckedAt = 0;
  static const int maxCoverageRefreshes = 6;
  static const int coverageRefreshGapMs = 60 * 1000;

  /// Observe the owner's screen-bearing sharing directive. The sample queue
  /// uses this to erase and unwire itself synchronously when sharing turns off.
  static void setFullTelemetryListener(void Function(bool enabled)? listener) {
    _fullTelemetryListener = listener;
  }

  /// Where the F2 one-shot line goes. Defaults to the process stderr (honouring
  /// IOOverrides so a host that redirects stderr still sees it); a test can swap
  /// it to capture the line and assert it fires exactly once.
  static void Function(String line) _warnSink = _defaultWarnSink;

  static void _defaultWarnSink(String line) {
    (IOOverrides.current?.stderr ?? stderr).writeln(line);
  }

  /// Test seam: swap the stderr sink the F2 line writes to. Pass null to
  /// restore the default (real stderr).
  static void setWarnSinkForTests(void Function(String line)? sink) {
    _warnSink = sink ?? _defaultWarnSink;
  }

  /// Emit one line on the same ungated stderr sink as the "stayed inactive"
  /// line. Shared so the drop-report warning (which has the same "the developer
  /// does not yet suspect the kit" reason to be loud) inherits this line's
  /// crash-safety and a test can capture both through one sink. Never throws.
  static void warnLine(String line) {
    Safe.fire(() => _warnSink(line));
  }

  /// True once this launch has re-knocked consent for an install that already
  /// holds credentials. The server's directives ride the consent ANSWER, so a
  /// registered install still has to knock — but only once per launch.
  static bool _directivesRefreshed = false;

  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// The real device platform, handed in by the adapter. Diagnostic default
  /// "unknown" until set — NEVER the runtime tag.
  static String _platform = 'unknown';

  static void setPlatform(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      _platform = value.trim();
    }
  }

  static String get platform => _platform;

  /// Current epoch time in ms. Single seam so tests can reason about ageMs.
  static int nowMs() => DateTime.now().millisecondsSinceEpoch;

  static void noteUploadRejected(UploadFailReason reason, int rowCount) {
    Safe.fire(() {
      _lastUploadFailAtMs = nowMs();
      _lastUploadFailReason = reason;
      _droppedUploads += rowCount < 0 ? 0 : rowCount;
      _lastAttemptFailed = true;
    });
  }

  static void noteUploadAccepted() {
    Safe.fire(() => _lastAttemptFailed = false);
  }

  static ({int at, UploadFailReason reason})? get lastUploadFailure {
    final at = _lastUploadFailAtMs;
    final reason = _lastUploadFailReason;
    return at == null || reason == null ? null : (at: at, reason: reason);
  }

  static int get droppedUploadCount => _droppedUploads;
  static bool get isLastUploadAttemptFailed => _lastAttemptFailed;

  static bool isUuid(String? v) => v != null && _uuidRe.hasMatch(v);

  /// Turn the kit on for [installId]. REQUIRES a UUID; a non-UUID id is refused
  /// (returns false, nothing stored). Idempotent for the same id. Never throws.
  static bool enable({
    required String installId,
    String? appName,
    String? projectKey,
    bool? shareMeterWithAI,
    bool? issuesOnly,
  }) {
    return Safe.run<bool>(false, () {
      if (RuntimeFlags.disabled) return false;
      if (!isUuid(installId)) {
        // Refuse — the kit never invents or normalises an id.
        return false;
      }

      final existing = Store.get(keyInstallId, null);
      var activeInstallId = installId;
      if (existing is String && existing != installId) {
        // A self-healed install persists the host-supplied id as its previous
        // id. On relaunch the host still supplies that baked id, so adopt the
        // settled replacement rather than refusing the same installation.
        final previous = Store.get(keyPreviousInstallId, null);
        if (previous == installId && isUuid(existing)) {
          activeInstallId = existing;
        } else {
          // A genuinely different id was already onboarded in this scope.
          return false;
        }
      }

      var firstResolution = false;
      if (!_projectKeyResolved) {
        _projectKey = ProjectKeyResolver.resolve(code: projectKey);
        _projectKeyResolved = true;
        firstResolution = true;
      }
      final resolved = _projectKey;
      if (firstResolution &&
          resolved.replacedDifferentKey &&
          !_keyOverrideWarned) {
        _keyOverrideWarned = true;
        warnLine(
          '[boosthis] Flutter project key override selected ${resolved.display}; '
          'the key passed in code will not be used.',
        );
      }

      Store.set(keyInstallId, activeInstallId, durable: true);
      // Restore the project identity beside the credentials before consent can
      // update it, so a restarted app names its project immediately.
      restoreKitProject(activeInstallId);
      if (appName != null && appName.isNotEmpty) {
        Store.set(keyAppName, appName, durable: true);
      }
      Store.set(keyRegistered, true, durable: true);
      // Re-enabling clears a prior disconnected state for this same id.
      Store.set(keyDisconnected, false, durable: true);
      if (Store.get(keyEnabledAt, null) is! int) {
        Store.set(keyEnabledAt, nowMs(), durable: true);
      }
      if (shareMeterWithAI != null) {
        Store.set(keyConsentShare, shareMeterWithAI, durable: true);
      }
      // PRE-CONTACT quiet opt-out (parity with RN `issuesOnly: true`). Only
      // moved when the caller PASSED it, same "explicit > persisted"
      // precedence as the sharing field.
      if (issuesOnly != null) {
        Store.set(keyPreContactQuiet, issuesOnly, durable: true);
      }
      return true;
    });
  }

  static bool get enabled {
    if (RuntimeFlags.disabled) return false;
    return registered && !disconnected;
  }

  static String? get installId {
    final v = Store.get(keyInstallId, null);
    return v is String && v.isNotEmpty ? v : null;
  }

  static String? get appName {
    final v = Store.get(keyAppName, null);
    if (v is String && v.isNotEmpty) return v;
    return RuntimeFlags.appName;
  }

  static bool get registered {
    final v = Store.get(keyRegistered, false);
    return v == true && installId != null;
  }

  static bool get disconnected => Store.get(keyDisconnected, false) == true;

  /// The install's delete/auth token, learned at consent. Null until the server
  /// hands one back.
  static String? get deleteToken => readToken();

  static String? readToken() {
    final v = Store.get(keyDeleteToken, null);
    return v is String && v.isNotEmpty ? v : null;
  }

  static void storeToken(String? token) {
    if (token != null && token.isNotEmpty) {
      Store.set(keyDeleteToken, token, durable: true);
    }
  }

  static void deleteTokenLocal() => Store.delete(keyDeleteToken);

  /// The SELF-scoped read token, issued at first consent. Kept apart from the
  /// delete token so a kit that only ever reads never has to hold the one
  /// credential that can erase the install.
  static String? get selfReadToken {
    final v = Store.get(keyReadToken, null);
    return v is String && v.isNotEmpty ? v : null;
  }

  /// True once the server has minted credentials for this install — the only
  /// honest meaning of "registered WITH THE SERVER". [registered] is the local
  /// switch (the host turned the kit on); this is the network fact.
  static bool get hasCredentials =>
      readToken() != null || selfReadToken != null;

  /// The single project-key answer selected at start. The whole key is used
  /// only by authenticated wire calls; status surfaces use [stored]'s mask.
  static String? get effectiveProjectKey {
    return _projectKey.key;
  }

  /// The last registration outcome worth surfacing: null (fine),
  /// `invalid_install_id`, or `already_registered_no_token` (the reinstall
  /// lockout — the owner repairs it from the dashboard; this kit never rotates
  /// the host's own install id behind its back).
  static String? get registrationStatus {
    final v = Store.get(keyRegistrationStatus, null);
    return v is String && v.isNotEmpty ? v : null;
  }

  /// POST /installs/consent — the handshake that mints this install's tokens.
  /// Nothing can upload before it succeeds, so every send path calls this
  /// first (cheaply: it returns immediately once credentials are held).
  ///
  /// [explicit] is true for a host's own enable() call and bypasses the retry
  /// cooldown, so a developer who just pasted their project key sees it work.
  /// Never throws; a transport failure simply leaves the kit unregistered.
  static Future<bool> ensureRegistered({
    String? projectKey,
    bool explicit = false,
  }) async {
    final result = await Safe.runAsync<bool>(false, () async {
      if (RuntimeFlags.disabled) return false;
      if (registrationStatus == invalidInstallIdMarker) {
        Registration.markRegistrationRefused();
        return false;
      }

      final id = installId;
      if (id == null || !isUuid(id)) return false;

      // ACTIVATION LOCK precondition: registration needs SOME credential — a
      // project key, or a token from a previous consent. A copied, keyless
      // kit has nothing the server would accept, so it stays silent. An
      // install that already holds credentials is registered either way, so
      // the honest answer for it is true rather than false.
      final key = _projectKey.key;
      if (key == null || key.isEmpty) {
        if (hasCredentials) {
          Registration.markRegistrationConfirmed();
        } else {
          Registration.markRegistrationRefused();
          _warnHintOnce(noProjectKeyHint(_projectKey.noProjectKeyChosen));
        }
        return hasCredentials;
      }

      // ALREADY REGISTERED — knock once more anyway.
      //
      // The server's two directives (the dashboard "Full telemetry" switch and
      // the AI-share mirror) ride the consent ANSWER and nothing else. A kit
      // that stops knocking the moment it holds credentials can therefore
      // never learn that the developer flipped a switch, which makes both
      // switches dead for every shipped app. One knock per launch (the RN kit
      // re-knocks the same way) is enough to carry them, and bounds the extra
      // traffic to a single request even though the uploader calls this before
      // every send. A failed refresh never regresses registration: we hold
      // credentials, so the answer stays true.
      if (hasCredentials) {
        if (!explicit && _directivesRefreshed) return true;
        _directivesRefreshed = true;
        final pending = _inFlightConsent;
        if (pending != null) {
          await pending;
          return true;
        }
        final refresh = _postConsent(id, key);
        _inFlightConsent = refresh;
        try {
          await refresh;
        } finally {
          _inFlightConsent = null;
        }
        return true;
      }

      if (!explicit) {
        final last = Store.get(keyConsentTry, 0);
        final lastMs = last is int ? last : 0;
        if (lastMs > 0 && (nowMs() - lastMs) < consentRetryMs) return false;
      }
      // The stamp must outlive a restart, or a keyless app re-knocks on every
      // launch. Written BEFORE the call so a failure still spends the slot.
      Store.set(keyConsentTry, nowMs(), durable: true);

      final inFlight = _inFlightConsent;
      if (inFlight != null) return inFlight;
      final fut = _postConsent(id, key);
      _inFlightConsent = fut;
      try {
        return await fut;
      } finally {
        _inFlightConsent = null;
      }
    });
    return result;
  }

  /// [rotated] guards the F1 reinstall self-heal: on the orphan marker, if we
  /// have not yet rotated this launch and hold no delete token, mint a fresh id
  /// and re-register EXACTLY ONCE. The flag passed back in on that retry closes
  /// the loop, so a server that keeps answering the same way can never cycle.
  static Future<bool> _postConsent(
    String id,
    String projectKey, {
    bool rotated = false,
  }) async {
    final payload = <String, Object?>{
      'installId': id,
      'runtime': runtime,
      'packageVersion': RUNTIME_VERSION,
    };
    final name = appName;
    if (name != null && name.isNotEmpty) payload['appName'] = name;
    final inventory = coverageInventory();
    if (!inventory.isEmpty) payload['coverage'] = inventory.toJson();
    // Remember even the empty answer: its omission is itself the inventory sent
    // at startup, and later positive evidence must be allowed to replace it.
    _lastCoverageSent = coverageFingerprint(inventory);

    // Proof of control for the one-time read-token backfill on re-consent.
    final held = readToken();
    final res = await Transmit.safeTransmit(
      '${RuntimeFlags.apiBase}/installs/consent',
      payload,
      authToken: projectKey,
      timeoutMs: 5000,
      headers: held == null
          ? null
          : <String, String>{'X-Boosthis-Install-Token': held},
    );

    final body = res.body;

    // The orphan dead end — checked BEFORE the success branch because it rides
    // a 200. When this install id is already registered but this copy holds no
    // credentials for it (a copied build, a restored backup, a rebuilt
    // container), the server answers 200 with
    // {"status":"already_registered_no_token"}. Falling into the success branch
    // would persist a credential-less registration that can never upload: the
    // install then looks connected, reports nothing, and says nothing — the
    // exact silent dead end the sibling kits self-heal out of.
    if (_isOrphanResponse(res.status, body)) {
      Registration.markRegistrationRefused();
      if (!rotated && readToken() == null && projectKey.isNotEmpty) {
        return _rotateInstallIdAndRetry(id, projectKey);
      }
      // Rotation has already happened (or cannot), and the answer is still the
      // orphan marker. This is NOT a registration: record it so the panel can
      // say so, warn once (F2), and stop. Never loop.
      if (body != null) _persistConsent(body);
      _warnStayedInactiveOnce(res.status, body);
      return false;
    }

    if ((res.status == 200 || res.status == 201) && body != null) {
      _persistConsent(body);
      if (hasCredentials) {
        Registration.markRegistrationConfirmed();
      } else {
        Registration.markRegistrationUnreachable();
      }
      return hasCredentials;
    }
    // A malformed install id will never fix itself: record it, warn once, and
    // never retry (the hourly stamp would otherwise be pure noise).
    if (body != null && body['error'] == invalidInstallIdMarker) {
      Registration.markRegistrationRefused();
      Store.set(keyRegistrationStatus, invalidInstallIdMarker, durable: true);
      if (!_invalidIdWarned) {
        _invalidIdWarned = true;
        Safe.note(
          StateError('server rejected install id as invalid_install_id'),
        );
      }
      _warnStayedInactiveOnce(res.status, body);
      return false;
    }
    // 404 = the server does not know this id. Per this kit's onboarding
    // contract the host owns the id, so we STOP instead of rotating to one the
    // host has never heard of; re-onboarding is an explicit host action.
    if (res.status == 404) markOrphan();
    if (res.status == 401 || res.status == 403) {
      Registration.markRegistrationRefused();
    } else {
      Registration.markRegistrationUnreachable();
    }
    _warnStayedInactiveOnce(res.status, body);
    return false;
  }

  /// Existing periodic paths call this after ordinary consent. It performs no
  /// work unless the inventory changed, checks at most once a minute, and sends
  /// at most six refreshes in one process. Never throws into the host.
  static Future<void> maybeRefreshCoverage({int? now}) async {
    await Safe.runAsync<void>(null, () async {
      if (RuntimeFlags.disabled || !hasCredentials) return;
      if (_coverageRefreshes >= maxCoverageRefreshes) return;
      final at = now ?? nowMs();
      if (_coverageCheckedAt != 0 &&
          at - _coverageCheckedAt < coverageRefreshGapMs) {
        return;
      }
      _coverageCheckedAt = at;
      final previous = _lastCoverageSent;
      if (previous == null) return;
      final current = coverageFingerprint(coverageInventory());
      if (current == previous) return;
      final id = installId;
      final key = effectiveProjectKey;
      if (id == null || key == null || key.isEmpty) return;
      _coverageRefreshes++;

      final pending = _inFlightConsent;
      if (pending != null) {
        await pending;
        return;
      }
      final refresh = _postConsent(id, key);
      _inFlightConsent = refresh;
      try {
        await refresh;
      } finally {
        _inFlightConsent = null;
      }
    });
  }

  /// The server's orphan answer: HTTP 200 carrying the frozen marker
  /// {"status":"already_registered_no_token"}. Matched on the BODY, because the
  /// status here is an ordinary success code.
  static bool _isOrphanResponse(int status, Map<String, Object?>? body) {
    if (status != 200) return false;
    if (body == null) return false;
    return body['status'] == orphanInstallMarker;
  }

  /// Mint a fresh install id, remember the one it replaced, and re-register
  /// EXACTLY ONCE — the `rotated: true` passed back in closes the loop.
  static Future<bool> _rotateInstallIdAndRetry(
    String oldId,
    String projectKey,
  ) async {
    final fresh = _newInstallId();
    // Keep the mapping so an operator can see what the id used to be, and swap
    // the active id BEFORE the retry so the fresh id is what goes on the wire.
    Store.set(keyPreviousInstallId, oldId, durable: true);
    Store.set(keyInstallId, fresh, durable: true);
    restoreKitProject(fresh);
    // A rotated id starts clean: it must never carry the previous id's orphan
    // registration state into the retry.
    Store.set(keyDisconnected, false, durable: true);
    Store.delete(keyRegistrationStatus);
    return _postConsent(fresh, projectKey, rotated: true);
  }

  /// A fresh random UUID for the ONE self-heal path. Uses the platform CSPRNG.
  static String _newInstallId() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant
    String hx(int i, int n) {
      final sb = StringBuffer();
      for (var j = i; j < i + n; j++) {
        sb.write(b[j].toRadixString(16).padLeft(2, '0'));
      }
      return sb.toString();
    }

    return '${hx(0, 4)}-${hx(4, 2)}-${hx(6, 2)}-${hx(8, 2)}-${hx(10, 6)}';
  }

  /// EXACTLY ONE line per launch when registration did not go through, on the
  /// runtime's standard error stream, NOT gated behind BOOSTHIS_DEBUG.
  ///
  /// Silence is the wrong answer here and this is the one place the kit says so
  /// out loud. A kit that cannot register looks identical to a kit that is
  /// working — same quiet process, same absent numbers — so the developer goes
  /// looking in the wrong place, usually for hours (a broken certificate store
  /// cost one customer ~19 minutes). A debug flag only helps the developer who
  /// already suspects the kit; this exists for the one who does not. The line
  /// names the coarse reason and the next move and carries NO project key, NO
  /// token, NO URL and NO server-supplied text — kit-generated strings only.
  static void _warnStayedInactiveOnce(int status, Map<String, Object?>? body) {
    _warnHintOnce(registrationFailureHint(status, body));
  }

  static void _warnHintOnce(List<String> hint) {
    Safe.fire(() {
      if (_inactiveWarned) return;
      _inactiveWarned = true;
      _inactiveHint = hint;
      _warnSink(
        '[boosthis] Boosthis stayed inactive because ${hint[0]}. ${hint[1]}',
      );
    });
  }

  static List<String> noProjectKeyHint(bool chosen) {
    if (chosen) {
      return <String>[
        'this app is set to run with no project key',
        'That is a deliberate setting: this app measures itself and never appears on your Boosthis dashboard. Nothing is being sent.',
      ];
    }
    return <String>[
      'no project key is wired into this app',
      'Without one this app measures itself and never appears on your Boosthis dashboard. Copy a project key from your Boosthis Setup page into this app, then relaunch the app.',
    ];
  }

  static String? get inactiveNoticeBody {
    final hint = _inactiveHint;
    if (hint == null) return null;
    return 'Boosthis stayed inactive because ${hint[0]}. ${hint[1]}';
  }

  /// [why, what to do] for the one-shot line above. Derived from the status and
  /// the frozen error markers only — never from server text.
  static List<String> registrationFailureHint(
    int status,
    Map<String, Object?>? body,
  ) {
    if (_isOrphanResponse(status, body)) {
      // The one case that reads like success on the wire: HTTP 200, and the
      // install still cannot upload. Name it plainly.
      return <String>[
        'this install id already belongs to another copy of the app, and this copy holds none of its credentials',
        'Unset BOOSTHIS_INSTALL_ID (or give this copy its own fresh UUID), then relaunch the app.',
      ];
    }
    if (status == 0) {
      // No HTTP answer at all: DNS, TLS, egress or a proxy. The kit's own last
      // recorded error is the single most useful thing we can say — it is where
      // a broken certificate store or a blocked egress actually shows up. But a
      // transport error's raw text is NOT kit-generated: it can carry the
      // request URL, a credential-bearing URL, or remote prose. So we classify
      // it into a fixed, kit-owned phrase and never echo the message itself.
      final recent = Safe.recentErrors;
      final last = recent.isEmpty ? '' : recent.last;
      final detail = _transportDetail(last);
      return <String>[
        'it could not reach the Boosthis API from this process$detail',
        'Check outbound HTTPS and certificate trust from this app, then relaunch the app.',
      ];
    }
    if (status == 401 || status == 403) {
      switch (body?['error']) {
        case 'invite_key_revoked':
          return <String>[
            'its project key has been revoked',
            'A revoked key never works again. Mint a new project key in your Boosthis dashboard, put it in this app, then relaunch the app.',
          ];
        case 'plan_required':
        case 'account_closure_pending':
          return <String>[
            'its project key is paused by a billing problem on the account',
            'Settle the account in your Boosthis dashboard and the same key starts working again. Nothing has been revoked.',
          ];
        case 'invite_key_unknown':
          return <String>[
            'its project key was not recognised',
            'Check it is the current key, pasted whole, with no stray spaces, and that it belongs to this project.',
          ];
        default:
          return <String>[
            "its project key wasn't accepted",
            'Check the project key in your Boosthis Setup page, then relaunch the app.',
          ];
      }
    }
    return <String>[
      'the server refused the registration (HTTP $status)',
      'Retry later; if it keeps happening, check the project key in your '
          'Boosthis dashboard.',
    ];
  }

  /// Turn the kit's last recorded transport error into a parenthetical for the
  /// one-shot inactive line. The recorded line is `TypeName: message` (see
  /// [Safe.note]); we read the type AND message ONLY to match, and emit a
  /// FIXED, kit-owned phrase. The error message never appears in the output.
  ///
  /// Guest-safe: never throws (an empty/odd line yields ''), allocates nothing
  /// unbounded, makes no network call. First match wins.
  static String _transportDetail(String recorded) {
    if (recorded.isEmpty) return '';
    final lower = recorded.toLowerCase();
    bool has(String needle) => lower.contains(needle);

    if (has('certificate') ||
        has('tls') ||
        has('ssl') ||
        has('x509') ||
        has('self signed') ||
        has('self-signed') ||
        has('unable to verify') ||
        has('certificate_verify_failed') ||
        has('sslhandshake') ||
        has('trust anchor') ||
        has('unable to get local issuer')) {
      return ' (the certificate store rejected the connection)';
    }
    if (has('getaddrinfo') ||
        has('name or service not known') ||
        has('enotfound') ||
        has('unknownhost') ||
        has('nodename nor servname') ||
        has('no such host') ||
        has('failed to resolve') ||
        has('dns')) {
      return ' (the API host name did not resolve)';
    }
    if (has('econnrefused') || has('connection refused')) {
      return ' (the connection was refused)';
    }
    if (has('etimedout') || has('timeout') || has('timed out')) {
      return ' (the connection timed out)';
    }
    if (has('proxy')) {
      return ' (a proxy rejected the connection)';
    }
    if (has('enetunreach') ||
        has('network is unreachable') ||
        has('no route to host')) {
      return ' (the network was unreachable)';
    }

    // No match: emit the TYPE/CLASS NAME ONLY, never the message. The recorded
    // line is `TypeName: message`, so the type is everything before the first
    // ": ". Drop every character outside [A-Za-z0-9_.], then cap at 60. An
    // empty result yields no parenthetical at all.
    final sep = recorded.indexOf(': ');
    final typeName = sep >= 0 ? recorded.substring(0, sep) : recorded;
    final buf = StringBuffer();
    for (var i = 0; i < typeName.length && buf.length < 60; i++) {
      final c = typeName[i];
      final isAllowed =
          (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) ||
          (c.compareTo('a') >= 0 && c.compareTo('z') <= 0) ||
          (c.compareTo('0') >= 0 && c.compareTo('9') <= 0) ||
          c == '_' ||
          c == '.';
      if (isAllowed) buf.write(c);
    }
    final sanitised = buf.toString();
    if (sanitised.isEmpty) return '';
    return ' ($sanitised)';
  }

  static void _persistConsent(Map<String, Object?> body) {
    final delete = body['deleteToken'];
    if (delete is String && delete.isNotEmpty) {
      Store.set(keyDeleteToken, delete, durable: true);
    }
    final read = body['readToken'];
    if (read is String && read.isNotEmpty) {
      Store.set(keyReadToken, read, durable: true);
    }
    // The project name is the one developer-authored wire string the panel
    // renders, so project_identity sanitises it again before display. Older
    // servers omit both fields; that must not erase a previously restored name.
    if (body.containsKey('projectName') || body.containsKey('projectCode')) {
      setKitProject(body['projectName'], body['projectCode']);
      final id = installId;
      if (id != null) persistKitProject(id);
    }
    // The server's own directives ride the same answer. Route the sharing
    // directive through applyServerFullTelemetry so an OFF is made DURABLE
    // (with retry) on the consent path too, not just on the entitlement
    // check-in — a memory-only OFF here would be forgotten at the next launch.
    final full = body['fullTelemetry'];
    final share = body['shareMeterWithAI'];
    applyServerFullTelemetry(fullTelemetry: full is bool ? full : null);
    if (share is bool && share) {
      Store.set(keyConsentShare, true, durable: true);
    }
    if (body['disconnected'] == true) {
      Store.set(keyDisconnected, true, durable: true);
    }
    final status = body['status'];
    // "already_registered_no_token" is the reinstall lockout: the install
    // exists but we hold nothing. Record it so the bubble/status can say so
    // and the owner can open a Repair window from the dashboard.
    if (status is String && status.isNotEmpty && !hasCredentials) {
      Store.set(keyRegistrationStatus, status, durable: true);
    } else if (hasCredentials) {
      Store.delete(keyRegistrationStatus);
    }
  }

  /// Everything the kit has stored about this install (for status/debug).
  static Map<String, Object?> stored() {
    return <String, Object?>{
      'installId': installId,
      'appName': appName,
      'registered': registered,
      'disconnected': disconnected,
      'fullTelemetry': fullTelemetry,
      'issuesEnabled': issuesEnabled,
      'hasToken': readToken() != null,
      'hasCredentials': hasCredentials,
      'registrationStatus': registrationStatus,
      'sharingOffNotDurable': _offPersistFailed,
      'projectKey': _projectKey.display,
      'projectKeySource': _projectKey.sourceDescription,
      'inactiveNotice': inactiveNoticeBody,
    };
  }

  /// PHONE-CATEGORY PRE-CONTACT DEFAULT — the sharing posture of a brand-new
  /// install in the window before the server has ever answered. Identical in
  /// all four phone kits (React Native, Swift, Flutter, Android/Kotlin) and
  /// held there by the phone-kit sharing parity guard. It matches the server's
  /// day-one default so the kit never states a second, contradictory answer.
  /// See .agents/memory/phone-kit-sharing-posture.md.
  static const bool preContactFullTelemetryDefault = true;

  /// Screen-bearing sharing switch.
  ///
  /// THREE-STATE, deliberately, and the SERVER'S answer is read FIRST. A stored
  /// value is what the owner's dashboard last said, and it is honoured in BOTH
  /// directions: their OFF must stop screen-bearing uploads even while the
  /// in-code opt-in is true — or while the sticky flag the server itself sets
  /// once an AI read connection exists is true. Those two only ever ADD
  /// sharing, and only in the window before the server has answered; a phone
  /// kit measures the customer's own end users, so the dashboard switch is the
  /// control they rely on and nothing may outrank it. The in-code opt-in stays
  /// an OR contributor and never a veto: an in-code false against a server true
  /// is still ON.
  ///
  /// NO stored value means we have not asked yet — the pre-contact default,
  /// never a fabricated "off". (Nothing can leave the device in that window
  /// regardless: every upload path also requires the delete token minted by the
  /// consent answer.)
  static bool get fullTelemetry {
    if (!enabled) return false;
    // A server OFF whose durable write failed keeps the session closed — never
    // fall back to the pre-contact "share" default after a known OFF.
    if (_offPersistFailed) return false;
    // The SERVER'S answer is read FIRST: it wins in BOTH directions.
    final stored = Store.get(keyFullTelemetry, null);
    if (stored is bool) return stored;
    // Pre-contact only, from here down. The in-code share opt-in ADDS sharing
    // (OR contributor, never a veto).
    if (Store.get(keyConsentShare, false) == true) return true;
    // The host's pre-contact quiet opt-out (parity with RN `issuesOnly`)
    // REMOVES sharing before the server has answered — never a fabricated OFF
    // once the server speaks (that was handled above).
    if (Store.get(keyPreContactQuiet, false) == true) return false;
    return preContactFullTelemetryDefault;
  }

  /// True when a server OFF was applied in memory but could not be confirmed
  /// durable. Surfaced by the in-app panel so the developer learns the OFF may
  /// not survive a relaunch — the kit never silently falls back to ON after a
  /// known OFF. See .agents/memory/phone-kit-sharing-posture.md.
  static bool get sharingOffNotDurable => _offPersistFailed;

  static bool get issuesEnabled {
    if (!enabled) return false;
    return Store.get(keyIssues, false) == true;
  }

  /// Apply the server's consent directive: whether full telemetry / issues are
  /// enabled for this project. Called by the entitlement check-in.
  /// An owner's OFF must be DURABLE: applied in memory immediately, but also
  /// confirmed to disk (with one retry) so the next launch does not find no
  /// stored value, read it as "not asked yet", and resume screen-bearing
  /// uploads under the pre-contact "share" default. If it still cannot be
  /// stored, the session stays closed ([_offPersistFailed] latches the gate
  /// shut) and the failure is surfaced in the panel — never a silent fall-back
  /// to ON after a known OFF. See .agents/memory/phone-kit-sharing-posture.md.
  static void applyServerFullTelemetry({
    bool? fullTelemetry,
    bool? issuesEnabled,
  }) {
    Safe.fire(() {
      if (fullTelemetry != null) {
        final persisted = Store.setDurableVerified(
          keyFullTelemetry,
          fullTelemetry,
        );
        if (!fullTelemetry && !persisted) {
          // A known OFF we could not make durable: keep the session closed and
          // say so, rather than fall back to ON next launch.
          _offPersistFailed = true;
        } else if (persisted || fullTelemetry) {
          // A known server ON ALWAYS wins and is never overridden by an in-code
          // or pre-contact preference — including a stale OFF latch. So a
          // confirmed write (either direction) OR any ON clears a prior
          // not-durable-OFF failure. Otherwise a failed OFF followed by an ON
          // whose write also fails would leave the session forced OFF forever.
          // A non-durable ON is safe: the next launch simply falls back to the
          // pre-contact default.
          _offPersistFailed = false;
        }
        Safe.fire(() => _fullTelemetryListener?.call(fullTelemetry));
      }
      if (issuesEnabled != null) {
        Store.set(keyIssues, issuesEnabled, durable: true);
      }
    });
  }

  /// The server says this install id is unknown (404 orphan). The Flutter kit
  /// STOPS rather than rotating: mark disconnected and keep the id for the
  /// host's own diagnostics. Re-onboarding is an explicit host action.
  static void markOrphan() {
    Safe.fire(() => Store.set(keyDisconnected, true, durable: true));
  }

  static bool get invalidInstallId {
    final v = Store.get(keyInstallId, null);
    return v is String && v.isNotEmpty && !isUuid(v);
  }

  /// How long this install has been enabled, in ms; null when never enabled.
  static int? ageMs() {
    final v = Store.get(keyEnabledAt, null);
    if (v is! int) return null;
    final int d = nowMs() - v;
    return d < 0 ? 0 : d;
  }

  /// Erase this install locally. (The server delete call is issued by the Kit
  /// facade before this, using the token.) Never throws.
  static bool forget() {
    return Safe.run<bool>(false, () {
      Store.forgetAll();
      // The platform-facts sensor keeps its observations in memory rather
      // than in the store, so forgetting the store would leave it running.
      // Nothing Boosthis-shaped survives forget().
      clearDeviceFacts();
      Instrument.resetScreenTiming();
      NavTracker.reset();
      return true;
    });
  }

  /// Test seam.
  static void resetForTests() {
    Instrument.resetScreenTiming();
    NavTracker.reset();
    Registration.resetForTests();
    _platform = 'unknown';
    _directivesRefreshed = false;
    _lastCoverageSent = null;
    _coverageRefreshes = 0;
    _coverageCheckedAt = 0;
    _inactiveWarned = false;
    _inactiveHint = null;
    _keyOverrideWarned = false;
    _projectKey = ProjectKeyResolver.resolve(environment: (_) => null);
    _projectKeyResolved = false;
    _invalidIdWarned = false;
    _offPersistFailed = false;
    _lastUploadFailAtMs = null;
    _lastUploadFailReason = null;
    _droppedUploads = 0;
    _lastAttemptFailed = false;
    _warnSink = _defaultWarnSink;
    _fullTelemetryListener = null;
    resetKitProjectForTests();
    // Forget the drop-report state too, so a test can assert the one-shot
    // drop line fires exactly once from a clean slate.
    DropReport.resetForTests();
    Store.resetForTests();
  }
}
