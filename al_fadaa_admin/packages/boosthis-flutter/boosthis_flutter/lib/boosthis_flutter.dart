/// Boosthis Flutter adapter — public barrel.
///
/// REQUIRES A FLUTTER SDK TO COMPILE. This file (and everything under
/// `lib/src/`) imports `package:flutter` and is therefore NOT compiled,
/// analysed or spawned by the meter-parity harness in this workspace, which
/// has the Dart SDK only. See `../../PORT_CONTRACT.md`.
///
/// This package is the ONLY Boosthis Flutter code allowed to import
/// `package:flutter`. It is a thin, mechanical translation layer: every export
/// below turns a Flutter engine signal (frame timing, error handler, lifecycle
/// event, image cache read, navigation, outbound HTTP) into a plain-Dart call
/// on the pure `boosthis` package, which owns all meter math. NO meter
/// arithmetic lives in this package.
///
/// One-line start:
///
///     void main() {
///       BoosthisFlutter.start(installId: 'your-install-id');
///       BoosthisFlutter.run(() => runApp(const MyApp()));
///     }
library boosthis_flutter;

export 'src/boosthis_flutter_base.dart' show BoosthisFlutter;
export 'src/boosthis_navigator_observer.dart' show BoosthisNavigatorObserver;
export 'src/boosthis_profiler.dart' show BoosthisProfiler;
export 'src/boosthis_http_overrides.dart' show BoosthisHttpOverrides;
export 'src/boosthis_bubble.dart' show BoosthisBubble;
