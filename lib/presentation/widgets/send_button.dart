import 'package:flutter/material.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';

class SendButton extends StatelessWidget {
  const SendButton({super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: enabled ? Colors.white : AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
