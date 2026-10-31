import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/expense_date_limits.dart';

/// Hai nút chọn ngày và giờ kèm nút reset "Bây giờ".
class ExpenseDateTimeField extends StatelessWidget {
  const ExpenseDateTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Ngày giờ ghi nhận',
    this.maxNow,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String label;

  /// Inject mốc "hiện tại" để test deterministic; mặc định là `DateTime.now()`.
  final DateTime? maxNow;

  Future<void> _pickDate(BuildContext context) async {
    final now = maxNow ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ExpenseDateLimits.clampToAllowedRange(value, now),
      firstDate: ExpenseDateLimits.firstDate(now),
      lastDate: ExpenseDateLimits.lastDate(now),
      helpText: 'Chọn ngày khoản chi',
    );
    if (picked == null) return;
    onChanged(ExpenseDateLimits.combine(picked, value.hour, value.minute));
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      helpText: 'Chọn giờ khoản chi',
    );
    if (picked == null) return;
    onChanged(ExpenseDateLimits.combine(value, picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickDate(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(DateFormatter.formatDate(value)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(DateFormatter.formatTime(value)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                final now = maxNow ?? DateTime.now();
                onChanged(ExpenseDateLimits.clampToAllowedRange(now, now));
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: palette.mintInk,
              ),
              child: const Text('Bây giờ'),
            ),
          ],
        ),
      ],
    );
  }
}
