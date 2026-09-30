# Boosthis for Flutter

**Version:** `0.1.66`

## One codebase can hold more than one project

Set `BOOSTHIS_PROJECT_KEY_FLUTTER` with `--dart-define` (or in the process
environment for command-line tools). The dart define is read first. This
per-language value wins over a key passed in code, followed by the existing
shared `BOOSTHIS_PROJECT_KEY` and legacy `BOOSTHIS_INVITE_KEY` values. Check
`Kit.status()` to confirm the masked key and its source before shipping.

Honest performance, crash and device meters for Flutter apps — readable by you,
and by your AI assistant.

The kit measures the frames your app actually renders, notices the errors it
actually throws, and reports what it can genuinely observe on the device. When
it cannot measure something, it says so and shows nothing rather than inventing
a number.

- **Your app can never break because of it.** Every entry point is wrapped so a
  failure inside the kit is swallowed inside the kit. The crash reporter is
  monitor-only: it chains to your existing `FlutterError.onError` /
  `PlatformDispatcher.onError` and always delegates — it never suppresses your
  errors.
- **Your app never blocks on it.** Nothing the kit does blocks the UI isolate on
  IO, and outbound work rides the kit's own uploader tick.
- **Your users' data never leaves the device un-checked.** No log message text,
  no request/response bodies, no query strings, no route arguments. Everything
  is checked against the PII guard on the way out.

## Two packages (this matters)

The kit ships as **two packages**:

- `boosthis` — **pure Dart, zero dependencies.** All meter math, state, wire
  format and the MCP server live here. It imports only `dart:` libraries and can
  be analysed and run with the Dart SDK alone.
- `boosthis_flutter` — a **thin Flutter adapter**, the only package that imports
  `package:flutter`. It translates Flutter engine callbacks (frame timings,
  error handlers, lifecycle, image cache) into plain-Dart calls on `boosthis`.
  It contains no meter math.

You add **both** packages and call the adapter. See `INSTALL.md`.

## The frame pipeline — the strongest signal a device runtime gives us

`SchedulerBinding.instance.addTimingsCallback` delivers a `FrameTiming` for
every frame with build, raster, vsync overhead and total span separated. That
powers smoothness, frozen frames, the frame floor, scroll smoothness, app-hang,
and **jank attribution split into build vs raster** — a distinction no other
Boosthis runtime can make.

## What gets measured

Every meter is either **genuinely measured or absent**. Each self-gates on its
own evidence floor (enough samples, enough observed wall time); until that floor
is met a meter is simply missing, and the dashboard renders it as **warming up**,
never as a fabricated `0` or `100`.

**Drop-in (no host cooperation, works in a release build):** smoothness, stability,
frozen frames, frame floor, app-hang, scroll, responsiveness, resilience,
`rasterJank` (build-vs-raster attribution), unhandled errors, swallowed errors,
leak watch, image weight (exact, from `PaintingBinding.instance.imageCache`),
foreground residency, background recovery, dimension churn, appearance churn,
memory stability (RSS trend/peak), scheduler latency (event-loop lag), storage
latency, cold start (first-frame future), device tier, dev posture, and the
crash-free / stability structural axes.

**Opt-in (report `{present, measurable:0}` with a reason until you wire them):**

- `navDeadTime` / `pressToScreen` / screens / per-screen timings — add
  `BoosthisNavigatorObserver`
  to your app. This is also the kit's per-request equivalent: without it the
  meters still report, but no screen timings are filed.
- `network` — install `BoosthisHttpOverrides` (chained) or the kit's client.
- `platformChannels` — only counted for channels created through the kit's
  wrapper.
- `reRenders` — wrap a subtree in `BoosthisProfiler` (the release-build stand-in
  for the debug-only build profiler), plus `timerLeaks` through the kit's Zone
  (`BoosthisFlutter.run`).

**Cannot know — recorded as such, never a warming tile:** GC and heap axes (the
Dart VM Service is compiled out of release builds; RSS trend is the honest
substitute), isolate-level scheduling beyond the main isolate, and the
server-only meters (access pressure, cookie exposure, load deflection, latency
floor over routes, idle CPU share) that do not apply to a device kit.

