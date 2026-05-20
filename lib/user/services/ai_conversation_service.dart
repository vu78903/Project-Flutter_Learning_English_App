import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import '../../admin/models/admin_models.dart';

class AiConversationService {
  static const _openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const _owlAlphaApiKey = String.fromEnvironment('OWL_ALPHA_API_KEY');
  static const _openRouterModel = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'openrouter/owl-alpha',
  );
  static final _openRouterUri = Uri.parse(
    'https://openrouter.ai/api/v1/chat/completions',
  );
  static const _connectionTimeout = Duration(seconds: 10);
  static const _requestTimeout = Duration(seconds: 35);
  static Future<Map<String, String>>? _envCache;

  Future<String> _effectiveOpenRouterApiKey() async {
    if (_openRouterApiKey.isNotEmpty) {
      return _openRouterApiKey;
    }
    if (_owlAlphaApiKey.isNotEmpty) {
      return _owlAlphaApiKey;
    }
    final env = await _loadEnv();
    final envOpenRouterKey = env['OPENROUTER_API_KEY'] ?? '';
    if (envOpenRouterKey.isNotEmpty) {
      return envOpenRouterKey;
    }
    final envOwlAlphaKey = env['OWL_ALPHA_API_KEY'] ?? '';
    if (envOwlAlphaKey.isNotEmpty) {
      return envOwlAlphaKey;
    }
    return '';
  }

  String get providerLabel => 'Owl Alpha';

  Future<String> generateOpening({required AiScenario scenario}) async {
    final apiKey = await _effectiveOpenRouterApiKey();
    if (apiKey.isEmpty) {
      throw const AiConversationException('Chưa cấu hình OpenRouter API key.');
    }

    try {
      return await _generateWithOwlAlpha(
        apiKey: apiKey,
        scenario: scenario,
        history: const [],
        userText:
            'Start the roleplay now. Greet me and ask the first natural question.',
      );
    } on TimeoutException {
      throw const AiConversationException(
        'Owl Alpha đang phản hồi chậm. Hãy chờ một chút rồi gửi lại.',
      );
    } on AiConversationException {
      rethrow;
    } on Object {
      throw const AiConversationException(
        'Không gọi được Owl Alpha. Kiểm tra mạng hoặc API key rồi thử lại.',
      );
    }
  }

  Future<String> generateReply({
    required AiScenario scenario,
    required List<AiTurn> history,
    required String userText,
  }) async {
    final apiKey = await _effectiveOpenRouterApiKey();
    if (apiKey.isEmpty) {
      throw const AiConversationException('Chưa cấu hình OpenRouter API key.');
    }

    try {
      return await _generateWithOwlAlpha(
        apiKey: apiKey,
        scenario: scenario,
        history: history,
        userText: userText,
      );
    } on TimeoutException {
      throw const AiConversationException(
        'Owl Alpha đang phản hồi chậm. Hãy chờ một chút rồi gửi lại.',
      );
    } on AiConversationException {
      rethrow;
    } on Object {
      throw const AiConversationException(
        'Không gọi được Owl Alpha. Kiểm tra mạng hoặc API key rồi thử lại.',
      );
    }
  }

  Future<String> _generateWithOwlAlpha({
    required String apiKey,
    required AiScenario scenario,
    required List<AiTurn> history,
    required String userText,
  }) async {
    final response = await _postJson(
      _openRouterUri,
      {
        'model': _openRouterModel,
        'messages': _buildMessages(scenario, history, userText),
        'temperature': 0.7,
        'top_p': 0.9,
        'max_tokens': 55,
      },
      headers: {
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://lexigo.local',
        'X-Title': 'LexiGo',
      },
    ).timeout(_requestTimeout);
    final choices = response['choices'] as List<dynamic>? ?? [];
    final choice = choices.isEmpty
        ? null
        : choices.first as Map<String, dynamic>?;
    final message = choice?['message'] as Map<String, dynamic>?;
    final content = message?['content'];
    final reply = _contentText(content).trim();
    if (reply.isEmpty) {
      throw const AiConversationException('Owl Alpha không trả về nội dung.');
    }
    return reply;
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) async {
    final client = HttpClient()..connectionTimeout = _connectionTimeout;
    try {
      final request = await client.postUrl(uri).timeout(_connectionTimeout);
      request.headers.contentType = ContentType.json;
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      request.write(jsonEncode(body));
      final response = await request.close().timeout(_requestTimeout);
      final responseText = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiConversationException(
          _friendlyOpenRouterError(response.statusCode, responseText),
        );
      }
      return jsonDecode(responseText) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  String _friendlyOpenRouterError(int statusCode, String responseText) {
    try {
      final json = jsonDecode(responseText) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? responseText;
      if (statusCode == 401 || statusCode == 403) {
        return 'OpenRouter API key không hợp lệ hoặc chưa có quyền dùng model.';
      }
      if (statusCode == 429 ||
          message.contains('quota') ||
          message.contains('Quota') ||
          message.contains('rate-limit') ||
          message.contains('rate limit')) {
        return 'OpenRouter API key đã hết quota hoặc đang bị giới hạn tốc độ.';
      }
      if (message.contains('not found') ||
          message.contains('No allowed providers') ||
          message.contains('not a valid model ID')) {
        return 'Model $_openRouterModel hiện không khả dụng trên OpenRouter. Hãy thử lại sau hoặc đổi OPENROUTER_MODEL.';
      }
      return message;
    } on Object {
      return responseText;
    }
  }

  List<Map<String, String>> _buildMessages(
    AiScenario scenario,
    List<AiTurn> history,
    String userText,
  ) {
    final recentHistory = _historyWithoutCurrentInput(history, userText);
    return [
      {
        'role': 'system',
        'content':
            '${_systemInstruction(scenario)}\n'
            'Scenario title: ${scenario.title}\n'
            'Difficulty: ${scenario.difficulty}',
      },
      for (final turn in recentHistory.skip(
        recentHistory.length > 6 ? recentHistory.length - 6 : 0,
      ))
        {'role': turn.fromAi ? 'assistant' : 'user', 'content': turn.text},
      {'role': 'user', 'content': userText},
    ];
  }

  List<AiTurn> _historyWithoutCurrentInput(
    List<AiTurn> history,
    String userText,
  ) {
    if (history.isEmpty) {
      return history;
    }
    final lastTurn = history.last;
    if (!lastTurn.fromAi && lastTurn.text.trim() == userText.trim()) {
      return history.sublist(0, history.length - 1);
    }
    return history;
  }

  String _contentText(Object? content) {
    if (content is String) {
      return content;
    }
    if (content is List) {
      return content
          .map((part) {
            if (part is Map<String, dynamic>) {
              return part['text'] as String? ?? '';
            }
            return '';
          })
          .where((text) => text.isNotEmpty)
          .join('\n');
    }
    return '';
  }

  Future<Map<String, String>> _loadEnv() {
    return _envCache ??= rootBundle
        .loadString('.env')
        .then(_parseEnv)
        .catchError((Object _) => <String, String>{});
  }

  Map<String, String> _parseEnv(String source) {
    final env = <String, String>{};
    for (final rawLine in const LineSplitter().convert(source)) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }
      final separator = line.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final key = line.substring(0, separator).trim();
      var value = line.substring(separator + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      env[key] = value;
    }
    return env;
  }

  String _systemInstruction(AiScenario scenario) {
    return '''
You are LexiGo AI, a natural English roleplay partner for Vietnamese learners.
Roleplay setting from admin: ${scenario.systemPrompt}
Rules:
- Stay in character and continue the situation naturally.
- Use the conversation history. Do not restart the scene or ignore what was just asked.
- Do not use a fixed script; vary your wording naturally through the API response.
- If the learner asks a question, answer that exact question first.
- If the scenario misses details like prices, times, places, or menu items, invent a simple realistic detail.
- Reply only in English, 1 or 2 short natural sentences under 28 words total.
- Ask one short follow-up question only when it fits the learner's message.
- Do not over-correct the learner.
- Do not repeat the same question if the learner already answered it.
- No translation, no explanation, no bullet points.
''';
  }
}

class AiTurn {
  const AiTurn({required this.fromAi, required this.text});

  final bool fromAi;
  final String text;
}

class AiConversationException implements Exception {
  const AiConversationException(this.message);

  final String message;

  @override
  String toString() => message;
}
