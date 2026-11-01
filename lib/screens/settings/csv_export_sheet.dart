import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/csv_export_service.dart';
import '../../providers/category_provider.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_segmented.dart';
import '../../widgets/pixel/pixel_sheet.dart';
import '../../widgets/pixel/pixel_snack_bar.dart';

enum CsvRangeChoice { month, all, custom }

class CsvExportSheet extends ConsumerStatefulWidget {
  const CsvExportSheet({super.key, this.service});

  final CsvExportService? service;

  @override
  ConsumerState<CsvExportSheet> createState() => _CsvExportSheetState();
}

class _CsvExportSheetState extends ConsumerState<CsvExportSheet> {
  CsvRangeChoice _choice = CsvRangeChoice.month;
  DateTimeRange? _customRange;
  bool _busy = false;

  ({DateTime from, DateTime to}) _resolveRange() {
    final now = DateTime.now();
    return switch (_choice) {
      CsvRangeChoice.month => (
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 1),
      ),
      CsvRangeChoice.custom => (
        from: _customRange?.start ?? DateTime(now.year, now.month, 1),
        to: _customRange?.end ?? now,
      ),
      CsvRangeChoice.all => (
        from: DateTime(now.year - 10, now.month, now.day),
        to: now,
      ),
    };
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10, now.month, now.day),
      lastDate: now,
      initialDateRange: _customRange,
    );
    if (picked != null) setState(() => _customRange = picked);
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final categories = ref.read(categoryProvider).categories;
      final names = <int, String>{
        for (final category in categories)
          if (category.id != null) category.id!: category.name,
      };
      final range = _resolveRange();
      final service = widget.service ?? CsvExportService();
      final result = await service.exportAndShare(
        from: range.from,
        to: range.to,
        categoryNames: names,
      );

      if (!mounted) return;
      if (result.rowCount == 0) {
        showPixelSnackBar(
          context,
          'Không có khoản chi nào trong khoảng này.',
          tone: PixelTone.info,
        );
      } else {
        Navigator.of(context).pop();
        showPixelSnackBar(
          context,
          'Đã xuất ${result.rowCount} khoản chi. Chọn nơi lưu trong hộp chia sẻ.',
          tone: PixelTone.success,
        );
      }
    } catch (error) {
      if (!mounted) return;
      showPixelSnackBar(
        context,
        'Không thể xuất CSV. Kiểm tra mạng và thử lại.',
        tone: PixelTone.danger,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final range = _resolveRange();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tải bản sao lưu toàn bộ khoản chi. Ảnh không kèm theo, chỉ ghi đường dẫn.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 16),
          PixelSegmented<CsvRangeChoice>(
            items: const [
              PixelSegmentItem(value: CsvRangeChoice.month, label: 'THÁNG NÀY'),
              PixelSegmentItem(value: CsvRangeChoice.all, label: 'TOÀN BỘ'),
              PixelSegmentItem(value: CsvRangeChoice.custom, label: 'TỰ CHỌN'),
            ],
            selected: _choice,
            onChanged: (value) => setState(() => _choice = value),
          ),
          const SizedBox(height: 12),
          if (_choice == CsvRangeChoice.custom)
            PixelButton(
              label: _customRange == null
                  ? 'Chọn khoảng thời gian'
                  : '${DateFormatter.formatDate(_customRange!.start)} – '
                        '${DateFormatter.formatDate(_customRange!.end)}',
              icon: 'calendar',
              variant: PixelButtonVariant.secondary,
              expanded: true,
              onPressed: _pickCustomRange,
            )
          else
            Text(
              '${DateFormatter.formatDate(range.from)} – ${DateFormatter.formatDate(range.to)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 16),
          PixelButton(
            label: 'Xuất và chia sẻ',
            isLoading: _busy,
            onPressed: _busy ? null : _export,
          ),
        ],
      ),
    );
  }
}

Future<void> showCsvExportSheet(BuildContext context) async {
  await showPixelSheet<void>(
    context: context,
    title: 'Xuất CSV (sao lưu)',
    builder: (_) => const CsvExportSheet(),
  );
}
