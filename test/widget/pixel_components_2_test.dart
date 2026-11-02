import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_badge.dart';
import 'package:pixket/widgets/pixel/pixel_empty_state.dart';
import 'package:pixket/widgets/pixel/pixel_loading.dart';
import 'package:pixket/widgets/pixel/pixel_segmented.dart';
import 'package:pixket/widgets/pixel/pixel_snack_bar.dart';
import 'package:pixket/widgets/pixel/pixel_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('PixelTextField hiện label và lỗi dưới field', (tester) async {
    final controller = TextEditingController(text: 'abc');
    await tester.pumpWidget(
      _wrap(
        PixelTextField(
          label: 'Mô tả',
          controller: controller,
          errorText: 'Không được để trống',
        ),
      ),
    );
    expect(find.text('Mô tả'), findsOneWidget);
    expect(find.text('Không được để trống'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelTextField obscureToggle đổi glyph eye', (tester) async {
    await tester.pumpWidget(
      _wrap(const PixelTextField(label: 'Mật khẩu', obscureToggle: true)),
    );
    final toggle = find.byKey(const ValueKey('pixel-obscure-toggle'));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('showPixelSnackBar hiển thị action', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    showPixelSnackBar(
      ctx,
      'Đã xóa khoản chi',
      actionLabel: 'Hoàn tác',
      onAction: () {},
    );
    await tester.pump();
    expect(find.text('Đã xóa khoản chi'), findsOneWidget);
    expect(find.text('Hoàn tác'), findsOneWidget);
  });

  testWidgets('PixelSegmented chọn đúng item', (tester) async {
    var selected = 'week';
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => PixelSegmented<String>(
            items: const [
              PixelSegmentItem(value: 'day', label: 'NGÀY'),
              PixelSegmentItem(value: 'week', label: 'TUẦN'),
              PixelSegmentItem(value: 'month', label: 'THÁNG'),
            ],
            selected: selected,
            onChanged: (v) => setState(() => selected = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('THÁNG'));
    await tester.pump();
    expect(selected, 'month');
  });

  testWidgets('PixelEmptyState có title, message và CTA', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        PixelEmptyState(
          glyph: 'receipt',
          title: 'CHƯA CÓ KHOẢN CHI',
          message: 'Mở camera và chụp khoản chi đầu tiên.',
          actionLabel: 'Mở camera',
          onAction: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Mở camera'));
    expect(taps, 1);
  });

  testWidgets('PixelLoading và PixelBadge render', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            PixelLoading(),
            PixelBadge(glyph: 'coffee', label: 'Cà phê'),
          ],
        ),
      ),
    );
    expect(find.byType(PixelLoading), findsOneWidget);
    expect(find.text('Cà phê'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
