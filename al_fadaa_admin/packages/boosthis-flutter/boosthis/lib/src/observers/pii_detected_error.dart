/// Raised when a payload contains a denylisted field name or a PII-looking
/// value. The kit catches this internally and drops the payload — it must
/// never escape into the host application.
///
/// Named PiiDetectedError to follow the sibling kits' *Error convention
/// (PHP: PiiDetectedException). Message text is byte-identical to the RN /
/// Ruby kits so the wire and logs read the same across runtimes.
library;

class PiiDetectedError implements Exception {
  final String path;
  final String fieldName;
  final String matchedFragment;

  PiiDetectedError(this.path, this.fieldName, this.matchedFragment);

  String get message =>
      'Boosthis no-PII guard refused outgoing payload: field "$path" '
      '(name "$fieldName") matches denied fragment "$matchedFragment". '
      "Boosthis's privacy contract forbids transmitting personally "
      'identifying data. If this field is genuinely non-PII, rename it; '
      'otherwise remove it.';

  @override
  String toString() => 'PiiDetectedError: $message';
}