## Privacy

**Sent:** frame/latency statistics, counts, durations, error class names, a
hashed crash signature, templated route/screen names, and the meter values above.

**Never sent:** log message text, request/response bodies, query strings, route
arguments, headers, cookies, source code, or anything typed by one of your users.

## The kill switch and entitlement

The runtime honours `BOOSTHIS_DISABLED` and the server entitlement gate,
identically to every sibling kit.

The floating bubble is on by default in every environment, including
production. `BOOSTHIS_BUBBLE` set to 0 hides it and the kit carries on
measuring; `BOOSTHIS_DISABLED` stops the kit altogether. Each name is read
from the environment where this runtime has one, and otherwise from a value
of the same name on the host.

## The MCP server

The pure package ships `boosthis-mcp`, a local stdio MCP server (JSON-RPC 2.0,
newline-delimited) that any MCP client can talk to over stdin/stdout. It exposes
the offline Flutter rule book plus the perf samples recorded in this process.
Run it with the Dart SDK:

```bash
dart run boosthis:boosthis_mcp
```

## Honest ceiling

About **36 meters drop-in, +4 opt-in ≈ 40** — above the PHP and Ruby kits, just
below Node/Go/Java, and slightly ahead of React Native because the engine hands
us raster-thread truth and an exact image cache where RN can only estimate.

## Changelog

### 0.1.66

An axis band with equal, reversed or non-finite good and poor constants is
now refused with InvertedAxisBandError rather than scored. This exposes a typo
in the kit's own scoring thresholds instead of reporting a misleading
perfect verdict.

### 0.1.65

The navigation reading now spans the whole wait: from the press until the
destination screen's own measurement completes, rather than stopping when that
screen began to mount. The dead time before anything appeared stays beside it
as its own number, and the time the screen then took to settle sits next to
it. A press that could not be joined to a screen is counted and reported — one
count for a screen that arrived past the join bound, one for a press no screen
followed — where before a slow navigation was discarded and only the quicker
ones were reported. The bound is 15 seconds, and it is stated with the
reading. An app without the navigator observer joins nothing and says so,
rather than sitting on a warming tile. Nothing here feeds the overall score.

### 0.1.64

The README and the install guide now say plainly what this kit adds to the app
it is installed in, before you ship it rather than after. The floating bubble
is described as on by default in every build, including release builds, with
the setting that hides it named in the same breath, and no guide calls it a
mandatory setup step any more. A phone app serves nothing, so this kit mounts
no address a stranger could request, and the guide now says so instead of
leaving you to work it out. The same statement for every Boosthis runtime is
published in one place. Nothing about what the kit measures, sends or displays
changed.

### 0.1.63

One rule now decides what a part of the app is called — a route here, a
screen on the device kits — and every Boosthis kit takes it from the same
source instead of carrying its own copy of the idea. The limit is 100
characters, the same bound the server enforces, so this kit never sends a
name the wire would quietly reshape. A longer name is REFUSED rather than
shortened: two routes whose names differ only past that point used to be
stored as one row with a pooled timing, under a name neither developer
wrote. A name the rule refuses is counted, and where you wrote it by hand
the kit says so once through the warning channel it already uses, with the
reason and an acceptable form — never echoing the rejected text back. This
kit no longer replaces a label containing a space or a privacy hit with the
literal `[redacted]`, and no longer truncates at 200. That placeholder was a
real-looking screen whose history was a pool of unrelated ones; a screen
that cannot be named is now refused and counted instead.

### 0.1.62

Seven new readings about the request path, errors and timers: what the services
this app calls served from their own cache, app-wide totals for failing screens
and the calls beneath them, and Dart timers created and never cancelled, with
the platform's own timer systems counted separately as the part this kit does
not watch, so a partial view never reads as a complete one. Rates are counted
per foreground hour, because an app in a pocket is not an app that failed to do
anything. Background work, held-open connections, process uptime and idle time
each say in a sentence why Flutter cannot expose them, instead of reporting a
zero.

### 0.1.61

