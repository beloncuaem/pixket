import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_progress.dart';

/// Tiến độ ngân sách tháng bằng các khối pixel; vượt hạn mức đổi sang hoa hồng.
class BudgetProgressCard extends ConsumerWidget {
  const BudgetProgressCard({
    super.key,
    required this.spent,
    required this.budget,
    this.onTap,
  });

  final double spent;
  final double budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    if (budget <= 0) {
      return PixelPanel(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AppIcon(name: 'wallet', size: 32, color: palette.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chưa đặt ngân sách',
                style: text.bodyMedium?.copyWith(color: palette.ink),
              ),
            ),
            AppIcon(name: 'chevronRight', size: 16, color: palette.inkMuted),
          ],
        ),
      );
    }

    final ratio = spent / budget;
    final isOver = spent > budget;
    final remaining = budget - spent;

    return PixelPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NGÂN SÁCH THÁNG',
                  style: text.labelLarge?.copyWith(color: palette.inkMuted),
                ),
              ),
              Text(
                CurrencyFormatter.format(budget),
                style: text.bodyMedium?.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PixelProgress(
            value: ratio,
            segments: 10,
            spendRamp: ref.watch(effectsProvider).chartSpendRamp,
          ),
          const SizedBox(height: 8),
          Text(
            'Đã chi: ${CurrencyFormatter.format(spent)}',
            style: text.bodySmall?.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isOver
                  ? 'QUÁ NGÂN SÁCH: ${CurrencyFormatter.format(-remaining)}'
                  : 'Còn lại: ${CurrencyFormatter.format(remaining)}',
              style: text.titleSmall?.copyWith(
                color: isOver ? palette.danger : palette.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
