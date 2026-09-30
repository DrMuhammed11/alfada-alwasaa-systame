import 'dart:io';
import 'dart:typed_data';

import 'json.dart';
import 'runtime_flags.dart';
import 'safe.dart';

/// Cross-restart state.
///
/// Flutter runs one long-lived UI isolate, so the PRIMARY backend is an
/// in-memory map that is the source of truth for the life of the process. It
/// persists to a per-app directory on disk for the handful of things that must
/// outlive a restart (install id, tokens, consent, kill-switch cache, cadence
/// stamps). Disk is a durability layer, NOT the hot path.
///
/// SCOPE IS PER APPLICATION, never machine-wide and never per kit copy. The
/// scope key is derived from the HOST app path (the documents/support dir the
/// adapter hands in, or an explicit `BOOSTHIS_PROJECT_ROOT`), the same way the
/// sibling kits hash a project root — never the kit's own source path.
///
/// GUEST SAFETY: a read-only or absent filesystem degrades to "no disk
/// persistence", never to an exception in the host. Writes flush to the OS but
/// NEVER fsync on the hot path — measurements are disposable, the host's frame
/// budget is not.
///
/// CREDENTIALS ON DISK. The scope directory's name is a truncated hash of the
/// host app path — public information, never a secret — and the files inside it
/// hold this install's bearer credentials: the delete token authorizes ingest
/// and forget, the read token authorizes reads of this install's private
/// telemetry. On a phone the app container is already private, but the package
/// falls back to the SYSTEM TEMP directory when no app state path is handed in,
/// which is exactly what a desktop, CLI or shared-host integration gets — and on
/// a shared Unix host that hands both tokens to every other local account.
///
/// Dart cannot fix that by tightening the directory: `dart:io` exposes a file's
/// mode but has no way to SET one, and both ways round that are closed to this
/// kit. Reaching `chmod(2)` through `dart:ffi` would re-open the silent-sensor
/// blind spot this kit is exempt from precisely because it loads nothing at
/// runtime, and spawning `/bin/chmod` costs a process per write and is
/// forbidden on iOS. So the kit does the half it can — it READS, and declines
/// to persist credentials it can see are reachable by other local accounts. See
/// [_prepareDir] for the rule and why it is not simply "must be 0700".
class Store {
  Store._();

  static const String dirPrefix = 'boosthis-';
  static final RegExp _keySanitize = RegExp(r'[^A-Za-z0-9._-]');

  /// Traversal bits for group and other (0o011). A directory that grants
  /// NEITHER cannot be walked into by anyone but its owner, whatever the modes
  /// deeper inside it are.
  static const int _othersTraverse = 0x9; // 0o011

  static final Map<String, Object?> _mem = <String, Object?>{};
  static String? _scopeDir;
  static bool _scopeDirPrivate = false;
  static String? _scopeKey;
  static String? _hostAppPath;

  /// Declared by the adapter/test: the host app's own documents/support
  /// directory. Resolved-once — only the first non-empty value is honoured.
  static void setHostAppPath(String? path) {
    if (path == null || path.isEmpty) return;
    _hostAppPath ??= path;
  }

  /// The host app path the adapter declared, if any. Read by observers that
  /// need to know whether the HOST named this location or the kit fell back to
  /// one of its own — a kit-chosen temp directory is not the app's store.
  static String? get hostAppPath => _hostAppPath;

  /// The path the scope key is hashed from — never the kit's own source path.
  /// Precedence: BOOSTHIS_PROJECT_ROOT, else adapter host path, else cwd, else
  /// the temp dir.
  static String hostRoot() {
    final override = RuntimeFlags.projectRoot;
    if (override != null && override.isNotEmpty) return _trimSep(override);
    if (_hostAppPath != null && _hostAppPath!.isNotEmpty) {
      return _trimSep(_hostAppPath!);
    }
    final cwd = Safe.run<String?>(null, () => Directory.current.path);
    if (cwd != null && cwd.isNotEmpty) return _trimSep(cwd);
    final tmp = Safe.run<String?>(null, () => Directory.systemTemp.path);
    return _trimSep(tmp ?? '.');
  }

  static String _trimSep(String p) => p.replaceAll(RegExp(r'[/\\]+$'), '');

  /// 16-hex-char scope key = SHA1(hostRoot)[0..16], identical in shape to the
  /// sibling kits (Ruby Digest::SHA1 / .NET SHA1, truncated to 16).
  static String scopeKey() =>
      _scopeKey ??= _sha1Hex(hostRoot()).substring(0, 16);

