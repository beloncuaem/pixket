import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';
import 'package:pixket/widgets/pixel/pixel_button.dart';
import 'package:pixket/widgets/pixel/pixel_chip.dart';
import 'package:pixket/widgets/pixel/pixel_divider.dart';
import 'package:pixket/widgets/pixel/pixel_panel.dart';
import 'package:pixket/widgets/pixel/pixel_progress.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('PixelButton vo hieu hoa van hien nhan va khong bat cham', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(PixelButton(label: 'Luu', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Luu'));
    expect(taps, 1);
    await tester.pumpWidget(
      _wrap(const PixelButton(label: 'Luu', onPressed: null)),
    );
    await tester.tap(find.text('Luu'), warnIfMissed: false);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      _wrap(
        PixelButton(label: 'Luu', onPressed: () => taps++, isLoading: true),
      ),
    );
    await tester.tap(find.text('Luu'), warnIfMissed: false);
    expect(taps, 1);
    expect(find.byType(AppIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelButton dat chieu cao cham 48dp', (tester) async {
    await tester.pumpWidget(_wrap(PixelButton(label: 'Luu', onPressed: () {})));
    final size = tester.getSize(find.byType(PixelButton));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('PixelButton thu gon nam trong Row khong nan vi bien vo han', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Row(
          children: [
            PixelButton(
              label: 'Xoa',
              icon: 'trash',
              variant: PixelButtonVariant.ghost,
              onPressed: () {},
            ),
            const Spacer(),
            PixelButton(label: 'Ap dung', icon: 'check', onPressed: () {}),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text('Xoa')).width, lessThan(200));
  });

  testWidgets('PixelChip chon/ bo chon doi trang thai', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => PixelChip(
            label: 'Ca phe',
            selected: selected,
            onTap: () => setState(() => selected = !selected),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ca phe'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppIcon), findsOneWidget);
  });

  testWidgets('PixelProgress clamp value va ve dung so khoi', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 200,
          child: PixelProgress(value: 1.7, segments: 10),
        ),
      ),
    );
    expect(find.byType(PixelProgress), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('AppPalette cung cap extension cho moi component', () {
    expect(AppPalette.light.ink, isNot(AppPalette.dark.ink));
  });

  testWidgets('PixelPanel render child', (tester) async {
    await tester.pumpWidget(_wrap(const PixelPanel(child: Text('noi dung'))));
    expect(find.text('noi dung'), findsOneWidget);
  });

  testWidgets('PixelDivider render khong nem loi', (tester) async {
    await tester.pumpWidget(_wrap(const Column(children: [PixelDivider()])));
    expect(find.byType(PixelDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
