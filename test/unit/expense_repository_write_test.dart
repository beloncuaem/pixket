import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

import 'package:pixket/core/utils/square_image.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/data/repositories/expense_repository.dart';
import 'package:pixket/data/repositories/expense_row_writer.dart';
import 'package:pixket/data/repositories/supabase_storage_service.dart';

/// Storage path thật có segment đầu là id người dùng dạng UUID.
const String u = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

class _FakeStorage extends SupabaseStorageService {
  static const String squarePath = '$u/migrated_sq.jpg';

  final List<String> uploads = [];
  final List<String> deleted = [];
  final List<String> squareUploads = [];
  final Map<String, String> signed;

  _FakeStorage({this.signed = const {}});

  @override
  Future<String> uploadReceiptImage(String localFilePath) async {
    uploads.add(localFilePath);
    return '$u/${localFilePath.split('/').last}';
  }

  @override
  Future<String> uploadSquareBytes(
    Uint8List bytes, {
    required String legacyPath,
  }) async {
    squareUploads.add(legacyPath);
    return squarePath;
  }

  @override
  Future<void> deleteByPath(String storagePath) async {
    deleted.add(storagePath);
  }

  @override
  Future<void> deletePaths(List<String> storagePaths) async {
    deleted.addAll(storagePaths);
  }

  @override
  Future<Map<String, String>> signPaths(
    List<String> paths, {
    int expiresIn = SupabaseStorageService.signedUrlTtlSeconds,
  }) async => {for (final p in paths) p: signed[p] ?? 'https://signed/$p'};
}

class _ThrowingWriter implements ExpenseRowWriter {
  @override
  String currentUserId() => u;

  @override
  Future<int> insert(Map<String, dynamic> values) async =>
      throw StateError('db down');

  @override
  Future<void> update(int id, Map<String, dynamic> values) async =>
      throw StateError('db down');

  @override
  Future<void> repointImage(String oldPath, String newPath) async =>
      throw StateError('db down');
}

class _RecordingWriter implements ExpenseRowWriter {
  Map<String, dynamic>? inserted;
  Map<String, dynamic>? updated;
  int? updatedId;
  final Map<String, String> repointed = {};

  @override
  String currentUserId() => u;

  @override
  Future<int> insert(Map<String, dynamic> values) async {
    inserted = values;
    return 77;
  }

  @override
  Future<void> update(int id, Map<String, dynamic> values) async {
    updatedId = id;
    updated = values;
  }

  @override
  Future<void> repointImage(String oldPath, String newPath) async {
    repointed[oldPath] = newPath;
  }
}

