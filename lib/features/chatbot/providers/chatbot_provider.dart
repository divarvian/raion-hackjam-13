import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chatbot_repository.dart';
import '../domain/chat_message.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepository();
});

class ChatbotState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatbotState({
    required this.messages,
    required this.isLoading,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatbotNotifier extends AutoDisposeFamilyNotifier<ChatbotState, String> {
  @override
  ChatbotState build(String arg) {
    // 'arg' is the policyId
    return ChatbotState(
      messages: [
        ChatMessage(
          text: 'Hai! Ada yang bingung dari artikel ini? Tanyakan saja kepadaku ya!',
          isUser: false,
        ),
      ],
      isLoading: false,
    );
  }

  void initializeChat(String articleContext) {
    // Only initialize if we haven't sent any user messages yet.
    // This prevents resetting the chat when the bottom sheet is reopened.
    if (state.messages.length > 1) return;
    ref.read(chatbotRepositoryProvider).startChat(articleContext);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Tambahkan pesan user ke UI
    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    // Panggil API
    final repo = ref.read(chatbotRepositoryProvider);
    final responseText = await repo.sendMessage(text);

    // Tambahkan balasan AI ke UI
    final aiMsg = ChatMessage(text: responseText, isUser: false);
    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
    );
  }
}

final chatbotProvider = AutoDisposeNotifierProviderFamily<ChatbotNotifier, ChatbotState, String>(() {
  return ChatbotNotifier();
});
