enum AppSection {
  feed('Nhật ký ảnh', 'camera'),
  dashboard('Tổng quan', 'house'),
  statistics('Thống kê', 'chart'),
  budget('Ngân sách', 'wallet');

  final String label;
  final String glyph;

  const AppSection(this.label, this.glyph);
}
