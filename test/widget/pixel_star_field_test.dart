import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_star_field.dart';

Widget _host({bool dark = true, bool disableAnimations = false}) =>
    ProviderScope(
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        // Builder + copyWith: `MediaQueryData(...)` dựng mới sẽ thay toàn bộ
        // MediaQuery (size/brightness/padding về mặc định). Chỉ sửa một cờ thì
        // dùng copyWith trên MediaQuery kế thừa.
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: disableAnimations),
            child: const Scaffold(
              body: SizedBox.expand(child: PixelStarField()),
            ),
          ),
        ),
      ),
    );

Finder _paint() => find.descendant(
  of: find.byType(PixelStarField),
  matching: find.byType(CustomPaint),
);

void main() {
  test('cùng seed ra cùng vị trí sao', () {
    const size = Size(360, 640);
    final a = buildStarField(size);
    final b = buildStarField(size);
    expect(a, isNotEmpty);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].x, b[i].x);
      expect(a[i].y, b[i].y);
      expect(a[i].cell, b[i].cell);
      expect(a[i].accent, b[i].accent);
      expect(a[i].tinted, b[i].tinted);
    }
  });

  test('một phần nhỏ sao mang màu accent và đủ cả sáu màu', () {
    final stars = buildStarField(const Size(1200, 1600));
    final accented = stars.where((star) => star.accent >= 0).toList();
    expect(accented.length / stars.length, closeTo(0.08, 0.05));
    expect(accented.map((star) => star.accent).toSet(), {0, 1, 2, 3, 4, 5});
    // Sao accent đã có màu riêng nên không nhuốm thêm màu star.
    expect(accented.where((star) => star.tinted), isEmpty);
  });

  test('mật độ 1 ô / 2200 px2, chặn trần 220 ô', () {
    expect(
      buildStarField(const Size(360, 640)).length,
      (360 * 640 / 2200).round(),
    );
    expect(buildStarField(const Size(1200, 1600)).length, 220);
  });

  test('keep-out nở thêm 4 px', () {
    const rect = Rect.fromLTWH(10, 10, 20, 20);
    expect(starKeptOut(const Offset(31, 20), [rect]), isTrue);
    expect(starKeptOut(const Offset(35, 20), [rect]), isFalse);
  });

  testWidgets('theme light không vẽ sao', (tester) async {
    await tester.pumpWidget(_host(dark: false));
    await tester.pump();
    expect(_paint(), findsNothing);
  });

  testWidgets('disableAnimations thì không còn controller chạy', (
    tester,
  ) async {
    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump();
    expect(_paint(), findsOneWidget, reason: 'sao vẫn vẽ, chỉ ngưng nhấp nháy');
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('dark vẽ sao và nhấp nháy', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(_paint(), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);
  });
}
