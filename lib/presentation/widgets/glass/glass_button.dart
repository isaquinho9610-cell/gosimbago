import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final widget = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.mediumBlue.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.mediumBlue.withValues(alpha: 0.8)
                : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? AppColors.mediumBlue : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: widget) : widget;
  }
}
