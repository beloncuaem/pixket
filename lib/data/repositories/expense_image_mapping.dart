import '../../core/utils/storage_paths.dart';
import '../models/expense.dart';

/// Danh sách path cần ký URL cho một trang khoản chi.
List<String> storagePathsOf(List<Expense> expenses) => [
  for (final expense in expenses)
    if (storagePathOf(expense.imagePath) case final path?) path,
];

/// Bản sao Expense kèm signed URL; phần tử không có URL giữ nguyên hiển thị trống.
List<Expense> attachSignedUrls(
  List<Expense> expenses,
  Map<String, String> signedByPath,
) => [
  for (final expense in expenses)
    expense.copyWith(
      displayImageUrl: signedByPath[storagePathOf(expense.imagePath)],
    ),
];
