import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';
import 'package:pixket/widgets/pixel/rainbow_rule.dart';

import '../support/memory_settings.dart';

void main() {
  testWidgets('header luôn kèm RainbowRule', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        effectsProvider.overrideWith(
          (ref) =>
              EffectSettingsNotifier(repository: MemorySettingsRepository()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: PixelScreenHeader(title: 'THỬ')),
      ),
    ));
    await tester.pump();
    expect(find.byType(RainbowRule), findsOneWidget);
  });
}