  /// Directory holding this app's durable state files. Read-only/full FS
  /// degrades to no-disk, never an exception.
  static String dir() {
    final cached = _scopeDir;
    if (cached != null) return cached;
    // Did the HOST name this location, or did the kit fall back to one it
    // picked itself? Only the fallback is shared with other local accounts by
    // definition, and only there does the kit get to refuse — see [_prepareDir].
    final hostChosen = RuntimeFlags.stateDir ?? _hostAppPath;
    final base = hostChosen ??
        Safe.run<String?>(null, () => Directory.systemTemp.path) ??
        '.';
    final d =
        '${_trimSep(base)}${Platform.pathSeparator}$dirPrefix${scopeKey()}';
    _scopeDirPrivate =
        Safe.run<bool>(false, () => _prepareDir(d, hostChosen != null));
    return _scopeDir = d;
  }

  /// The scope directory ONLY when it is safe to keep this install's tokens in.
  /// Every durable read and write goes through this; null switches disk off for
  /// the run. State we refuse to write is also state we must not read back —
  /// otherwise a directory another account pre-created at the predictable path
  /// becomes a way to feed the kit someone else's install id and tokens.
  static String? _durableDir() {
    final d = dir();
    return _scopeDirPrivate ? d : null;
  }

  /// The primary backing store is always the in-process memory map.
  static String backend() => 'memory';

  /// Can durable state survive a restart? False also covers a scope directory
  /// other local accounts can reach — credentials are never written into one,
  /// so there is nothing durable to promise.
  static bool writable() {
    return Safe.run<bool>(false, () {
      final d = _durableDir();
      if (d == null) return false;
      final probe =
          File('$d${Platform.pathSeparator}.boosthis-probe-$pid.tmp');
      probe.writeAsStringSync('');
      probe.deleteSync();
      return true;
    });
  }

  /// Where a key's file lives when the directory may hold credentials. Null
  /// switches disk off — see [_durableDir].
  static String? _pathFor(String key) {
    final d = _durableDir();
    if (d == null) return null;
    return '$d${Platform.pathSeparator}${_fileNameFor(key)}';
  }

  /// Where a key's file lives whatever the directory's permissions are. Used by
  /// removal only — sweeping a directory we refuse to write into is still right.
  static String _anyPathFor(String key) =>
      '${dir()}${Platform.pathSeparator}${_fileNameFor(key)}';

  static String _fileNameFor(String key) =>
      '${key.replaceAll(_keySanitize, '_')}.json';

  // ── may this directory hold credentials? ──────────────────────────────

  /// Decide whether [d] may hold this install's delete and read tokens.
  ///
  /// The rule is NOT "the directory must be 0700", because Dart cannot make it
  /// so and because a 0755 directory is not automatically exposed. What matters
  /// is whether another local account can WALK to it: a state file is only
  /// reachable if every directory on the way in grants group or other traversal.
  /// One component that grants neither shuts the whole path — which is how a
  /// 0755 scope directory inside a private per-user temp (macOS `$TMPDIR`) or
  /// inside an app's own container stays private with no chmod anywhere.
  ///
  /// Two things are refused outright:
  ///
  ///   * a SYMLINK at the predictable path. It leads somewhere the kit never
  ///     chose, which is the cheapest way for another account to have the
  ///     tokens written where it can read them.
  ///   * a scope directory the kit picked ITSELF — the system-temp fallback a
  ///     desktop, CLI or shared-host integration gets — that other accounts can
  ///     walk into. There the tokens stay in memory for the run instead.
  ///
  /// A location the HOST named ([RuntimeFlags.stateDir] or the app container
  /// handed to [setHostAppPath]) is used as before when the walk says it is
  /// reachable. Those permissions are the host's to set, and second-guessing
  /// them would cost every phone install its durable state: an iOS container is
  /// isolated by the sandbox rather than by POSIX modes, and its path is
  /// traversable by design.
  static bool _prepareDir(String d, bool hostChosen) {
    final dirObj = Directory(d);
    if (!dirObj.existsSync()) {
      Safe.fire(() => dirObj.createSync(recursive: true));
    }
    if (!dirObj.existsSync()) return false;
    if (!_posixModes) return true;
    if (Safe.run<bool>(false, () => FileSystemEntity.isLinkSync(d))) {
      return false;
    }
    if (hostChosen) return true;
    return !_openToOthers(d);
  }

