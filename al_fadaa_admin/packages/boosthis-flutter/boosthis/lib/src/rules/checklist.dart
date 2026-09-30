// The Boosthis checklist — Flutter / Dart edition (82 Flutter-specific rules).
//
// Tenth runtime. A port of the sibling kits' checklists (Ruby's checklist.rb,
// .NET's Checklist.cs, PHP's Checklist.php, and the React Native pack) carrying
// Flutter/Dart-specific rules for the pitfalls that actually bite real Flutter
// apps: setState granularity and needless rebuilds, missing const constructors,
// unbounded ListView/Column trees, image decode sizing, isolate/compute offload
// of CPU-bound work, platform-channel chatter, shader-compilation jank,
// CustomPaint/saveLayer raster cost, unawaited Futures and unhandled async
// errors, controller/StreamSubscription disposal, local sqflite N+1 and missing
// indexes, HTTP client reuse and timeouts, release-vs-debug measurement, and the
// Flutter performance lints. Each entry mirrors the shape of every other runtime
// checklist so cross-runtime tooling can treat any rule uniformly:
//
//   { id, title, whenToApply, evidence, category, languages }
//
// DETECTION METADATA ONLY. This pack ships the stable id, one-line title, the
// "whenToApply" trigger shape, and plain-text evidence references so matching
// works fully offline and no user code ever leaves the host. The prescriptive
// "what to change" guidance (fixTemplate) is the crown-jewel IP and lives
// SERVER-ONLY in lib/boosthis-fixes, served one rule at a time. There are
// deliberately NO fixTemplate fields and NO URLs anywhere in this file —
// evidence entries are human-readable doc references only.
//
// PURE DART: this file imports only dart: libraries and uses relative imports,
// per the frozen port contract.

/// Rule grouping, parallel to every sibling runtime's Category. The string
/// values match the wire enum used by the Python / Go / PHP / Ruby packs
/// ("case-study" / "industry" / "operational") so cross-runtime tooling reads
/// them uniformly. Kept in this file (rather than its own category.dart)
/// because the whole checklist ships as one unit and these labels have no use
/// apart from [Entry], exactly as the sibling kits nest them beside Entry.
class Category {
  const Category._();

  static const String caseStudy = 'case-study';
  static const String industry = 'industry';
  static const String operational = 'operational';
}

/// One checklist rule. Detection metadata only — never a fixTemplate.
///
/// The field names (id, title, whenToApply, evidence, category, languages)
/// match the sibling packs one-for-one; [languages] is fixed to
/// `['flutter']` for cross-runtime symmetry.
class Entry {
  Entry(
    this.id,
    this.title,
    this.whenToApply,
    List<String> evidence,
    this.category,
  ) : evidence = List<String>.unmodifiable(evidence),
      languages = const <String>['flutter'];

  /// Stable kebab-case id, prefixed `flutter-`.
  final String id;

  /// One-line rule title.
  final String title;

  /// The trigger shape — when this rule applies.
  final String whenToApply;

  /// Human-readable doc / incident references. Never URLs, never a fix.
  final List<String> evidence;

  /// A [Category] wire string.
  final String category;

  /// Always `['flutter']` — this pack's runtime identity.
  final List<String> languages;
}

/// The Boosthis Flutter/Dart checklist. Detection metadata only.
class Checklist {
  const Checklist._();

  // Cross-call cache of the built rule list — build once, reuse.
  static List<Entry>? _cache;

  /// All Flutter checklist rules. Detection metadata only — never a
  /// fixTemplate.
  static List<Entry> all() => _cache ??= List<Entry>.unmodifiable(_build());

