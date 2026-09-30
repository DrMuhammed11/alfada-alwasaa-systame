/// What this PHONE PLATFORM allows — Flutter kit.
///
/// Boosthis holds a measured record of what a hosting platform really
/// permits. It could not answer for a phone, and a phone is held to MORE
/// rules than any server host: background execution windows, doze and app
/// standby, memory ceilings the OS enforces by killing you, timers that stop
/// without saying so. An assistant writing a Flutter app is working against
/// all of that with runtime feedback from nobody.
///
/// This file is this kit's contribution to that record. It reports FACTS
/// ABOUT THE PLATFORM — never about the app, the device or its owner — so
/// the server can pool them across every install on the same OS band.
///
/// THREE RULES DECIDE EVERY LINE HERE.
///
/// **Only what we WATCHED.** Every fact is a by-product of work the kit was
/// doing anyway: an upload already in flight, a tick already scheduled, a
/// memory-pressure callback the framework already delivered. Nothing here
/// starts work or arms a timer in order to answer a question.
///
/// **A key we omit is not a "no".** Four of the seven device facts are not
/// readable from Dart without a platform channel into native code, and this
/// kit ships no native side. Those keys never appear. Reporting our own
/// deafness as a platform finding is the one way this could make the record
/// worse than the empty one it starts from; the Swift and Kotlin kits report
/// those facts for the same bands.
///
/// **Nothing here is about a person.** Three yes/no observations and two
/// timestamps that never leave the process. The platform band is the only
/// thing describing the device, and it is exactly as specific as filing a
/// fact requires.
///
/// NEVER BLOCKS THE INTERFACE. Bookkeeping over integers on whatever isolate
/// already called in. No platform channel, no I/O, no unbounded loop. Every
/// entry point is total and can be called from a framework callback.
library;

import 'dart:io' show Platform;

import 'safe.dart';

/// The snapshot key the block travels under. Matches the server's
/// DEVICE_FACTS_KEY; a mismatch here is a block silently ignored.
const String kDeviceFactsKey = 'deviceFacts';

/// A background period shorter than this proves nothing. Matches the phone
/// kits' suspend threshold: a trip through `inactive` for a permission sheet
/// is the app still working, and judging "did pending work finish?" across
/// 200 ms answers yes on every platform, which measures nothing.
const int kDeviceBackgroundMinMs = 10000;

/// How late a timer may fire and still count as having fired in the
/// background. A tick due a second before the app came back and delivered a
/// second after it did is the OS holding it, not running it.
const int kTimerLateSlackMs = 1000;

/// The closed vendor list the server files a fact under. Spelled here only to
/// keep an arbitrary manufacturer string from travelling; anything not on it
/// is dropped and the server files under "unknown", which is a different
/// answer from any named vendor and never merged with one.
const List<String> kKnownVendors = <String>[
  'google',
  'samsung',
  'xiaomi',
  'huawei',
  'honor',
  'oppo',
  'vivo',
  'oneplus',
  'realme',
  'meizu',
  'asus',
  'sony',
  'nokia',
  'motorola',
];

int _backgroundSince = 0;
final Set<int> _pendingAtBackground = <int>{};
final Set<int> _inFlight = <int>{};
int _nextWorkId = 1;
int _armedDueAt = 0;

/// Three-valued: null means never observed. A false is only ever written by
/// watching the platform fail to do the thing, never by failing to look.
bool? _backgroundWorkRuns;
bool? _timersRunInBackground;
bool? _lowMemoryWarningGiven;

/// Reported by the adapter, which is the only place that can see it: an
/// Android manufacturer needs a device-info plugin, and this kit will not
/// require one. Null until an app that has one tells us.
String? _vendor;

