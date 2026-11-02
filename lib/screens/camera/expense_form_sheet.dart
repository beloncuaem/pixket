import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/amount_input_formatter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/expense_date_limits.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/storage_paths.dart';
import '../../data/models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/priority_provider.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_chip.dart';
import '../../widgets/pixel/pixel_confetti.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_receipt_image.dart';
import '../../widgets/pixel/pixel_sheet.dart';
import '../../widgets/pixel/pixel_text_field.dart';
import 'expense_datetime_field.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  final String? imagePath;
  final Expense? expense;

  @visibleForTesting
  final DateTime? maxNow;

  const ExpenseFormSheet({super.key, this.imagePath, this.expense, this.maxNow})
    : assert(imagePath != null || expense != null);

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _captionController;
  late final TextEditingController _amountController;
  int? _selectedCategoryId;
  late int _selectedPriority;
  late DateTime _occurredAt;
  String? _dateError;
  bool _isSaving = false;
  bool _didSave = false;

  bool get _isEditing => widget.expense != null;
  String? get _sourceImagePath => widget.expense?.imagePath ?? widget.imagePath;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _captionController = TextEditingController(text: expense?.caption ?? '');
    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : CurrencyFormatter.toEditableText(expense.amount),
    );
    _selectedCategoryId = expense?.categoryId;
    _selectedPriority = expense?.priority ?? 2;
    _occurredAt = expense?.createdAt ?? DateTime.now();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final categories = ref.read(categoryProvider).categories;
    final fallbackCategory = categories.where(
      (category) => category.name == 'Khác',
    );
    final categoryId =
        _selectedCategoryId ??
        (fallbackCategory.isEmpty ? null : fallbackCategory.first.id);
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy danh mục Khác để lưu khoản chi.'),
        ),
      );
      return;
    }

    final amount = CurrencyFormatter.parseInput(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Số tiền phải lớn hơn 0.')));
      return;
    }

    final dateError = ExpenseDateLimits.validate(_occurredAt, DateTime.now());
    if (dateError != null) {
      setState(() => _dateError = dateError);
      return;
    }
    setState(() => _dateError = null);

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        final updated = widget.expense!.copyWith(
          caption: _captionController.text.trim(),
          amount: amount,
          categoryId: categoryId,
          priority: _selectedPriority,
          createdAt: _occurredAt,
        );
        await ref.read(expenseProvider.notifier).updateExpense(updated);
      } else {
        final sourceImagePath = _sourceImagePath;
        if (sourceImagePath == null) {
          throw StateError('Không tìm thấy ảnh đã chọn.');
        }
        final newExpense = Expense(
          caption: _captionController.text.trim(),
          amount: amount,
          categoryId: categoryId,
          priority: _selectedPriority,
          imagePath: sourceImagePath,
          createdAt: _occurredAt,
        );
        await ref.read(expenseProvider.notifier).addExpense(newExpense);
        _didSave = true;

        // Ảnh đã nằm trên Cloud, xóa bản tạm trên máy.
        final localFile = File(sourceImagePath);
        if (await localFile.exists()) {
          try {
            await localFile.delete();
          } catch (_) {}
        }
      }
      if (!mounted) return;
      PixelConfetti.burst(context);
      if (_isEditing) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật khoản chi.')));
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message
          : 'Không thể lưu lên Cloud. Kiểm tra kết nối mạng và thử lại.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    final draftPath = widget.imagePath;
    if (!_didSave &&
        !_isEditing &&
        draftPath != null &&
        storagePathOf(draftPath) == null) {
      final file = File(draftPath);
      if (file.existsSync()) file.delete();
    }
    _captionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final categoryState = ref.watch(categoryProvider);
    final priorityState = ref.watch(priorityProvider);

    // `showPixelSheet` đã bọc SingleChildScrollView, ở đây chỉ cần Column.
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: PixelReceiptImage.source(
                _sourceImagePath,
                expense: widget.expense,
                semanticLabel: 'Ảnh khoản chi',
              ),
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Ảnh không thể thay đổi sau khi đã lưu.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: palette.inkMuted),
              ),
            ),
          const SizedBox(height: 16),
          PixelTextField(
            label: 'Ghi chú (tùy chọn)',
            hint: 'Ví dụ: Ăn trưa, mua sữa...',
            controller: _captionController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          PixelTextField(
            key: const Key('expenseAmountField'),
            label: 'Số tiền (VND)',
            hint: '35000',
            controller: _amountController,
            keyboardType: TextInputType.number,
            textCapitalization: TextCapitalization.none,
            inputFormatters: const [ThousandsSeparatorInputFormatter()],
            validator: (value) {
              final amount = CurrencyFormatter.parseInput(value ?? '');
              return amount == null || amount <= 0
                  ? 'Nhập số tiền lớn hơn 0'
                  : null;
            },
          ),
          const SizedBox(height: 20),
          ExpenseDateTimeField(
            value: _occurredAt,
            maxNow: widget.maxNow,
            onChanged: (next) => setState(() {
              _occurredAt = next;
              _dateError = ExpenseDateLimits.validate(
                next,
                widget.maxNow ?? DateTime.now(),
              );
            }),
          ),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _dateError!,
                style: text.bodySmall?.copyWith(color: palette.danger),
              ),
            ),
          const SizedBox(height: 20),
          Text('Danh mục', style: text.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Không chọn danh mục sẽ tự xếp vào Khác.',
            style: text.bodySmall?.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 8),
          if (categoryState.isLoading && categoryState.categories.isEmpty)
            const PixelLoading(blocks: 3)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categoryState.categories)
                  PixelChip(
                    label: category.name,
                    icon: IconHelper.normalizeIconKey(category.icon),
                    selected: _selectedCategoryId == category.id,
                    accent: palette.accentForCategory(category.name),
                    onTap: () => setState(() {
                      _selectedCategoryId = _selectedCategoryId == category.id
                          ? null
                          : category.id;
                    }),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          Text('Mức độ cần thiết', style: text.titleSmall),
          const SizedBox(height: 8),
          if (priorityState.levels.isEmpty)
            const PixelLoading(blocks: 3)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in priorityState.levels)
                  PixelChip(
                    label: level.name,
                    selected: _selectedPriority == level.id,
                    accent: palette.priorityColor(level.id),
                    onTap: () => setState(() => _selectedPriority = level.id),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          PixelButton(
            label: _isEditing ? 'LƯU THAY ĐỔI' : 'LƯU KHOẢN CHI',
            icon: 'check',
            expanded: true,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _saveExpense,
          ),
        ],
      ),
    );
  }
}

Future<void> openExpenseForm(
  BuildContext context, {
  String? imagePath,
  Expense? expense,
  DateTime? maxNow,
}) async {
  await showPixelSheet<void>(
    context: context,
    title: expense == null ? 'Thêm khoản chi' : 'Chỉnh sửa khoản chi',
    fullScreen: true,
    builder: (_) => ExpenseFormSheet(
      imagePath: imagePath,
      expense: expense,
      maxNow: maxNow,
    ),
  );
}