  /// Find one rule by its stable id, or null when unknown.
  static Entry? findById(String id) {
    for (final entry in all()) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// All rules in one category (pass a [Category] wire string).
  static List<Entry> byCategory(String category) => all()
      .where((entry) => entry.category == category)
      .toList(growable: false);

  /// Test seam only — drops the cached list.
  static void reset() => _cache = null;

  // Build one rule. Detection metadata only — never a fixTemplate.
  // Mirrors the private rule() helper in every sibling runtime.
  static Entry rule(
    String id,
    String title,
    String whenToApply,
    String category,
    // Evidence references, spread as trailing positional-ish args below.
    String evidence1,
    String evidence2,
  ) => Entry(id, title, whenToApply, <String>[evidence1, evidence2], category);

  // The Flutter rules, built once and cached.
  static List<Entry> _build() => <Entry>[
    // ----- Case Study (18) — patterns from real Flutter/Dart prod incidents -----
    rule(
      "flutter-registration-retry-no-cooldown",
      'Cool down failed registration/handshake retries — never re-attempt every tick',
      'A one-time \'first contact\' call (install/device registration, consent, enrollment, license activation, first token mint) is lazily retried from a hot path — every upload flush, Timer tick, frame callback, or app-resume — with no cool-down and no special handling for HTTP 429. Symptom: a client that cannot finish registering (offline at setup, pending invite, busy server) silently re-attempts dozens of times an hour; behind a shared NAT egress the retries drain the server\'s per-source registration rate bucket and starve OTHER clients\' genuine first registrations, so the failure surfaces on a different device than the bug.',
      Category.caseStudy,
      'Boosthis production incident (Jul 2026) — per-tick consent retries starved a shared per-source registration rate bucket and blocked new installs',
      'Google SRE Book — Handling Overload (retry amplification)',
    ),
    rule(
      "flutter-install-id-reuse",
      'Never reuse a registration/install ID across installs — mint a fresh UUID each time',
      'Host code hard-codes an install/instance identifier, copies one from a sample app, or persists a single ID (in an asset, SharedPreferences seeded from a constant, or a --dart-define) and re-presents it across reinstalls, so the SAME identity is claimed by more than one logical install. Symptom: once an original install is orphaned (consented but its credential was lost), every LATER install presenting that same ID keeps getting a credential-less \'you already registered\' success forever — a deadlock no server lever can break. Mint a fresh UUID (crypto-random v4) per logical install at first run, persist it only for that install, and never seed it from a literal, a bundled asset, another app, or a previous install.',
      Category.caseStudy,
      'Boosthis production incident (Jul 2026) — a persisted-and-reused install ID left every later install stuck on a credential-less success after the first install was orphaned; fix mints a fresh UUID per install',
      'RFC 4122 — UUID uniqueness guarantees',
    ),
    rule(
      "flutter-session-cookie-payment-redirect",
      'Never rely on session/auth cookies surviving a payment/3DS redirect',
      'A payment confirm / return / callback flow that hops out to a bank/3DS/gateway page (a WebView, an external browser via url_launcher, or an in-app-browser tab) relies on the logged-in session cookie surviving the CROSS-SITE redirect back to your return URL to finish an order. Symptom: the browser drops the SameSite=Lax/Strict session cookie on the cross-site hop, or the external browser has a different cookie jar than the WebView, so a customer who really PAID lands on a login screen with no order recorded. The return/confirm leg must be session-FREE — re-verify the payment server-to-server by the payment/order IDs carried in the return deep link, and run a background sweep that reconciles paid-but-stranded checkouts.',
      Category.caseStudy,
      'Boosthis production incident (Jul 2026) — a payment confirm leg required the login session; the 3DS cross-site redirect dropped the cookie and stranded a paid customer at the login screen; fix verifies server-to-server by ID',
      'MDN — SameSite cookie attribute and cross-site redirect behaviour',
    ),
    rule(
      "flutter-background-work-needs-scheduler",
      'Scheduled/background work must never depend on a screen being open',
      'Work that MUST happen on a schedule — subscription renewals, data-retention purges, token rotation, digest sends, cache reconciliation — is triggered from inside a widget\'s build/initState, a screen\'s route callback, or a foreground Timer that only ticks while an app is open, instead of a real OS background task (WorkManager / BGTaskScheduler via a plugin) or a server-side scheduler. Symptom: as long as the user keeps the app open the work runs, but the moment the app is backgrounded or killed, renewals silently stop and required purges never happen, with no error because nothing ran. Anything time-driven needs an OS-scheduled background task or a server cron, never a foreground screen\'s lifecycle.',
      Category.caseStudy,
      'Boosthis production incident (Jul 2026) — renewals and retention purges ran only from a foreground screen\'s Timer, so they silently never fired once the app was backgrounded; moved onto an OS background task',
      'Flutter docs — background processing and platform background execution limits',
    ),
    rule(
      "flutter-setstate-above-changing-subtree",
      'Call setState on the smallest widget that changes — not a top-level ancestor',
      'A high-in-the-tree StatefulWidget (an App/Scaffold/Page state) calls setState for a change that only affects a small leaf — a counter badge, a text field\'s value, a single list tile — so Flutter rebuilds the entire subtree below it every change. Symptom: typing in a field or ticking an animation rebuilds hundreds of widgets per keystroke/frame, the DevTools rebuild-count overlay lights up the whole page, and the app janks under interaction even though only one glyph changed. Push the mutable state DOWN into the smallest widget that actually depends on it (or use a ValueListenableBuilder / a scoped provider selector) so setState rebuilds only the leaf, not the world.',
      Category.caseStudy,
      'Flutter docs — Performance best practices: minimize the widgets rebuilt by setState',
      'Flutter DevTools — the rebuild-count / widget-rebuild profiler',
    ),
    rule(
      "flutter-missing-const-constructors",
      'Mark unchanging widgets const so Flutter can skip rebuilding them',
      'Widget subtrees that never change for a given input (icons, static text, padding, decorations, list separators) are constructed WITHOUT the const keyword inside a build() method, so every parent rebuild allocates a brand-new widget instance and Flutter\'s element diff cannot short-circuit them. Symptom: a parent that rebuilds often (an animation, a scroll, a setState) re-runs build for dozens of static children each frame, inflating rebuild counts and GC churn for widgets whose output is identical. Add const to constructors of immutable widgets (and enable the prefer_const_constructors lint) so Flutter reuses the canonicalized instance and prunes the rebuild.',
      Category.caseStudy,
      'Flutter docs — Performance best practices: use const constructors where possible',
      'Dart lint — prefer_const_constructors',
    ),
    rule(
      "flutter-listview-not-builder",
      'Build long/dynamic lists with ListView.builder — never a ListView with a full children list',
      'A long or growing list is rendered with ListView(children: items.map(...).toList()), Column, or SingleChildScrollView wrapping every row, so EVERY item widget is built and laid out up front whether or not it is on screen. Symptom: opening the screen builds hundreds/thousands of off-screen widgets, first paint is slow, memory holds the whole list, and scrolling a large dataset janks; the eager .toList() also re-maps the whole collection on every rebuild. Use ListView.builder / SliverList with an itemBuilder (and itemExtent/prototypeItem when row height is known) so Flutter lazily builds and recycles only the visible viewport.',
      Category.caseStudy,
      'Flutter docs — Working with long lists (ListView.builder)',
      'Flutter docs — Creating a ListView.builder vs. the default constructor',
    ),
    rule(
      "flutter-sync-work-in-build",
      'Keep build() pure and cheap — no synchronous decode, IO, or heavy compute in build',
      'A widget\'s build() method does real work every time it runs — parsing/formatting large data, decoding JSON, running a regex, reading a file synchronously, sorting a big list, or building a heavy object graph — instead of returning a lightweight description of the UI. Symptom: because build() can run many times per second (animation, scroll, setState, media-query changes), the work repeats every frame and blows the 16ms budget, producing jank that scales with how often the widget rebuilds. Move the computation out of build (do it once in initState/didChangeDependencies, memoize it, or precompute it), and keep build() allocation-light.',
      Category.caseStudy,
      'Flutter docs — Performance best practices: build methods should be fast and side-effect free',
      'Flutter docs — avoid expensive work in build()',
    ),
    rule(
      "flutter-heavy-work-on-ui-isolate",
      'Run CPU-heavy work on a background isolate with compute()/Isolate.run — not the UI isolate',
      'CPU-bound work — parsing a large JSON body, decoding/encoding images, cryptographic hashing, sorting/searching a big collection, PDF or CSV generation — runs synchronously on the UI (root) isolate, which is the same isolate that drives layout, paint, and gesture handling. Symptom: while the work runs the UI freezes completely (frozen frames, unresponsive taps, the OS \'app not responding\' watchdog on a long stall) because Dart is single-threaded per isolate and nothing else can run. Offload the pure computation to a background isolate via compute() or Isolate.run() (Flutter 3.7+) and await the result, so the UI isolate keeps hitting its frame budget.',
      Category.caseStudy,
      'Flutter docs — Concurrency and isolates (compute / Isolate.run)',
      'Flutter cookbook — Parse JSON in the background with an isolate',
    ),
    rule(
      "flutter-image-no-cache-dimensions",
      'Decode images to their displayed size with cacheWidth/cacheHeight or ResizeImage',
      'An Image (network/asset/file) is displayed much smaller than its source resolution but decoded at full size — no cacheWidth/cacheHeight, no ResizeImage wrapper, no server-side thumbnail — so a multi-megapixel photo is decoded into a full-size bitmap for a 96px thumbnail. Symptom: the image cache and native memory balloon (each decoded frame is width×height×4 bytes regardless of display size), lists of photos cause memory spikes and GC pauses, and low-end devices get killed by the OS. Pass cacheWidth/cacheHeight (or wrap in ResizeImage) sized to the LOGICAL render size × devicePixelRatio so the engine decodes a right-sized bitmap.',
      Category.caseStudy,
      'Flutter docs — Image cache and cacheWidth/cacheHeight decode sizing',
      'Flutter API — ResizeImage and reducing image memory',
    ),
    rule(
      "flutter-opacity-clip-shadow-overdraw",
      'Avoid Opacity/ClipPath/elevation overdraw — use cheaper equivalents or RepaintBoundary',
      'Expensive compositing is used where a cheaper primitive would do: Opacity/AnimatedOpacity wrapping a large or animating subtree (it saves a layer and blends every frame), ClipPath/antiAlias clipping on scrolling content, or many Material elevations/BoxShadows stacked so the GPU overdraws the same pixels repeatedly. Symptom: raster-thread jank (the frame\'s raster time, not build time, blows the budget), visible in the DevTools performance overlay\'s bottom bar, worst while scrolling or animating. Prefer cheaper equivalents (fade via a color/AnimatedOpacity on a small child, Container decoration instead of Opacity, clipBehavior none where possible) and add RepaintBoundary around costly static subtrees so they aren\'t re-rasterized every frame.',
      Category.caseStudy,
      'Flutter docs — Performance best practices: Opacity, clipping, and saveLayer cost',
      'Flutter docs — RepaintBoundary and reducing raster-thread work',
    ),
    rule(
      "flutter-controllers-not-disposed",
      'Dispose AnimationController/StreamSubscription/Timer/TextEditingController in dispose()',
      'A State creates a long-lived resource — AnimationController, StreamSubscription (from .listen), Timer/Timer.periodic, TextEditingController/FocusNode/ScrollController, ChangeNotifier listeners — but its dispose() (or the subscription\'s cancel()) is missing or incomplete, so the resource outlives the widget. Symptom: after the screen is popped the ticker keeps firing, the stream callback fires setState on a defunct State (throwing \'setState after dispose\'), timers keep waking the app, and the retained objects leak memory and battery. Cancel/dispose every such resource in State.dispose() (and cancel subscriptions), matching each create with a tear-down.',
      Category.caseStudy,
      'Flutter docs — State.dispose and releasing resources (controllers, tickers)',
      'Flutter docs — cancel StreamSubscription and Timer in dispose',
    ),
    rule(
      "flutter-unawaited-futures",
      'Don\'t drop a Future on the floor — await it or use unawaited() with error handling',
      'Async work is started and the returned Future is discarded without an await, a .catchError, or an explicit unawaited() — a fire-and-forget save/upload, an async call in a non-async callback, or a forgotten await inside a try that therefore catches nothing. Symptom: exceptions thrown inside the dropped Future become unhandled async errors (surfaced to PlatformDispatcher.onError or silently swallowed), ordering guarantees break because the caller continues before the work finishes, and the failure is invisible until data is missing. Await the Future where completion/ordering matters, wrap it in try/catch or .catchError, or mark a deliberate fire-and-forget with unawaited() AND attach error handling.',
      Category.caseStudy,
      'Dart docs — asynchronous programming: don\'t ignore Futures',
      'Dart API — unawaited() and handling fire-and-forget errors',
    ),
    rule(
      "flutter-network-cancellation-no-rollback",
      'A cancelled/timed-out request may still have committed remotely — make retries idempotent',
      'Code aborts an outbound HTTP call via a timeout, a cancel token (dio CancelToken), or by dropping the Future when a screen closes, catches the resulting error, and retries or reports failure assuming the server did nothing. Symptom: cancellation only abandons YOUR wait; the request may already be in flight or committed remotely, so a timed-out \'create payment\' or \'send message\' that is retried double-charges or double-sends, and a cancelled write that actually landed is shown to the user as failed. Treat a cancelled/timed-out mutation as UNKNOWN, not failed — carry an idempotency key so a retry is deduped server-side, and reconcile by querying the resource\'s real state before retrying.',
      Category.caseStudy,
      'Stripe API docs — Idempotent requests',
      'Dart / dio docs — request cancellation (CancelToken) and timeouts abandon only the local wait',
    ),
    rule(
      "flutter-navigation-redirect-loop",
      'A router redirect must not send an unauthenticated user to a guarded route',
      'A GoRouter/Navigator redirect (or an auth guard) sends unauthenticated users to a login/onboarding route, but that target route is itself covered by the same guard — or the redirect condition never becomes false — so it redirects again immediately. Symptom: the app flickers between screens, the redirect callback runs in a tight loop burning frames and battery, or GoRouter throws a \'redirect loop detected\' assertion; it often triggers only for a subset of users (an expired token, a first-launch state) so it looks like a data bug. Exempt the redirect target from the guard that triggers the redirect, and assert the destination is reachable without the condition that caused the redirect.',
      Category.caseStudy,
      'go_router docs — redirect and redirect-loop detection',
      'Flutter docs — Navigator/route guards and auth redirects',
    ),
    rule(
      "flutter-jank-shader-compilation",
      'Warm up shaders so first-run animations don\'t jank on shader compilation',
      'The first time a particular animation, transition, or effect runs, the Skia/Impeller shader it needs is compiled on the raster thread on demand, stalling that frame. Symptom: the FIRST play of an animation (a page transition, a ripple, a custom paint) janks hard on a fresh install while every later play is smooth — a classic \'jank only the first time\' report that is impossible to reproduce after warmup. Mitigate with shader warm-up (SkSL bundling captured via --dump-skp-on-shader-compilation / --bundle-sksl-path on the Skia backend), by preferring the Impeller renderer where available (it precompiles shaders and removes this class of jank), and by exercising key animations off-screen during a splash/warmup phase.',
      Category.caseStudy,
      'Flutter docs — Reducing shader compilation jank on mobile',
      'Flutter docs — Impeller rendering engine and shader precompilation',
    ),
    rule(
      "flutter-platform-channel-per-frame",
      'Don\'t chatter over a platform channel every frame — batch and cache native calls',
      'A method/event channel to native code (a plugin call, a sensor read, a platform value like locale or safe-area) is invoked inside build(), a per-frame callback, a scroll listener, or a tight Timer, so every frame crosses the async Dart↔platform boundary. Symptom: each call is serialized and hops isolates/threads with real latency, so per-frame channel traffic adds jank and drains battery, and a burst (one call per list item during a scroll) can back up the channel. Read platform values ONCE and cache them, subscribe to an EventChannel stream instead of polling, and batch multiple native operations into a single channel call rather than N per frame.',
      Category.caseStudy,
      'Flutter docs — Platform channels: performance and batching',
      'Flutter docs — EventChannel streaming vs. polling MethodChannel',
    ),
    rule(
      "flutter-oversized-image-in-memory",
      'Cap image cache and in-memory bitmap size — unbounded decode OOMs low-end devices',
      'The app loads user- or network-supplied images with no bound on decoded size or on the imageCache — full-resolution camera photos, unbounded galleries, or an imageCache whose maximumSizeBytes was never tuned — so decoded bitmaps accumulate in native memory. Symptom: memory climbs as the user scrolls a media feed (each decoded frame is width×height×4 bytes), the OS starts killing the app in the background, and low-RAM devices crash on large images. Bound the work: size PaintingBinding.instance.imageCache.maximumSizeBytes to the device budget, decode at display size (cacheWidth/cacheHeight), and reject or downscale oversized source images before decode.',
      Category.caseStudy,
      'Flutter docs — PaintingBinding.imageCache and maximumSizeBytes',
      'Flutter docs — decoding images at display size to bound memory',
    ),
    // ----- Industry (38) — Flutter/Dart performance & reliability best practice -----
    rule(
      "flutter-rebuild-fanout-inherited-widget",
      'Scope InheritedWidget/Provider updates so a change doesn\'t rebuild every dependent',
      'A broad InheritedWidget / Provider / ChangeNotifier at the top of the tree exposes a fat model, and widgets depend on the WHOLE model (context.watch of the object, Provider.of without a selector) rather than the one field they read. Symptom: any change to any field notifies and rebuilds every dependent widget in the subtree, so an unrelated toggle rebuilds the whole page; rebuild counts fan out far beyond what actually changed. Split state into narrower notifiers, use Selector / context.select / a ValueListenable per field, and expose immutable slices so only widgets that read the changed field rebuild.',
      Category.industry,
      'Flutter docs — InheritedWidget updateShouldNotify and dependency scope',
      'provider docs — Selector / context.select to narrow rebuilds',
    ),
    rule(
      "flutter-context-provider-value-unmemoized",
      'Don\'t build a fresh provider value object in build — memoize it so children don\'t rebuild',
      'An InheritedWidget/Provider/ChangeNotifierProvider is given a NEW value object constructed inline in build() (Provider.value(value: MyModel(...)) or a fresh map/list literal), so the provider sees a new identity every parent rebuild and notifies all dependents even though the data is unchanged. Symptom: every ancestor rebuild cascades into a full rebuild of every widget that reads the provider, defeating the point of the provider; it looks like \'everything rebuilds when anything changes\'. Hoist the value so it is created once (a field, a memoized instance, a const), and only rebuild dependents when the underlying data actually changes.',
      Category.industry,
      'provider docs — prefer Provider over Provider.value with an inline object',
      'Flutter docs — InheritedWidget identity and updateShouldNotify',
    ),
    rule(
      "flutter-inline-closures-to-const-child",
      'Don\'t pass fresh inline closures/objects to a child you want const-cached',
      'A widget passes an inline closure (onTap: () => ...), a fresh list/map literal, or a newly-constructed object as a prop to a child that could otherwise be const or is wrapped for memoization, so the child gets a new-identity prop every rebuild and can never be skipped. Symptom: children that should be stable rebuild on every parent frame because their props change identity each time; adding const to the child has no effect because a captured closure keeps changing. Hoist stable callbacks to fields/methods, pass const literals where possible, and keep prop identity stable so const/element reuse can prune the child.',
      Category.industry,
      'Dart lint — prefer_const_constructors (blocked by non-const arguments)',
      'Flutter docs — const widgets and stable prop identity for element reuse',
    ),
    rule(
      "flutter-single-animation-driver",
      'Drive a widget\'s animations from one AnimationController via a single Ticker',
      'A single animated widget spins up multiple AnimationControllers, or several widgets each create their own Ticker, when one controller (composed with Tween/CurvedAnimation/Interval) could drive them all. Symptom: multiple independent tickers each schedule frames and run their own listeners, multiplying per-frame callback work and making the animations drift out of sync; each extra controller is also an extra dispose obligation. Use ONE AnimationController per animated component, derive sub-animations with Tween/Interval/CurvedAnimation off that single controller, and drive rebuilds through AnimatedBuilder so only the animated subtree repaints.',
      Category.industry,
      'Flutter docs — AnimationController, Tween, and composing animations',
      'Flutter docs — AnimatedBuilder and driving multiple animations from one controller',
    ),
    rule(
      "flutter-animation-not-stopped-offscreen",
      'Stop/repeat-pause animations when the screen is not visible',
      'An AnimationController.repeat() (a spinner, a shimmer, a looping effect) keeps running after its screen is pushed under another route, moved to an inactive tab, or the app is backgrounded, because nothing pauses it on visibility change. Symptom: an off-screen animation keeps scheduling frames and rebuilding every ~16ms forever, burning CPU/GPU and battery for pixels nobody can see, and can keep the whole app from ever going idle. Pause/stop the controller when the route is not current (RouteAware.didPushNext / a VisibilityDetector) and on AppLifecycleState.paused, and resume it when the screen becomes visible again.',
      Category.industry,
      'Flutter docs — RouteAware / RouteObserver for visibility changes',
      'Flutter docs — pausing AnimationController when not visible',
    ),
    rule(
      "flutter-applifecycle-not-observed",
      'Pause timers, streams & polling when the app is backgrounded',
      'Foreground-only work — polling Timers, animation loops, location/sensor streams, websocket keep-alives, expensive periodic refreshes — keeps running when the app goes to the background because nothing observes AppLifecycleState. Symptom: the app drains battery and data while not on screen, keeps sockets and sensors alive needlessly, and may be killed by the OS for background CPU use. Register a WidgetsBindingObserver (or AppLifecycleListener) and, on AppLifecycleState.paused/inactive, pause timers, cancel/pause streams, and stop animations; resume them on AppLifecycleState.resumed.',
      Category.industry,
      'Flutter docs — WidgetsBindingObserver and AppLifecycleState',
      'Flutter docs — AppLifecycleListener for pausing background work',
    ),
    rule(
      "flutter-list-no-itemextent",
      'Give long lists itemExtent/prototypeItem so the viewport doesn\'t measure every child',
      'A large ListView.builder/CustomScrollView has variably-measured children and no itemExtent or prototypeItem, so the scroll machinery must lay out children to know their size when computing scroll offsets, and heavy per-item builders run more than necessary. Symptom: scrolling a big list janks and the scrollbar/scroll-to-index math is expensive, especially when jumping far; it is worse with complex item widgets. When rows share a fixed height, set itemExtent (or prototypeItem) so the viewport can compute offsets without measuring, and keep item builders cheap and const-heavy.',
      Category.industry,
      'Flutter docs — ListView itemExtent / prototypeItem for scroll performance',
      'Flutter docs — Sliver layout and fixed-extent optimizations',
    ),
    rule(
      "flutter-oversized-savelayer-custompaint",
      'Avoid needless saveLayer() in CustomPaint and repaint only what changes',
      'A CustomPainter allocates an offscreen layer every paint — an explicit canvas.saveLayer, a blend mode/opacity that forces one, or a painter whose shouldRepaint always returns true — and/or repaints on every frame when its inputs did not change. Symptom: raster-thread cost spikes because saveLayer allocates and composites an offscreen buffer per paint, and unnecessary repaints re-run expensive path/gradient work; this is raster jank, not build jank. Return false from shouldRepaint when inputs are unchanged, avoid saveLayer unless a group opacity/blend genuinely needs it, wrap the CustomPaint in a RepaintBoundary, and cache expensive Path/Picture objects.',
      Category.industry,
      'Flutter docs — CustomPainter shouldRepaint and avoiding needless repaints',
      'Flutter docs — Canvas.saveLayer cost and RepaintBoundary',
    ),
    rule(
      "flutter-mediaquery-of-rebuild-fanout",
      'Read only the MediaQuery slice you need so keyboard/rotation changes don\'t rebuild the page',
      'A high-in-the-tree widget calls MediaQuery.of(context) (grabbing the whole MediaQueryData) when it only needs one field like size or viewInsets, so it becomes a dependent of EVERY MediaQuery change. Symptom: opening the keyboard (viewInsets changes) or rotating the device rebuilds a large subtree that only cared about width, adding avoidable rebuilds during interactions users already perceive as heavy. Read the narrow slice (MediaQuery.sizeOf / .viewInsetsOf / .paddingOf, Flutter 3.10+) at the LEAF that uses it, so only that leaf rebuilds when that specific dimension changes.',
      Category.industry,
      'Flutter docs — MediaQuery.sizeOf/.viewInsetsOf and scoped dependencies (Flutter 3.10)',
      'Flutter docs — MediaQuery.of subscribes to all MediaQueryData changes',
    ),
    rule(
      "flutter-json-decode-on-ui-isolate",
      'Decode large JSON responses off the UI isolate with compute()',
      'A large HTTP response body is parsed with jsonDecode (and mapped into model objects) synchronously on the UI isolate right where the response arrives, so a big payload is walked and allocated on the same isolate that renders. Symptom: a multi-hundred-KB response freezes the UI for the duration of the parse (dropped/frozen frames right after a fetch), worst on lists that decode big collections; it scales with payload size and device speed. Move jsonDecode + model mapping into a background isolate via compute()/Isolate.run() and return plain data, so the UI isolate only touches the finished objects.',
      Category.industry,
      'Flutter cookbook — Parse JSON in the background with compute()',
      'Dart docs — jsonDecode cost scales with payload size',
    ),
    rule(
      "flutter-string-concat-in-loop",
      'Build strings with StringBuffer, not += in a loop',
      'A loop accumulates a large string with s = s + part or s += part (Dart strings are immutable, so each iteration allocates a new string and copies the whole prefix), or repeatedly concatenates in an export/serialization routine. Symptom: an O(N) build becomes O(N²) in time and allocation, GC pressure spikes, and a big export or CSV/HTML generation stalls the isolate. Accumulate with a StringBuffer (buffer.write(part); buffer.toString() once at the end) or String join, turning the work back into linear time and one allocation.',
      Category.industry,
      'Dart docs — StringBuffer for efficient string building',
      'Dart docs — String immutability and O(n^2) concatenation',
    ),
    rule(
      "flutter-collection-in-build-recreated",
      'Don\'t allocate lists/maps/sorts inside build — hoist or memoize them',
      'build() (or a per-frame callback) allocates and populates collections every run — .map().toList(), .where().toList(), a fresh sort, a new Map literal, or a filtered copy of a source list — so the same data structure is rebuilt from scratch on every rebuild. Symptom: rebuild-heavy widgets churn the allocator and GC every frame doing work whose inputs did not change, compounding any other rebuild-storm problem. Compute the collection once when its inputs change (in initState/didUpdateWidget or a memoized getter) and reference the cached result in build; keep build() a cheap description, not a data-processing step.',
      Category.industry,
      'Flutter docs — Performance best practices: avoid rebuilding costly objects in build',
      'Dart docs — allocation and GC pressure from per-frame collections',
    ),
    rule(
      "flutter-regex-recompiled-in-build",
      'Compile RegExp once as a static final — not inside build or a per-item callback',
      'A RegExp is constructed with RegExp(...) inside build(), an itemBuilder, a validator, or a loop, so the pattern is recompiled on every rebuild/item/iteration. Symptom: validators and formatters that run per keystroke or per list item pay repeated regex-compile cost, adding avoidable CPU on the UI isolate during interactions. Hoist the pattern to a static final RegExp (or a top-level final) compiled once at class load, and reuse that instance everywhere it is matched.',
      Category.industry,
      'Dart docs — RegExp construction cost and reuse',
      'Flutter docs — hoist expensive objects out of build/itemBuilder',
    ),
    rule(
      "flutter-catastrophic-backtracking-regex",
      'Avoid catastrophic-backtracking (ReDoS) regexes on user input',
      'A field validator or parser matches user-controlled input against a RegExp with nested quantifiers ((a+)+, (.*)*) or overlapping alternation. Symptom: a crafted input pegs the UI isolate for seconds inside the matcher, freezing the whole app (Dart regex runs on the isolate that called it) — a self-inflicted denial of service triggered by typing. Rewrite the pattern to avoid nested/ambiguous quantifiers, anchor it, cap the input length before matching, and run any genuinely heavy matching on a background isolate.',
      Category.industry,
      'OWASP — Regular expression Denial of Service (ReDoS)',
      'Dart docs — RegExp runs on the calling isolate',
    ),
    rule(
      "flutter-sync-file-io-on-ui-isolate",
      'Never use dart:io sync file APIs (readAsStringSync) on the UI isolate',
      'File or storage access on the UI isolate uses the synchronous dart:io APIs — File.readAsStringSync, writeAsBytesSync, existsSync in a hot path, or a synchronous SharedPreferences/SQLite call — blocking the isolate until the disk operation returns. Symptom: the UI freezes for the duration of the IO (worse on slow storage or large files), producing dropped frames on screens that read config/cache at startup or on tap. Use the async variants (readAsString(), writeAsBytes()) and await them, and move large or bursty file work onto a background isolate so the UI isolate never blocks on disk.',
      Category.industry,
      'Dart docs — dart:io async file APIs vs the *Sync variants',
      'Flutter docs — keep disk I/O off the UI isolate',
    ),
    rule(
      "flutter-timer-leak-after-dispose",
      'Don\'t call setState from a Timer/Future callback after the State is disposed',
      'A Timer, Future.then, or stream callback captures a State and calls setState (or touches context) when it fires, but the callback can complete AFTER the widget is disposed (the user navigated away before the delay/response). Symptom: \'setState() called after dispose()\' exceptions, or silent work on a defunct element; under load these appear as intermittent crashes tied to fast navigation. Cancel the Timer/subscription in dispose(), and guard late callbacks with an if (!mounted) return before setState so a completion that races disposal is a no-op.',
      Category.industry,
      'Flutter docs — State.mounted guard before setState in async callbacks',
      'Flutter docs — cancel Timers/subscriptions in dispose',
    ),
    rule(
      "flutter-scroll-listener-heavy-work",
      'Keep ScrollController/scroll-notification listeners cheap and throttled',
      'A ScrollController listener or NotificationListener<ScrollNotification> does heavy work on every scroll offset change — setState that rebuilds a large tree, layout math, an analytics call, or a synchronous read — so work runs many times per frame while the finger moves. Symptom: scrolling janks in proportion to how much the listener does, because it fires at pointer/scroll frequency; the more it rebuilds, the worse the drop. Keep the listener minimal, update only a narrow ValueNotifier the affected leaf listens to (not a page-level setState), and throttle/debounce expensive side effects (analytics, network) off the scroll path.',
      Category.industry,
      'Flutter docs — ScrollController listeners fire at scroll frequency',
      'Flutter docs — throttle/debounce expensive scroll side effects',
    ),
    rule(
      "flutter-large-image-asset-no-resolution-variants",
      'Cache and right-size list thumbnails — reuse decoded images across cells',
      'A scrolling list of images re-fetches/re-decodes the same or full-size images per cell — no CachedNetworkImage / image cache reuse, no cacheWidth sized to the cell, thumbnails pulled at full resolution — so the same bytes are decoded repeatedly and cells don\'t share decoded frames. Symptom: scrolling a media list janks and memory spikes because each visible cell decodes a large bitmap and nothing is reused as cells recycle. Use a caching image widget keyed by URL, decode at the cell\'s rendered size (cacheWidth/cacheHeight), and let the shared imageCache serve reused images so recycled cells hit the cache instead of re-decoding.',
      Category.industry,
      'cached_network_image docs — memory/disk caching and memCacheWidth',
      'Flutter docs — imageCache reuse across recycled list cells',
    ),
    rule(
      "flutter-unbounded-stream-buffer",
      'Bound fast producers into slow UI — don\'t let a stream/event queue grow unboundedly',
      'A high-frequency source (a sensor EventChannel, a websocket, a rapid-fire StreamController) is consumed by an async handler that awaits slow work (a DB write, a setState-driven rebuild) with no backpressure, so events arrive faster than they are drained and the pending queue/microtask backlog grows. Symptom: memory climbs, latency between event and UI grows without bound, and eventually the isolate is saturated processing a backlog the user no longer cares about. Apply backpressure: sample/throttle/debounce the stream (Stream.transform, an interval sampler), use a bounded buffer that drops or conflates stale events, or pause the subscription while a slow handler runs.',
      Category.industry,
      'Dart docs — Stream backpressure, pause/resume, and buffering',
      'rxdart / Stream docs — throttle, debounce, and sampling operators',
    ),
    rule(
      "flutter-notifier-fires-on-equal-value",
      'Notify listeners only on real value changes — don\'t notifyListeners on identical values',
      'A ChangeNotifier/ValueNotifier calls notifyListeners() (or assigns .value) even when the new value equals the old one — a setter that always notifies, a stream that re-emits identical states, a model that notifies on every assignment. Symptom: listeners and their widgets rebuild for no-op changes, so redundant notifications multiply rebuilds and hide the real changes in the noise. Compare before notifying (if (newValue == _value) return;), rely on ValueNotifier\'s built-in equality short-circuit, and use distinct() on streams so a callback fires once per REAL change.',
      Category.industry,
      'Flutter docs — ValueNotifier equality short-circuit',
      'Dart docs — Stream.distinct to suppress duplicate emissions',
    ),
    rule(
      "flutter-heavy-widget-mount-all-at-once",
      'Stagger heavy widget mounts across frames instead of building them all in one frame',
      'A screen builds many heavy widgets in a single frame — a dashboard of charts, a grid of decoded images, several map/webview/platform-view instances mounted together at first paint. Symptom: the mount frame blows the budget badly (a long first-frame stall or a visible hitch on navigation) because all the expensive initialization happens at once. Stagger the work: show a lightweight skeleton first, then mount heavy children progressively across frames (addPostFrameCallback, a phased builder, or lazy slivers that build as they scroll into view) so no single frame carries the whole cost.',
      Category.industry,
      'Flutter docs — SchedulerBinding.addPostFrameCallback for phased mounting',
      'Flutter docs — lazy slivers build children as they scroll into view',
    ),
    rule(
      "flutter-image-precache-missing",
      'precacheImage heavy images before navigating so the next screen doesn\'t decode on paint',
      'A navigation target shows a large hero/background image that is only fetched and decoded when the destination widget first builds, so the decode happens during the transition\'s first frames. Symptom: the screen transition janks or shows a blank/placeholder flash because the image decode competes with the navigation animation on the UI/raster threads. Warm the asset before navigating with precacheImage(...) (or prefetch via the caching image provider) during idle time or as the user starts the navigation gesture, so the destination paints from a ready decoded frame.',
      Category.industry,
      'Flutter docs — precacheImage to warm images before display',
      'Flutter docs — avoid decoding during route transitions',
    ),
    rule(
      "flutter-const-widgets-lint-off",
      'Turn on the Flutter performance lints (prefer_const_constructors et al.)',
      'analysis_options.yaml does not include flutter_lints/the recommended lint set, so the analyzer never flags missing const constructors, unnecessary rebuilds, unawaited futures, or unclosed sinks. Symptom: the whole class of const/dispose/await mistakes ships unnoticed because nothing warns at author time; reviewers catch them inconsistently. Enable the flutter_lints package (include: package:flutter_lints/flutter.yaml) plus prefer_const_constructors, prefer_const_literals_to_create_immutables, unawaited_futures, and close_sinks, so the analyzer enforces the performance/leak rules mechanically in CI.',
      Category.industry,
      'Flutter docs — flutter_lints and the recommended lint set',
      'Dart docs — analysis_options.yaml and enabling lints',
    ),
    rule(
      "flutter-rebuild-whole-tree-on-theme",
      'Let widgets react to only the Theme/inherited slice they use',
      'Widgets depend on the whole Theme (Theme.of(context) returning ThemeData) or a broad inherited model to read one token (a single color or text style), so any theme/inherited change rebuilds them all. Symptom: a theme toggle or a broad inherited update rebuilds far more of the tree than visually changed. Read the narrow slice a widget needs and let each widget declare exactly the inherited data it depends on, so a change to an unrelated token doesn\'t force it to rebuild.',
      Category.industry,
      'Flutter docs — Theme.of subscribes to ThemeData changes',
      'Flutter docs — read narrow inherited slices instead of the whole model',
    ),
    // ----- Operational (20) — build, tooling, observability & release hygiene -----
    rule(
      "flutter-debug-build-shipped",
      'Profile and ship in release/profile mode — debug builds are not representative',
      'Performance is judged from a debug build, or a debug/JIT build is shipped, so measurements include debug-mode overhead (assertions, no AOT, the service isolate, slow-mode banners) and users run un-optimized code. Symptom: the app feels janky in a way that vanishes in a real build, OR a debug build reaches production and runs far slower and larger than the AOT release. Always profile in profile mode (flutter run --profile) and ship a release AOT build (flutter build --release); never draw performance conclusions or optimize against a debug build, because the JIT/AOT gap dwarfs most micro-optimizations.',
      Category.operational,
      'Flutter docs — Flutter\'s build modes (debug, profile, release)',
      'Flutter docs — profile in profile mode, never judge performance from debug',
    ),
    rule(
      "flutter-no-frame-budget-monitoring",
      'Watch the raster and build frame times against the 16ms budget',
      'The app has no visibility into per-frame build and raster timings (no SchedulerBinding.addTimingsCallback wiring, no DevTools performance profiling in the workflow), so jank is only noticed by feel. Symptom: dropped/janky frames ship unnoticed because nothing measures the 16ms (60Hz) / 8ms (120Hz) budget or separates build-thread from raster-thread cost. Record FrameTiming via addTimingsCallback (or a perf kit), track the worst-window p95 of build and raster durations separately, and profile with the DevTools performance view so regressions are caught against an explicit frame budget.',
      Category.operational,
      'Flutter docs — SchedulerBinding.addTimingsCallback and FrameTiming',
      'Flutter DevTools — the performance view (build vs raster thread)',
    ),
    rule(
      "flutter-cold-start-not-budgeted",
      'Budget cold start — keep first-frame work and heavy main() init small',
      'App startup does heavy work before or during the first frame — synchronous plugin init, large JSON/config parsing in main(), eager construction of services, a slow await chain before runApp — with no budget or measurement on time-to-first-frame. Symptom: the app shows a blank/native splash for a long time on cold start, worst on low-end devices and after an update clears caches. Keep main() lean (defer non-critical init until after the first frame with addPostFrameCallback or a warmup phase), do heavy setup lazily/off-isolate, and measure time-to-first-frame against a budget so cold-start regressions are caught.',
      Category.operational,
      'Flutter docs — measuring app startup / time-to-first-frame',
      'Flutter docs — defer non-critical init off the startup path',
    ),
    rule(
      "flutter-screen-load-not-budgeted",
      'Set a per-screen time-to-interactive budget and track nav dead time',
      'Individual screens have no load/interactivity budget — a screen that fetches, decodes, and builds heavy content on entry is not measured against a target, so slow screens ship unnoticed. Symptom: some routes take a long, variable time to become interactive after navigation (nav dead time) but nothing flags them because only crashes are tracked. Instrument each route\'s time from push to first-interactive (a nav observer + a frame callback), set a per-screen budget, and alert when a screen\'s p95 blows it, so slow screens are caught the way slow endpoints are.',
      Category.operational,
      'Flutter docs — NavigatorObserver for per-route instrumentation',
      'Flutter docs — measuring time-to-interactive per screen',
    ),
    rule(
      "flutter-track-nested-routes-separately",
      'Attribute performance per route/screen, not one app-wide bucket',
      'Performance is tracked only at the app level (a single global timer or overall frame stats) with no per-route attribution, so a slow nested screen is averaged into the whole app\'s numbers. Symptom: the aggregate looks fine while one specific route janks or loads slowly, and there is no way to tell which screen is responsible. Use a NavigatorObserver / GoRouter observer to open a span per route (tagged with the route name) and record build/raster/load metrics per screen, so nested and modal routes are measured separately instead of merged into one bucket.',
      Category.operational,
      'Flutter docs — NavigatorObserver / RouteObserver and route names',
      'OpenTelemetry — span-per-operation attribution',
    ),
    rule(
      "flutter-put-tracker-on-every-route",
      'Attach the perf tracker to each route, not just a shared shell widget',
      'Perf instrumentation is mounted only on a shared shell (a root MaterialApp wrapper or a single global observer) and not on each concrete route/screen, so per-screen timings collapse into the shell\'s bucket. Symptom: distinct screens can\'t be told apart in the data because only the shell is instrumented; nested route work is attributed to the container, not the screen the user sees. Attach tracking to each route via the NavigatorObserver\'s didPush (keyed by the route\'s settings.name) or a per-screen mixin, so every screen gets its own name and timings rather than inheriting the shell\'s.',
      Category.operational,
      'Flutter docs — per-screen instrumentation via NavigatorObserver.didPush',
      'Boosthis — attach tracking to each route, not just the shell',
    ),
    rule(
      "flutter-no-regression-gate-in-ci",
      'Gate releases on integration-test frame/timeline benchmarks',
      'There is no automated performance check before release — no integration_test with traceAction/reportTimeline, no frame-timing benchmark in CI — so a change that regresses scroll jank or startup ships and is only caught by users. Symptom: performance silently degrades release over release because nothing measures it in CI; a regression is a field report, not a failed build. Add integration tests that drive key flows and record the timeline (binding.traceAction + reportTimeline / the flutter driver \'frame_build_times\' summary), assert against a budget, and fail the build when frame times or startup regress past threshold.',
      Category.operational,
      'Flutter docs — integration_test, traceAction and reportTimeline',
      'Flutter docs — frame_build_times timeline summary in CI',
    ),
    rule(
      "flutter-crash-reporter-suppresses-host",
      'Chain FlutterError.onError / PlatformDispatcher.onError — never suppress the host\'s handler',
      'Error instrumentation overwrites FlutterError.onError or PlatformDispatcher.onError with its own handler and does not call the previously-installed one, or it swallows the error so the framework/host never sees it. Symptom: the app\'s own crash reporter (or Flutter\'s red-screen / console dump) stops receiving errors once the kit is installed, so real crashes silently disappear from the tool the team actually watches. A monitor must CHAIN: capture the prior handler, do its own reporting, then always delegate to the prior handler (and return the framework\'s default handling), never replace-and-suppress.',
      Category.operational,
      'Flutter docs — FlutterError.onError and chaining error handlers',
      'Flutter docs — PlatformDispatcher.onError for platform-dispatched errors',
    ),
    rule(
      "flutter-unhandled-async-errors-lost",
      'Capture unhandled async errors via PlatformDispatcher.onError and a guarded zone',
      'Errors thrown in async gaps (a Future with no catch, a stream error with no onError, work in a Timer) have no top-level capture — PlatformDispatcher.onError is unset and the app is not run inside a guarded zone — so they are printed and dropped. Symptom: crashes and failures that originate off the synchronous call stack never reach the crash reporter, so the dashboard undercounts real failures and users hit silent breakage. Set PlatformDispatcher.onError to report-and-return-true for platform-dispatched async errors, and/or run the app inside runZonedGuarded so uncaught zone errors are captured and forwarded to the reporter.',
      Category.operational,
      'Flutter docs — runZonedGuarded and PlatformDispatcher.onError for async errors',
      'Flutter docs — capturing errors outside the framework\'s synchronous stack',
    ),
    rule(
      "flutter-secrets-in-dart-define-or-asset",
      'Treat any key compiled into the app (--dart-define, asset, const) as public',
      'A secret — an API key, a signing secret, a privileged token — is baked into the app via a const String, a bundled asset, or a --dart-define value, on the assumption that a compiled Flutter binary hides it. Symptom: the value is trivially extractable from the APK/IPA/web bundle (strings, decompilation, or the readable web JS), so a \'secret\' shipped in the client is effectively public and can be abused against your backend. Only ship PUBLIC-by-design tokens (a scoped, rate-limited ingest key) in the client; keep real secrets server-side, proxy privileged calls through your backend, and scope/rotate any client token as if it were already leaked.',
      Category.operational,
      'OWASP MASVS — secrets must not be stored client-side',
      'Flutter docs — --dart-define values are compiled into the binary, not hidden',
    ),
    rule(
      "flutter-pii-in-telemetry",
      'Scrub PII from logs, breadcrumbs, and telemetry before it leaves the device',
      'Diagnostic data sent off-device — crash breadcrumbs, analytics events, span/metric attributes, log lines — includes user PII or secrets: emails, tokens, full request bodies, precise location, or a route argument object logged verbatim. Symptom: personal or sensitive data leaks into third-party telemetry and log stores, a privacy and compliance exposure, and payloads bloat with data nobody needs for debugging. Redact/allowlist attributes before export (hash or drop identifiers, strip auth headers and bodies, coarsen location), and keep raw user content out of breadcrumbs and metric dimensions entirely.',
      Category.operational,
      'OWASP — sensitive data exposure in logs and telemetry',
      'Boosthis — redact/allowlist attributes before export',
    ),
    rule(
      "flutter-verbose-logging-in-release",
      'Silence debug print/logging in release builds',
      'The app uses print()/debugPrint or a verbose logger unconditionally, so release builds still emit per-event log lines (and print is synchronous and can be throttled/blocked by the platform log pipe). Symptom: release logging adds overhead on hot paths, can stall on the platform log buffer, and leaks internal detail (and possibly PII) to anyone reading device logs. Gate logging behind kReleaseMode/kDebugMode (or a log level), route through a logger that no-ops in release, and never print user data; keep the release console quiet.',
      Category.operational,
      'Flutter docs — kReleaseMode/kDebugMode and debugPrint',
      'Dart docs — print() is synchronous and can block on the platform log pipe',
    ),
    rule(
      "flutter-no-graceful-drain-on-background",
      'Flush in-flight work when the app is backgrounded/detached — it may be killed next',
      'Pending work that must survive — a queued upload, an unsaved draft, buffered analytics/telemetry — is only flushed on a timer or on the next launch, with nothing done on AppLifecycleState.paused/detached, even though the OS can kill a backgrounded app at any time. Symptom: data queued just before the user swipes the app away is silently lost when the OS reclaims the process, and the loss is invisible until the data is missing. On AppLifecycleState.paused/detached, flush queued uploads/telemetry and persist unsaved state promptly (bounded by the OS\'s short background window), so a backgrounded-then-killed app doesn\'t drop in-flight work.',
      Category.operational,
      'Flutter docs — AppLifecycleState.paused/detached and the short background window',
      'Flutter docs — persist and flush before the OS may reclaim the process',
    ),
    rule(
      "flutter-capture-jank-artifacts",
      'Capture a timeline/trace artifact when a frame or isolate stalls',
      'When the UI freezes (a long frame, a blocked isolate, an ANR-class stall) there is no artifact left behind — no captured FrameTiming spike, no dev timeline slice, no record of what ran during the stall. Symptom: a hang is reported by feel or an OS ANR with no evidence, so the root cause (a sync decode, a blocked await, a shader compile) is invisible and the incident recurs. Wire a hang-capture path: record FrameTiming outliers via addTimingsCallback, wrap suspect sections in Timeline.startSync/finishSync so they appear in a captured trace, and persist a diagnostic artifact on a detected stall so every hang leaves something to diagnose.',
      Category.operational,
      'Flutter docs — Timeline.startSync/finishSync for trace slices',
      'Flutter docs — FrameTiming outliers via addTimingsCallback',
    ),
    rule(
      "flutter-monitor-memory-leaks",
      'Watch for leaked disposables and rising memory over a session',
      'Nothing tracks whether disposables (controllers, subscriptions, timers) actually get torn down or whether memory grows across a session, so a leak (an undisposed controller, a retained closure, an unbounded imageCache) is only noticed when the app is OOM-killed. Symptom: memory climbs the longer the app runs and eventually the OS kills it, with no earlier signal. Use the leak-tracking tooling (dart:developer / the DevTools memory view, package:leak_tracker\'s dispose diagnostics) to detect not-disposed objects, and observe RSS/imageCache size over a session so a leak is caught as a trend, not as a crash.',
      Category.operational,
      'Flutter docs — DevTools memory view and dispose diagnostics',
      'package:leak_tracker — detecting not-disposed objects',
    ),
    rule(
      "flutter-boosthis-not-mounted-in-mcp",
      'Wire Boosthis into your AI editor\'s MCP config so the agent can read live perf state',
      'The project uses Boosthis for Flutter perf tracking but the developer\'s AI editor has no Boosthis MCP server configured, so the assistant can\'t see live per-route timings, the rule book, or session summaries and instead guesses at performance. Symptom: AI-suggested changes ignore what is actually slow in this app — which routes jank, which frames blow the raster budget. Add the local Boosthis stdio MCP server to the editor\'s MCP config so the agent reads real state (per-route build/raster timings and the Flutter rule book) before advising, keeping everything local and private.',
      Category.operational,
      'Model Context Protocol docs — configuring MCP servers',
      'Boosthis README — MCP setup',
    ),
    rule(
      "flutter-vendored-copy-drifts-from-source",
      'Regenerate build_runner/vendored artefacts in CI and fail on diff — never hand-edit the copy',
      'The repo embeds a GENERATED or COPIED artefact that duplicates a source of truth — code produced by build_runner (*.g.dart / *.freezed.dart from json_serializable, freezed, retrofit), a committed pubspec.lock, generated localizations, or a vendored package copied under a local path — and code edits the SOURCE while the embedded copy keeps serving old bytes. Symptom: nothing throws and the app compiles because the stale generated file still satisfies callers; the app silently uses an old fromJson mapping or an old model shape that no longer matches the annotated source. Two valid Dart files coexist, so the drift never errors — it just serves the past until someone re-runs build_runner by hand.',
      Category.caseStudy,
      'Boosthis production incident (Aug 2026) — an edited json_serializable model served old bytes because its .g.dart was not regenerated and diffed in CI',
      'Dart build_runner docs — generated .g.dart/.freezed.dart belong to the generator; run build_runner then fail CI on a git diff, never hand-edit',
    ),
    rule(
      "flutter-restart-old-process-holds-port",
      'A hot-restart/dev tool must serve the NEW code — fail loud when an old process holds the port',
      "A dev restart leaves an OLD process alive: an orphaned `flutter run`/DevTools daemon, a detached `dart run build_runner watch`, or a mock/dev HTTP server the app talks to that is respawned without killing the previous one so it keeps its old bind. Symptom: either the new dev server errors with the port in use, OR the tool silently picks another port while the OLD server keeps answering on the URL the app is configured for — so the app hits a stale backend/build and your latest change never appears, with no error to explain it. A dev-server helper that auto-increments the port on conflict instead of failing is this trap.",
      Category.caseStudy,
      'Boosthis production incident (Aug 2026) — an orphaned local mock server kept serving old responses on the expected port while the restarted one moved to a random port',
      "Dart HttpServer docs — bind failures should be fatal; kill the previous dev/mock process by pid rather than letting a new one silently shift ports",
    ),
    rule(
      "flutter-observer-never-attached",
      'Assert the NavigatorObserver/timing hook is registered and prove one real event moves the metric',
      "A NavigatorObserver, a SchedulerBinding.addTimingsCallback frame-timing hook, a RouteObserver, or a custom perf tracker is written and compiles, but nothing registers it — the observer is never passed to MaterialApp's navigatorObservers, the timings callback is never added, or the tracker is constructed but never wired to a route. Symptom: the metric it feeds reads zero forever and its dashboard tile is empty or perpetually warming, yet widget unit tests pass because the observer's callback works when invoked directly. The bug is the missing registration, which only a real navigation/frame driven through the mounted app can catch.",
      Category.caseStudy,
      'Boosthis production incident (Aug 2026) — a NavigatorObserver compiled and unit-tested green but was never added to navigatorObservers, so its route metric read zero indefinitely',
      "Flutter docs — a NavigatorObserver only fires when passed to navigatorObservers and addTimingsCallback only reports once registered on SchedulerBinding",
    ),
    rule(
      "flutter-fixed-ms-timing-assert",
      'Pump until the condition holds, never a fixed Duration plus a millisecond assert',
      "A test, gate, or readiness check hinges on a FIXED number of milliseconds: it does tester.pump(Duration(milliseconds: N)) once and asserts the frame is done instead of pumpAndSettle, sleeps a Future.delayed(Duration(...)) then asserts, or reads a Stopwatch delta and asserts it finished in under N ms. Symptom BOTH ways: on a shared or busy machine (a CI runner, a throttled container, a laptop mid-build) wall-clock time measures the MACHINE, not the code, so the check fails when nothing is wrong; and on an idle machine the same assert stays green even after the code got slower, so a real regression ships silently. A single fixed pump also races widgets that settle in more frames than you guessed.",
      Category.caseStudy,
      'Boosthis production incident (Aug 2026) — a gate asserted a finish-time by reading a Stopwatch the instant it ran instead of pumping to the condition with a bounded deadline, so it failed on a loaded runner while the widget code was correct',
      'Flutter docs — pumpAndSettle and FakeAsync/clock advance virtual time so tests assert the settled CONDITION; keep jank budgets as FrameTiming percentiles from real runs, and use integration_test timeouts only as a generous bound on hanging',
    ),
    rule(
      "flutter-credentialed-refusal-signin-challenge",
      "Do not turn a credentialed refusal into a sign in restart",
      "In Flutter response handling through Dio or package http interceptors and secure storage, a response with status 401 and an authenticate challenge clears a stored credential and starts sign in even though the request carried an authorization header. The app turns one refused call into a forced login and reports a healthy reachable service as unavailable.",
      Category.operational,
      "Dio and package http interceptor documentation",
      "HTTP authentication status and challenge semantics",
    ),
    rule(
      "flutter-generic-refusal-message",
      "Give every refusal a distinct actionable code and message",
      "In Flutter, distinct failures such as offline transport expired session permission refusal and server fault all become the same generic message. Users and support cannot tell which action can recover the request.",
      Category.operational,
      "Flutter error presentation and networking documentation",
      "HTTP problem detail and stable error code guidance",
    ),
    rule(
      "flutter-strict-credential-scheme-parsing",
      "Normalize credential schemes and token whitespace before parsing",
      "In Flutter, authorization headers are built by concatenating a scheme with a pasted or stored token without trimming surrounding whitespace quotes or line breaks. A valid credential becomes a near miss before Dio or package http sends it.",
      Category.operational,
      "Dart String and HTTP header documentation",
      "HTTP authentication scheme parsing guidance",
    ),
    rule(
      "flutter-silent-protection-fail-open",
      "Surface every degraded protection even when it fails open",
      "In Flutter, a local protection such as certificate validation credential refresh input validation or request gating catches an unavailable dependency or bad configuration and continues without recording that protection is degraded. The app silently sends work through an unprotected path.",
      Category.operational,
      "Flutter networking and security documentation",
      "Mobile degraded mode observability guidance",
    ),
    rule(
      "flutter-checked-address-not-the-one-connected",
      "Validate one address but let HttpClient resolve again",
      "Code checks a caller supplied URI with InternetAddress.lookup and then gives its hostname to dart io HttpClient Dio or package http or allows automatic redirects. The client resolves again for the socket, so rebinding or a redirect can reach private loopback or metadata space that the earlier check rejected.",
      Category.industry,
      "HttpClient connectionFactory controls the socket used by the request",
      "Socket startConnect pins an InternetAddress and redirect handling exposes every hop",
    ),
    rule(
      "flutter-logging-taken-over-instead-of-chained",
      "Replace the host Flutter error or logging hook",
      "A package or bootstrap replaces FlutterError.onError PlatformDispatcher.instance.onError debugPrint or a runZonedGuarded error path without retaining and invoking the previous callback. The host formatter destination redaction crash reporter or zone policy silently stops receiving errors.",
      Category.operational,
      "FlutterError onError is a replaceable global callback",
      "PlatformDispatcher onError and runZonedGuarded handle isolate errors",
    ),
    rule(
      "flutter-async-lock-reentered-by-holder",
      "Reenter a nonreentrant async lock while holding it",
      "Code runs inside package synchronized Lock.synchronized or package mutex Mutex.protect and invokes a callback listener getter or helper that enters the same lock again. The default lock is not reentrant, so the inner Future waits behind the outer Future while the outer Future waits for the callback.",
      Category.industry,
      "package synchronized Lock is nonreentrant by default",
      "package mutex protect holds ownership until its Future completes",
    ),
    rule(
      "flutter-retry-leaves-future-running",
      "Retry while the abandoned request Future is running",
      "A Future.timeout Future.any Timer or retry helper gives up and starts another Dio package http or dart io request without cancelling the losing operation. Dart Future has no implicit cancellation, so the old socket upload stream or connection remains active and its result is discarded.",
      Category.operational,
      "Future timeout does not cancel its source Future",
      "Dio CancelToken and HttpClientRequest abort explicitly terminate requests",
    ),
    rule(
      "flutter-dependency-call-no-timeout",
      "Put a deadline on every outside service call",
      "A screen or repository calls an outside service, such as a hosted identity provider, object storage, or a payments or analytics SDK, through package http, Dio or dart io HttpClient with no timeout on the Future, no connectTimeout or receiveTimeout, and no deadline of its own. On a poor mobile network the provider stalls rather than fails, so a FutureBuilder sits on its loading branch with nothing to show and no error to render. Sign in is the worst place for it, because the whole app waits behind it before anything paints, and a Dart Future has no deadline unless one is given to it.",
      Category.industry,
      "Dart Future timeout documentation — a Future has no deadline of its own",
      "Dio documentation — connectTimeout and receiveTimeout are separate options",
    ),
    rule(
      "flutter-dependency-retry-uncapped",
      "Cap the retries against an outside service",
      "A Dio retry interceptor, a retry package call, or a hand written loop re-attempts a failed outside service call with no attempt ceiling, no total budget, no jitter and no Retry After handling. It is often re-fired from a connectivity listener or an app lifecycle resumed callback, so it restarts on every foreground. The provider's bad minute is then paid for in the user's battery and cellular data, because every device re-attempts on the same triggers, and a permanently refused payload is retried for as long as the app is installed.",
      Category.industry,
      "RFC 9110 — Retry-After",
      "AWS Architecture Blog — exponential backoff and jitter",
    ),
    rule(
      "flutter-dependency-calls-serial",
      "Start independent outside service calls together",
      "A widget or repository awaits several outside service Futures one after another where no call consumes the previous one's result, such as the session, then the avatar from object storage, then the customer record. The usual shape is a run of awaits in initState, a loader, or the future given to a FutureBuilder. The screen then waits for the sum of every provider's latency instead of the slowest, so a screen that should appear in three hundred milliseconds appears in nine hundred, and on a mobile network where each round trip is already expensive that difference is exactly what a user calls slow.",
      Category.industry,
      "Dart Future wait documentation — the futures must already be started to run concurrently",
      "Google SRE Book — Latency (serial dependencies add, parallel dependencies max)",
    ),
    rule(
      "flutter-dependency-on-visitor-path",
      "Take an outside service off the path the user is waiting on",
      "A screen awaits an outside service call whose answer the user never sees before it navigates or completes an action, such as an analytics event, a CRM sync, a welcome message, or a derived thumbnail upload. The user pays the latency and inherits the failure of work they will never see, so a slow analytics vendor makes the app feel slow and a broken one makes a working action look failed. Dropping the await is not the fix on its own: an unawaited Future whose error is never handled becomes an unhandled asynchronous error, and the work is abandoned when the app is backgrounded.",
      Category.industry,
      "Dart documentation — an unawaited Future error surfaces as an unhandled asynchronous error",
      "Google SRE Book — Addressing Cascading Failures (shed non-critical work from the serving path)",
    ),
    rule(
      "flutter-job-without-time-limit",
      "Give every background task a deadline of its own",
      "A Workmanager callback, a background fetch handler or a headless task runs work with no deadline of its own and returns only when the work happens to finish. The platform then kills the task before it reports anything, so no success or failure is recorded, the operating system learns the app does not finish its background work, and it is scheduled less generously afterwards. On the user's side the only visible effect is a battery cost with nothing to show for it, and nothing inside the app can see why the background work stopped arriving.",
      Category.industry,
      "Workmanager documentation — the callback must return a result before the platform execution window closes",
      "Dart Future timeout documentation — racing the work against a deadline is what makes a result reachable",
    ),
    rule(
      "flutter-job-retries-forever",
      "Cap background retries and give the last failure a destination",
      "A background task asks the platform to retry on every failure, with no attempt count persisted across launches and no distinction between a rejection that will never succeed and a transient error that might. A permanently rejected payload is then retried by the operating system with backoff for the life of the install, on the user's battery and cellular data, and because the failure is never recorded anywhere it is invisible to the user and to the backend that could fix it. An attempt counter held in memory is gone before the next attempt, because each background run is a fresh isolate.",
      Category.industry,
      "Workmanager documentation — returning failure schedules a retry with backoff",
      "AWS Architecture guidance — a poison message needs a destination other than the queue it fails in",
    ),
    rule(
      "flutter-ai-call-no-timeout",
      "Put a deadline on every AI provider call",
      "Flutter has no first-party OpenAI or Anthropic Dart SDK, so an app commonly sends a generation request through package http, Dio or dart io HttpClient. The call has no client timeout, Future timeout or cancellation path, and a model that is slow to generate or a streamed response that stops producing bytes leaves the Future and its loading screen open indefinitely on a mobile connection. Distinct from flutter-dependency-call-no-timeout in naming the unusually long generation and streaming phases of an AI call, not only its connection and first response.",
      Category.industry,
      "Dart Future timeout documentation — a Future has no deadline of its own",
      "OpenAI API reference — Responses and streaming responses",
    ),
    rule(
      "flutter-ai-retry-ignores-retry-after",
      "Honor the AI provider's Retry-After before retrying",
      "Code using package http, Dio or dart io HttpClient catches an AI provider 429 or overloaded response and retries after a fixed or locally calculated delay without parsing the Retry-After response header. A Dio interceptor may also stack its loop on top of another retry layer. Retrying before the provider's published time spends a costly generation attempt on a refusal and keeps a fleet of phones rate limited together. Distinct from flutter-dependency-retry-uncapped in checking the AI provider's explicit delay even when the local retry count is already bounded.",
      Category.industry,
      "RFC 9110 — Retry-After",
      "OpenAI API documentation — rate limits",
    ),
    rule(
      "flutter-ai-calls-serial",
      "Run independent AI calls concurrently with Future.wait",
      "A repository or screen awaits independent AI completions, embeddings, classifications or moderation requests one after another through package http or Dio even though no later prompt consumes an earlier result. Since generation calls can each take seconds, those awaits make the user wait for the sum rather than the slowest call; create the Futures before awaiting and join the fixed-size group with Future.wait. Distinct from flutter-dependency-calls-serial in identifying several expensive model operations, whose fan-out also needs an explicit concurrency bound when its size comes from user input.",
      Category.industry,
      "Dart Future wait documentation — the futures must already be started to run concurrently",
      "OpenAI API reference — Responses, embeddings and moderations",
    ),
    rule(
      "flutter-ai-duplicate-prompt",
      "Send each logical AI prompt only once per request",
      "One user action sends the same normalized prompt, model and parameters to the same AI endpoint more than once, commonly because a Future is created again in build, two repository helpers perform the same lookup, or a retry runs after one response already succeeded. Flutter has no first-party OpenAI or Anthropic Dart SDK to deduplicate raw package http or Dio requests, so both calls consume input and output tokens and one answer is usually discarded. The finding is duplicate provider requests within one logical action, not two prompts that merely contain similar user text.",
      Category.industry,
      "OpenAI API reference — usage input_tokens and output_tokens",
      "Anthropic Messages API reference — usage fields",
    ),
    rule(
      "flutter-ai-prompt-cache-cold",
      "Keep large shared prompt prefixes stable so provider caching hits",
      "An app repeatedly sends large system instructions, tool schemas or shared documents in JSON through package http or Dio, but dynamic timestamps, request IDs, Map insertion order or user-specific text appear before that reusable prefix and cached-input usage stays zero. At the wire level OpenAI prompt caching depends on an exact prefix match, while Anthropic supports cache_control on reusable content blocks. Keep stable material first with deterministic serialization and move changing content last; this is provider prompt caching, not Flutter's image or local data caches.",
      Category.industry,
      "OpenAI API documentation — prompt caching",
      "Anthropic documentation — prompt caching",
    ),
    rule(
      "flutter-ai-stream-usage-not-requested",
      "Request usage metadata on every streamed AI response",
      "An OpenAI-family streaming request made as JSON through package http Client.send, Dio with ResponseType.stream, or dart io HttpClient sets stream true but omits stream_options with include_usage true. The app can parse Server-Sent Events and render text deltas yet receives no terminal usage block, so it cannot attribute input, output, cached tokens or cost to the user action. The stream reader must also continue through the final usage event rather than closing as soon as a finish reason appears.",
      Category.industry,
      "OpenAI API reference — stream_options.include_usage",
      "Dart package http documentation — StreamedResponse",
    ),
  ];
}
