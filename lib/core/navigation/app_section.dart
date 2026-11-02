enum AppSection {
  feed('Nhật ký ảnh', 'holocam'),
  dashboard('Tổng quan', 'bridge'),
  statistics('Thống kê', 'radar'),
  budget('Ngân sách', 'cargo');

  final String label;
  final String glyph;

  const AppSection(this.label, this.glyph);
}
