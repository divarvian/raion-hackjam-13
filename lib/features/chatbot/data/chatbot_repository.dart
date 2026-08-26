import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotRepository {
  late final GenerativeModel _primaryModel;
  late final GenerativeModel _fallbackModel;
  ChatSession? _chatSession;
  String? _currentContext;

  ChatbotRepository() {
    // Get API Key from .env
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    final systemInstruction = Content.system(
      'Kamu adalah Kawal.Z AI, asisten virtual yang ramah untuk anak muda Gen Z di Indonesia. '
      'Kamu bertugas untuk membantu menjawab pertanyaan terkait isu politik, hukum, kebijakan, dan sosial. '
      'Gunakan bahasa gaul yang santai, mudah dimengerti, edukatif, tapi tetap netral dan tidak memihak. '
      'Gunakan emoji secukupnya untuk membuat obrolan lebih asik.\n\n'
      'PENTING: Gunakan format Markdown standar (**tebal**, *miring*). JANGAN PERNAH gunakan tag HTML seperti <i>, <b>, atau <br>.\n\n'
      'ATURAN KETAT (GUARDRAIL): '
      'JIKA user bertanya hal yang SAMA SEKALI BUKAN tentang isu publik, hukum, politik, atau konteks artikel yang sedang dibaca (misalnya tanya resep masakan, curhat pribadi, cinta, matematika, game, dll), '
      'TOLAK DENGAN SOPAN SECARA SINGKAT (MAKSIMAL 2 KALIMAT SAJA) dan ingatkan bahwa kamu hanya fokus membahas isu-isu Kawal.Z.',
    );

    _primaryModel = GenerativeModel(
      model: 'gemini-3.5-flash-lite', // Menggunakan model Lite langsung untuk menghindari limit
      apiKey: apiKey,
      systemInstruction: systemInstruction,
    );

    _fallbackModel = GenerativeModel(
      model: 'gemini-3.5-flash-lite', // Model fallback yang cepat dan ringan
      apiKey: apiKey,
      systemInstruction: systemInstruction,
    );
  }

  void startChat(String contextData) {
    _currentContext = contextData;
    _initSession(_primaryModel);
  }

  void _initSession(GenerativeModel model) {
    _chatSession = model.startChat(
      history: [
        Content.text(
          'Ini adalah konteks artikel yang sedang dibaca user:\n$_currentContext\n\nTolong jawab pertanyaan user berikutnya berdasarkan konteks ini jika relevan.',
        ),
        Content.model([
          TextPart(
            'Siap! Aku akan membantu menjawab pertanyaan user tentang artikel ini.',
          ),
        ]),
      ],
    );
  }

  Future<String> sendMessage(String message) async {
    if (_chatSession == null) {
      throw Exception('Chat session not initialized. Call startChat first.');
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'Maaf, aku tidak mengerti maksudmu.';
    } catch (e) {
      final errorMessage = e.toString();

      // Jika terjadi error 500 (Internal Error), 503 (High Demand), atau overloaded
      if (errorMessage.contains('500') ||
          errorMessage.contains('503') ||
          errorMessage.contains('high demand') ||
          errorMessage.contains('Internal error')) {
        debugPrint(
          'Gemini 3.7 Flash is overloaded or returning 500. Falling back to 3.5 Flash-Lite...',
        );

        // Pindah ke model fallback yang lebih stabil
        _initSession(_fallbackModel);

        try {
          // Coba kirim ulang pesan menggunakan fallback model
          final fallbackResponse = await _chatSession!.sendMessage(
            Content.text(message),
          );
          return fallbackResponse.text ?? 'Maaf, aku tidak mengerti maksudmu.';
        } catch (fallbackError) {
          debugPrint('Fallback model also failed: $fallbackError');
          return 'Wah, sepertinya server AI lagi kepenuhan banget nih. Coba lagi nanti ya!';
        }
      }

      debugPrint('Error sending message to Gemini: $e');
      return 'Wah, sepertinya koneksiku lagi gangguan nih. Coba lagi nanti ya!';
    }
  }
}
