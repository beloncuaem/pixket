import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/mosaic_wipe.dart';

Widget _host(Object key, {bool enabled = true}) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: MosaicWipe(
      transitionKey: key,
      enabled: enabled,
      child: Center(child: Text('key-$key')),
    ),
  ),
);

void main() {
  testWidgets('đổi key thì lật lưới rồi mới thay con', (tester) async {
    await tester.pumpWidget(_host('a'));
    expect(find.text('key-a'), findsOneWidget);

    await tester.pumpWidget(_host('b'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(const ValueKey('mosaic-wipe')), findsOneWidget);
    expect(find.text('key-a'), findsOneWidget, reason: 'chưa tới điểm đổi');

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('key-b'), findsOneWidget, reason: 'đổi ở giữa lượt lật');

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('mosaic-wipe')), findsNothing);
  });

  testWidgets('enabled false đổi ngay, không lưới', (tester) async {
    await tester.pumpWidget(_host('a', enabled: false));
    await tester.pumpWidget(_host('b', enabled: false));
    await tester.pump();
    expect(find.text('key-b'), findsOneWidget);
    expect(find.byKey(const ValueKey('mosaic-wipe')), findsNothing);
  });
}
