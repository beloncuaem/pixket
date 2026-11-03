import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_bar_chart.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_pie_chart.dart';
import '../../widgets/pixel/pixel_share_row.dart';

typedef DailySeries = ({
  List<DateTime> dates,
  List<double> values,
  List<String> valueTexts,
});

/// Sort theo ngày tăng dần; key không parse được bị bỏ qua (không ném lỗi).
DailySeries dailySeries(Map<String, double> dailyTotals) {
  final parser = DateFormat('yyyy-MM-dd');
  final keys = dailyTotals.keys.toList()..sort();
  final dates = <DateTime>[];
  final values = <double>[];
  final texts = <String>[];
  for (final key in keys) {
    try {
      dates.add(parser.parseStrict(key));
    } on FormatException {
      continue;
    }
    final value = dailyTotals[key] ?? 0;
    values.add(value);
    texts.add(CurrencyFormatter.format(value));
  }
  return (dates: dates, values: values, valueTexts: texts);
}

/// Glyph của bốn mức ưu tiên, cùng thứ tự với [AppStrings.priorityLabels].
const List<String> _priorityGlyphs = ['check', 'sparkle', 'gift', 'close'];

/// Ba khối thống kê (tròn theo danh mục, hàng mức độ cần thiết, cột theo
/// ngày) + nhận xét. Màn Thống kê và screen khác chỉ cần nhúng widget này.
class StatisticsCharts extends ConsumerWidget {
  const StatisticsCharts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final stats = ref.watch(statisticsProvider);
    final categories = ref.watch(categoryProvider).categories;
    final nameById = {
      for (final c in categories)
        if (c.id != null) c.id!: c.name,
    };

    if (stats.isLoading && stats.totalAmount == 0) {
      return const PixelPanel(
        child: Center(child: PixelLoading(label: 'Đang tính thống kê…')),
      );
    }

    final catEntries = stats.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final series = dailySeries(stats.dailyTotals);
    final priorityValues = [
      for (var p = 0; p < AppStrings.priorityLabels.length; p++)
        stats.priorityTotals[p] ?? 0,
    ];
    final hasPriority = priorityValues.any((v) => v > 0);
    final priorityTotal = priorityValues.fold<double>(
      0,
      (sum, v) => sum + (v > 0 ? v : 0),
    );

    // Lát tròn và hàng chú thích dùng chung một accent ổn định theo tên danh
    // mục nên ô màu trong legend luôn khớp màu lát cắt.
    final catSlices = <PixelPieSlice>[];
    for (final entry in catEntries) {
      final name = nameById[entry.key] ?? 'Khác';
      catSlices.add(
        PixelPieSlice(
          label: name,
          value: entry.value,
          valueText: CurrencyFormatter.format(entry.value),
          color: palette.accentForCategory(name),
        ),
      );
    }

    final effects = ref.watch(effectsProvider);
    // Mốc tham chiếu = max của kỳ đang xem, giờ chỉ còn tô cột theo ngày.
    final dayMax = series.values.fold<double>(0, (a, b) => b > a ? b : a);
    final on = effects.chartSpendRamp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THEO DANH MỤC', style: text.labelLarge),
              const SizedBox(height: 10),
              if (catSlices.isEmpty)
                Text(
                  'Chưa có dữ liệu trong khoảng này.',
                  style: text.bodyMedium?.copyWith(color: palette.inkMuted),
                )
              else ...[
                Center(child: PixelPieChart(slices: catSlices)),
                const SizedBox(height: 10),
                for (final slice in catSlices)
                  PixelShareRow(
                    label: slice.label,
                    color: slice.color,
                    value: slice.value,
                    total: stats.totalAmount,
                    valueText: slice.valueText,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MỨC ĐỘ CẦN THIẾT', style: text.labelLarge),
              const SizedBox(height: 10),
              if (!hasPriority)
                Text(
                  'Chưa có dữ liệu trong khoảng này.',
                  style: text.bodyMedium?.copyWith(color: palette.inkMuted),
                )
              else
                for (var p = 0; p < AppStrings.priorityLabels.length; p++)
                  PixelShareRow(
                    label: AppStrings.priorityLabels[p],
                    glyph: _priorityGlyphs[p],
                    color: palette.priorityColor(p),
                    value: priorityValues[p],
                    total: priorityTotal,
                    valueText: CurrencyFormatter.format(priorityValues[p]),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THEO NGÀY', style: text.labelLarge),
              const SizedBox(height: 10),
              PixelBarChart(
                dates: series.dates,
                values: series.values,
                valueTexts: series.valueTexts,
                reference: on ? dayMax : null,
              ),
            ],
          ),
        ),
        if (stats.insights.isNotEmpty) ...[
          const SizedBox(height: 12),
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NHẬN XÉT', style: text.labelLarge),
                const SizedBox(height: 8),
                for (final insight in stats.insights)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppIcon(
                          name: 'sparkle',
                          size: 16,
                          color: palette.butterInk,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight,
                            style: text.bodyMedium?.copyWith(
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
