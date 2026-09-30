/// BoosthisBubble — in-app developer overlay.
///
/// REQUIRES A FLUTTER SDK TO COMPILE. Imports `package:flutter`; NOT compiled
/// or analysed by this workspace's meter-parity harness. See
/// `../../../PORT_CONTRACT.md`.
///
/// A minimal overlay that RENDERS the pure package's bubble state. It contains
/// NO meter math and computes nothing — it reads whatever `Boosthis.bubbleState`
/// returns and paints it, subscribing to `Boosthis.bubbleChanges` for repaints.
///
/// Drop it above your app's content (e.g. via a `Stack` or `MaterialApp.builder`):
///
///     MaterialApp(
///       builder: (context, child) => Stack(
///         children: [ if (child != null) child, const BoosthisBubble() ],
///       ),
///     )
///
/// It respects the pure package's own visibility decision (BOOSTHIS_BUBBLE,
/// legacy aliases, kill switch): when `bubbleState.visible` is false it paints
/// nothing. All build logic is guarded so a render-time throw can never crash
/// the host.
library;

import 'dart:async';

import 'package:boosthis/boosthis.dart' as boosthis;
import 'package:flutter/material.dart';

/// A tiny, self-contained overlay that mirrors the pure package's bubble state.
class BoosthisBubble extends StatefulWidget {
  const BoosthisBubble({super.key});

  @override
  State<BoosthisBubble> createState() => _BoosthisBubbleState();
}

class _BoosthisBubbleState extends State<BoosthisBubble> {
  StreamSubscription<void>? _sub;
  bool _expanded = false;