  /// Can an account other than the owner reach [d]? True only when every
  /// directory from [d] up to the filesystem root grants group or other
  /// traversal. Group membership is treated as hostile, which is the
  /// conservative reading on a shared host.
  static bool _openToOthers(String d) {
    return Safe.run<bool>(true, () {
      var cur = Directory(d).absolute.path;
      // Bounded: a pathological path must never spin the host's isolate.
      for (var depth = 0; depth < 64; depth++) {
        final stat = FileStat.statSync(cur);
        if (stat.type == FileSystemEntityType.notFound) return true;
        if (stat.mode & _othersTraverse == 0) return false;
        final parent = Directory(cur).parent.absolute.path;
        if (parent == cur) return true;
        cur = parent;
      }
      return true;
    });
  }

  /// Windows has no POSIX modes, so the check is skipped there rather than
  /// refusing every directory.
  static bool get _posixModes => !Platform.isWindows;

  /// Read a value. Corrupt disk state is treated as absent, never a throw.
  static Object? get(String key, [Object? fallback]) {
    if (RuntimeFlags.disabled) return fallback;
    return Safe.run<Object?>(fallback, () {
      if (_mem.containsKey(key)) return _deepDup(_mem[key]);
      final val = _readDisk(key);
      return val ?? fallback;
    });
  }

