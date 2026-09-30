import '../core/runtime_flags.dart';
import '../core/safe.dart';

/// One entry in the append-only AI provider wire table.
class AiProviderEntry {
  const AiProviderEntry(this.id, this.hosts);

  final String id;
  final List<String> hosts;
}

/// The maintained list. APPEND ONLY — a provider's 1-based position is its
/// wire code. This is kept verbatim and in the same order as the Node runtime.
const List<AiProviderEntry> aiProviders = <AiProviderEntry>[
  AiProviderEntry('openai', <String>['api.openai.com']),
  AiProviderEntry('anthropic', <String>['api.anthropic.com']),
  AiProviderEntry('google', <String>[
    'generativelanguage.googleapis.com',
    'aiplatform.googleapis.com',
    '.aiplatform.googleapis.com',
  ]),
  AiProviderEntry('azure-openai', <String>[
    '.openai.azure.com',
    '.cognitiveservices.azure.com',
  ]),
  AiProviderEntry('aws-bedrock', <String>['.amazonaws.com']),
  AiProviderEntry('mistral', <String>[
    'api.mistral.ai',
    'codestral.mistral.ai',
  ]),
  AiProviderEntry('cohere', <String>['api.cohere.ai', 'api.cohere.com']),
  AiProviderEntry('groq', <String>['api.groq.com']),
  AiProviderEntry('together', <String>['api.together.xyz', 'api.together.ai']),
  AiProviderEntry('perplexity', <String>['api.perplexity.ai']),
  AiProviderEntry('deepseek', <String>['api.deepseek.com']),
  AiProviderEntry('xai', <String>['api.x.ai']),
  AiProviderEntry('fireworks', <String>['api.fireworks.ai']),
  AiProviderEntry('openrouter', <String>['openrouter.ai']),
  AiProviderEntry('replicate', <String>['api.replicate.com']),
  AiProviderEntry('huggingface', <String>[
    'api-inference.huggingface.co',
    'router.huggingface.co',
  ]),
  AiProviderEntry('voyage', <String>['api.voyageai.com']),
  AiProviderEntry('cerebras', <String>['api.cerebras.ai']),
  AiProviderEntry('declared', <String>[]),
];

const int declaredProviderCode = 19;
const int maxDeclaredAiEndpoints = 8;
const int _maxHostLength = 253;
const List<String> _awsBedrockPrefixes = <String>[
  'bedrock-runtime.',
  'bedrock.',
];

List<String> _declaredHosts = <String>[];
bool _envRead = false;

/// Classify a bare destination host against the maintained provider table.
int aiProviderCode(Object? host) {
  return Safe.run<int>(0, () {
    final h = host is String ? host.toLowerCase() : '';
    if (h.isEmpty) return 0;
    for (var i = 0; i < aiProviders.length; i++) {
      final entry = aiProviders[i];
      for (final suffix in entry.hosts) {
        final hit = suffix.startsWith('.')
            ? h.endsWith(suffix) || h == suffix.substring(1)
            : h == suffix;
        if (!hit) continue;
        if (entry.id == 'aws-bedrock' &&
            !_awsBedrockPrefixes.any(h.startsWith)) {
          continue;
        }
        return i + 1;
      }
    }
    return 0;
  });
}

/// Reduce a hostname, hostname with port, or full URL to an exact bare host.
String? normaliseDeclaredEndpoint(Object? raw) {
  return Safe.run<String?>(null, () {
    if (raw is! String) return null;
    var value = raw.trim().toLowerCase();
    if (value.isEmpty || RegExp(r'\s').hasMatch(value)) return null;
    if (value.contains('://')) {
      final uri = Uri.tryParse(value);
      if (uri == null || uri.host.isEmpty) return null;
      value = uri.host;
    } else {
      final slash = value.indexOf('/');
      if (slash >= 0) value = value.substring(0, slash);
      final at = value.lastIndexOf('@');
      if (at >= 0) value = value.substring(at + 1);
      if (value.startsWith('[')) {
        final close = value.indexOf(']');
        if (close < 0) return null;
        value = value.substring(1, close);
      } else {
        final colon = value.lastIndexOf(':');
        if (colon >= 0) value = value.substring(0, colon);
      }
    }
    if (value.startsWith('[') && value.endsWith(']')) {
      value = value.substring(1, value.length - 1);
    }
    if (value.isEmpty || value.length > _maxHostLength || value.contains('*')) {
      return null;
    }
    return value;
  });
}

List<Object?> _envDeclarations() {
  final raw = RuntimeFlags.env('BOOSTHIS_AI_ENDPOINTS');
  return raw == null ? <Object?>[] : raw.split(',');
}

void _rebuild(Iterable<Object?> extra) {
  final out = <String>[];
  for (final candidate in <Object?>[..._envDeclarations(), ...extra]) {
    final host = normaliseDeclaredEndpoint(candidate);
    if (host == null || out.contains(host)) continue;
    if (out.length >= maxDeclaredAiEndpoints) break;
    out.add(host);
  }
  _declaredHosts = out;
}

void _ensureEnvRead() {
  if (_envRead) return;
  _envRead = true;
  _rebuild(const <Object?>[]);
}

/// Merge code declarations with BOOSTHIS_AI_ENDPOINTS, retaining at most eight.
int setDeclaredAiEndpoints(Iterable<Object?>? endpoints) {
  _envRead = true;
  _rebuild(endpoints ?? const <Object?>[]);
  return _declaredHosts.length;
}

int declaredAiEndpointCount() {
  _ensureEnvRead();
  return _declaredHosts.length;
}

/// Known providers win over declarations; declarations are exact-host only.
int aiProviderCodeOrDeclared(Object? host) {
  final known = aiProviderCode(host);
  if (known != 0) return known;
  _ensureEnvRead();
  final h = host is String ? host.toLowerCase() : '';
  final bare = h.startsWith('[') && h.endsWith(']')
      ? h.substring(1, h.length - 1)
      : h;
  return _declaredHosts.contains(bare) ? declaredProviderCode : 0;
}

void resetDeclaredAiEndpointsForTests() {
  _declaredHosts = <String>[];
  _envRead = false;
}
