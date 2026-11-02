import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_logo.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';

void main() {
  testWidgets('header có mark + tiêu đề và không còn dải cầu vồng động', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: PixelScreenHeader(title: 'THỬ')),
      ),
    );
    await tester.pump();

    expect(find.text('THỬ'), findsOneWidget);
    expect(find.byType(PixelLogo), findsOneWidget);
    // Dải cầu vồng cũ là animation lặp; header giờ phải hội tụ ngay.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('header có nút back thì không gắn mark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: PixelScreenHeader(title: 'THỬ', onBackTap: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PixelLogo), findsNothing);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
  });
}
