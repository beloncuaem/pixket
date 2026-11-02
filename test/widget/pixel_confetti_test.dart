import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_confetti.dart';

import '../support/memory_settings.dart';

Widget _host(MemorySettingsRepository repo) => ProviderScope(
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
          // effectsProvider tạo trễ: watch để khoá đã lưu được nạp trước khi chạm.
          ref.watch(effectsProvider);
          return ElevatedButton(
            onPressed: () => PixelConfetti.burst(context),
            child: const Text('BURST'),
          );
        },
      ),
    ),
  ),
);

void main() {
  testWidgets('burst vẽ một overlay rồi tự gỡ sau 480 ms', (tester) async {
    await tester.pumpWidget(_host(MemorySettingsRepository()));
    await tester.tap(find.text('BURST'));
    await tester.pump();
    expect(find.byKey(const ValueKey('pixel-confetti')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('pixel-confetti')), findsNothing);
  });

  testWidgets('khoá tắt thì không vẽ', (tester) async {
    final repo = MemorySettingsRepository()..store['fx_confetti'] = 'false';
    await tester.pumpWidget(_host(repo));
    await tester.tap(find.text('BURST'));
    await tester.pump();
    expect(find.byKey(const ValueKey('pixel-confetti')), findsNothing);
  });
}
