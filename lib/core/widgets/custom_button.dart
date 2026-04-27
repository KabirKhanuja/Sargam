import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool destructive;

  const PrimaryActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColors.textPrimary : const Color(0xFF1B1300);
    final bg = destructive ? AppColors.surfaceHigh : AppColors.gold;

    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 10),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
