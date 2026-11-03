import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/category.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/statistics_provider.dart';
import 'package:pixket/screens/statistics/statistics_charts.dart';
import 'package:pixket/screens/statistics/statistics_screen.dart';
import 'package:pixket/widgets/pixel/pixel_bar_chart.dart';
import 'package:pixket/widgets/pixel/pixel_pie_chart.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';
import 'package:pixket/widgets/pixel/pixel_segmented.dart';
import 'package:pixket/widgets/pixel/pixel_share_row.dart';
import 'package:pixket/widgets/pixel/pixel_stat_tile.dart';

class _FakeStatsNotifier extends StateNotifier<StatisticsState>
    implements StatisticsNotifier {
  _FakeStatsNotifier(super.state);

  // Màn Statistics gọi loadStatistics trong initState; bản fake chỉ cần không
  // làm gì vì dữ liệu đã được đặt sẵn ở constructor.
  @override
  Future<void> loadStatistics(DateTime from, DateTime to) async {}

  @override
  Future<void> refreshStatistics() async {}

  @override
  Future<void> generateInsights(DateTime from, DateTime to) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StatisticsState _filledStats() => StatisticsState(
  categoryTotals: const {10: 500000, 11: 250000},
  priorityTotals: const {0: 400000, 3: 350000},
  dailyTotals: const {
    '2026-10-30': 100000,
    '2026-10-31': 200000,
    '2026-11-01': 450000,
  },
  totalAmount: 750000,
  insights: const ['Ăn uống chiếm 67% tổng chi.'],
);

Widget _harness(Widget child, {StatisticsState? stats, double? textScale}) =>
    ProviderScope(
      overrides: [
        statisticsProvider.overrideWith(
          (ref) => _FakeStatsNotifier(stats ?? _filledStats()),
        ),
        categoryProvider.overrideWith(
          (ref) => _FakeCategoryNotifier(
            CategoryState(
              categories: [
                Category(id: 10, name: 'Ăn uống', icon: 'forkKnife'),
                Category(id: 11, name: 'Đi lại', icon: 'car'),
              ],
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: textScale == null
            ? child
            : MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
                child: child,
              ),
      ),
    );

void main() {
  test('dailySeries sort tăng dần và text đã format', () {
    final s = dailySeries(const {'2026-11-02': 20, '2026-11-01': 10});
    expect(s.dates.first.day, 1);
    expect(s.values, [10, 20]);
    expect(s.valueTexts.length, 2);
  });

  test('dailySeries chuỗi ngày hỏng bị bỏ qua', () {
    final s = dailySeries(const {'abc': 5, '2026-11-01': 10});
    expect(s.values, [10]);
  });

  testWidgets('StatisticsCharts render tròn, hàng chú thích và cột', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(const SingleChildScrollView(child: StatisticsCharts())),
    );
    expect(find.byType(PixelPieChart), findsOneWidget);
    // 2 hàng danh mục + 4 hàng mức độ cần thiết.
    expect(find.byType(PixelShareRow), findsNWidgets(6));
    expect(find.byType(PixelBarChart), findsOneWidget);
    expect(find.text('THEO DANH MỤC'), findsOneWidget);
    expect(find.text('MỨC ĐỘ CẦN THIẾT'), findsOneWidget);
    expect(find.text('THEO NGÀY'), findsOneWidget);
    expect(find.text('Ăn uống chiếm 67% tổng chi.'), findsOneWidget);
    // Nhãn bậc mức chi đã bỏ: cột to nhất của kỳ không còn bị gọi là vượt mức.
    expect(find.text('Vượt mức'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatisticsCharts rỗng hiện hướng dẫn', (tester) async {
    await tester.pumpWidget(
      _harness(
        const SingleChildScrollView(child: StatisticsCharts()),
        stats: StatisticsState(
          categoryTotals: const {},
          priorityTotals: const {},
          dailyTotals: const {},
          totalAmount: 0,
          insights: const [],
        ),
      ),
    );
    expect(find.text('Chưa có dữ liệu trong khoảng này.'), findsWidgets);
    expect(find.byType(PixelPieChart), findsNothing);
    expect(find.byType(PixelShareRow), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatisticsScreen dùng PixelSegmented, không còn AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(const StatisticsScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PixelSegmented<StatRange>), findsOneWidget);
    expect(find.text('Tháng này'), findsWidgets);
    expect(find.byType(PixelScreenHeader), findsOneWidget);
    expect(find.byType(PixelStatTile), findsWidgets);
    expect(find.byType(AppBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatisticsScreen 1.3x text scale không vỡ', (tester) async {
    await tester.pumpWidget(_harness(const StatisticsScreen(), textScale: 1.3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