  /// Drives the panel's own scroll view AND the scrollbar beside it. Flutter
  /// asserts that an always-visible thumb is attached to exactly one
  /// controller, so the two share this one.
  final ScrollController _panelScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    try {
      // Repaint whenever the pure package pushes a new bubble state.
      _sub = boosthis.Boosthis.bubbleChanges.listen((_) {
        if (mounted) setState(() {});
      });
    } catch (_) {
      /* no stream available — the bubble just won't live-update */
    }
  }

  @override
  void dispose() {
    try {
      _sub?.cancel();
    } catch (_) {
      /* ignore */
    }
    try {
      _panelScroll.dispose();
    } catch (_) {
      /* ignore */
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fully guarded: a throw while reading/painting the bubble must never crash
    // the host app. On any failure we paint nothing.
    try {
      final Map<String, Object?> state = boosthis.Boosthis.bubbleState();
      final bool visible = state['visible'] == true;
      if (!visible) return const SizedBox.shrink();

      final String label = (state['label'] as String?) ?? 'Boosthis';
      final String project =
          (state['project'] as String?) ?? boosthis.PROJECT_UNKNOWN_TEXT;
      final String installId =
          (state['installId'] as String?) ?? boosthis.INSTALL_ID_UNKNOWN_TEXT;
      final String? score = state['score']?.toString();
      final List<Object?> tiles =
          (state['tiles'] as List<Object?>?) ?? const <Object?>[];
      final String? notice = state['notice'] as String?;
      final String? uploadFailReason = state['uploadFailReason'] as String?;
      final int uploadsLost = (state['uploadsLost'] as num?)?.toInt() ?? 0;
      final Object? drops = state['drops'];

      return Positioned(
        right: 12,
        bottom: 12,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: _expanded
                ? _panel(
                    label,
                    project,
                    installId,
                    score,
                    tiles,
                    notice,
                    uploadFailReason,
                    uploadsLost,
                    drops,
                  )
                : _pill(label, score),
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _pill(String label, String? score) {
    return GestureDetector(
      onTap: () {
        if (mounted) setState(() => _expanded = true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xE6101418),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Text(
          score == null ? label : '$label · $score',
          style: const TextStyle(
            color: Color(0xFFEAEEF2),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _panel(
    String label,
    String project,
    String installId,
    String? score,
    List<Object?> tiles,
    String? notice,
    String? uploadFailReason,
    int uploadsLost,
    Object? drops,
  ) {
    final Widget? banner = _noticeBanner(notice, uploadFailReason, uploadsLost);
    final Widget? droppedRow = _droppedRow(drops);
    // A PHONE IS THE ONLY SCREEN THIS PANEL EVER MEETS. A flat 240 is wider
    // than the usable width of the narrowest phones once the overlay's own 12
    // margins are taken off, and a Column with no ceiling grows past the top
    // of the screen as tiles arrive — which in Flutter is the yellow-and-black
    // overflow banner with the tiles above it simply unreachable. So: the
    // width is capped against the real screen, the height against 72% of it,
    // and everything past that ceiling scrolls behind a thumb that is always
    // drawn rather than one that appears only once you are already dragging.
    final Size screen = MediaQuery.of(context).size;
    final double panelWidth =
        (screen.width - 24.0).clamp(120.0, 240.0).toDouble();
    return GestureDetector(
      onTap: () {
        if (mounted) setState(() => _expanded = false);
      },
      child: Container(
        width: panelWidth,
        constraints: BoxConstraints(maxHeight: screen.height * 0.72),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xF2101418),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Scrollbar(
          controller: _panelScroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _panelScroll,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFEAEEF2),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (banner != null) ...<Widget>[const SizedBox(height: 8), banner],
                const SizedBox(height: 8),
                Text(
                  '${boosthis.INSTALL_ID_LABEL}: $installId',
                  style: const TextStyle(color: Color(0xFFB6BEC6), fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  '${boosthis.PROJECT_LABEL}: $project',
                  style: const TextStyle(color: Color(0xFFB6BEC6), fontSize: 11),
                ),
                if (score != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      score,
                      style: const TextStyle(
                        color: Color(0xFF9FE6B0),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    boosthis.SCORE_CAPTION,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF7C858E), fontSize: 10),
                  ),
                ],
                if (droppedRow != null) ...<Widget>[
                  const SizedBox(height: 8),
                  droppedRow,
                ],
                const SizedBox(height: 8),
                ...tiles.map(_tileRow),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The install-state notice — the device-kit equivalent of the sibling
  /// bubbles' showNotice branches. A registered-but-silent (or unregistered, or
  /// id-rejected) install must SAY SO here, or a healthy-looking bubble hides a
  /// dashboard that stays empty forever. Copy is code-defined, byte-parity with
  /// the sibling kits; it carries no project key, token, URL or server text.
  Widget? _noticeBanner(
    String? notice,
    String? uploadFailReason,
    int uploadsLost,
  ) {
    String title;
    String body;
    switch (notice) {
      case 'not-registered':
        title = 'Not registered yet';
        body = boosthis.Telemetry.inactiveNoticeBody ??
            'This app has not registered with Boosthis, so nothing is being sent. Check the project key and this app\'s outbound network access, then relaunch the app.';
        break;
      case 'sharing-off':
        title = 'Nothing is being uploaded';
        body = 'This app is registered, but sharing is off: these meters stay '
            'on this screen and your Boosthis dashboard stays empty. Turn '
            'sharing on there, or start the kit with shareMeterWithAI: true.';
        break;
      case 'registration-unknown':
        title = "Can't check right now";
        body =
            'Boosthis could not be reached to confirm whether this app is registered, '
            'so this panel cannot say either way yet. This is not a failed install and '
            'it does not mean anything stopped — it settles by itself once the check '
            "goes through. Do not change the install line's id while this is showing.";
        break;
      case 'uploads-failing':
        title = 'Uploads are not getting through';
        final reason = switch (uploadFailReason) {
          'unauthorized' => 'Refused — credentials rejected',
          'rejected' => 'Refused — batch rejected',
          'server-error' => 'Boosthis failed to store it',
          _ => 'No answer — timed out or unreachable',
        };
        body =
            'This app is registered and sharing is on, but the last batch of measurements did not reach Boosthis, so your dashboard is missing the most recent data. $reason.${uploadsLost > 0 ? ' Uploads lost: $uploadsLost.' : ''}';
        break;
      default:
        // Unknown / no notice (including "install-id-not-uuid", which the host
        // fixes in code, not in this dev overlay): say nothing.
        return null;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0x33F97316),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x66F97316)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF97316),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: const TextStyle(color: Color(0xFFCBD2D9), fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// The "Measurements dropped" figure — the device-kit equivalent of the
  /// sibling bubbles' showDrops branch. The pure package hands over ONLY a count
  /// and code-defined cause MARKERS; this renderer owns the words, byte-parity
  /// with the sibling kits and the web page, so no server-provided text is ever
  /// shown. Returns null (and the panel shows nothing at all) when there is
  /// nothing dropped.
  Widget? _droppedRow(Object? drops) {
    if (drops is! Map) return null;
    final Object? countRaw = drops['count'];
    if (countRaw is! num || countRaw <= 0) return null;
    final int count = countRaw.toInt();

    // Marker -> literal cause text. Same words the project's web page uses.
    const Map<String, String> causeText = <String, String>{
      'labelRejected': 'route names the privacy guard refused',
      'traceCapReached': 'spans past the 20-span limit',
      'snapshotEntryFiltered': 'snapshot entries the privacy guard refused',
    };
    final Object? rawCauses = drops['causes'];
    final List<String> causes = <String>[];
    if (rawCauses is List) {
      for (final c in rawCauses) {
        final String? text = causeText[c?.toString()];
        if (text != null) causes.add(text);
      }
    }

    // Value: "<n> — <cause>[; <cause>…]" (em dash U+2014), or a bare count when
    // the only causes reported are ones this kit does not name.
    final String value =
        causes.isEmpty ? '$count' : '$count \u2014 ${causes.join('; ')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Measurements dropped',
            style: TextStyle(
              color: Color(0xFFF97316),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Color(0xFFCBD2D9), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _tileRow(Object? raw) {
    // Each tile is whatever the pure package emitted. We render a name + value
    // (or "warming up" when the axis is absent) without interpreting it.
    if (raw is! Map) return const SizedBox.shrink();
    final Map<Object?, Object?> tile = raw;
    final String name =
        tile['label']?.toString() ?? tile['key']?.toString() ?? '—';
    final Object? value = tile['value'];
    final bool warming =
        value == null || tile['present'] == false || tile['warming'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            name,
            style: const TextStyle(color: Color(0xFFB6BEC6), fontSize: 11),
          ),
          Text(
            warming ? 'warming up' : value.toString(),
            style: TextStyle(
              color: warming
                  ? const Color(0xFF7C858E)
                  : const Color(0xFFEAEEF2),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
