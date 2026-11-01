/// Tính số ô được tô cho một tỉ lệ, luôn nằm trong [0, cells].
int pixelFilledCells(double ratio, int cells) {
  if (cells <= 0) return 0;
  if (ratio.isNaN) return 0;
  if (ratio.isInfinite) return ratio > 0 ? cells : 0;
  final filled = (ratio * cells).round();
  return filled.clamp(0, cells);
}

/// Chia [cells] ô cho các phần tử của [values] theo largest remainder.
/// Tổng kết quả đúng bằng cells khi total > 0, ngược lại toàn 0.
List<int> allocateCells(List<double> values, int cells) {
  if (values.isEmpty) return const [];
  if (cells <= 0) return List<int>.filled(values.length, 0);
  var total = 0.0;
  for (final v in values) {
    if (v > 0) total += v;
  }
  if (total <= 0) return List<int>.filled(values.length, 0);

  final exact = [for (final v in values) (v > 0 ? v : 0.0) / total * cells];
  final result = [for (final e in exact) e.floor()];
  var used = result.fold<int>(0, (a, b) => a + b);

  final order = [for (var i = 0; i < exact.length; i++) i]
    ..sort((a, b) {
      final ra = exact[a] - result[a];
      final rb = exact[b] - result[b];
      final c = rb.compareTo(ra);
      return c != 0 ? c : a.compareTo(b);
    });

  var cursor = 0;
  while (used < cells) {
    result[order[cursor % order.length]] += 1;
    used += 1;
    cursor += 1;
  }
  return result;
}

/// '12%' — không bao giờ trả NaN hay dấu phẩy thập phân.
String sharePercent(double part, double total) {
  if (total <= 0) return '0%';
  final percent = (part / total * 100).round();
  return '${percent.clamp(0, 100)}%';
}

/// Chọn index nhãn trục, luôn có index đầu và cuối, thưa đều.
List<int> pickAxisIndices(int count, int maxLabels) {
  if (count <= 0) return const [];
  if (maxLabels <= 1) return [count - 1];
  if (count <= maxLabels) return [for (var i = 0; i < count; i++) i];
  final step = (count - 1) / (maxLabels - 1);
  final indices = <int>[];
  for (var k = 0; k < maxLabels; k++) {
    final i = (k * step).round();
    if (indices.isEmpty || i != indices.last) indices.add(i);
  }
  if (indices.last != count - 1) indices.add(count - 1);
  return indices;
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
