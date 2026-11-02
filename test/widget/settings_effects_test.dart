import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/providers/theme_provider.dart';
import 'package:pixket/screens/settings/settings_screen.dart';

import '../support/memory_settings.dart';

// Cùng khuôn fake với test/widget/trash_settings_pixel_test.dart: SettingsScreen
// watch authProvider + themeProvider, cả hai đều chạm DB nếu để thật.
// effectsProvider cũng phải override: notifier thật gọi AppSettingsRepository
// (sqflite) ngay trong constructor → MissingPluginException khi test.
class _FakeAuth extends StateNotifier<AppAuthState> implements AuthNotifier {
  _FakeAuth() : super(const AppAuthState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTheme extends StateNotifier<ThemeMode> implements ThemeNotifier {
  _FakeTheme() : super(ThemeMode.light);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Text _chipLabel(WidgetTester tester, String key) =>
    tester.widgetList<Text>(find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(Text),
    )).single;

void main() {
  testWidgets('6 khoá hiệu ứng đọc/ghi qua provider', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuth()),
        themeProvider.overrideWith((ref) => _FakeTheme()),
        effectsProvider.overrideWith(
          (ref) =>
              EffectSettingsNotifier(repository: MemorySettingsRepository()),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('GIAO DIỆN & HIỆU ỨNG'), findsOneWidget);
    for (final label in [
      'Nền sao (chế độ tối)',
      'Vệt cầu vồng dưới header',
      'Cầu vồng quét khi chụp',
      'Pháo giấy khi lưu',
      'Lật mosaic khi đổi mục',
      'Biểu đồ tô theo mức chi',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'thiếu khoá $label');
    }

    // mosaic mặc định TẮT, năm khoá còn lại BẬT.
    expect(_chipLabel(tester, 'fx_mosaic').data, 'TẮT');
    expect(_chipLabel(tester, 'fx_stars').data, 'BẬT');

    await tester.ensureVisible(find.byKey(const ValueKey('fx_mosaic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fx_mosaic')));
    await tester.pumpAndSettle();
    expect(_chipLabel(tester, 'fx_mosaic').data, 'BẬT');
  });
}