/// The version band's two numbers, and the one thing `dart:io` cannot see.
///
/// A fact is filed under an OS AND a version band. Without the number the
/// server holds no band, files nothing, and says so to nobody — so this kit
/// establishes the number or sends no observation at all.
///
/// Android's API level is readable here: the Dart VM builds
/// `Platform.operatingSystemVersion` from the platform's own `SDK_INT` and
/// prints it as "... (API 34)". Reading a number the OS wrote is not the
/// guess this record forbids; failing to find one leaves it null.
///
/// Apple's is not readable here at all, because `Platform.isIOS` is true on
/// an iPad and iPadOS is a different platform with different background
/// rules. A host app that carries a device-info plugin can close that gap
/// through [setDeviceIdentity]; until it does, this kit files nothing on
/// Apple hardware rather than filing an iPad's answer under iOS.
int? _androidApi;
int? _iosMajor;
bool? _isPad;

/// The parse is done once and remembered, including its failure: the OS
/// version string cannot change inside a process, so a second look would
/// give the same answer at the same cost.
bool _osVersionRead = false;

/// The app's foreground state changed. Fed from the kit's ONE lifecycle
/// callback. Both background facts are decided here, because the answer is
/// only knowable at the transition: work still pending when the app comes
/// BACK is work the platform did not run.
void noteDeviceLifecycle(bool active, {int? nowMs}) {
  Safe.fire(() {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (!active) {
      // A repeat (inactive → paused is one trip out, not two) must not
      // re-snapshot, or work started while already backgrounded would be
      // judged as if it had been pending at the transition.
      if (_backgroundSince == 0) {
        _backgroundSince = now;
        _pendingAtBackground
          ..clear()
          ..addAll(_inFlight);
      }
      return;
    }
    if (_backgroundSince == 0) return;
    if (now - _backgroundSince >= kDeviceBackgroundMinMs) {
      // Work in flight when the app left and STILL in flight now did not run
      // while the app was away. A measured false: we watched the platform
      // hold it, we did not merely fail to see it finish.
      for (final int id in _pendingAtBackground) {
        if (_inFlight.contains(id)) {
          _backgroundWorkRuns = false;
          break;
        }
      }
      // A tick due through the whole of that window that never arrived is a
      // timer the platform stopped.
      if (_armedDueAt > 0 &&
          _armedDueAt >= _backgroundSince &&
          _armedDueAt <= now - kTimerLateSlackMs) {
        _timersRunInBackground = false;
      }
    }
    _backgroundSince = 0;
    _pendingAtBackground.clear();
    _armedDueAt = 0;
  });
}

/// Work the kit has just handed to the platform and is waiting on — an upload
/// already on its way, never something started to be measured. Returns a
/// handle; 0 on any failure, and settling 0 is a no-op.
int noteWorkPending() {
  return Safe.run<int>(0, () {
    final int id = _nextWorkId++;
    _inFlight.add(id);
    // Flat memory in a session that runs for days: a caller that leaks a
    // handle must not grow this set. Dropping the oldest can only ever LOSE
    // an observation, never invent one.
    if (_inFlight.length > 64) {
      _inFlight.remove(_inFlight.first);
    }
    return id;
  });
}

/// That work finished. If it was already in flight when the app backgrounded
/// and finished while the app was still there, this platform ran it.
void noteWorkSettled(int id, {int? nowMs}) {
  Safe.fire(() {
    if (id == 0) return;
    _inFlight.remove(id);
    if (!_pendingAtBackground.remove(id)) return;
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (_backgroundSince > 0 &&
        now - _backgroundSince >= kDeviceBackgroundMinMs) {
      _backgroundWorkRuns = true;
    }
  });
}

/// A repeating tick the kit had ALREADY scheduled is due at [dueAt]. Only the
/// tick outstanding across a background period matters, so one stamp is the
/// whole state.
void noteTimerArmed(int dueAt, {int? nowMs}) {
  Safe.fire(() {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (dueAt < now) return;
    _armedDueAt = dueAt;
  });
}

/// That tick fired. Firing while the app is genuinely backgrounded is the
/// platform letting an armed timer run.
void noteTimerFired({int? nowMs}) {
  Safe.fire(() {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (_backgroundSince > 0 &&
        now - _backgroundSince >= kDeviceBackgroundMinMs) {
      _timersRunInBackground = true;
    }
    _armedDueAt = 0;
  });
}

