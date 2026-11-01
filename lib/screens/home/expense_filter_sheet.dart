import 'package:flutter/material.dart';

import '../../core/utils/amount_input_formatter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/category.dart';
import '../../data/models/priority_level.dart';

/// Bộ lọc khoản chi trên màn Tổng quan.
class ExpenseFilter {
  final String search;
  final DateTimeRange? dateRange;
  final int? categoryId;
  final int? priorityId;
  final double? minAmount;
  final double? maxAmount;

  const ExpenseFilter({
    this.search = '',
    this.dateRange,
    this.categoryId,
    this.priorityId,
    this.minAmount,
    this.maxAmount,
  });

  bool get isActive =>
      search.isNotEmpty ||
      dateRange != null ||
      categoryId != null ||
      priorityId != null ||
      minAmount != null ||
      maxAmount != null;

  ExpenseFilter copyWith({
    String? search,
    DateTimeRange? dateRange,
    int? categoryId,
    int? priorityId,
    double? minAmount,
    double? maxAmount,
    bool clearDateRange = false,
    bool clearCategory = false,
    bool clearPriority = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) => ExpenseFilter(
    search: search ?? this.search,
    dateRange: clearDateRange ? null : dateRange ?? this.dateRange,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    priorityId: clearPriority ? null : priorityId ?? this.priorityId,
    minAmount: clearMinAmount ? null : minAmount ?? this.minAmount,
    maxAmount: clearMaxAmount ? null : maxAmount ?? this.maxAmount,
  );
}

/// Mở sheet lọc và trả bộ lọc mới; null khi người dùng đóng giữa chừng.
Future<ExpenseFilter?> showExpenseFilterSheet(
  BuildContext context, {
  required ExpenseFilter initial,
  required List<Category> categories,
  required List<PriorityLevel> priorities,
}) => showModalBottomSheet<ExpenseFilter>(
  context: context,
  isScrollControlled: true,
  builder: (context) => ExpenseFilterSheet(
    initial: initial,
    categories: categories,
    priorities: priorities,
  ),
);

class ExpenseFilterSheet extends StatefulWidget {
  final ExpenseFilter initial;
  final List<Category> categories;
  final List<PriorityLevel> priorities;

  const ExpenseFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
    required this.priorities,
  });

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late DateTimeRange? _dateRange;
  late int? _categoryId;
  late int? _priorityId;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initial.dateRange;
    _categoryId = widget.initial.categoryId;
    _priorityId = widget.initial.priorityId;
    _minController = TextEditingController(
      text: CurrencyFormatter.toEditableText(widget.initial.minAmount ?? 0),
    );
    _maxController = TextEditingController(
      text: CurrencyFormatter.toEditableText(widget.initial.maxAmount ?? 0),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (result != null) setState(() => _dateRange = result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lọc giao dịch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(
                    _dateRange == null
                        ? 'Chọn khoảng thời gian'
                        : '${DateFormatter.formatDate(_dateRange!.start)} – ${DateFormatter.formatDate(_dateRange!.end)}',
                  ),
                ),
                if (_dateRange != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _dateRange = null),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Bỏ lọc thời gian'),
                  ),
                const SizedBox(height: 12),
                Text('Danh mục', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    ...widget.categories.map(
                      (category) => ChoiceChip(
                        avatar: IconHelper.getIconWidget(
                          category.icon,
                          size: 15,
                        ),
                        label: Text(category.name),
                        selected: _categoryId == category.id,
                        onSelected: (selected) => setState(
                          () => _categoryId = selected ? category.id : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Mức độ cần thiết',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _priorityId == null,
                      onSelected: (_) => setState(() => _priorityId = null),
                    ),
                    ...widget.priorities.map(
                      (priority) => ChoiceChip(
                        label: Text(priority.name),
                        selected: _priorityId == priority.id,
                        onSelected: (selected) => setState(
                          () => _priorityId = selected ? priority.id : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [
                          ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Từ số tiền',
                          suffixText: '₫',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [
                          ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Đến số tiền',
                          suffixText: '₫',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, const ExpenseFilter()),
                      child: const Text('Xóa bộ lọc'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        ExpenseFilter(
                          search: widget.initial.search,
                          dateRange: _dateRange,
                          categoryId: _categoryId,
                          priorityId: _priorityId,
                          minAmount: CurrencyFormatter.parseInput(
                            _minController.text,
                          ),
                          maxAmount: CurrencyFormatter.parseInput(
                            _maxController.text,
                          ),
                        ),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
