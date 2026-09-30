/// Boosthis: privacy-safe crash reporter (Flutter). MONITOR-ONLY.
///
/// Captures REAL uncaught crashes from the host app and turns each one into a
/// tiny, scrubbed fingerprint safe to send off-device. This is NOT a perf
/// checklist rule — it is a separate always-on channel (for registered apps).
/// Nothing here runs as an import side-effect.
///
/// MONITOR-ONLY / NEVER SUPPRESSES: this module only RECORDS. The adapter/
/// integration group chains `FlutterError.onError` / `PlatformDispatcher.onError`
/// and, for every crash, calls [capture] to record it and then ALWAYS delegates
/// to the host's PREVIOUS handler — the kit can never swallow a host crash or
/// clobber host behaviour. Sources are tagged `uncaught` (FlutterError),
/// `unhandledRejection` (PlatformDispatcher async), and `render` (the kit's own
/// error boundary).
///
/// PRIVACY: the DEFAULT payload carries only the error type, a hashed
/// signature, a redacted top frame, and a bucketed count — never source,
/// values, or PII. OPT-IN detailed mode additionally carries a PII-scrubbed
/// first message line (`summary`) and sanitized stack `frames` (function + file
/// BASENAME + line/col). Anything that trips the PII guard is dropped
/// individually. Field names deliberately avoid the PII denylist.
///
/// READABLE RELEASE FRAMES: a Flutter release built with `--obfuscate
/// --split-debug-info` prints no file, no line and no function — just
/// addresses, under a `build_id:` header. The symbol file that could name them
/// is keyed on that ELF build id plus each frame's DSO-relative `virt`
/// address, so those two now ride the frame. The absolute (`abs`) address does
/// NOT: it says where ASLR put the binary on one launch and nothing about the
/// build. Both halves or neither, so an address from a build we have no
/// symbols for stays honestly unresolved.
///
/// Crash-safety: every entry point is wrapped so a bug in the reporter can
/// never crash the host. Pending crashes are persisted to state storage so a
/// FATAL crash is still reported on the next launch.
library;

import '../core/runtime_flags.dart' show RuntimeFlags;
import '../core/safe.dart' show Safe;
import '../core/store.dart' show Store;
import '../meters/meter_axes.dart' show linearScore, ratingFor;
import '../integration/span_scope.dart' show SpanScope;
import '../integration/trace.dart' show Trace;
import 'pii.dart' show checkNoPii;

const String _storageKey = 'boosthis:crash-pending:v1';

/// Bound the in-memory + persisted crash set (distinct SIGNATURES).
const int kMaxCrashes = 200;

/// Server caps a batch at 50 reports.
const int kMaxBatch = 50;

/// Server caps a single signature's occurrences at 100000.
const int kMaxOccurrences = 100000;

/// Server caps detailed frames at 20.
const int kMaxFrames = 20;

/// The three crash kinds (wire strings).
const String crashKindUncaught = 'uncaught';
const String crashKindUnhandledRejection = 'unhandledRejection';
const String crashKindRender = 'render';

const Set<String> _validKinds = <String>{
  crashKindUncaught,
  crashKindUnhandledRejection,
  crashKindRender,
};

/// Network submitter wired by the telemetry client (→ transmit). Returns the
/// number of reports the server accepted. Registered on enableTelemetry,
/// cleared on forget().
typedef CrashSubmitter =
    Future<int> Function(List<Map<String, Object?>> crashes);

class _CrashEntry {
  String signature;
  String errorName;
  String kind;
  String redactedFrame;
  String? summary;
  List<Map<String, Object?>>? frames;
  String? traceId;
  String? spanId;
  int sessionTotal;
  int unsent;
  int lastSeen;
  _CrashEntry({
    required this.signature,
    required this.errorName,
    required this.kind,
    required this.redactedFrame,
    this.summary,
    this.frames,
    this.traceId,
    this.spanId,
    required this.sessionTotal,
    required this.unsent,
    required this.lastSeen,
  });
}

CrashSubmitter? _activeSubmitter;
bool _active = false;
bool _detailedMode = false;
bool _restoredOnce = false;
int _crashTotal = 0;
int _telemetryStartedAt = 0;

