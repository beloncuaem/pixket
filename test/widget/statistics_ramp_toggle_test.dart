import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_share_bar.dart';

import '../support/memory_settings.dart';

/// Widget probe: đọc khoá y như `statistics_charts.dart` rồi truyền xuống
/// `PixelShareBar`, để test khoá mà không phải fake cả statisticsProvider.
class RampProbe extends ConsumerWidget {
  const RampProbe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(effectsProvider).chartSpendRamp;
    return PixelShareBar(
      label: 'Ăn uống',
      glyph: 'coffee',
      value: 80,
      total: 100,
      valueText: '80.000₫',
      useSpendRamp: on,
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

void main() {
  testWidgets('khoá bật thì tô ramp và in nhãn chữ', (tester) async {
    await tester.pumpWidget(_host(MemorySettingsRepository()));
    await tester.pump();
    // t = 80/100 → bậc 3 → rose + nhãn 'Vượt mức' (màu không mang nghĩa một mình).
    expect(
      find.byWidgetPredicate(
        (w) => w is Container && w.color == AppPalette.light.rampFill(0.8),
      ),
      findsWidgets,
    );
    expect(find.text('Vượt mức'), findsOneWidget);
  });

  testWidgets('khoá chart_spend_ramp tắt thì về accent danh mục', (
    tester,
  ) async {
    final repo = MemorySettingsRepository()
      ..store['chart_spend_ramp'] = 'false';
    await tester.pumpWidget(_host(repo));
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.color == AppPalette.light.accentForCategory('Ăn uống'),
      ),
      findsWidgets,
    );
    expect(find.text('Vượt mức'), findsNothing);
  });
}
