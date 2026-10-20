import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/money_format.dart';

class BudgetAlertBanner extends StatelessWidget {
  final String period;
  final double budget;
  final double spent;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const BudgetAlertBanner({
    super.key,
    required this.period,
    required this.budget,
    required this.spent,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (budget <= 0 || spent <= budget) {
      return const SizedBox.shrink();
    }

    final overAmount = spent - budget;
    final percentOver = ((spent / budget) * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1218), // Deep danger tinted background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Alert Icon Container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + Badge
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Over $period Budget!',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$percentOver% used',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dismiss button if provided
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textMuted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              'You have exceeded your $period allowance by ${formatPeso(overAmount)}. Total spent is ${formatSpent(spent)} against your ${formatPeso(budget)} limit.',
              style: const TextStyle(
                color: Color(0xFFE2C9CF),
                fontSize: 13,
                height: 1.35,
              ),
            ),

            if (onAction != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Adjust Budget'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
