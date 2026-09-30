import 'activation_notice.dart';
import 'line_sink.dart';

enum ProjectKeyProblem { authWord, quoted, cutOff, wrongShape }

enum BadgeState { visible, hiddenBySetting, switchedOff }

class StartAnnounce {
  StartAnnounce._();

  static bool _announced = false;
  static bool _announcementPending = false;
  static final Set<String> _refused = <String>{};
  static final List<String> _heldRefusals = <String>[];
  static const List<String> _authWords = <String>[
    'bearer',
    'token',
    'basic',
    'apikey',
    'api-key',
    'key',
  ];
  static const String _quoteChars = '"\'`\u2018\u2019\u201c\u201d';

  static ProjectKeyProblem? findProjectKeyProblem(Object? raw) {
    if (raw is! String) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    final lower = value.toLowerCase();
    for (final word in _authWords) {
      if (lower.startsWith(word) &&
          value.length > word.length &&
          RegExp(r'\s').hasMatch(value[word.length])) {
        return ProjectKeyProblem.authWord;
      }
    }
    if (_quoteChars.contains(value[0]) ||
        _quoteChars.contains(value[value.length - 1]) ||
        (value.startsWith('<') && value.endsWith('>'))) {
      return ProjectKeyProblem.quoted;
    }
    if (value.startsWith('...') ||
        value.endsWith('...') ||
        value.startsWith('\u2026') ||
        value.endsWith('\u2026')) {
      return ProjectKeyProblem.cutOff;
    }
    if (value.length < 8 || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      return ProjectKeyProblem.wrongShape;
    }
    return null;
  }

  static String _problemSentence(ProjectKeyProblem problem) {
    switch (problem) {
      case ProjectKeyProblem.authWord:
        return 'it starts with an authorization word. Paste the key on its own, with nothing in front of it.';
      case ProjectKeyProblem.quoted:
        return 'it is wrapped in quotes. Paste the key on its own, with no quotes around it.';
      case ProjectKeyProblem.cutOff:
        return 'it looks cut off. Paste the whole key from your Boosthis Setup page.';
      case ProjectKeyProblem.wrongShape:
        return 'it is not the shape of a project key. A project key is one unbroken value from your Boosthis Setup page.';
    }
  }

  static String projectKeyRefusalLine(
    ProjectKeyProblem problem,
    String source,
  ) =>
      '[boosthis] Boosthis will not use the project key from $source: ${_problemSentence(problem)}';

  static String? projectKeyTail(Object? key) {
    if (key is! String) return null;
    final value = key.trim();
    if (value.isEmpty) return null;
    return value.length <= 4 ? value : value.substring(value.length - 4);
  }

  static String kitStartupLine(
    String? tail, [
    BadgeState badgeState = BadgeState.visible,
  ]) {
    final head = tail != null
        ? '[boosthis] Boosthis starting: project key ...$tail. Registering next.'
        : '[boosthis] Boosthis starting: no project key. Nothing will register.';
    switch (badgeState) {
      case BadgeState.hiddenBySetting:
        return '$head Badge hidden by a setting; Boosthis is still running.';
      case BadgeState.switchedOff:
        return '$head Badge hidden: Boosthis is switched off.';
      case BadgeState.visible:
        return head;
    }
  }

  static void announceKitStart(String? key, BadgeState badgeState) {
    if (_announced) return;
    _announced = true;
    _say(kitStartupLine(projectKeyTail(key), badgeState));
    flushHeldRefusals();
    ActivationNotice.watch(badgeVisible: badgeState == BadgeState.visible);
  }

  static void beginStartAnnouncement() {
    if (_announced) return;
    _announcementPending = true;
  }

  static void flushHeldRefusals() {
    _announcementPending = false;
    final lines = List<String>.of(_heldRefusals);
    _heldRefusals.clear();
    for (final line in lines) {
      _say(line);
    }
  }

  static void sayAfterStartupLine(String line) {
    if (_announcementPending) {
      _heldRefusals.add(line);
      return;
    }
    _say(line);
  }

  static bool warnProjectKeyRefused(Object? raw, String source) {
    final problem = findProjectKeyProblem(raw);
    if (problem == null) return false;
    if (_refused.add(source)) {
      sayAfterStartupLine(projectKeyRefusalLine(problem, source));
    }
    return true;
  }

  static void _say(String line) {
    KitLineSink.say(line);
  }

  static void resetForTests() {
    ActivationNotice.resetForTests();
    _announced = false;
    _announcementPending = false;
    _refused.clear();
    _heldRefusals.clear();
  }
}