void main() {
  late _FakeStorage storage;
  late Directory tempDir;

  setUp(() async {
    storage = _FakeStorage();
    tempDir = await Directory.systemTemp.createTemp('ct_img');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<String> fakeImage() async {
    final file = File('${tempDir.path}/IMG_1.jpg');
    await file.writeAsBytes([1, 2, 3]);
    return file.path;
  }

  test('upload lỗi DB thì dọn ảnh vừa tải lên', () async {
    final image = await fakeImage();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: _ThrowingWriter(),
    );

    await expectLater(
      repository.saveExpense(
        expenseId: null,
        imageSource: image,
        values: {'caption': 'A', 'amount': 1000},
      ),
      throwsStateError,
    );
    expect(storage.uploads, [image]);
    expect(storage.deleted, ['$u/IMG_1.jpg']);
  });

  test('insert lưu path thay vì URL và không xóa ảnh cũ', () async {
    final image = await fakeImage();
    final writer = _RecordingWriter();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: writer,
    );

    final id = await repository.saveExpense(
      expenseId: null,
      imageSource: image,
      values: {'caption': 'A'},
    );

    expect(id, 77);
    expect(writer.inserted?['image_url'], '$u/IMG_1.jpg');
    expect(storage.deleted, isEmpty);
  });

  test('giá trị legacy URL được chuẩn hóa về path khi update', () async {
    final writer = _RecordingWriter();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: writer,
    );

    await repository.saveExpense(
      expenseId: 5,
      imageSource:
          'https://x.supabase.co/storage/v1/object/public/expense-receipts/$u/old.jpg',
      values: {'caption': 'B'},
    );

    expect(writer.updatedId, 5);
    expect(writer.updated?['image_url'], '$u/old.jpg');
    expect(storage.uploads, isEmpty);
  });

  test('thiếu ảnh khi đang có ảnh thì giữ nguyên dòng cũ', () async {
    final writer = _RecordingWriter();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: writer,
    );

    await repository.saveExpense(
      expenseId: 9,
      imageSource: null,
      values: {'caption': 'C', 'image_url': '$u/keep.jpg'},
    );

    expect(writer.updated?['image_url'], '$u/keep.jpg');
  });

  test('decorateWithSignedUrls gán URL cho cả dòng legacy', () async {
    final repository = ExpenseRepository(
      storageService: _FakeStorage(signed: {'$u/a.jpg': 'https://s/a'}),
      writer: _RecordingWriter(),
    );
    final rows = [
      Expense(
        caption: 'A',
        amount: 1,
        categoryId: 1,
        createdAt: DateTime(2026, 11, 1),
        imagePath: '$u/a.jpg',
      ),
    ];

    final decorated = await repository.decorateWithSignedUrls(rows);
    expect(decorated.single.displayImageUrl, 'https://s/a');
  });

  test('decorate không ném lỗi khi ký URL thất bại', () async {
    final repository = ExpenseRepository(
      storageService: _BrokenStorage(),
      writer: _RecordingWriter(),
    );
    final rows = [
      Expense(
        caption: 'A',
        amount: 1,
        categoryId: 1,
        createdAt: DateTime(2026, 11, 1),
        imagePath: '$u/a.jpg',
      ),
    ];

    final decorated = await repository.decorateWithSignedUrls(rows);
    expect(decorated.single.displayImageUrl, isNull);
  });

  test('migrateLegacyImages cắt, upload và repoint rồi trả path cũ', () async {
    final bytes = img.encodeJpg(img.Image(width: 1600, height: 900));
    final client = MockClient((_) async => http.Response.bytes(bytes, 200));
    final storage = _FakeStorage();
    final writer = _RecordingWriter();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: writer,
      httpClient: client,
    );

    final repointed = await repository.migrateLegacyImages({
      '$u/a.jpg': 'https://signed/a',
    });

    expect(repointed, ['$u/a.jpg']);
    expect(storage.squareUploads, ['$u/a.jpg']);
    expect(writer.repointed, {'$u/a.jpg': _FakeStorage.squarePath});
    // Lần hai cùng một path: _migrationAttempted đã ghi nhớ nên không gọi lại.
    expect(
      await repository.migrateLegacyImages({'$u/a.jpg': 'https://signed/a'}),
      isEmpty,
    );
  });

  test('migrateLegacyImages bỏ qua ảnh đã vuông và ảnh tải lỗi', () async {
    final repository = ExpenseRepository(
      storageService: _FakeStorage(),
      writer: _RecordingWriter(),
      httpClient: MockClient(
        (_) async => http.Response.bytes(Uint8List.fromList([1, 2, 3]), 500),
      ),
    );

    expect(
      await repository.migrateLegacyImages({
        '$u/b_sq.jpg': 'https://signed/b',
        '$u/c.jpg': 'https://signed/c',
      }),
      isEmpty,
    );
  });

  test('writeSquareCopy đặt marker _sq cạnh tệp gốc', () async {
    final source = File('${tempDir.path}/IMG_2.jpg');
    await source.writeAsBytes(
      img.encodeJpg(img.Image(width: 1600, height: 900)),
    );

    final squared = await writeSquareCopy(source);

    expect(squared.path, endsWith(squareImageSuffix));
    expect(isSquareImagePath(squared.path), isTrue);
    expect(await squared.exists(), isTrue);
    // Ảnh đã vuông đi qua writeSquareCopy phải trả chính nó, không nén lần hai.
    expect(await writeSquareCopy(squared), same(squared));
  });
}

class _BrokenStorage extends SupabaseStorageService {
  @override
  Future<Map<String, String>> signPaths(
    List<String> paths, {
    int expiresIn = SupabaseStorageService.signedUrlTtlSeconds,
  }) async => throw StateError('offline');
}
