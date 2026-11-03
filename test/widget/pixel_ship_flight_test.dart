import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_ship_flight.dart';

Finder _ship() => find.byKey(const ValueKey('pixel-ship-flight'));

Widget _host({
  required void Function(BuildContext) onPressed,
  bool disableAnimations = false,
}) => MaterialApp(
  theme: AppTheme.dark,
  // Cờ phải áp dụng cho cả overlay nên đặt ở `builder` của MaterialApp.
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => onPressed(context),
          child: const Text('chụp'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('phi thuyền bay qua màn hình rồi tự gỡ overlay', (tester) async {
    await tester.pumpWidget(_host(onPressed: PixelShipFlight.launch));

    await tester.tap(find.text('chụp'));
    await tester.pump();
    expect(_ship(), findsOneWidget);

    // Giữa lượt bay 700 ms vẫn còn trên màn hình.
    await tester.pump(const Duration(milliseconds: 350));
    expect(_ship(), findsOneWidget);

    await tester.pumpAndSettle();
    expect(_ship(), findsNothing, reason: 'overlay phải tự gỡ');
  });

  testWidgets('reduced motion không bật hiệu ứng bay', (tester) async {
    await tester.pumpWidget(
      _host(disableAnimations: true, onPressed: PixelShipFlight.launch),
    );

    await tester.tap(find.text('chụp'));
    await tester.pumpAndSettle();

    expect(_ship(), findsNothing);
  });

  testWidgets('overlay không chặn chạm và có RepaintBoundary', (tester) async {
    await tester.pumpWidget(_host(onPressed: PixelShipFlight.launch));

    await tester.tap(find.text('chụp'));
    await tester.pump();

    expect(
      find.ancestor(of: _ship(), matching: find.byType(IgnorePointer)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: _ship(), matching: find.byType(RepaintBoundary)),
      findsWidgets,
    );
  });
}
