import 'thresholds.dart';
import 'inverted_axis_band_error.dart';
export 'inverted_axis_band_error.dart';

/// Composite score computation — the SAME formula as every other Boosthis
/// runtime (PHP, Java, Python, Go, Node, Ruby, .NET, React Native):
///
///   score = TTFF x 0.25 + TTI x 0.45 + FID x 0.30
///
/// good >= 85 · needs-work >= 60 · poor < 60.
///
/// [scoreMetric] is ported byte-for-byte from the React Native kit's
/// `linearScore`: piecewise-linear, 100 at/below `good`, 0 at/above `poor`,
/// `round(100 * (1 - (value - good) / (poor - good)))` between (lower input =
/// better). The meter-parity guard diffs this against the RN reference.
///
/// Nothing else may touch this score. Every additive axis (infrastructure
/// meters, security-exposure meters, learned meters) is display-only by
/// contract.
class Score {
  Score._();

  static const String good = 'good';
  static const String needsWork = 'needs-work';
  static const String poor = 'poor';

  /// A band is the pair of constants in our source assigning 100 at [good_]
  /// and 0 at [poor_], interpolated linearly between. Equal, reversed or
  /// non-finite ends are a typo in our kit, never the customer's app. This
  /// used to silently answer 100, hiding a backwards meter behind a perfect
  /// verdict. The throw is the BACKSTOP: scripts' axis-band-inversion gate
  /// reads declared constants out of every shipped kit and fails the release
  /// before an inverted pair can reach anybody.
  static int scoreMetric(num value, num good_, num poor_) {
    if (!good_.isFinite || !poor_.isFinite || poor_ <= good_) {
      throw InvertedAxisBandError(good_, poor_);
    }
    if (value <= good_) return 100;
    if (value >= poor_) return 0;
    return (100 * (1 - (value - good_) / (poor_ - good_))).round();
  }

  /// Compute the composite score from raw metrics. A null metric is treated
  /// as "not measured, assume good" (full 100), matching the other runtimes.
  static int computeScore(num? ttffMs, num? ttiMs, num? fidMs) {
    final ttff = ttffMs == null
        ? 100
        : scoreMetric(ttffMs, Thresholds.kTtffGood, Thresholds.kTtffPoor);
    final tti = ttiMs == null
        ? 100
        : scoreMetric(ttiMs, Thresholds.kTtiGood, Thresholds.kTtiPoor);
    final fid = fidMs == null
        ? 100
        : scoreMetric(fidMs, Thresholds.kFidGood, Thresholds.kFidPoor);

    return (ttff * Thresholds.kTtffWeight +
            tti * Thresholds.kTtiWeight +
            fid * Thresholds.kFidWeight)
        .round();
  }

  /// Rating from a composite 0-100 score.
  static String getRating(num score) {
    if (score >= Thresholds.kCompositeGood) return good;
    if (score >= Thresholds.kCompositeNeedsWork) return needsWork;
    return poor;
  }

  /// Rate a single duration against the shared TTI band. The poor boundary is
  /// INCLUSIVE (ms >= poor -> "poor"), byte-identical to the sibling span
  /// emitters so a duration maps to the SAME enum in every layer at the edge.
  static String getDurationRating(num ms) {
    if (ms <= Thresholds.kTtiGood) return good;
    if (ms >= Thresholds.kTtiPoor) return poor;
    return needsWork;
  }
}
