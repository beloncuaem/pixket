import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/rainbow_sweep.dart';

import '../support/memory_settings.dart';

Widget _host(MemorySettingsRepository repo, VoidCallback onCovered) =>
    ProviderScope(
      overrides: [
        effectsProvider.overrideWith(
          (ref) => EffectSettingsNotifier(repository: repo),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              // effectsProvider tạo trễ: phải watch để khoá đã lưu được nạp
              // trước khi chạm, như trên app thật (MainScreen watch sẵn).
              ref.watch(effectsProvider);
              return ElevatedButton(
                onPressed: () =>
                    RainbowSweep.play(context, onCovered: onCovered),
                child: const Text('PLAY'),
              );
            },
          ),
        ),
      ),
    );

void main() {
  testWidgets('onCovered chạy một lần ở bậc 4-5, overlay gỡ sau 740 ms', (
    tester,
  ) async {
    var covered = 0;
    await tester.pumpWidget(_host(MemorySettingsRepository(), () => covered++));
    await tester.tap(find.text('PLAY'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 200));
    expect(covered, 0, reason: 'chưa tới bậc che kín');
    await tester.pump(const Duration(milliseconds: 100));
    expect(covered, 1, reason: 'bậc 4 bắt đầu ở 246 ms');
    expect(find.byKey(const ValueKey('rainbow-sweep')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(covered, 1, reason: 'không gọi lần hai');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('rainbow-sweep')), findsNothing);
  });

  testWidgets('khoá tắt thì không vẽ nhưng vẫn gọi onCovered một lần', (
    tester,
  ) async {
    final repo = MemorySettingsRepository()..store['fx_capture_sweep'] = 'false';
    var covered = 0;
    await tester.pumpWidget(_host(repo, () => covered++));
    await tester.tap(find.text('PLAY'));
    await tester.pump();
    expect(covered, 1);
    expect(find.byKey(const ValueKey('rainbow-sweep')), findsNothing);
  });
}