/// The OS warned the app about memory pressure. Positive-only by nature: a
/// session that saw no warning saw nothing, and may simply have had plenty of
/// memory. Writing a false would record our silence as the platform's.
void noteLowMemoryWarning() {
  _lowMemoryWarningGiven = true;
}

/// Tell the sensor who made this handset, when the host app happens to know.
/// Dropped unless it is one of the closed list — a manufacturer field can
/// hold anything a handset maker types, including a model name.
void setDeviceVendor(String? maker) {
  Safe.fire(() {
    if (maker == null) return;
    final String word = maker.trim().toLowerCase();
    if (kKnownVendors.contains(word)) _vendor = word;
  });
}

/// Tell the sensor which device this is, when the host app can see what
/// `dart:io` cannot.
///
/// The one thing this kit genuinely needs and cannot read is whether an
/// Apple device is an iPad: `Platform.isIOS` is true for both, and iPadOS is
/// filed as its own platform because its background rules differ. An app
/// carrying `device_info_plus` (or its own channel) can pass `isPad` and the
/// OS major here, and its observations join the record like any other kit's.
/// Without it, Apple observations are withheld — an iPad's answer filed
/// under iOS is a wrong answer, not an imprecise one.
///
/// `androidApi` is accepted for the same reason and almost never needed: the
/// kit reads Android's API level from the OS itself, and this only covers a
/// build whose version string does not carry one.
///
/// Every value is checked. An implausible number is dropped rather than
/// filed, and dropping it leaves the identity incomplete, which withholds
/// the observation instead of banding it wrongly.
void setDeviceIdentity({int? iosMajor, bool? isPad, int? androidApi}) {
  Safe.fire(() {
    if (isPad != null) _isPad = isPad;
    final int? major = _plausibleVersion(iosMajor);
    if (major != null) _iosMajor = major;
    final int? api = _plausibleVersion(androidApi);
    if (api != null) _androidApi = api;
  });
}

/// A version number this record will file under. Anything else is not a
/// smaller number, it is not a version.
int? _plausibleVersion(int? v) {
  if (v == null) return null;
  if (v < 1 || v > 999) return null;
  return v;
}

/// Read whatever the OS itself printed into its version string, once.
///
/// Android: the Dart VM prints the platform's own `SDK_INT` as "(API 34)".
/// Apple: `Platform.operatingSystemVersion` opens "Version 17.4.1 (Build …)".
/// Both are numbers the OS wrote about itself. A string that carries neither
/// leaves the field null, and null withholds the observation.
void _readOsVersionOnce() {
  if (_osVersionRead) return;
  _osVersionRead = true;
  final String? family = _osFamily();
  if (family == null) return;
  final String raw = _osVersionForTests ?? Platform.operatingSystemVersion;
  if (family == 'android') {
    final RegExpMatch? m = RegExp(r'\bAPI (\d{1,3})\b').firstMatch(raw);
    if (m != null) _androidApi ??= _plausibleVersion(int.tryParse(m.group(1)!));
    return;
  }
  final RegExpMatch? m = RegExp(r'^Version (\d{1,3})(?:\.|\s|$)').firstMatch(raw);
  if (m != null) _iosMajor ??= _plausibleVersion(int.tryParse(m.group(1)!));
}

/// @internal test seams. Never set outside a test: on a device the real
/// lookup runs, and these exist so a desktop VM can exercise the wire shape
/// this kit produces on a phone — the half that was previously asserted only
/// when the suite happened to be running on one.
String? _osFamilyForTests;
String? _osVersionForTests;

/// `android`, `apple`, or null for anything that is not a phone. The kind of
/// hardware, not the platform: which Apple OS this is cannot be read here at
/// all, and is decided in [deviceOsWord].
String? _osFamily() {
  if (_osFamilyForTests != null) return _osFamilyForTests;
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'apple';
  return null;
}

