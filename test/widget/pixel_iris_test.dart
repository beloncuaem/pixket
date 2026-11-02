import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_iris.dart';

Finder _iris() => find.byKey(const ValueKey('pixel-iris'));

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
  testWidgets('onCovered chạy đúng một lần lúc iris khép kín', (tester) async {
    var covered = 0;
    await tester.pumpWidget(
      _host(
        onPressed: (context) =>
            PixelIris.play(context, onCovered: () => covered++),
      ),
    );

    await tester.tap(find.text('chụp'));
    await tester.pump();
    expect(_iris(), findsOneWidget);
    expect(covered, 0, reason: 'chưa khép kín thì chưa đổi cảnh');

    // Nửa đầu 260 ms là lượt khép: mốc 130 ms là lúc che kín.
    await tester.pump(const Duration(milliseconds: 130));
    expect(covered, 1);

    await tester.pumpAndSettle();
    expect(covered, 1, reason: 'không gọi lại lần hai');
    expect(_iris(), findsNothing, reason: 'overlay phải tự gỡ');
  });

  testWidgets('reduced motion vẫn mở form và gỡ overlay', (tester) async {
    var covered = 0;
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        onPressed: (context) =>
            PixelIris.play(context, onCovered: () => covered++),
      ),
    );

    await tester.tap(find.text('chụp'));
    await tester.pumpAndSettle();

    expect(covered, 1);
    expect(_iris(), findsNothing);
  });

  testWidgets('overlay iris không chặn chạm', (tester) async {
    await tester.pumpWidget(
      _host(onPressed: (context) => PixelIris.play(context, onCovered: () {})),
    );

    await tester.tap(find.text('chụp'));
    await tester.pump();

    expect(
      find.ancestor(of: _iris(), matching: find.byType(IgnorePointer)),
      findsOneWidget,
    );
  });
}
