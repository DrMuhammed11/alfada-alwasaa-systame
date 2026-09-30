import 'runtime_flags.dart';
import 'start_announce.dart';

enum ProjectKeySource {
  environment,
  code,
  sharedEnvironment,
  none,
}

class ResolvedProjectKey {
  const ResolvedProjectKey({
    required this.key,
    required this.source,
    required this.replacedDifferentKey,
    required this.display,
    required this.noProjectKeyChosen,
  });

  final String? key;
  final ProjectKeySource source;
  final bool replacedDifferentKey;
  final String? display;
  final bool noProjectKeyChosen;

  String get sourceDescription {
    switch (source) {
      case ProjectKeySource.environment:
        return 'Flutter key from the environment';
      case ProjectKeySource.code:
        return 'key passed in code';
      case ProjectKeySource.sharedEnvironment:
        return 'shared key from the environment';
      case ProjectKeySource.none:
        return 'no project key configured';
    }
  }
}

class ProjectKeyResolver {
  ProjectKeyResolver._();

  static const String environmentName = 'BOOSTHIS_PROJECT_KEY_FLUTTER';

  static String? _clean(String? value, String source) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    return StartAnnounce.warnProjectKeyRefused(cleaned, source) ? null : cleaned;
  }

  static String? mask(String? value) {
    final key = value?.trim();
    if (key == null || key.isEmpty) return null;
    final characters = key.runes.toList(growable: false);
    if (characters.length < 8) return 'set';
    return '…${String.fromCharCodes(characters.sublist(characters.length - 4))}';
  }

  static ResolvedProjectKey resolve({
    String? code,
    String? Function(String name)? environment,
  }) {
    final read = environment ?? RuntimeFlags.env;
    final language = _clean(read(environmentName), environmentName);
    final supplied = _clean(code, 'the key passed in code');
    final shared =
        _clean(read('BOOSTHIS_PROJECT_KEY'), 'BOOSTHIS_PROJECT_KEY') ??
            _clean(read('BOOSTHIS_INVITE_KEY'), 'BOOSTHIS_INVITE_KEY');
    final key = language ?? supplied ?? shared;
    final noKeySwitch = read('BOOSTHIS_NO_PROJECT_KEY');
    final noProjectKeyChosen = key == null &&
        const <String>{'1', 'true', 'yes', 'on'}
            .contains(noKeySwitch?.trim().toLowerCase());
    final source = language != null
        ? ProjectKeySource.environment
        : supplied != null
            ? ProjectKeySource.code
            : shared != null
                ? ProjectKeySource.sharedEnvironment
                : ProjectKeySource.none;
    return ResolvedProjectKey(
      key: key,
      source: source,
      replacedDifferentKey:
          language != null && supplied != null && language != supplied,
      display: mask(key),
      noProjectKeyChosen: noProjectKeyChosen,
    );
  }
}