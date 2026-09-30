import 'json.dart';
import 'safe.dart';
import 'store.dart';

/// The label every developer-facing surface puts in front of the project.
const String PROJECT_LABEL = 'Project';

/// The kit-owned wording for a project that has a code but no name.
const String PROJECT_UNNAMED_TEXT = 'Unnamed project';

/// The kit-owned wording used before the server has identified the project.
const String PROJECT_UNKNOWN_TEXT = 'Not received from Boosthis yet';

const String INSTALL_ID_LABEL = 'Install ID';
const String INSTALL_ID_UNKNOWN_TEXT = 'not assigned yet';

/// The caption under the headline score. A local score is not upload proof.
const String SCORE_CAPTION =
    'Measured on this device. Not proof anything reached Boosthis.';

const int _maxNameChars = 60;
const int _maxCodeChars = 16;

/// What this process currently knows about the project behind its key.
class KitProject {
  const KitProject({this.name, this.code});

  final String? name;
  final String? code;
}

KitProject _current = const KitProject();
String? _restoredInstallId;

/// Remove controls, collapse whitespace, trim, and cap developer-authored text.
String? sanitizeProjectName(Object? value) {
  return Safe.run<String?>(null, () {
    if (value is! String) return null;
    var cleaned = value
        .replaceAll(RegExp(r'[\u0000-\u001f\u007f-\u009f]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.runes.length > _maxNameChars) {
      cleaned = String.fromCharCodes(cleaned.runes.take(_maxNameChars)).trim();
    }
    return cleaned.isEmpty ? null : cleaned;
  });
}

/// Keep only the short letters-and-digits project fingerprint.
String? sanitizeProjectCode(Object? value) {
  return Safe.run<String?>(null, () {
    if (value is! String) return null;
    final cleaned = value
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .substringSafe(0, _maxCodeChars);
    return cleaned.isEmpty ? null : cleaned;
  });
}

/// Record a consent reply. A valid code replaces the whole identity; a name on
/// its own advances only the name and keeps a code already received.
void setKitProject(Object? name, Object? code) {
  Safe.fire(() {
    final nextCode = sanitizeProjectCode(code);
    final nextName = sanitizeProjectName(name);
    if (nextCode != null) {
      _current = KitProject(name: nextName, code: nextCode);
    } else if (nextName != null) {
      _current = KitProject(name: nextName, code: _current.code);
    }
  });
}

/// Return a copy so callers cannot mutate module state.
KitProject getKitProject() =>
    KitProject(name: _current.name, code: _current.code);

/// The one spelling used by every surface.
String projectDisplay(KitProject? project) {
  return Safe.run<String>(PROJECT_UNKNOWN_TEXT, () {
    final code = project?.code;
    if (code == null || code.isEmpty) return PROJECT_UNKNOWN_TEXT;
    return '${project?.name ?? PROJECT_UNNAMED_TEXT} ($code)';
  });
}

/// The durable key shared with the install's other credentials.
String projectStoreKey(String installId) => 'project:$installId';

/// Persist the already-sanitised identity as the specified JSON object.
void persistKitProject(String installId) {
  Safe.fire(() {
    final raw = Json.encode(<String, Object?>{
      'name': _current.name,
      'code': _current.code,
    });
    if (raw != null) {
      Store.set(projectStoreKey(installId), raw, durable: true);
    }
  });
}

/// Restore once for an install before its first consent request. Corrupt or
/// absent state simply leaves the honest unknown fallback in place.
void restoreKitProject(String installId) {
  Safe.fire(() {
    if (_restoredInstallId == installId) return;
    _restoredInstallId = installId;
    _current = const KitProject();
    final raw = Store.get(projectStoreKey(installId), null);
    if (raw is! String) return;
    final stored = Json.decode(raw);
    if (stored == null) return;
    setKitProject(stored['name'], stored['code']);
  });
}

/// Test-only: forget the process copy. Durable state remains under [Store].
void resetKitProjectForTests() {
  _current = const KitProject();
  _restoredInstallId = null;
}

extension on String {
  String substringSafe(int start, int end) {
    if (length <= start) return '';
    return substring(start, length < end ? length : end);
  }
}
