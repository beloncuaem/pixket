// Sinh ic_launcher.png cho năm mật độ Android từ chính lưới logo, không thêm
// dependency. Mặc định skip để `flutter test` trong CI không ghi đè file.
// Chạy: PIXKET_GEN_ICONS=1 flutter test test/tool/launcher_icons_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/widgets/pixel/pixel_logo.dart';

/// Cỡ mipmap chuẩn của Android; tất cả đều chia hết cho lưới 24 nên mỗi cell
/// là một số nguyên pixel và không phải resample.
const _densities = <String, int>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

void main() {
  final enabled = Platform.environment['PIXKET_GEN_ICONS'] == '1';

  testWidgets('ghi ic_launcher.png cho năm mật độ', (tester) async {
    // Spec §3: mark mono mực #DCEBFF trên nền #0E2A4F. Cả hai đều là token
    // dark (lineStrong / canvas) nên không hardcode màu ở đây.
    final palette = AppPalette.dark.copyWith(ink: AppPalette.dark.lineStrong);

    for (final entry in _densities.entries) {
      final px = entry.value;
      final key = GlobalObjectKey(entry.key);

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, extensions: [palette]),
        // Center để RepaintBoundary nhận constraint lỏng và ôm đúng px×px;
        // nếu không nó bị route ép thành 800×600 của test window.
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox.square(
              dimension: px.toDouble(),
              child: ColoredBox(
                color: palette.canvas,
                child: PixelLogo(size: px.toDouble(), mono: true),
              ),
            ),
          ),
        ),
      ));

      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));

      // Mã hoá PNG và ghi file là async thật; FakeAsync của testWidgets sẽ treo
      // vĩnh viễn nếu không thoát ra bằng runAsync.
      final png = await tester.binding.runAsync<Uint8List?>(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        expect(image.width, px, reason: '${entry.key} sai chiều rộng');
        expect(image.height, px, reason: '${entry.key} sai chiều cao');
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return bytes?.buffer.asUint8List();
      });

      expect(png, isNotNull, reason: '${entry.key} không mã hoá được PNG');
      final path =
          'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png';
      await tester.binding.runAsync(
        () => File(path).writeAsBytes(png!, flush: true),
      );
      debugPrint('đã ghi $path (${px}x$px)');
    }
  },
      // testWidgets chỉ nhận skip dạng bool nên không kèm lý do; xem header.
      skip: !enabled);
}