Frozen frames and app hangs now wait for a foreground window long enough to
express their per-hour rate instead of publishing one immediately. Reporting
early meant dividing by a one-minute floor, so a single frozen frame was
published as "60 an hour" beside a window the same reading reported as zero
minutes — a confident poor verdict over nothing. Nothing is lost: the counts
keep accruing and both readings appear as soon as the window is real.

### 0.1.60

Four readings are no longer graded: how long the app was in the foreground, how often the screen rotated, how often the theme changed, and how many memory warnings the operating system sent. Those score what the person and the device did, not the app — a phone left in a pocket read as a red 0 out of 100 and no change to your app could move it. The numbers still ship; only the score and its bands are gone. Return-from-background recovery is still graded: that one is your app's own resume work. Warm-up now waits on foreground time rather than wall time, so a reading can no longer open on time the app spent in the background.

### 0.1.59

Added CPU consumption and thread-footprint readings from Android procfs, with
explicit not-measurable reasons on iOS, plus blocked-async counts from the
periodic scheduler timer the kit already runs.

### 0.1.58

The in-app panel now includes the new memory and collection readings in its
warming set, so it shows the same meter set as the web dashboard for this
Flutter app while those rows fill.

### 0.1.57

Peak and resident-memory trends and memory warnings now use the shared names,
units and bands used by the other kits. Memory trends now carry the standard
error used to judge them and abstain while movement sits inside it. When this
Flutter engine cannot sample process memory, the reading now declares the
reason instead of showing a zero or leaving the dashboard blank.

### 0.1.56

The kit now reports system load from the kernel's one-minute runnable-task
average, scoped to this device. Its existing storage speed and storage
failures readings now also state that their probe describes this device. When
the app has a store but the probe cannot be completed, the dashboard shows the
reason rather than a zero; an app with no store still sends no storage
reading.

### 0.1.55

- The whole screen list now reaches the app map, so a screen nobody has opened
  is drawn and marked "not seen" instead of being invisible. Pass your route
  table to the observer — `BoosthisNavigatorObserver(routes: routes)` — or hand
  over a `GoRouter` with `Boosthis.registerRouteTable(router)`; screens built at
  run time can be named by hand with `Boosthis.declareScreens([...])` and ride
  the same list marked as declared. An app with no router to read says there
  was nothing to read rather than sending an empty list.

### 0.1.54

- The kit no longer says measuring has started just because Boosthis confirmed
  the install. A confirmation is permission, not a reading, and announcing one
  as the other sent a developer hunting a fault that was not there while our
  own server correctly reported the same install as never having measured
  anything. The line now says what a confirmation actually proves, and what
  produces a reading: one is taken when a page view or screen finishes. Every
  Boosthis kit carrying this line was corrected together.

### 0.1.53

- Storage Failures — a new reading beside Storage Speed, taken at the same
  probe. The kit reported how long its small state-dir write took but never
  whether it worked, so a device whose storage answers instantly and refuses
  every write read as healthy. The new tile is the share of those probes that
  did not complete, kept separate from the timing because a slow store and a
  failing store are different problems. It still touches only the kit’s own
  files. A device with nowhere to write shows both tiles saying so in their
  own words rather than a 0% nobody measured, and neither reading feeds your
  score.

### 0.1.52

- An app that had already healed a damaged install id stopped registering on
  every later launch. The host still hands the kit the id baked into the build,
  the kit found a different id already settled in storage, and it treated that
  as a second installation and refused. It now recognises the id it replaced
  and carries on as the same install, so the readings continue on one line
  instead of stopping at the next restart. Nothing measured changed.

### 0.1.51

- The panel this kit draws inside your app now fits a phone: its width is
  capped against the real screen instead of a flat 240, its height against just
  under three-quarters of the screen, and anything past that scrolls behind a
  thumb that is always drawn. Nothing measured changed.

### 0.1.50

- A clean AI tile no longer hides the calls this kit could not see. The number
  of HTTP clients loaded in your app that Boosthis cannot watch now rides on
  the AI reading, including zero — the kit saying it looked and found nothing
  here that can bypass it. Only the count leaves; which libraries your app uses
  is never sent.

