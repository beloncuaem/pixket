import '../../core/constants/app_strings.dart';

class Expense {
  final int? id;
  final String? imagePath;

  /// Signed URL chỉ dùng để hiển thị trong phiên hiện tại; không lưu vào DB.
  final String? displayImageUrl;
  final String caption;
  final double amount;
  final int categoryId;
  final int priority; // 0, 1, 2, 3
  final DateTime createdAt;
  final DateTime? deletedAt;

  Expense({
    this.id,
    this.imagePath,
    this.displayImageUrl,
    required this.caption,
    required this.amount,
    required this.categoryId,
    this.priority = 0,
    required this.createdAt,
    this.deletedAt,
  });

  DateTime get dateTime => createdAt;
  DateTime get date => createdAt;
  bool get isDeleted => deletedAt != null;

  String get priorityLabel {
    if (priority >= 0 && priority < AppStrings.priorityLabels.length) {
      return AppStrings.priorityLabels[priority];
    }
    return '';
  }

  Expense copyWith({
    int? id,
    String? imagePath,
    String? displayImageUrl,
    String? caption,
    double? amount,
    int? categoryId,
    int? priority,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      displayImageUrl: displayImageUrl ?? this.displayImageUrl,
      caption: caption ?? this.caption,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'image_path': imagePath,
      'caption': caption,
      'amount': amount,
      'category_id': categoryId,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String?,
      caption: map['caption'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      priority: map['priority'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String),
    );
  }
}
