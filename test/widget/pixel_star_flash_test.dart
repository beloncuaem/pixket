import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_star_flash.dart';

Finder _flash() => find.byKey(const ValueKey('pixel-star-flash'));

Widget _host({
  required void Function(BuildContext) onPressed,
  bool disableAnimations = false,
}) => MaterialApp(
  theme: AppTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => onPressed(context),
          child: const Text('lưu'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('burst vẽ sao rồi tự gỡ overlay', (tester) async {
    await tester.pumpWidget(
      _host(onPressed: (context) => PixelStarFlash.burst(context)),
    );

    await tester.tap(find.text('lưu'));
    await tester.pump();
    expect(_flash(), findsOneWidget);

    await tester.pumpAndSettle();
    expect(_flash(), findsNothing, reason: 'hiệu ứng phải tự dọn');
  });

  testWidgets('nhận toạ độ tuỳ chọn và không chặn chạm', (tester) async {
    await tester.pumpWidget(
      _host(
        onPressed: (context) =>
            PixelStarFlash.burst(context, at: const Offset(120, 480)),
      ),
    );

    await tester.tap(find.text('lưu'));
    await tester.pump();

    expect(_flash(), findsOneWidget);
    expect(
      find.ancestor(of: _flash(), matching: find.byType(IgnorePointer)),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
    expect(_flash(), findsNothing);
  });

  testWidgets('reduced motion vẫn lóe rồi tắt', (tester) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        onPressed: (context) => PixelStarFlash.burst(context),
      ),
    );

    await tester.tap(find.text('lưu'));
    await tester.pump();
    expect(_flash(), findsOneWidget);

    await tester.pumpAndSettle();
    expect(_flash(), findsNothing);
  });
}