### 0.1.49

- An app that calls a model this kit does not recognise — one you host, a
  private gateway, a regional endpoint — no longer looks like an app with no AI
  in it. A POST whose path is an inference shape is counted, and the AI reading
  appears saying it cannot be measured, carrying that count and nothing else:
  no address, no path, never timed or scored. Name the endpoint in
  `BOOSTHIS_AI_ENDPOINTS` or `BoosthisFlutter.start(aiEndpoints: ...)` to turn
  later calls into a full reading; the address is compared inside the app and
  never leaves it.

### 0.1.48

- Wording only; nothing the kit measures, sends or decides changed. A
  comment in the kit's own source named a number of kits that was two
  releases out of date. It now says “every kit”, which cannot go stale.

### 0.1.47

- Spans now say what kind of work they were and whether the work succeeded: one
  word from a fixed list — handler, db, http, cache, queue, job, render, other
  — and one of `ok` or `error`. The outgoing calls the kit stands inside are
  labelled `http` and carry the status they came back with, taken where the kit
  already measures, so nothing extra is watched or timed.
- A crash raised inside a measured synchronous frame reports the action it
  happened in. Both fields are optional, and a leg you time yourself through
  `trackSpan` carries neither, because the kit is not told what sort of work it
  was: absence reads as not reporting, never as a clean result.

### 0.1.46

- Your app now helps answer what a phone actually allows. As it runs, the kit
  notices whether work left pending survived being backgrounded, whether a
  timer armed before backgrounding really fired, and whether the system asked
  it to give memory back — and reports those three answers alongside the
  Android API level or iOS version they were seen on. Nothing about the device
  or its owner is sent: the answers are pooled per platform, so what we hold is
  a fact about Android 14, not about anybody's handset. A fact this app could
  not measure is sent as nothing at all, never as a no.
- On Apple hardware the kit stays quiet until your app tells it which device it
  is: `Boosthis.recordDeviceIdentity(isPad: …)`, once at startup. Dart reports
  `ios` for an iPad too, and iPadOS is a different platform with different
  background rules — an iPad's answer filed under iOS would be a wrong answer
  rather than a vague one. Android needs no such call; the OS prints its own
  API level, and where it does not, the kit reports nothing rather than
  guessing a version.

### 0.1.45

- A fast screen can no longer be reported as steady. Interactions are timed
  in whole milliseconds, so work that finishes in under half a millisecond
  records as 0ms, and a screen whose earlier window is all zeros leaves the
  baseline axis nothing to divide by. Those screens were counted as examined
  and then dropped in silence, so an app whose sub-millisecond screen
  suddenly took 100ms still scored 100 and read “steady”. A screen that
  cannot be divided by is now reported as too fast to compare, the steady
  count names only the screens actually compared, and an app where every
  screen was too fast says it cannot judge rather than scoring full marks.
  Screens slow enough to compare are judged exactly as before.

### 0.1.44

- Traces from a Flutter app now actually arrive. Every outbound call this kit
  traced was labelled in a shape the server refuses — a bare verb, where a
  route was expected — so the row was thrown away at the door and no Flutter
  trace ever reached your dashboard, with nothing to say why. The label is now
  the canonical form the server reads, and the kit checks a span label on the
  device before sending it, so an unusable one is dropped here rather than
  counted as a delivery that quietly went nowhere.

### 0.1.43

- Crashes are now actually delivered. The Flutter kit recorded every crash it
  saw and then kept it on the device for ever: nothing connected the reporter
  to the network, so the reports piled up locally and no crash ever reached
  your dashboard. Two smaller faults went with it — the kit described a crash
  using words the server rejects, and it threw the stack away before recording
  it, so every crash looked identical and nameless. Crash reports now leave the
  device, carry the top line of the stack, and a crash that killed the app is
  sent on the next launch.

### 0.1.42

- A running install no longer reports itself as never activated. The kit
  sent its regular licence check-in with the read-only credential, and the
  server records nothing from that one — so the time of the check-in and the
  kit version were never written down, and your dashboard (and any AI
  assistant reading it) was told this install had never activated for as long
  as it ran. The check-in now uses the install own write credential, the same
  one every measurement upload has always used.

