import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  String _cleanHtmlTags(String text) {
    return text
        .replaceAll('<i>', '*')
        .replaceAll('</i>', '*')
        .replaceAll('<b>', '**')
        .replaceAll('</b>', '**')
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n');
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: message.isUser
            ? Text(
                message.text,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              )
            : MarkdownBody(
                data: _cleanHtmlTags(message.text),
                styleSheet: MarkdownStyleSheet(
                  p: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  strong: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  em: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ),
      ),
    );
  }
}
