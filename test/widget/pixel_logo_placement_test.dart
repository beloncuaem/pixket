import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_logo.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';

import '../support/memory_settings.dart';

void _noop() {}

/// Header chứa RainbowRule (Consumer) nên bắt buộc có ProviderScope.
Widget _host(Widget header) => ProviderScope(
  overrides: [
    effectsProvider.overrideWith(
      (ref) => EffectSettingsNotifier(repository: MemorySettingsRepository()),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: header),
  ),
);

void main() {
  testWidgets('header cấp section có mark, header push thì không', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const PixelScreenHeader(title: 'A', onMenuTap: _noop)),
    );
    expect(find.byType(PixelLogo), findsOneWidget);

    await tester.pumpWidget(
      _host(const PixelScreenHeader(title: 'B', onBackTap: _noop)),
    );
    expect(find.byType(PixelLogo), findsNothing);
  });
}