### 0.1.41

- Cold start now says which interval it measured: from Boosthis starting to
  the first frame your app rendered. Pure Dart cannot see the launch itself,
  so the engine bring-up before that is outside the figure — the reading is
  therefore reported without a rating rather than being scored as if it were
  the whole start-up. The number is unchanged.

### 0.1.40

- The kit now reports which parts of the app it is watching and which it found
  but cannot watch, so the project page can show blind spots.

### 0.1.39

- A crash frame from an obfuscated release build now carries the ELF build id
  and the DSO-relative address the stack prints — what a `--split-debug-info`
  symbol file is keyed on. Until now the frame carried a file and a line, which
  a symbol file cannot be looked up by, so a release crash stayed a column of
  hex for ever. Both halves of the key travel together or neither does: half a
  key would match against the wrong build. The launch-specific absolute address
  is a lookup input only and never leaves the device, and a readable
  (non-obfuscated) stack is unchanged.

### 0.1.38

- A trace that crosses into this runtime now nests the whole way through. Each
  measured leg of an action records which leg called it, and passes its own
  identity on to the next service it calls, so a full-stack action draws as a
  waterfall instead of going flat at this hop. The identifiers are random,
  carry no request data, and nothing new is uploaded.

### 0.1.37

- An app using the navigation observer now files a timing every time a screen
  arrives: the wait from the route being pushed to the first frame the engine
  reports afterwards. That observer used to feed the navigation meters only,
  so a Flutter project could register, go active and report every meter while
  its project page still said no measurements had arrived. Nothing new is
  collected — the route name it already recorded, with the wait beside it. A
  screen popped before it ever drew files nothing; a frame report too prompt
  to be that screen's own (the engine hands over completed frames in batches)
  is skipped rather than filed as an instant screen; and a wait beyond ten
  seconds — a backgrounded app — is dropped rather than filed as a very slow
  one.

### 0.1.36

- Screens and interactions this kit already timed now reach your project page.
  They upload in small batches (100 at most) under the same sharing
  permission, privacy guard and credential as the snapshot it already sent,
  and are dropped rather than queued for ever when the server cannot be
  reached. Nothing new is measured — a project that could only ever say
  "registered, no measurements yet" now fills in its own timings.

### 0.1.35

- Six new AI-provider rules catch package `http`, Dio and `dart:io`
  `HttpClient` calls without `Future.timeout` or cancellation, retries that
  ignore `Retry-After`, serial independent work instead of `Future.wait`,
  duplicate normalized prompts, unstable shared prefixes that defeat prompt
  caching or `cache_control`, and streams missing
  `stream_options.include_usage` or their final usage event. Rule book only:
  nothing new is measured and nothing new is sent.

### 0.1.34

- A deliberately cut project credential now makes the installed kit stop and
  report the server's non-active status immediately. An ordinary unauthorized
  response or an unreachable server still preserves the cached entitlement, so
  recoverable installs are not stranded.

### 0.1.33

- Six new rules about calling an outside service: a call with no deadline,
  retries with no cap, independent calls made one after another instead of
  together, a vendor call left on the visitor's own path, and the two
  background-job versions of the same mistake — a job with no time limit, and
  one that retries forever with nowhere to fail to. Each names the fix, and is
  written against Dart's own mechanisms — `Future.timeout`, a capped retry,
  `Future.wait` and a give-up path. Rule book only: nothing new is measured
  and nothing new is sent.

### 0.1.32

- A leg the kit cannot honestly place on its trace is now left out instead of
  drawn at the start of the action. The kit remembers where each trace began in
  a table of fifty; a screen with more actions in flight than that could lose
  its own trace's start and report the next leg at zero — a bar at the left
  edge that can out-rank the layer the action really began on. Those legs are
  now withheld and counted instead of reported in the wrong place.

### 0.1.31

- A leg of a trace the kit measures now carries a real start offset. The
  offset was left at zero unless the app passed one, so an app measuring two
  legs of one action got both bars drawn on top of each other at the left
  edge. The public argument stays available for a leg an app records by hand.

