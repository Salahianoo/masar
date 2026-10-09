import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Talks to رفيق on the team PC: pc/rafeeq-proxy.mjs behind the "masar"
/// Cloudflare tunnel, in front of LM Studio (Qwen3.5-9B). See pc/README.md.
///
/// Configured at build time, never committed:
///   flutter run --dart-define=MASAR_LLM_URL=https://rafeeq.salahabushamseih.com \
///               --dart-define=MASAR_LLM_TOKEN=`RAFEEQ_GATE_TOKEN from pc/.env`
///
/// The token travels inside the app binary, which is acceptable for the
/// hackathon build only: rotate it in pc/.env afterwards, and move this call
/// behind askMentor (functions/) once the backend is deployed.
class RafeeqClient {
  RafeeqClient({String? url, String? token})
      : _url = url ?? const String.fromEnvironment('MASAR_LLM_URL'),
        _token = token ?? const String.fromEnvironment('MASAR_LLM_TOKEN');

  final String _url;
  final String _token;

  static const model = 'qwen/qwen3.5-9b';
  static const _timeout = Duration(seconds: 40);

  bool get configured => _url.isNotEmpty && _token.isNotEmpty;

  /// The reply text. Throws [RafeeqUnavailable] when the PC can't answer:
  /// not configured, off, busy (the proxy answers 503 while another student
  /// is being served), or too slow.
  Future<String> chat({required String system, required List<({String role, String text})> history}) async {
    if (!configured) throw const RafeeqUnavailable();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(Uri.parse('${_url.replaceAll(RegExp(r'/$'), '')}/v1/chat/completions'));
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $_token')
        ..contentType = ContentType.json;
      request.write(jsonEncode({
        'model': model,
        'temperature': 0.4,
        'max_tokens': 500,
        'reasoning_effort': 'none',
        'messages': [
          {'role': 'system', 'content': system},
          for (final m in history) {'role': m.role, 'content': m.text},
        ],
      }));
      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join().timeout(_timeout);
      if (response.statusCode != 200) throw const RafeeqUnavailable();
      final content = ((jsonDecode(body) as Map)['choices'] as List).first['message']['content'] as String? ?? '';
      // Qwen may think aloud; the student only gets what follows.
      final reply = content.replaceAll(RegExp(r'<think>[\s\S]*?(</think>\s*|$)'), '').trim();
      if (reply.isEmpty) throw const RafeeqUnavailable();
      return reply;
    } on RafeeqUnavailable {
      rethrow;
    } on Object {
      throw const RafeeqUnavailable();
    } finally {
      client.close(force: true);
    }
  }
}

class RafeeqUnavailable implements Exception {
  const RafeeqUnavailable();
  @override
  String toString() => 'رفيق مشغول هلق، جرّب كمان شوي';
}
