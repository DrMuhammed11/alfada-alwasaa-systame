/// Boosthis — pure-Dart core for the Flutter kit.
///
/// This is the package barrel: the ONE public import surface
/// (`package:boosthis/boosthis.dart`). It carries no Flutter dependency — the
/// widget/adapter layer lives in the separate `boosthis_flutter` package and
/// re-exports what a Flutter app needs on top of this core.
///
/// Everything here is zero-dependency, `dart:`-only Dart. The runtime tag on
/// the wire is `"flutter"`, rule ids are prefixed `flutter-`, and the kit
/// version is `RUNTIME_VERSION`.
library;

// ─── core ────────────────────────────────────────────────────────────────────
export 'src/core/kit.dart';
export 'src/core/kit_version.dart' show RUNTIME_VERSION;
export 'src/core/safe.dart';
export 'src/core/json.dart';
export 'src/core/score.dart';
export 'src/core/samples.dart';
export 'src/core/sample_uploader.dart';
export 'src/core/store.dart';
export 'src/core/telemetry.dart';
export 'src/core/thresholds.dart';
export 'src/core/runtime_flags.dart';
export 'src/core/project_key.dart';
export 'src/core/start_announce.dart';
export 'src/core/activation_notice.dart';
export 'src/core/project_identity.dart';
export 'src/core/registration.dart';
export 'src/core/transmit.dart';
export 'src/core/uploader.dart';
export 'src/core/snapshot.dart';
export 'src/core/kill_switch.dart';
export 'src/core/integrity.dart';
export 'src/core/build_identity.dart';
export 'src/core/coverage_inventory.dart';
export 'src/core/watchable_surfaces.dart';

// ─── privacy guard ─────────────────────────────────────────────────────────
export 'src/observers/pii.dart';
export 'src/observers/pii_detected_error.dart';

// ─── meters ────────────────────────────────────────────────────────────────
export 'src/meters/meter_axes.dart';
export 'src/meters/flutter_meters.dart';
export 'src/meters/extra_meters.dart';
export 'src/meters/runtime_vitals.dart';
export 'src/meters/device_tier.dart';
export 'src/meters/suspend_sensor.dart';
export 'src/meters/request_error_timer.dart';

// ─── observers ───────────────────────────────────────────────────────────────
export 'src/observers/cold_start.dart';
export 'src/observers/cpu_scheduling.dart';
export 'src/observers/crash_reporter.dart';
export 'src/observers/dev_posture.dart';
export 'src/observers/image_weight.dart';
export 'src/observers/leak_watch.dart';
export 'src/observers/lifecycle_axes.dart';
export 'src/observers/live_detectors.dart';
export 'src/observers/memory_meters.dart';
export 'src/observers/platform_channels.dart';
export 'src/observers/scheduler_latency.dart';
export 'src/observers/storage_latency.dart';
export 'src/observers/system_load.dart';
export 'src/observers/swallowed_errors.dart';
export 'src/observers/timer_leaks.dart';
export 'src/observers/unhandled_errors.dart';

// ─── integration + MCP ─────────────────────────────────────────────────────
export 'src/integration/instrument.dart';
export 'src/integration/nav_tracker.dart';
export 'src/integration/route_inventory.dart';
export 'src/integration/network_sampler.dart';
export 'src/integration/ai_providers.dart';
export 'src/integration/ai_calls.dart';
export 'src/integration/zone_timers.dart';
export 'src/integration/span_emitter.dart';
export 'src/integration/span_scope.dart';
export 'src/integration/span_work.dart';
export 'src/integration/trace.dart';
export 'src/integration/community.dart';
export 'src/integration/propose.dart';
export 'src/integration/bubble.dart';
export 'src/mcp/mcp.dart';
export 'src/mcp/mcp_measure.dart';
export 'src/mcp/live_read.dart';

// ─── rules ───────────────────────────────────────────────────────────────────
export 'src/rules/checklist.dart';

// ─── static facade the Flutter adapter drives ────────────────────────────────
export 'src/boosthis_facade.dart';
