import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/rainbow_rule.dart';

import '../support/memory_settings.dart';

Widget _host({bool disableAnimations = false}) => ProviderScope(
  overrides: [
    effectsProvider.overrideWith(
      (ref) => EffectSettingsNotifier(repository: MemorySettingsRepository()),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
        ),
        child: const Scaffold(body: RainbowRule()),
      ),
    ),
  ),
);

void main() {
  testWidgets('cao đúng 5 px, chạy MỘT lượt 1,6 s rồi tĩnh', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(tester.getSize(find.byType(RainbowRule)).height, 5);
    expect(tester.binding.hasScheduledFrame, isTrue);

    // Nếu dải loop vô hạn thì pumpAndSettle timeout ở đây — đó là lỗi, không
    // phải lý do để đổi sang tester.pump() cố định.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('disableAnimations thì dải tĩnh ngay', (tester) async {
    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
