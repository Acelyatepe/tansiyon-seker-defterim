import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Seçim değişiminde animasyon veya dalga efekti kullanmaz.
class InstantChoice extends StatelessWidget {
  const InstantChoice({
    super.key,
    required this.labels,
    required this.selected,
    required this.accent,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final Color accent;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.neutral,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: List.generate(
            labels.length,
            (index) {
              final isSelected = selected == index;

              return Expanded(
                child: Semantics(
                  selected: isSelected,
                  child: TextButton(
                    onPressed:
                        onSelected == null ? null : () => onSelected!(index),
                    style: TextButton.styleFrom(
                      animationDuration: Duration.zero,
                      splashFactory: NoSplash.splashFactory,
                      backgroundColor:
                          isSelected ? accent : Colors.transparent,
                      foregroundColor:
                          isSelected ? Colors.white : AppColors.text,
                      disabledForegroundColor:
                          isSelected ? Colors.white : AppColors.text,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}