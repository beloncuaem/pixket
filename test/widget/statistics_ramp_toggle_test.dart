import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_bar_chart.dart';

import '../support/memory_settings.dart';

/// Widget probe: đọc khoá y như `statistics_charts.dart` rồi truyền xuống
/// `PixelBarChart`, để test khoá mà không phải fake cả statisticsProvider.
class RampProbe extends ConsumerWidget {
  const RampProbe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(effectsProvider).chartSpendRamp;
    return PixelBarChart(
      dates: [DateTime(2026, 11, 1), DateTime(2026, 11, 2)],
      values: const [80, 40],
      valueTexts: const ['80.000₫', '40.000₫'],
      reference: on ? 100 : null,
    );
  }
}

Widget _host(MemorySettingsRepository repo) => ProviderScope(
  overrides: [
    effectsProvider.overrideWith(
      (ref) => EffectSettingsNotifier(repository: repo),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: const Scaffold(body: RampProbe()),
  ),
);

List<Color?> _cellColors(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .where((c) => c.color != null)
    .map((c) => c.color)
    .toList();

void main() {
  testWidgets('khoá bật thì cột tô theo bậc mức chi', (tester) async {
    await tester.pumpWidget(_host(MemorySettingsRepository()));
    await tester.pump();
    // t = 80/100 → bậc 3 → rose; t = 40/100 → bậc 1 → mint.
    expect(_cellColors(tester), contains(AppPalette.light.rampFill(0.8)));
    expect(_cellColors(tester), contains(AppPalette.light.rampFill(0.4)));
  });

  testWidgets('khoá chart_spend_ramp tắt thì cột về một màu mint', (
    tester,
  ) async {
    final repo = MemorySettingsRepository()
      ..store['chart_spend_ramp'] = 'false';
    await tester.pumpWidget(_host(repo));
    await tester.pump();
    expect(_cellColors(tester), contains(AppPalette.light.mint));
    expect(_cellColors(tester), isNot(contains(AppPalette.light.rampFill(0.8))));
  });
}
