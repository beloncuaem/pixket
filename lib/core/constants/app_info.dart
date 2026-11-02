/// Nguồn duy nhất cho tên hiển thị và phiên bản app.
/// Spec §4.8: `pubspec.yaml` phải dùng cùng `version`/`build` với file này.
class AppInfo {
  AppInfo._();

  static const String name = 'Pixket';
  static const String version = '2.4.0';
  static const String build = '5';
  static const String tagline = 'PIXEL JOURNAL';
  static const String aboutLabel = 'Phiên bản $version • $tagline';
}
