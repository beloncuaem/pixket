import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Build web compile sạch kể cả khi có `dart:io` (dart2js stub), nên thứ duy
/// nhất giữ cho app không crash trên trình duyệt là test cấu trúc này.
///
/// Allowlist là cơ chế thắt dần: nó khai những chỗ còn nợ. Một tệp đã được bọc
/// mà vẫn nằm trong allowlist cũng làm test đỏ, để không ai nợ thay cho không.
void main() {
  List<String> libFiles() => Directory('lib')
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => p.endsWith('.dart'))
      .toList();

  List<String> importing(List<String> files, List<String> needles) => [
    for (final path in files)
      if (needles.any((n) => File(path).readAsStringSync().contains(n))) path,
  ];

  void expectBoundary({
    required List<String> found,
    required Set<String> allowed,
    required String rule,
  }) {
    final violations = found
        .where((p) => !p.endsWith('_io.dart') && !allowed.contains(p))
        .toList();
    expect(violations, isEmpty, reason: '$rule: còn file chung chạm boundary ($violations).');
    final stale = allowed.where((p) => !found.contains(p)).toList();
    expect(stale, isEmpty, reason: '$rule: allowlist cũ, xóa $stale khỏi danh sách nợ.');
  }

  final files = libFiles();

  test('R1: dart:io chỉ trong *_io.dart', () {
    expectBoundary(
      found: importing(files, ["import 'dart:io'"]),
      // seam render mà Task 5 sở hữu: file duy nhất còn nợ dart:io sau Task 2,
      // allowlist chỉ rỗng khi Task 5 thay nó bằng ReceiptCacheImage.
      allowed: const <String>{'lib/widgets/pixel/pixel_receipt_image.dart'},
      rule: 'R1',
    );
  });

  test('R2: flutter_cache_manager và cached_network_image chỉ trong *_io.dart', () {
    expectBoundary(
      found: importing(files, [
        "package:flutter_cache_manager",
        "package:cached_network_image",
      ]),
      allowed: {
        'lib/app.dart',
        'lib/providers/expense_provider.dart',
        'lib/widgets/pixel/pixel_receipt_image.dart',
      },
      rule: 'R2',
    );
  });

  test('R3: gal, camera, flutter_local_notifications chỉ trong *_io.dart', () {
    expectBoundary(
      found: importing(files, [
        "package:gal/gal.dart",
        "package:camera/camera.dart",
        "package:flutter_local_notifications",
      ]),
      allowed: {
        'lib/core/services/notification_service.dart',
        'lib/core/utils/save_to_gallery.dart',
      },
      rule: 'R3',
    );
  });
}
