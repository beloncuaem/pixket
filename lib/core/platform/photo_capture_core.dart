import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Ống kính chung cho mọi cách lấy ảnh hóa đơn: ống ngắm sống, đổi camera, chọn
/// từ thư viện. Screen chỉ nói chuyện với lớp này, không import plugin.
abstract class PhotoCapture {
  const PhotoCapture();

  /// Mở thiết bị ảnh. Phải luôn kết thúc bằng một trạng thái giải thích được
  /// (`isReady` hoặc `errorMessage`), không bao giờ treo ở "đang khởi tạo".
  Future<void> initialize();

  bool get isReady;

  String? get errorMessage;

  /// false trên nền tảng không có ống ngắm sống: screen khi đó hiện hướng dẫn
  /// chọn ảnh thay vì vùng ngắm, và không bao giờ chờ `isReady`.
  bool get supportsLiveViewfinder;

  /// Có ít nhất hai camera để đổi thị kính không.
  bool get canSwitchCamera;

  /// Đổi sang camera khác; không có camera thứ hai thì vô sự.
  Future<void> useNextCamera();

  /// null khi người dùng hủy hoặc ống ngắm chưa sẵn sàng.
  Future<Uint8List?> capture();

  /// null khi người dùng hủy.
  Future<({Uint8List bytes, String extension})?> pickFromGallery();

  /// Vùng ngắm. `aspectRatio` là tỷ lệ khung caller muốn; ống ngắm hiện tại cắt
  /// vuông theo `squareBytes` nên bản camera bỏ qua tham số này.
  Widget buildViewfinder(BuildContext context, {double aspectRatio = 1});

  /// Giải phóng thiết bị ảnh khi màn hình rời khỏi cây widget, để camera không
  /// bị chiếm sau khi người dùng đã thoát screen. Vì seam là toàn cục, hàm này
  /// giả định tại một thời điểm chỉ có một screen sở hữu nó — đúng với hiện tại
  /// (chỉ `main_screen.dart:49` gắm `CameraScreen`).
  void dispose();
}

/// Phần screen render cho trạng thái hiện tại của [PhotoCapture]. Tách thành
/// hàm thuần để bảng sự thật — nhất là "web không bao giờ ở trạng thái khởi
/// tạo" — test được mà không cần plugin hay trình duyệt.
enum PhotoCapturePane { liveViewfinder, initializing, error, galleryPrompt }

/// Thứ tự ưu tiên có chủ đích: lỗi thắng mọi thứ (người dùng phải thấy lý do),
/// rồi tới nền tảng không có ống ngắm (trạng thái kết thúc — không có gì để
/// chờ), sau đó mới tới khởi tạo.
PhotoCapturePane photoCapturePaneFor({
  required bool supportsLiveViewfinder,
  required bool isReady,
  required String? errorMessage,
}) {
  if (errorMessage != null) return PhotoCapturePane.error;
  if (!supportsLiveViewfinder) return PhotoCapturePane.galleryPrompt;
  return isReady
      ? PhotoCapturePane.liveViewfinder
      : PhotoCapturePane.initializing;
}
