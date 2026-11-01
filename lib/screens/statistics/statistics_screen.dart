import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_screen_header.dart';
import '../../widgets/pixel/pixel_segmented.dart';
import '../../widgets/pixel/pixel_stat_tile.dart';
import 'statistics_charts.dart';

enum StatRange { today, week, month, year, custom }

String statRangeLabel(StatRange range) => switch (range) {
  StatRange.today => 'Hôm nay',
  StatRange.week => 'Tuần này',
  StatRange.month => 'Tháng này',
  StatRange.year => 'Năm nay',
  StatRange.custom => 'Tùy chọn',
};

class StatisticsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;

  const StatisticsScreen({super.key, this.onMenuTap});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatRange _selectedRange = StatRange.month;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  void _loadData() {
    ref.read(statisticsProvider.notifier).loadStatistics(_startDate, _endDate);
  }

  void _setRange(StatRange range) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    setState(() {
      _selectedRange = range;
      switch (range) {
        case StatRange.today:
          _startDate = startOfToday;
          _endDate = endOfToday;
        case StatRange.week:
          _startDate = startOfToday.subtract(Duration(days: now.weekday - 1));
          _endDate = endOfToday;
        case StatRange.month:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = endOfToday;
        case StatRange.year:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = endOfToday;
        case StatRange.custom:
          break;
      }
    });
    if (range != StatRange.custom) _loadData();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = StatRange.custom;
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        );
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final stats = ref.watch(statisticsProvider);
    final subtitle = _selectedRange == StatRange.custom
        ? '${DateFormatter.formatDate(_startDate)} – ${DateFormatter.formatDate(_endDate)}'
        : statRangeLabel(_selectedRange);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: PixelScreenHeader(
              title: 'THỐNG KÊ',
              subtitle: subtitle,
              onMenuTap: widget.onMenuTap,
              trailing: PixelIconButton(
                icon: 'calendar',
                tooltip: 'Chọn khoảng ngày',
                onPressed: _pickCustomRange,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // 'Tùy chọn' nằm ở nút lịch trên header để 4 phân đoạn còn lại
                // đủ chỗ đọc được trên màn ngang 360 dp.
                PixelSegmented<StatRange>(
                  items: [
                    for (final range in [
                      StatRange.today,
                      StatRange.week,
                      StatRange.month,
                      StatRange.year,
                    ])
                      PixelSegmentItem(
                        value: range,
                        label: statRangeLabel(range),
                      ),
                  ],
                  selected: _selectedRange,
                  onChanged: _setRange,
                ),
                const SizedBox(height: 12),
                if (stats.isLoading && stats.totalAmount == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: PixelLoading(label: 'Đang tải thống kê…'),
                    ),
                  )
                else ...[
                  PixelStatTile(
                    label: 'Tổng chi',
                    value: CurrencyFormatter.format(stats.totalAmount),
                    glyph: 'wallet',
                  ),
                  const SizedBox(height: 12),
                  const StatisticsCharts(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