final Map<String, _CrashEntry> _pending = <String, _CrashEntry>{};

/// Register the crash auto-submitter. Pass null to clear (on opt-out).
void setCrashSubmitter(CrashSubmitter? submitter) {
  _activeSubmitter = submitter;
}

// ── Redaction helpers ──────────────────────────────────────────────

/// Cheap stable djb2 hash. Input is already redacted/non-reversible; the
/// output GROUPS identical crash classes and carries no recoverable data.
String _hash(String input) {
  var h = 5381;
  for (var i = 0; i < input.length; i++) {
    h = ((h * 33) ^ input.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return (h & 0xFFFFFFFF).toRadixString(36);
}

String _bucketCount(int n) {
  if (n <= 1) return '1';
  if (n <= 5) return '2-5';
  if (n <= 20) return '6-20';
  if (n <= 100) return '21-100';
  return '100+';
}

/// Keep only identifier characters so an error NAME can never carry an
/// email/path/URL/value. Collapses to "Error" if empty.
String _sanitizeErrorName(String name) {
  var cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9_$]'), '');
  if (cleaned.length > 80) cleaned = cleaned.substring(0, 80);
  return cleaned.isNotEmpty ? cleaned : 'Error';
}

/// Reduce a file path/URL to its bare basename, dropping directories, URL
/// scheme/host, query strings, and fragments.
String _fileBasename(String raw) {
  var s = raw;
  final q = s.indexOf(RegExp(r'[?#]'));
  if (q >= 0) s = s.substring(0, q);
  final segs = s.split(RegExp(r'[\\/]'));
  s = segs.isNotEmpty ? segs[segs.length - 1] : '';
  s = s.trim();
  if (s.length > 120) s = s.substring(0, 120);
  return s.isNotEmpty ? s : '<unknown>';
}

class _RawFrame {
  final String func;
  final String file;
  final int? line;
  final int? column;

  /// Obfuscated (AOT) Dart frames only: the ELF GNU build id of the binary the
  /// frame was in, and the frame's DSO-relative address. Together these are
  /// what a `--split-debug-info` symbol file is keyed on; a file and a line are
  /// not, which is why an obfuscated release stack has never been readable.
  final String? buildId;
  final int? offset;
  _RawFrame(
    this.func,
    this.file,
    this.line,
    this.column, {
    this.buildId,
    this.offset,
  });
}

int? _clampInt(String s) {
  final n = int.tryParse(s);
  if (n == null || n < 0) return null;
  return n > 100000000 ? 100000000 : n;
}

/// The server's ceiling for a frame offset (`crashFrameOffsetMax`). Bigger than
/// the line/column clamp because this is an address inside a binary, not a
/// position in a file.
const int _kMaxFrameOffset = 4294967295;

/// Parse a hex address. Out of range is null rather than clamped: a wrong
/// offset resolves to a confidently wrong symbol, which is worse than no
/// symbol at all.
int? _parseHexOffset(String? raw) {
  if (raw == null || raw.isEmpty || raw.length > 16) return null;
  final n = int.tryParse(raw, radix: 16);
  if (n == null || n < 0 || n > _kMaxFrameOffset) return null;
  return n;
}

/// Parse a Dart / JS stack into frames. Handles Dart's
/// ("#0  Foo.bar (package:app/x.dart:12:3)") and the V8/JSC formats a
/// cross-platform host may emit. Paths reduce to basenames here so no absolute
/// path/URL survives parsing.
List<_RawFrame> parseStack(String? stack) {
  if (stack == null || stack.isEmpty) return <_RawFrame>[];
  final frames = <_RawFrame>[];
  // An obfuscated AOT stack states the binary's build id ONCE, in a header
  // above the frames, and then prints addresses. Every frame below it belongs
  // to that build, so the id is picked up here and attached to each one.
  String? buildId;
  for (final lineRaw in stack.split('\n')) {
    final line = lineRaw.trim();
    if (line.isEmpty) continue;

    // "build_id: '2f7d…'" — the ELF GNU build id, and the ONLY thing that says
    // which build the addresses below belong to.
    final idHeader = RegExp(
      r"^build_id:\s*'?([0-9a-fA-F]{4,64})'?",
    ).firstMatch(line);
    if (idHeader != null) {
      buildId = idHeader.group(1)!.toLowerCase();
      continue;
    }

    // Obfuscated frame: "#00 abs 7f0f8ecad3af virt 00000000000ad3af Sym+0x1f".
    // `abs` is where ASLR happened to put it on THIS launch and never leaves
    // the device; `virt` is the DSO-relative address a split-debug-info file
    // is keyed on, so that is what travels.
    final aot = RegExp(
      r'^#\d+\s+abs\s+([0-9a-fA-F]+)(?:\s+virt\s+([0-9a-fA-F]+))?'
      r'(?:\s+(\S+))?\s*$',
    ).firstMatch(line);
    if (aot != null) {
      final off = _parseHexOffset(aot.group(2));
      // Only a frame that has BOTH halves of the key can be looked up, so
      // either both travel or neither does. Half a key is an invitation to
      // match it against the wrong build.
      final keyed = off != null && buildId != null;
      var sym = (aot.group(3) ?? '').split('+').first;
      sym = sym.replaceAll(RegExp(r'[^A-Za-z0-9_$.<>]'), '');
      if (sym.length > 120) sym = sym.substring(0, 120);
      frames.add(
        _RawFrame(
          sym.isNotEmpty ? sym : '<anonymous>',
          '<unknown>',
          null,
          null,
          // One without them stays an unresolved frame, which is the truth.
          buildId: keyed ? buildId : null,
          offset: keyed ? off : null,
        ),
      );
      if (frames.length >= kMaxFrames) break;
      continue;
    }

    var func = '<anonymous>';
    var loc = '';
    // Dart: "#12  Foo.bar (file:line:col)"
    final dart = RegExp(r'^#\d+\s+(.*?)\s+\((.*)\)$').firstMatch(line);
    final v8 = RegExp(r'^at\s+(.*?)\s+\((.*)\)$').firstMatch(line);
    if (dart != null) {
      func = dart.group(1) ?? '<anonymous>';
      loc = dart.group(2) ?? '';
    } else if (v8 != null) {
      func = v8.group(1) ?? '<anonymous>';
      loc = v8.group(2) ?? '';
    } else {
      final v8NoFn = RegExp(r'^at\s+(.*)$').firstMatch(line);
      final jsc = RegExp(r'^(.*?)@(.*)$').firstMatch(line);
      if (v8NoFn != null) {
        loc = v8NoFn.group(1) ?? '';
      } else if (jsc != null) {
        final g1 = jsc.group(1);
        func = (g1 != null && g1.isNotEmpty) ? g1 : '<anonymous>';
        loc = jsc.group(2) ?? '';
      } else {
        continue;
      }
    }
    var file = loc;
    int? lineNo;
    int? colNo;
    final m =
        RegExp(r'^(.*):(\d+):(\d+)$').firstMatch(loc) ??
        RegExp(r'^(.*):(\d+)$').firstMatch(loc);
    if (m != null) {
      file = m.group(1) ?? loc;
      lineNo = _clampInt(m.group(2)!);
      colNo = m.groupCount >= 3 && m.group(3) != null
          ? _clampInt(m.group(3)!)
          : null;
    }
    func = func.replaceAll(RegExp(r'[^A-Za-z0-9_$.<>\s]'), '').trim();
    if (func.length > 120) func = func.substring(0, 120);
    if (func.isEmpty) func = '<anonymous>';
    frames.add(_RawFrame(func, _fileBasename(file), lineNo, colNo));
    if (frames.length >= kMaxFrames) break;
  }
  return frames;
}

String _formatRedactedFrame(_RawFrame? top) {
  if (top == null) return '<unknown>';
  final lineSuffix = top.line != null ? ':${top.line}' : '';
  var s = '${top.func} (${top.file}$lineSuffix)';
  if (s.length > 160) s = s.substring(0, 160);
  return s;
}

/// First line of the message, scrubbed: dropped entirely if it trips the PII
/// guard. Returns null when there is nothing safe to keep.
String? _sanitizeSummary(String message) {
  var first = message.split(RegExp(r'\r?\n')).first.trim();
  if (first.length > 300) first = first.substring(0, 300);
  if (first.isEmpty) return null;
  if (checkNoPii(first) != null) return null;
  return first;
}

class _RedactedCrash {
  final String signature;
  final String errorName;
  final String kind;
  final String redactedFrame;
  final String? summary;
  final List<Map<String, Object?>>? frames;
  _RedactedCrash(
    this.signature,
    this.errorName,
    this.kind,
    this.redactedFrame,
    this.summary,
    this.frames,
  );
}

/// Turn a raw throw into the closed, PII-safe crash shape. Detailed fields are
/// added only when [_detailedMode] is on and they pass the PII guard.
_RedactedCrash _redactError(Object? error, String? stack, String rawKind) {
  // The wire vocabulary is CLOSED: the server refuses a whole batch whose kind
  // is not one of the three. A caller naming its own source ("flutter", "zone")
  // must never be able to make a report unsendable, so an unknown kind becomes
  // `uncaught` here — at capture, where the persisted copy is written too.
  final kind = _validKinds.contains(rawKind) ? rawKind : crashKindUncaught;
  final rawName = error is Error ? error.runtimeType.toString() : 'Error';
  final message = error?.toString() ?? '';
  final errorName = _sanitizeErrorName(rawName);
  final frames = parseStack(stack);
  final top = frames.isNotEmpty ? frames.first : null;
  final redactedFrame = _formatRedactedFrame(top);
  // Signature basis must never contain user values. A redacted top frame is
  // code-defined + safe; with NO frame we fall back to code-defined tokens
  // only — never the raw message, which could carry a value.
  final basis = top != null ? redactedFrame : '$errorName|$kind|<no-frame>';
  var signature = '$errorName:${_hash(basis)}';
  if (signature.length > 120) signature = signature.substring(0, 120);
  String? summary;
  List<Map<String, Object?>>? outFrames;
  if (_detailedMode) {
    summary = _sanitizeSummary(message);
    final safeFrames = <Map<String, Object?>>[];
    for (final f in frames.take(kMaxFrames)) {
      final fr = <String, Object?>{'func': f.func, 'file': f.file};
      if (f.line != null) fr['line'] = f.line;
      if (f.column != null) fr['column'] = f.column;
      // The split-debug-info key. Both halves or neither — a build id with no
      // offset points at a symbol file and says nothing to look up in it.
      if (f.buildId != null && f.offset != null) {
        fr['buildId'] = f.buildId;
        fr['offset'] = f.offset;
      }
      if (checkNoPii(fr) != null) continue;
      safeFrames.add(fr);
    }
    if (safeFrames.isNotEmpty) outFrames = safeFrames;
  }
  return _RedactedCrash(
    signature,
    errorName,
    kind,
    redactedFrame,
    summary,
    outFrames,
  );
}

// ── Capture + flush ────────────────────────────────────────────────

/// Record one crash. Never throws. No-op until [installCrashReporter] has run.
/// MONITOR-ONLY: this records; the caller (adapter) ALWAYS delegates to the
/// host's previous handler afterwards.
void capture(Object? error, StackTrace? stack, String kind) {
  Safe.fire(() {
    if (!_active || RuntimeFlags.disabled) return;
    _crashTotal += 1;
    final r = _redactError(error, stack?.toString(), kind);
    final now = DateTime.now().millisecondsSinceEpoch;
    // Name only an action genuinely open in this kit's own synchronous scope.
    // Most asynchronous Flutter crashes have no such frame; absence is honest
    // and is never replaced with whichever request happens to be in flight.
    final at = SpanScope.currentAction();
    final existing = _pending[r.signature];
    if (existing != null) {
      existing.sessionTotal = existing.sessionTotal + 1 > kMaxOccurrences
          ? kMaxOccurrences
          : existing.sessionTotal + 1;
      existing.unsent = existing.unsent + 1 > kMaxOccurrences
          ? kMaxOccurrences
          : existing.unsent + 1;
      existing.kind = r.kind;
      existing.errorName = r.errorName;
      existing.redactedFrame = r.redactedFrame;
      existing.lastSeen = now;
      if (r.summary != null) existing.summary = r.summary;
      if (r.frames != null) existing.frames = r.frames;
      // A report that knows its action overwrites; one that does not leaves the
      // last known action alone rather than wiping it.
      if (at != null) {
        existing.traceId = at.traceId;
        existing.spanId = at.spanId;
      }
    } else {
      _pending[r.signature] = _CrashEntry(
        signature: r.signature,
        errorName: r.errorName,
        kind: r.kind,
        redactedFrame: r.redactedFrame,
        summary: r.summary,
        frames: r.frames,
        traceId: at?.traceId,
        spanId: at?.spanId,
        sessionTotal: 1,
        unsent: 1,
        lastSeen: now,
      );
      _evictIfNeeded();
    }
    // Persist immediately so a FATAL crash before the flush is still reported
    // on the next launch.
    _persist();
    _scheduleFlush();
  });
}

/// Public entry for the kit's own error boundary render throws (SDK-internal).
void reportRenderError(Object? error, StackTrace? stack) {
  capture(error, stack, crashKindRender);
}

void _evictIfNeeded() {
  if (_pending.length <= kMaxCrashes) return;
  final sortable = _pending.values.toList()
    ..sort((a, b) => a.lastSeen.compareTo(b.lastSeen));
  for (final e in sortable) {
    if (_pending.length <= kMaxCrashes) break;
    if (e.unsent <= 0) _pending.remove(e.signature);
  }
  var i = 0;
  while (_pending.length > kMaxCrashes && i < sortable.length) {
    _pending.remove(sortable[i].signature);
    i += 1;
  }
}

bool _flushing = false;
bool _flushQueued = false;

void _scheduleFlush() {
  // Fire-and-forget; never blocks the host / UI isolate.
  Safe.fire(() {
    _flush();
  });
}

/// Flush out of band with a capture. The lifecycle calls this once the
/// submitter is registered, so crashes parked by a previous fatal session
/// leave on this launch instead of waiting for the next crash. Never throws.
void flushCrashes() {
  _scheduleFlush();
}

List<Map<String, Object?>> buildBatch() {
  final batch = <Map<String, Object?>>[];
  for (final e in _pending.values) {
    if (e.unsent <= 0) continue;
    final item = <String, Object?>{
      'signature': e.signature,
      'errorName': e.errorName,
      'kind': e.kind,
      'redactedFrame': e.redactedFrame,
      'countBucket': _bucketCount(e.sessionTotal),
      'occurrences': e.unsent > kMaxOccurrences ? kMaxOccurrences : e.unsent,
    };
    if (e.summary != null) item['summary'] = e.summary;
    if (e.frames != null) item['frames'] = e.frames;
    if (e.traceId != null) item['traceId'] = e.traceId;
    if (e.spanId != null) item['spanId'] = e.spanId;
    batch.add(item);
    if (batch.length >= kMaxBatch) break;
  }
  return batch;
}

void _applySent(List<Map<String, Object?>> batch) {
  for (final sent in batch) {
    final cur = _pending[sent['signature']];
    if (cur == null) continue;
    final occ = (sent['occurrences'] as int?) ?? 0;
    cur.unsent = cur.unsent - occ < 0 ? 0 : cur.unsent - occ;
  }
}

/// Flush pending crashes through the registered submitter. Always-on for
/// registered apps (only BOOSTHIS_DISABLED / forget() / a missing submitter
/// stop it). Never throws.
Future<void> _flush() async {
  if (_flushing) {
    _flushQueued = true;
    return;
  }
  if (_activeSubmitter == null || RuntimeFlags.disabled || _pending.isEmpty) {
    return;
  }
  _flushing = true;
  try {
    final batch = buildBatch();
    if (batch.isEmpty) return;
    var accepted = 0;
    try {
      accepted = await _activeSubmitter!(batch);
    } catch (_) {
      accepted = 0;
    }
    if (accepted > 0) {
      _applySent(batch);
      _persist();
    }
  } finally {
    _flushing = false;
    if (_flushQueued) {
      _flushQueued = false;
      _scheduleFlush();
    }
  }
}

// ── Persistence ─────────────────────────────────────────────────────

void _persist() {
  Safe.fire(() {
    final list = _pending.values.take(kMaxCrashes).map(_entryToJson).toList();
    // The store holds structured values directly (durable across sessions),
    // exactly like the kill-switch record — no JSON-string round trip.
    Store.set(_storageKey, list, durable: true);
  });
}

Map<String, Object?> _entryToJson(_CrashEntry e) => <String, Object?>{
  'signature': e.signature,
  'errorName': e.errorName,
  'kind': e.kind,
  'redactedFrame': e.redactedFrame,
  if (e.summary != null) 'summary': e.summary,
  if (e.frames != null) 'frames': e.frames,
  if (e.traceId != null) 'traceId': e.traceId,
  if (e.spanId != null) 'spanId': e.spanId,
  'sessionTotal': e.sessionTotal,
  'unsent': e.unsent,
  'lastSeen': e.lastSeen,
};

/// Restore any crashes persisted from a previous (possibly fatal) session.
/// Synchronous — the store holds the structured list directly. Idempotent;
/// never throws.
void restore() {
  if (_restoredOnce) return;
  _restoredOnce = true;
  try {
    final parsed = Store.get(_storageKey, null);
    if (parsed is! List) return;
    for (final c in parsed) {
      if (c is! Map) continue;
      final sig = c['signature'];
      final name = c['errorName'];
      final frame = c['redactedFrame'];
      final kind = c['kind'];
      final sessionTotal = c['sessionTotal'];
      final unsent = c['unsent'];
      if (sig is String &&
          name is String &&
          frame is String &&
          kind is String &&
          _validKinds.contains(kind) &&
          sessionTotal is num &&
          unsent is num) {
        if (_pending.containsKey(sig)) continue;
        _pending[sig] = _CrashEntry(
          signature: sig,
          errorName: name,
          kind: kind,
          redactedFrame: frame,
          summary: c['summary'] is String ? c['summary'] as String : null,
          frames: c['frames'] is List
              ? (c['frames'] as List)
                    .whereType<Map>()
                    .map((m) => Map<String, Object?>.from(m))
                    .toList()
              : null,
          traceId: Trace.isValidTraceId(c['traceId'])
              ? c['traceId'] as String
              : null,
          spanId: SpanScope.sanitizeSpanId(c['spanId']),
          sessionTotal: sessionTotal.toInt(),
          unsent: unsent.toInt(),
          lastSeen: c['lastSeen'] is num
              ? (c['lastSeen'] as num).toInt()
              : DateTime.now().millisecondsSinceEpoch,
        );
      }
    }
    _evictIfNeeded();
  } catch (_) {
    // Corrupt/absent store — start clean.
  }
}

// ── Install / uninstall ─────────────────────────────────────────────

/// Activate the reporter. Called once from enableTelemetry by the integration
/// group AFTER it has chained the host handlers (which then call [capture]).
/// Idempotent: calling again only updates `detailed`. Records the crashFree
/// observation-window origin. Never throws.
void installCrashReporter({required bool detailed}) {
  Safe.fire(() {
    _detailedMode = detailed;
    if (_active) return;
    _active = true;
    if (_telemetryStartedAt == 0) {
      _telemetryStartedAt = DateTime.now().millisecondsSinceEpoch;
    }
    // Restore any crashes persisted from a previous (possibly fatal) session
    // and flush them now that a submitter is registered.
    Safe.fire(() {
      restore();
      _scheduleFlush();
    });
  });
}

/// Tear down the reporter and clear all pending crash state, including the
/// persisted store. Called by telemetry.forget(). Never throws. The adapter is
/// responsible for restoring the host's previous handlers.
void uninstallCrashReporter() {
  _active = false;
  _detailedMode = false;
  _pending.clear();
  _crashTotal = 0;
  _telemetryStartedAt = 0;
  Safe.fire(() {
    Store.delete(_storageKey);
  });
}

// ── crashFree axis inputs ───────────────────────────────────────────

/// Crashes captured since telemetry started (crashFree axis input).
int crashCount() => _crashTotal;

/// Minutes observed since the crash hook was installed (crashFree axis window).
/// 0 before install / after forget. Never throws.
int crashWindowMin() {
  if (_telemetryStartedAt == 0) return 0;
  final ms = DateTime.now().millisecondsSinceEpoch - _telemetryStartedAt;
  return ms > 0 ? ms ~/ 60000 : 0;
}

/// Observe at least this many minutes before claiming crash-free (a crash
/// surfaces immediately regardless).
const int kCrashFreeMinWindowMin = 5;

/// Crash-rate bands: crashes per hour. 0/hr -> 100 - 3/hr -> 0.
const int kCrashFreeRateGood = 0;
const int kCrashFreeRatePoor = 3;

/// The Crash Free axis - how stable this app is for real users - derived
/// purely from the crash hook the kit ALREADY installs, via a counter. No new
/// collection. Scored on the observed crash RATE (crashes per hour) against
/// the cross-runtime band good 0 / poor 3, matching the React Native kit
/// byte-for-byte.
///
/// Warm-up gate: null (OMITTED / warming) while there have been ZERO crashes
/// AND fewer than [kCrashFreeMinWindowMin] minutes observed - but a crash
/// surfaces IMMEDIATELY, even during warm-up, so a real crash is never hidden
/// behind the window. Numbers-only wire ({score, rating, crashes, windowMin});
/// the server rebuilds any caption. Additive + display-only: never feeds the
/// TTFF/TTI/FID speed composite. Pure read - never throws.
Map<String, Object?>? readCrashFree() {
  try {
    final rawCrashes = crashCount();
    final rawWindow = crashWindowMin();
    final crashes = rawCrashes < 0 ? 0 : rawCrashes;
    final windowMin = rawWindow < 0 ? 0 : rawWindow;
    // No crash yet and too little time observed -> warming.
    if (crashes == 0 && windowMin < kCrashFreeMinWindowMin) return null;
    // Floor the window at one minute so a crash in the first seconds cannot
    // divide by ~0 into a nonsense rate.
    const minHours = 1 / 60;
    final rawHours = windowMin / 60;
    final hours = rawHours < minHours ? minHours : rawHours;
    final perHour = crashes / hours;
    final score = linearScore(perHour, kCrashFreeRateGood, kCrashFreeRatePoor);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'crashes': crashes,
      'windowMin': windowMin,
    };
  } catch (_) {
    return null;
  }
}

