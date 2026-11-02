/// Tiện ích thuần về đường dẫn ảnh hóa đơn trong Supabase Storage.
/// Không chạm mạng, không phụ thuộc model khác nên unit test được.
library;

const String receiptBucket = 'expense-receipts';

/// Path dạng `<uuid>/tên_tệp`; uuid là id người dùng nên không nhầm với tệp cục bộ.
final RegExp _storedPathPattern = RegExp(r'^[0-9a-fA-F][0-9a-fA-F-]{34,35}/.+');

/// Suy ra path object từ giá trị đang lưu: path chuẩn, public URL legacy,
/// signed URL. Trả null nếu là ảnh cục bộ hoặc giá trị không hợp lệ.
String? storagePathOf(String? storedValue) {
  final value = storedValue?.trim();
  if (value == null || value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(receiptBucket);
    if (bucketIndex < 0 || bucketIndex == segments.length - 1) return null;
    return segments.sublist(bucketIndex + 1).join('/');
  }

  return _storedPathPattern.hasMatch(value) ? value : null;
}

/// Chia danh sách thành các lô tối đa `size` phần tử, giữ nguyên thứ tự.
List<List<T>> chunkList<T>(List<T> items, {int size = 50}) {
  if (items.isEmpty) return const [];
  final chunkSize = size < 1 ? 1 : size;
  final result = <List<T>>[];
  for (var start = 0; start < items.length; start += chunkSize) {
    final end = start + chunkSize > items.length
        ? items.length
        : start + chunkSize;
    result.add(items.sublist(start, end));
  }
  return result;
}

typedef SignedUrlSigner = Future<Map<String, String>> Function(
  List<String> batch,
);

/// Ký URL cho từng lô, khử trùng trước khi gọi signer.
Future<Map<String, String>> signPathsInChunks(
  Iterable<String> paths, {
  required SignedUrlSigner signer,
  int chunkSize = 50,
}) async {
  final unique = paths
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toSet()
      .toList();

  final result = <String, String>{};
  for (final batch in chunkList(unique, size: chunkSize)) {
    result.addAll(await signer(batch));
  }
  return result;
}
