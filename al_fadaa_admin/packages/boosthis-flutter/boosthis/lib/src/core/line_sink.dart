/// The ungated informational sink used by kit-owned lifecycle lines.
class KitLineSink {
  KitLineSink._();

  static void say(String line) {
    try {
      // ignore: avoid_print
      print(line);
    } catch (_) {}
  }
}
