/// Tính số ô được tô cho một tỉ lệ, luôn nằm trong [0, cells].
int pixelFilledCells(double ratio, int cells) {
  if (cells <= 0) return 0;
  if (ratio.isNaN) return 0;
  if (ratio.isInfinite) return ratio > 0 ? cells : 0;
  final filled = (ratio * cells).round();
  return filled.clamp(0, cells);
}

/// '12%' — không bao giờ trả NaN hay dấu phẩy thập phân.
String sharePercent(double part, double total) {
  if (total <= 0) return '0%';
  final percent = (part / total * 100).round();
  return '${percent.clamp(0, 100)}%';
}

/// Tóm tắt chữ cho screen reader của bar chart (spec §3.6).
String pixelBarChartSemantics(
  List<DateTime> dates,
  List<double> values,
  List<String> valueTexts,
) {
  if (dates.isEmpty || values.isEmpty) return '';
  final n = [
    dates.length,
    values.length,
    valueTexts.length,
  ].reduce((a, b) => a < b ? a : b);
  final lines = <String>[];
  for (var i = 0; i < n; i++) {
    final d = dates[i];
    lines.add(
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}: ${valueTexts[i]}',
    );
  }
  return lines.join('\n');
}
