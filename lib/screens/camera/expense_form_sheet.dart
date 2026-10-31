import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount_input_formatter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/storage_paths.dart';
import '../../data/models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/priority_provider.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  final String? imagePath;
  final Expense? expense;

  const ExpenseFormSheet({super.key, this.imagePath, this.expense})
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

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        final updated = widget.expense!.copyWith(
          caption: _captionController.text.trim(),
          amount: amount,
          categoryId: categoryId,
          priority: _selectedPriority,
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
          createdAt: DateTime.now(),
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
    final categoryState = ref.watch(categoryProvider);
    final priorityState = ref.watch(priorityProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Text(
                    _isEditing ? 'Chỉnh sửa khoản chi' : 'Thêm khoản chi',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildSquareImage(),
                  if (_isEditing) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Ảnh không thể thay đổi sau khi đã lưu.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _captionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (tùy chọn)',
                      hintText: 'Ví dụ: Ăn trưa, mua sữa...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Số tiền (VND)',
                      hintText: '35.000',
                      suffixText: '₫',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = CurrencyFormatter.parseInput(value ?? '');
                      return amount == null || amount <= 0
                          ? 'Nhập số tiền lớn hơn 0'
                          : null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Danh mục',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text('Không chọn tag sẽ tự xếp vào danh mục Khác.'),
                  const SizedBox(height: 8),
                  if (categoryState.isLoading &&
                      categoryState.categories.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryState.categories.map((category) {
                        final selected = _selectedCategoryId == category.id;
                        return ChoiceChip(
                          avatar: IconHelper.getIconWidget(
                            category.icon,
                            size: 16,
                          ),
                          label: Text(category.name),
                          selected: selected,
                          onSelected: (value) => setState(() {
                            _selectedCategoryId = value ? category.id : null;
                          }),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Mức độ cần thiết',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (priorityState.levels.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: priorityState.levels.map((level) {
                        final selected = _selectedPriority == level.id;
                        return ChoiceChip(
                          label: Text(level.name),
                          selected: selected,
                          selectedColor: level.color.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: selected ? level.color : null,
                            fontWeight: selected ? FontWeight.bold : null,
                          ),
                          onSelected: (value) {
                            if (value) {
                              setState(() => _selectedPriority = level.id);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveExpense,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Lưu thay đổi' : 'Lưu khoản chi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSquareImage() {
    final path = _sourceImagePath;
    final placeholder = Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image_outlined, size: 56),
    );

    final storedPath = storagePathOf(path);
    Widget image;
    if (path == null || path.isEmpty) {
      image = placeholder;
    } else if (storedPath != null) {
      // Ảnh đã nằm trên Cloud: chỉ hiển thị được qua signed URL.
      final url = widget.expense?.displayImageUrl;
      image = url == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              cacheKey: storedPath,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => placeholder,
            );
    } else {
      final file = File(path);
      image = file.existsSync()
          ? Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder;
    }

    return Semantics(
      label: 'Ảnh của khoản chi',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(aspectRatio: 1, child: image),
      ),
    );
  }
}
