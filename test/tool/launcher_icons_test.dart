// Sinh ic_launcher.png cho năm mật độ Android và icon thương hiệu 1024 từ chính
// lưới logo, không thêm dependency. Mặc định skip để `flutter test` trong CI
// không ghi đè file.
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
/// là một số nguyên pixel và không phải resample. `brand` là icon 1024 cho tài
/// liệu thương hiệu: lưới nội suy theo tỉ lệ nên cell lẻ chỉ làm nét mượt hơn.
const _targets = <String, ({int px, String path})>{
  'mdpi': (
    px: 48,
    path: 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
  ),
  'hdpi': (
    px: 72,
    path: 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
  ),
  'xhdpi': (
    px: 96,
    path: 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
  ),
  'xxhdpi': (
    px: 144,
    path: 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
  ),
  'xxxhdpi': (
    px: 192,
    path: 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  ),
  'brand': (px: 1024, path: 'docs/brand/pixket_icon_1024.png'),
};

void main() {
  final enabled = Platform.environment['PIXKET_GEN_ICONS'] == '1';

  testWidgets(
    'ghi icon launcher năm mật độ và icon thương hiệu 1024',
    (tester) async {
      // Nền canvas dark vì sao `*` chỉ vẽ trên theme tối; launcher giữ cầu sao.
      final palette = AppPalette.dark;

      // Cửa sổ test mặc định 800×600 sẽ bóp icon 1024 xuống 800 ô; nới surface
      // ra bằng cỡ lớn nhất để mỗi SizedBox giữ đúng px×px.
      await tester.binding.setSurfaceSize(const Size.square(1024));

      for (final entry in _targets.entries) {
        final px = entry.value.px;
        final key = GlobalObjectKey(entry.key);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              extensions: [palette],
            ),
            // Center để RepaintBoundary nhận constraint lỏng và ôm đúng px×px;
            // nếu không nó bị route ép thành 800×600 của test window.
            home: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox.square(
                  dimension: px.toDouble(),
                  child: ColoredBox(
                    color: palette.canvas,
                    child: PixelLogo(size: px.toDouble()),
                  ),
                ),
              ),
            ),
          ),
        );

        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );

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
        final path = entry.value.path;
        await tester.binding.runAsync(
          () => File(path).writeAsBytes(png!, flush: true),
        );
        debugPrint('đã ghi $path (${px}x$px)');
      }
    },
    // testWidgets chỉ nhận skip dạng bool nên không kèm lý do; xem header.
    skip: !enabled,
  );
}
