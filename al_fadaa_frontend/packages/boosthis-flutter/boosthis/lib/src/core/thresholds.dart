/// Score thresholds, weights, and rating cutoffs.
///
/// Ported byte-for-byte from the React Native kit's `thresholds.ts` so a
/// "good" React Native screen and a "good" Flutter screen mean the same thing
/// across the stack:
///
///   TTFF: good <= 300ms, poor >= 800ms,  weight 0.25
///   TTI:  good <= 500ms, poor >= 1500ms, weight 0.45
///   FID:  good <= 50ms,  poor >= 150ms,  weight 0.30
///
/// Composite rating: good >= 85, needs-work >= 60, else poor.
///
/// The meter-parity guard diffs these numbers against the RN reference — any
/// drift fails the build. Original TS constant names are noted in comments.
class Thresholds {
  Thresholds._();

  // SCORE_THRESHOLDS.ttff
  static const int kTtffGood = 300; // TTFF_GOOD
  static const int kTtffPoor = 800; // TTFF_POOR

  // SCORE_THRESHOLDS.tti
  static const int kTtiGood = 500; // TTI_GOOD
  static const int kTtiPoor = 1500; // TTI_POOR

  // SCORE_THRESHOLDS.fid
  static const int kFidGood = 50; // FID_GOOD
  static const int kFidPoor = 150; // FID_POOR

  // SCORE_WEIGHTS
  static const double kTtffWeight = 0.25; // SCORE_WEIGHTS.ttff
  static const double kTtiWeight = 0.45; // SCORE_WEIGHTS.tti
  static const double kFidWeight = 0.30; // SCORE_WEIGHTS.fid

  // RATING_CUTOFFS
  static const int kCompositeGood = 85; // RATING_CUTOFFS.good
  static const int kCompositeNeedsWork = 60; // RATING_CUTOFFS.needsWork
}
