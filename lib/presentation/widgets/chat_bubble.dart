import 'package:flutter/material.dart';
import 'package:gemma_local/core/models/chat_message.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';
import 'package:gemma_local/presentation/widgets/typing_indicator.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.accent
                    : message.isError
                    ? AppColors.errorBg
                    : AppColors.bubbleAi,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: message.text.isEmpty && !isUser
                  ? TypingIndicator()
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : message.isError
                            ? AppColors.errorText
                            : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.userAvatar,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.person, size: 16, color: Colors.white),
    );
  }
}