### 0.1.30

- Your install's access tokens are no longer left where other accounts on the
  same machine can read them. This kit keeps the tokens the server issues in a
  state file so a restart does not orphan the install. Inside a phone app's
  own folder that is already private, but a desktop or command-line Flutter
  app falls back to the system temporary folder, where any other local account
  could read them and then send or erase this project's measurements. The kit
  now checks that folder before trusting it: a link left at its path is
  refused, and a fallback folder other accounts can walk into is not used at
  all — state stays in memory for that run instead. A folder your own app
  hands the kit is used exactly as before. Nothing about what is measured or
  sent has changed.

### 0.1.29

- Carries the shared list of problem kinds that every reporting kit keeps in
  step, now that the back-end kits report caching problems (a reply served with
  no caching instruction, a blanket never-cache, and a cacheable reply with no
  version stamp). This kit measures nothing new and reports none of those
  kinds — it holds the same list its siblings hold so the words never drift.

### 0.1.28

- The kit now reports the problems it keeps seeing: retries hammering the same
  destination without backing off, and a burst of calls fanning out at once.
  Fix outcomes are reported too, so a change that worked can be recommended to
  another project. Nothing new is measured. Only a hashed signature travels
  (kind, severity band, rough count) — never a screen name, address, value or
  code — and nothing is sent before the install is registered and its consent
  answer allows it. The work stays off the interface thread.

### 0.1.27

- Refused upload loss now counts the measurement rows in each batch rather than
  counting each batch as one.

### 0.1.25

- A refused upload batch is now recorded and shown. Non-2xx replies and
  requests that never answer are classified (credentials rejected, batch
  rejected, Boosthis failed to store it, no answer), and the panel names the
  reason and how many uploads have been lost instead of showing a healthy
  reading.

### 0.1.25 — 2026-08-26

- The Boosthis button now appears before the first successful check-in. Until
  now it stayed hidden until Boosthis had confirmed the install, so an app
  that could not reach Boosthis at all — a preview with no outbound network, a
  rejected or rotated project key, a reinstall — showed nothing and looked
  broken. The button now draws straight away and opens on the kit's existing
  “Not registered yet” notice, with the reason when one is known. Everything
  that hid the button before still hides it: the kill switch, the bubble-off
  directive, the in-code option set false, a tampered install and a lapsed
  offline grace window. Nothing is measured or uploaded before the install is
  confirmed — that is unchanged.

### 0.1.24 — 2026-08-26

- Four new checklist rules cover connecting to the address actually validated,
  leaving the host's logging and exception hooks alone, avoiding re-entry of
  non-reentrant locks, and cancelling an abandoned attempt before retrying.

### 0.1.23

- Waiting for a first confirmation is now honest end to end: the kit only says
  it registered once registration really succeeded, it waits for the whole
  confirmation chase before reporting that nothing confirmed the install, and
  stopping the kit now leaves no timer or watch running.

### 0.1.22

- A newly registered app now explains a first-confirmation wait after a short
  grace, reports whether Boosthis confirmed or locked it, and chases that first
  answer on a bounded retry ladder instead of waiting for the next heartbeat.

### 0.1.21

- Registration refusals now distinguish revoked, billing-paused, unrecognised,
  and generic keys. Deliberate local-only mode is distinguished from a missing
  project key, and every inactive reason is shown in the app and on stderr.

### 0.1.20

- The rule book gains four new checks for refusals that get mistaken for
  outages: an app that throws away its credential and sends the person back to
  sign in the moment a service answers with a sign-in challenge, one identical
  message shown for every different refusal, a credential check that is strict
  about letter case, quoting or spacing, and a protection that fails open in
  silence with nothing recorded. The fifth check in this family — a shared
  allowance with no per-caller share — does not apply to an app running on a
  device, which serves no callers of its own.

### 0.1.19

- The in-app panel now asks Boosthis whether this install is registered, clearly
  distinguishes registered, not registered, and unable to check, and always
  shows the install id. It only says nothing is being sent when the check
  confirms that.

## Licence

Apache-2.0.
