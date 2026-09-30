/// The shared leading words of a refusal, identical across the shipped kits.
const String invertedBandMessage =
    'boosthis: inverted axis band, good must be below poor';

/// A pair of band constants in our source that cannot define a score.
class InvertedAxisBandError implements Exception {
  final num good;
  final num poor;

  const InvertedAxisBandError(this.good, this.poor);

  @override
  String toString() => '$invertedBandMessage (good=$good, poor=$poor)';
}