  /// Write a value. Memory always holds it; [durable] also flushes to disk.
  static void set(String key, Object? value, {bool durable = false}) {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      _mem[key] = _deepDup(value);
      if (durable) _writeDisk(key, value);
    });
  }

  /// Read-modify-write; single UI isolate, so no cross-thread lock needed.
  ///
  /// TWO CALL SHAPES are accepted so every sibling group's existing call sites
  /// compile against one Store:
  ///   • `update(key, fn, fallback: seed)`  — mutator is the 2nd positional
  ///   • `update(key, seed, fn)`            — seed is the 2nd positional, the
  ///                                          mutator is the 3rd
  /// They are told apart at runtime: when the 2nd positional is itself a
  /// function it is the mutator (shape 1); otherwise it is the seed and the 3rd
  /// positional is the mutator (shape 2). The seed is the value handed to the
  /// mutator when the key is currently absent.
  static Object? update(
    String key,
    Object? secondArg, [
    Object? Function(Object? current)? maybeMutator,
    bool durable = false,
  ]) {
    if (RuntimeFlags.disabled) return null;

    final Object? Function(Object? current) mutator;
    final Object? seed;
    if (maybeMutator == null && secondArg is Object? Function(Object?)) {
      // Shape 1: update(key, fn) — no seed; absent key mutates over null.
      mutator = secondArg;
      seed = null;
    } else {
      // Shape 2: update(key, seed, fn) — seed handed to the mutator when the
      // key is absent.
      seed = secondArg;
      if (maybeMutator == null) return seed;
      mutator = maybeMutator;
    }

    return Safe.run<Object?>(seed, () {
      final Object? cur =
          _mem.containsKey(key) ? _mem[key] : (_readDisk(key) ?? seed);
      final next = mutator(cur);
      _mem[key] = _deepDup(next);
      if (durable) _writeDisk(key, next);
      return next;
    });
  }

  /// Durable write that is CONFIRMED to have hit disk, with ONE retry,
  /// returning whether it persisted. Memory always holds [value] (so the
  /// running session already reflects it); the bool reports only whether the
  /// value will survive a restart. Used for the one directive an owner's OFF
  /// depends on — a screen-bearing sharing switch the next launch must not
  /// silently forget and re-open under the pre-contact "share" default. See
  /// .agents/memory/phone-kit-sharing-posture.md.
  ///
  /// When durable state is not writable (a read-only sandbox, the parity
  /// harness) there is nowhere to confirm, so this reports false — the caller
  /// then keeps the session closed rather than trusting a memory-only OFF a
  /// restart would drop.
  static bool setDurableVerified(String key, Object? value) {
    if (RuntimeFlags.disabled) return false;
    return Safe.run<bool>(false, () {
      _mem[key] = _deepDup(value);
      final encoded = Json.encode(value);
      if (encoded == null) return false;
      for (var attempt = 0; attempt < 2; attempt++) {
        _writeDisk(key, value);
        final readBack = _readDisk(key);
        if (readBack != null && Json.encode(readBack) == encoded) return true;
      }
      return false;
    });
  }

  static void delete(String key) {
    Safe.fire(() {
      _mem.remove(key);
      final f = File(_anyPathFor(key));
      if (f.existsSync()) f.deleteSync();
    });
  }

  /// Erase every trace of this app's state — memory + on-disk directory.
  static void forgetAll() {
    Safe.fire(() {
      _mem.clear();
      final d = _scopeDir ?? dir();
      final dirObj = Directory(d);
      if (dirObj.existsSync()) {
        for (final f in dirObj.listSync()) {
          if (f is File) Safe.fire(() => f.deleteSync());
        }
        Safe.fire(() => dirObj.deleteSync());
      }
      _scopeDir = null;
      _scopeDirPrivate = false;
    });
  }

  /// Test seam: point the store at a throwaway directory and clear memory.
  ///
  /// A directory handed in here stands in for one the HOST named, which is what
  /// the permissions rule treats it as. Pass `hostChosen: false` to exercise the
  /// other side — the system-temp fallback the kit picks for itself.
  static void useDirectoryForTests(String d, {bool hostChosen = true}) {
    _scopeDir = d;
    _mem.clear();
    _scopeDirPrivate = Safe.run<bool>(false, () => _prepareDir(d, hostChosen));
  }

  /// Test seam: fully reset in-memory + scope resolution.
  static void resetForTests() {
    _mem.clear();
    _scopeDir = null;
    _scopeDirPrivate = false;
    _scopeKey = null;
    _hostAppPath = null;
  }

  // ── disk ──────────────────────────────────────────────────────────────

  static Object? _readDisk(String key) {
    return Safe.run<Object?>(null, () {
      final path = _pathFor(key);
      if (path == null) return null;
      final f = File(path);
      if (!f.existsSync()) return null;
      final raw = f.readAsStringSync();
      if (raw.isEmpty) return null;
      return Json.decodeAny(raw);
    });
  }

  static void _writeDisk(String key, Object? value) {
    Safe.fire(() {
      final encoded = Json.encode(value);
      if (encoded == null) return;
      final path = _pathFor(key);
      if (path == null) return;
      final tmp = '$path.$pid.tmp';
      final tmpFile = File(tmp);
      // Dart's write takes no mode, so the file lands at the process umask.
      // What keeps it away from other accounts is the DIRECTORY: _pathFor only
      // answers for a scope directory they cannot walk into.
      tmpFile.writeAsStringSync(encoded, flush: false);
      Safe.fire(() => tmpFile.renameSync(path));
    });
  }

  static Object? _deepDup(Object? value) {
    if (value is Map) {
      final out = <String, Object?>{};
      value.forEach((k, v) => out['$k'] = _deepDup(v));
      return out;
    }
    if (value is List) return value.map(_deepDup).toList();
    return value;
  }

  // ── SHA1 (pure Dart, zero-dependency) ───────────────────────────────────
  static String _sha1Hex(String input) {
    final bytes = _utf8Bytes(input);
    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    final ml = bytes.length * 8;
    final padded = <int>[...bytes, 0x80];
    while (padded.length % 64 != 56) {
      padded.add(0);
    }
    for (var i = 7; i >= 0; i--) {
      padded.add((ml >> (i * 8)) & 0xff);
    }

    final w = Int32List(80);
    for (var chunk = 0; chunk < padded.length; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        final j = chunk + i * 4;
        w[i] = (padded[j] << 24) |
            (padded[j + 1] << 16) |
            (padded[j + 2] << 8) |
            padded[j + 3];
      }
      for (var i = 16; i < 80; i++) {
        w[i] = _rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      var a = h0, b = h1, c = h2, d = h3, e = h4;
      for (var i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (b & c) | (~b & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }
        final temp = (_rotl(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _rotl(b, 30);
        b = a;
        a = temp;
      }
      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    return _hex32(h0) + _hex32(h1) + _hex32(h2) + _hex32(h3) + _hex32(h4);
  }

  static int _rotl(int v, int bits) =>
      ((v << bits) | ((v & 0xFFFFFFFF) >> (32 - bits))) & 0xFFFFFFFF;

  static String _hex32(int v) =>
      (v & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');

  static List<int> _utf8Bytes(String s) {
    final out = <int>[];
    for (final rune in s.runes) {
      if (rune < 0x80) {
        out.add(rune);
      } else if (rune < 0x800) {
        out.add(0xC0 | (rune >> 6));
        out.add(0x80 | (rune & 0x3F));
      } else if (rune < 0x10000) {
        out.add(0xE0 | (rune >> 12));
        out.add(0x80 | ((rune >> 6) & 0x3F));
        out.add(0x80 | (rune & 0x3F));
      } else {
        out.add(0xF0 | (rune >> 18));
        out.add(0x80 | ((rune >> 12) & 0x3F));
        out.add(0x80 | ((rune >> 6) & 0x3F));
        out.add(0x80 | (rune & 0x3F));
      }
    }
    return out;
  }
}
