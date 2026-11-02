import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_palette.dart';

void main() {
  for (final palette in [AppPalette.light, AppPalette.dark]) {
    final name = palette == AppPalette.light ? 'light' : 'dark';

    group('spendBand $name', () {
      test('bậc 0 dưới 0.25', () {
        expect(palette.spendBand(0), 0);
        expect(palette.spendBand(0.249), 0);
        expect(palette.spendBand(0.1), 0);
      });

      test('bậc 1 từ 0.25 đến dưới 0.5', () {
        expect(palette.spendBand(0.25), 1);
        expect(palette.spendBand(0.499), 1);
      });

      test('bậc 2 từ 0.5 đến dưới 0.75', () {
        expect(palette.spendBand(0.5), 2);
        expect(palette.spendBand(0.749), 2);
      });

      test('bậc 3 từ 0.75 trở lên, kể cả vượt mốc', () {
        expect(palette.spendBand(0.75), 3);
        expect(palette.spendBand(1), 3);
        expect(palette.spendBand(1.4), 3);
      });

      test('t âm về bậc 0', () {
        expect(palette.spendBand(-0.5), 0);
        expect(palette.spendBand(-100), 0);
      });

      test('NaN (kỳ rỗng 0/0) về bậc 0, không tô đỏ oan', () {
        expect(palette.spendBand(double.nan), 0);
        expect(palette.rampLabel(double.nan), 'Thấp');
      });

      test('rampFill và rampInk đi theo đúng bậc', () {
        expect(palette.rampFill(0), palette.sky);
        expect(palette.rampFill(0.3), palette.mint);
        expect(palette.rampFill(0.6), palette.butter);
        expect(palette.rampFill(0.9), palette.rose);

        expect(palette.rampInk(0), palette.skyInk);
        expect(palette.rampInk(0.3), palette.mintInk);
        expect(palette.rampInk(0.6), palette.butterInk);
        expect(palette.rampInk(0.9), palette.roseInk);
      });

      test('rampLabel là tiếng Việt và đủ 4 bậc phân biệt', () {
        final labels = [
          palette.rampLabel(0),
          palette.rampLabel(0.3),
          palette.rampLabel(0.6),
          palette.rampLabel(0.9),
        ];
        expect(labels, ['Thấp', 'Vừa', 'Cao', 'Vượt mức']);
        expect(labels.toSet().length, 4);
      });
    });
  }
}
