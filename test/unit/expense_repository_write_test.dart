import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/repositories/expense_repository.dart';
import 'package:chi_tieu/data/repositories/expense_row_writer.dart';
import 'package:chi_tieu/data/repositories/supabase_storage_service.dart';

/// Storage path thật có segment đầu là id người dùng dạng UUID.
const String u = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

class _FakeStorage extends SupabaseStorageService {
  final List<String> uploads = [];
  final List<String> deleted = [];
  final Map<String, String> signed;

  _FakeStorage({this.signed = const {}});

  @override
  Future<String> uploadReceiptImage(String localFilePath) async {
    uploads.add(localFilePath);
    return '$u/${localFilePath.split('/').last}';
  }

  @override
  Future<void> deleteByPath(String storagePath) async {
    deleted.add(storagePath);
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
}

class _RecordingWriter implements ExpenseRowWriter {
  Map<String, dynamic>? inserted;
  Map<String, dynamic>? updated;
  int? updatedId;

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

    expect(
      () => repository.saveExpense(
        expenseId: null,
        imageSource: image,
        values: {'caption': 'A', 'amount': 1000},
      ),
      throwsStateError,
    );
    await Future<void>.delayed(Duration.zero);
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
}

class _BrokenStorage extends SupabaseStorageService {
  @override
  Future<Map<String, String>> signPaths(
    List<String> paths, {
    int expiresIn = SupabaseStorageService.signedUrlTtlSeconds,
  }) async => throw StateError('offline');
}
