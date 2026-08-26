import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'chatbot_bottom_sheet.dart';

class AiFab extends StatelessWidget {
  final String policyId;
  final String articleContext;

  const AiFab({super.key, required this.policyId, required this.articleContext});

  void _openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatbotBottomSheet(
        policyId: policyId,
        articleContext: articleContext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openChat(context),
      backgroundColor: AppColors.primaryLight,
      child: const Icon(Icons.auto_awesome, color: Colors.white),
    );
  }
}
