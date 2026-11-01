import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/amount_input_formatter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/category.dart';
import '../../data/models/priority_level.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_chip.dart';
import '../../widgets/pixel/pixel_divider.dart';
import '../../widgets/pixel/pixel_sheet.dart';
import '../../widgets/pixel/pixel_text_field.dart';

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

/// Mở sheet lọc; trả bộ lọc mới, null khi người dùng đóng giữa chừng.
Future<ExpenseFilter?> openExpenseFilterSheet(
  BuildContext context, {
  required ExpenseFilter initial,
  required List<Category> categories,
  required List<PriorityLevel> priorities,
}) => showPixelSheet<ExpenseFilter>(
  context: context,
  title: 'Lọc giao dịch',
  builder: (_) => ExpenseFilterSheet(
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

  void _apply() {
    Navigator.pop(
      context,
      ExpenseFilter(
        search: widget.initial.search,
        dateRange: _dateRange,
        categoryId: _categoryId,
        priorityId: _priorityId,
        minAmount: CurrencyFormatter.parseInput(_minController.text),
        maxAmount: CurrencyFormatter.parseInput(_maxController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Khoảng thời gian', style: text.titleSmall),
        const SizedBox(height: 8),
        PixelButton(
          label: _dateRange == null
              ? 'CHỌN KHOẢNG NGÀY'
              : '${DateFormatter.formatDate(_dateRange!.start)} – '
                    '${DateFormatter.formatDate(_dateRange!.end)}',
          icon: 'calendar',
          variant: PixelButtonVariant.secondary,
          expanded: true,
          onPressed: _pickDateRange,
        ),
        if (_dateRange != null) ...[
          const SizedBox(height: 8),
          PixelButton(
            key: const ValueKey('clear-date'),
            label: 'Bỏ lọc thời gian',
            icon: 'close',
            variant: PixelButtonVariant.ghost,
            onPressed: () => setState(() => _dateRange = null),
          ),
        ],
        const SizedBox(height: 16),
        Text('Danh mục', style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PixelChip(
              label: 'Tất cả',
              icon: 'dotsThreeOutline',
              selected: _categoryId == null,
              showCheck: false,
              onTap: () => setState(() => _categoryId = null),
            ),
            for (final category in widget.categories)
              PixelChip(
                label: category.name,
                icon: IconHelper.normalizeIconKey(category.icon),
                selected: _categoryId == category.id,
                onTap: () => setState(
                  () => _categoryId = _categoryId == category.id
                      ? null
                      : category.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Mức độ cần thiết', style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PixelChip(
              label: 'Tất cả',
              icon: 'dotsThreeOutline',
              selected: _priorityId == null,
              showCheck: false,
              onTap: () => setState(() => _priorityId = null),
            ),
            for (final priority in widget.priorities)
              PixelChip(
                label: priority.name,
                accent: palette.priorityColor(priority.id),
                selected: _priorityId == priority.id,
                onTap: () => setState(
                  () => _priorityId = _priorityId == priority.id
                      ? null
                      : priority.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PixelTextField(
                key: const Key('filterMin'),
                label: 'Từ số tiền',
                controller: _minController,
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
                inputFormatters: const [ThousandsSeparatorInputFormatter()],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PixelTextField(
                key: const Key('filterMax'),
                label: 'Đến số tiền',
                controller: _maxController,
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
                inputFormatters: const [ThousandsSeparatorInputFormatter()],
              ),
            ),
          ],
        ),
        const PixelDivider(),
        Row(
          children: [
            PixelButton(
              key: const ValueKey('clear-filter'),
              label: 'XÓA BỘ LỌC',
              icon: 'undo',
              variant: PixelButtonVariant.ghost,
              onPressed: () => Navigator.pop(context, const ExpenseFilter()),
            ),
            const Spacer(),
            PixelButton(label: 'ÁP DỤNG', icon: 'check', onPressed: _apply),
          ],
        ),
      ],
    );
  }
}
