import 'dart:async';

import 'kill_switch.dart';
import 'line_sink.dart';
import 'runtime_flags.dart';
import 'safe.dart';

/// Kit-owned literals shared byte-for-byte with the browser and phone kits.
const String AWAITING_ACTIVATION_LINE =
    '[boosthis] Registered. Waiting for Boosthis to confirm this install: until it does, nothing is measured and no badge is drawn.';
const String ACTIVATION_CONFIRMED_LINE =
    '[boosthis] Boosthis confirmed this install and the badge is up. That only means measuring is allowed: a reading is taken when a page view or screen finishes.';
const String ACTIVATION_STILL_WAITING_LINE =
    '[boosthis] Boosthis has still not confirmed this install. It keeps asking in the background, and the badge appears the moment it does.';
const String ACTIVATION_LOCKED_LINE =
    '[boosthis] Boosthis answered for this install, but this project is locked, so nothing is measured. Open your Boosthis dashboard to see why.';

abstract class ActivationNoticeTimer {
  void cancel();
}

class _DartNoticeTimer implements ActivationNoticeTimer {
  _DartNoticeTimer(Duration delay, void Function() callback)
    : _timer = Timer(delay, callback);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

typedef ActivationNoticeScheduler =
    ActivationNoticeTimer Function(Duration delay, void Function() callback);

/// Explains the one legitimate state in which a correctly installed kit draws
/// no badge: its first server confirmation has not arrived yet.
class ActivationNotice {
  ActivationNotice._();

  static const int _announceAfterMs = 2500;

  /// Longer than the cumulative activation chase (46.5s), so the verdict
  /// cannot land while its final and most likely knock is still in flight.
  static const int _verdictAfterMs = 50000;

  static bool _watching = false;
  static bool _spoke = false;
  static bool _settled = false;
  static int _waitStartedAt = 0;
  static ActivationNoticeTimer? _graceTimer;
  static ActivationNoticeTimer? _verdictTimer;
  static void Function()? _unsubscribe;
  static ActivationNoticeScheduler _schedule = (delay, callback) =>
      _DartNoticeTimer(delay, callback);
  static bool Function() _disabled = () => RuntimeFlags.disabled;
  static bool Function() _activated = KillSwitch.isActivated;
  static bool Function() _active = KillSwitch.isActive;
  static int Function() _nowMs = () => DateTime.now().millisecondsSinceEpoch;

  static String _outcome() {
    return Safe.run<String>('waiting', () {
      if (_disabled()) return 'off';
      if (!_activated()) return 'waiting';
      return _active() ? 'confirmed' : 'locked';
    });
  }

  static ActivationNoticeTimer? _later(int ms, void Function() callback) {
    return Safe.run<ActivationNoticeTimer?>(null, () {
      return _schedule(Duration(milliseconds: ms), () {
        Safe.fire(callback);
      });
    });
  }

  static void _stopWatching() {
    Safe.fire(() => _unsubscribe?.call());
    _unsubscribe = null;
    Safe.fire(() => _graceTimer?.cancel());
    Safe.fire(() => _verdictTimer?.cancel());
    _graceTimer = null;
    _verdictTimer = null;
  }

  static void _settle(String outcome) {
    if (_settled) return;
    _settled = true;
    _stopWatching();
    if (!_spoke || outcome == 'off') return;
    KitLineSink.say(
      outcome == 'confirmed'
          ? ACTIVATION_CONFIRMED_LINE
          : outcome == 'locked'
          ? ACTIVATION_LOCKED_LINE
          : ACTIVATION_STILL_WAITING_LINE,
    );
  }

  static void _announceIfStillWaiting() {
    _graceTimer = null;
    if (_settled) return;
    final outcome = _outcome();
    if (outcome != 'waiting') {
      _settle(outcome);
      return;
    }
    // This line begins "Registered.", so keep looking on the same cadence
    // until registration has really handed the kit a credential. If it never
    // does, stay silent: the registration failure line owns that story.
    if (!KillSwitch.hasInstallCredential()) {
      final elapsed = _nowMs() - _waitStartedAt;
      if (elapsed >= _verdictAfterMs - _announceAfterMs) {
        _stopWatching();
        return;
      }
      _graceTimer = _later(_announceAfterMs, _announceIfStillWaiting);
      if (_graceTimer == null) _stopWatching();
      return;
    }
    _spoke = true;
    KitLineSink.say(AWAITING_ACTIVATION_LINE);
    Safe.fire(() {
      final off = KillSwitch.subscribe(() {
        Safe.fire(() {
          final now = _outcome();
          if (now != 'waiting') _settle(now);
        });
      });
      if (_settled) {
        Safe.fire(off);
      } else {
        _unsubscribe = off;
      }
    });
    if (_settled) return;
    final elapsed = _nowMs() - _waitStartedAt;
    final remaining = elapsed >= _verdictAfterMs
        ? 0
        : _verdictAfterMs - elapsed;
    _verdictTimer = _later(remaining, () {
      _verdictTimer = null;
      _settle(_outcome());
    });
  }

  /// Start the grace window. [badgeVisible] is the exact visibility answer used
  /// by the startup line, so this notice can never contradict that line.
  static void watch({required bool badgeVisible}) {
    Safe.fire(() {
      if (!badgeVisible || _watching || _disabled() || _activated()) return;
      _watching = true;
      _spoke = false;
      _settled = false;
      _waitStartedAt = _nowMs();
      _graceTimer = _later(_announceAfterMs, _announceIfStillWaiting);
      if (_graceTimer == null) _watching = false;
    });
  }

  /// Test-only scheduler/read seams. A fake scheduler advances virtual time, so
  /// the suite never sleeps for the production grace or verdict.
  static void setTestHooks({
    ActivationNoticeScheduler? scheduler,
    bool Function()? disabled,
    bool Function()? activated,
    bool Function()? active,
    int Function()? nowMs,
  }) {
    if (scheduler != null) _schedule = scheduler;
    if (disabled != null) _disabled = disabled;
    if (activated != null) _activated = activated;
    if (active != null) _active = active;
    if (nowMs != null) _nowMs = nowMs;
  }

  /// Cancel pending notice work when the kit is stopped/forgotten.
  static void stop() {
    Safe.fire(() {
      _settled = true;
      _stopWatching();
      _watching = false;
    });
  }

  static void resetForTests() {
    _stopWatching();
    _watching = false;
    _spoke = false;
    _settled = false;
    _schedule = (delay, callback) => _DartNoticeTimer(delay, callback);
    _disabled = () => RuntimeFlags.disabled;
    _activated = KillSwitch.isActivated;
    _active = KillSwitch.isActive;
    _nowMs = () => DateTime.now().millisecondsSinceEpoch;
  }
}
