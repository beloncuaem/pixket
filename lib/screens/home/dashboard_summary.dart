import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_stat_tile.dart';

/// Thẻ tổng chi tháng: một con số hero kèm ba stat tile rút gọn.
class DashboardSummary extends StatelessWidget {
  const DashboardSummary({
    super.key,
    required this.month,
    required this.today,
    required this.week,
    required this.expenseCount,
  });

  final double month;
  final double today;
  final double week;
  final int expenseCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return PixelPanel(
      background: palette.mint,
      borderColor: palette.lineStrong,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHI THÁNG NÀY',
            style: text.labelLarge?.copyWith(color: palette.mintInk),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(month),
              style: text.displayLarge?.copyWith(
                color: palette.onAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PixelStatTile(
                  label: 'HÔM NAY',
                  value: CurrencyFormatter.short(today),
                  glyph: 'calendar',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelStatTile(
                  label: 'TUẦN NÀY',
                  value: CurrencyFormatter.short(week),
                  glyph: 'filmStrip',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelStatTile(
                  label: 'SỐ KHOẢN',
                  value: '$expenseCount',
                  glyph: 'receipt',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