/// The raw OS word, or null when this is not a phone or cannot be placed.
/// Never a ready-made band: the server derives that, so four kits cannot
/// spell a platform four ways. Unknown stays unknown.
///
/// Null on an Apple device the host app has not identified. `dart:io` cannot
/// tell an iPad from an iPhone, and iPadOS is filed separately because its
/// background rules differ, so reporting 'ios' for both would answer an iPad
/// question with an iPhone observation. [setDeviceIdentity] closes that gap
/// for an app that can see it; without it this kit stays silent on Apple
/// hardware and the Swift kit, which can always tell, fills those bands.
String? deviceOsWord() {
  return Safe.run<String?>(null, () {
    final String? family = _osFamily();
    if (family == 'android') return 'android';
    if (family == 'apple') {
      final bool? pad = _isPad;
      if (pad == null) return null;
      return pad ? 'ipados' : 'ios';
    }
    return null;
  });
}

/// The block the snapshot carries, or null when there is nothing to say.
///
/// Null on three honest paths: this is not a phone; the OS could not be
/// read; or nothing has been observed yet. A block with a platform and no
/// fact is not an observation, and sending one would have the record dating
/// an answer it does not hold.
///
/// A fourth path is the version band. A fact is filed under an OS AND a
/// version band, so an observation carrying no number is filed nowhere: the
/// server drops it, and nothing anywhere says a Flutter install tried. This
/// kit therefore establishes the number — read from the OS's own version
/// string on Android, declared through [setDeviceIdentity] on Apple — or
/// sends nothing at all. Silence we chose is honest; silence we discover
/// months later in an empty record is not.
Map<String, Object?>? readDeviceFactsBlock() {
  return Safe.run<Map<String, Object?>?>(null, () {
    final String? os = deviceOsWord();
    if (os == null) return null;
    _readOsVersionOnce();
    final bool android = os == 'android';
    final int? version = android ? _androidApi : _iosMajor;
    if (version == null) return null;
    final Map<String, Object?> out = <String, Object?>{};
    if (_backgroundWorkRuns != null) {
      out['backgroundWorkRuns'] = _backgroundWorkRuns! ? 1 : 0;
    }
    if (_timersRunInBackground != null) {
      out['timersRunInBackground'] = _timersRunInBackground! ? 1 : 0;
    }
    if (_lowMemoryWarningGiven != null) {
      out['lowMemoryWarningGiven'] = _lowMemoryWarningGiven! ? 1 : 0;
    }
    if (out.isEmpty) return null;
    out['os'] = os;
    if (android) {
      out['androidApi'] = version;
    } else {
      out['iosMajor'] = version;
    }
    if (_vendor != null) out['vendor'] = _vendor;
    return out;
  });
}

/// Wipe every observation. Wired into the same forget()/erase path as the
/// other sensors.
void clearDeviceFacts() {
  _backgroundSince = 0;
  _pendingAtBackground.clear();
  _inFlight.clear();
  _nextWorkId = 1;
  _armedDueAt = 0;
  _backgroundWorkRuns = null;
  _timersRunInBackground = null;
  _lowMemoryWarningGiven = null;
  _vendor = null;
  // The identity goes too, for the same reason the vendor does: an erase
  // leaves nothing here describing the device. Android re-reads its API
  // level from the OS on the next look; an Apple app re-declares its kind
  // the way it did at start-up, and until it does its facts are withheld
  // rather than filed under a guess.
  _androidApi = null;
  _iosMajor = null;
  _isPad = null;
  _osVersionRead = false;
}

/// @internal test hooks — deterministic state without wall-clock games.
class DeviceFactsInternals {
  static void reset() {
    clearDeviceFacts();
    _osFamilyForTests = null;
    _osVersionForTests = null;
  }

  static bool? get backgroundWorkRuns => _backgroundWorkRuns;
  static bool? get timersRunInBackground => _timersRunInBackground;
  static bool? get lowMemoryWarningGiven => _lowMemoryWarningGiven;
  static int get inFlightCount => _inFlight.length;
  static String? get vendor => _vendor;
  static int? get androidApi => _androidApi;
  static int? get iosMajor => _iosMajor;

  /// Run the recognition rules as though this process were on a phone.
  /// Never called outside a test; on a device the real lookup is what runs.
  static void setPlatformForTests(String? family, {String? osVersion}) {
    _osFamilyForTests = family;
    _osVersionForTests = osVersion;
    _osVersionRead = false;
  }
}
