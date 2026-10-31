import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../data/models/category.dart';
import '../../core/utils/amount_input_formatter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hamburger_button.dart';
import '../../widgets/screen_background.dart';

import 'package:intl/intl.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;

  const BudgetScreen({super.key, this.onMenuTap});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  bool _isTotalBudget = true;
  bool _isSavingBudget = false;
  final _totalBudgetController = TextEditingController();
  final Map<int, TextEditingController> _categoryControllers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  void _loadData() {
    final budgetState = ref.read(budgetProvider);
    final categoryState = ref.read(categoryProvider);

    if (budgetState.totalBudget != null &&
        budgetState.totalBudget!.amount > 0) {
      _totalBudgetController.text = CurrencyFormatter.toEditableText(
        budgetState.totalBudget!.amount,
      );
    }

    for (var cat in categoryState.categories) {
      if (cat.id != null) {
        final amount = budgetState.categoryBudgets[cat.id];
        _categoryControllers[cat.id!] = TextEditingController(
          text: CurrencyFormatter.toEditableText(amount ?? 0),
        );
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (_isSavingBudget) return;
    setState(() => _isSavingBudget = true);
    final currentMonth = ref.read(budgetProvider).month;
    try {
      if (_isTotalBudget) {
        final total =
            CurrencyFormatter.parseInput(_totalBudgetController.text) ?? 0.0;
        await ref
            .read(budgetProvider.notifier)
            .setTotalBudget(month: currentMonth, amount: total);
      } else {
        final Map<int, double> catBudgets = {};
        _categoryControllers.forEach((id, controller) {
          final val = CurrencyFormatter.parseInput(controller.text);
          if (val != null && val > 0) {
            catBudgets[id] = val;
          }
        });
        await ref
            .read(budgetProvider.notifier)
            .setCategoryBudgets(
              month: currentMonth,
              categoryBudgets: catBudgets,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã lưu ngân sách!')));
      }
    } catch (e) {
      if (mounted) {
        final message = e is BudgetValidationException
            ? e.message
            : 'Lỗi khi lưu ngân sách';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isSavingBudget = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BudgetState>(budgetProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        if (next.totalBudget != null && next.totalBudget!.amount > 0) {
          if (_totalBudgetController.text.isEmpty) {
            _totalBudgetController.text = next.totalBudget!.amount
                .toInt()
                .toString();
          }
        }
        for (var entry in next.categoryBudgets.entries) {
          final controller = _categoryControllers[entry.key];
          if (controller != null &&
              controller.text.isEmpty &&
              entry.value > 0) {
            controller.text = entry.value.toInt().toString();
          }
        }
      }
    });

    final budgetState = ref.watch(budgetProvider);
    final categoryState = ref.watch(categoryProvider);
    final currentMonth = DateFormat('MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: HamburgerButton(onTap: widget.onMenuTap),
        ),
        leadingWidth: 64,
        title: Text('Ngân sách tháng $currentMonth'),
      ),
      body: ScreenBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Tổng')),
                  ButtonSegment(
                    value: false,
                    label: Text('Chia theo danh mục'),
                  ),
                ],
                selected: {_isTotalBudget},
                onSelectionChanged: (set) {
                  setState(() => _isTotalBudget = set.first);
                },
              ),
            ),
            Expanded(
              child: _isTotalBudget
                  ? _buildTotalBudgetView(budgetState)
                  : _buildCategoryBudgetView(
                      categoryState.categories,
                      budgetState,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSavingBudget ? null : _saveBudget,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSavingBudget
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Lưu ngân sách',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBudgetView(BudgetState budgetState) {
    final spent = budgetState.totalSpent;
    final budget = budgetState.totalBudget?.amount ?? 0.0;
    final rawPercent = budget > 0 ? spent / budget : 0.0;
    final percent = rawPercent.clamp(0.0, 1.0);
    final remaining = budget - spent;
    final isOver = remaining < 0;

    Color progressColor = Colors.teal;
    if (percent >= 1.0) {
      progressColor = Colors.red;
    } else if (percent >= 0.8) {
      progressColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _totalBudgetController,
            keyboardType: TextInputType.number,
            inputFormatters: const [ThousandsSeparatorInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Ngân sách tổng (VND)',
              hintText: '5.000.000',
              suffixText: '₫',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          if (budget > 0)
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: percent,
                    color: progressColor,
                    backgroundColor: Colors.grey.shade200,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đã tiêu: ${CurrencyFormatter.format(spent)}'),
                      Text('${(rawPercent * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOver
                        ? 'Quá ngân sách: ${CurrencyFormatter.format(-remaining)}'
                        : 'Còn lại: ${CurrencyFormatter.format(remaining)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isOver ? Colors.red : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetView(
    List<Category> categories,
    BudgetState budgetState,
  ) {
    if (categories.isEmpty) {
      return const Center(child: Text('Chưa có danh mục nào'));
    }

    return ListView.builder(
      itemCount: categories.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final cat = categories[index];
        if (cat.id == null) return const SizedBox.shrink();

        if (!_categoryControllers.containsKey(cat.id!)) {
          final amt = budgetState.categoryBudgets[cat.id!];
          _categoryControllers[cat.id!] = TextEditingController(
            text: amt != null && amt > 0 ? amt.toInt().toString() : '',
          );
        }

        final budget = budgetState.categoryBudgets[cat.id!] ?? 0.0;
        final spent = budgetState.categorySpent[cat.id!] ?? 0.0;
        final rawPercent = budget > 0 ? spent / budget : 0.0;
        final percent = rawPercent.clamp(0.0, 1.0);
        final remaining = budget - spent;
        final isOver = remaining < 0;

        Color progressColor = Colors.teal;
        if (percent >= 1.0) {
          progressColor = Colors.red;
        } else if (percent >= 0.8) {
          progressColor = Colors.orange;
        }

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          borderRadius: 22,
          child: Column(
            children: [
              Row(
                children: [
                  IconHelper.getIconWidget(
                    cat.icon,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _categoryControllers[cat.id!],
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Ngân sách',
                  suffixText: '₫',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (budget > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percent,
                  color: progressColor,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã tiêu: ${CurrencyFormatter.format(spent)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${(rawPercent * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isOver
                        ? 'Quá ngân sách: ${CurrencyFormatter.format(-remaining)}'
                        : 'Còn lại: ${CurrencyFormatter.format(remaining)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOver ? Colors.red : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