/// Test/debug helpers.
class CrashInternals {
  static String get storageKey => _storageKey;
  static bool isActive() => _active;
  static bool isDetailed() => _detailedMode;
  static int pendingSize() => _pending.length;
  static List<Map<String, Object?>> getPending() =>
      _pending.values.map(_entryToJson).toList();

  static Map<String, Object?> redactErrorForTests(
    Object? error,
    String? stack,
    String kind,
  ) => _entryFromRedacted(_redactError(error, stack, kind));

  static List<Map<String, Object?>> buildBatchForTests() => buildBatch();

  static void setCrashCountForTests(int n) => _crashTotal = n;
  static void setTelemetryStartedAtForTests(int t) => _telemetryStartedAt = t;
  static void setDetailedForTests(bool d) => _detailedMode = d;
  static void setActiveForTests(bool a) => _active = a;

  static void reset() {
    _pending.clear();
    _active = false;
    _detailedMode = false;
    _restoredOnce = false;
    _flushing = false;
    _flushQueued = false;
    _activeSubmitter = null;
    _crashTotal = 0;
    _telemetryStartedAt = 0;
  }
}

Map<String, Object?> _entryFromRedacted(_RedactedCrash r) => <String, Object?>{
  'signature': r.signature,
  'errorName': r.errorName,
  'kind': r.kind,
  'redactedFrame': r.redactedFrame,
  if (r.summary != null) 'summary': r.summary,
  if (r.frames != null) 'frames': r.frames,
};
