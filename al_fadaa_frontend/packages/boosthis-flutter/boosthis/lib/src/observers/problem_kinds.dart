/// The shared problem vocabulary — Flutter copy.
///
/// Every Boosthis kit, in every language, reports a problem under a name from
/// THIS list. One name per problem is what lets the same problem found by a Go
/// service and by a Flutter app meet in one place on the server instead of
/// splitting into two spellings that never group.
///
/// The list is a COPY. The one true list is `lib/problem-kinds.json` at the
/// repo root, which also carries the plain-English meaning of each name; the
/// guard in `scripts/src/__tests__/kitProblemReporting.test.ts` fails the build
/// if this copy and that list ever disagree. A kit therefore cannot invent a
/// spelling: adding a detector means adding its name to the shared list first.
///
/// What a kit must accumulate and upload — signature rules, the local
/// occurrence threshold, the batch cap and the consent gates — is written down
/// once in `docs/kit-problem-reporting-contract.md`.
library;

/// Every problem name a Boosthis kit may report. Sorted, so a diff against the
/// shared list is readable by eye.
const List<String> kProblemKinds = <String>[
  'ai-cache-cold',
  'ai-duplicate-prompt',
  'ai-no-timeout',
  'ai-retry-no-backoff',
  'ai-serial-calls',
  'ai-stream-usage-missing',
  'api-thundering-herd',
  'budget-regression',
  'cache-headers-missing',
  'cache-never-store',
  'cache-no-revalidator',
  'connection-leak',
  'connection-stalled',
  'eager-list-mount',
  'failing-api',
  'ghost-mount',
  'idle-burn',
  'post-commit-effect-storm',
  'rage-tap',
  'reconnect-per-screen',
  'reconnect-storm',
  'regression',
  'remount-storm-global',
  'render-monolith',
  'render-storm',
  'retry-storm',
  'slow-api',
  'slow-nav',
  'slow-press-handler',
  'slow-route',
  'stranded-interval',
];

final Set<String> _known = kProblemKinds.toSet();

/// Is this a name from the shared vocabulary? Anything else is not reported —
/// the accumulator DROPS it rather than uploading a spelling no other kit and
/// no server surface can read.
bool isProblemKind(String kind) => _known.contains(kind);

/// Two names for one problem, seen from two sides.
///
/// The snapshot channel's server-side allowlist carries no route-shaped names,
/// so the snapshot builder folds these before upload. The mapping lives in the
/// shared list too, so a porter reuses it instead of inventing a third
/// spelling. The candidate channel does NOT fold: changing what a kit uploads
/// is what splits history.
const Map<String, String> kProblemKindFold = <String, String>{
  'slow-route': 'slow-api',
  'budget-regression': 'regression',
};
