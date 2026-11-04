import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_palette.dart';
import 'photo_capture_core.dart';

/// Ống ngắm thật qua plugin `camera`. Logic này bê nguyên từ
/// `camera_screen.dart` (controller, danh sách camera, đổi thị kính, preview
/// cắt vuông) — screen chỉ còn nói chuyện với seam.
class CameraPluginPhotoCapture extends PhotoCapture {
  CameraController? _controller;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  bool _isReady = false;
  String? _error;
  int _selectedCameraIndex = 0;
  bool _isSwitching = false;

  final ImagePicker _picker = ImagePicker();

  /// Lần mở ống ngắm hiện hành. `initialize()` và `dispose()` tăng số này để
  /// công việc dở dang biết mình đã bị bỏ — tương đương check `mounted` khi
  /// screen còn tự giữ controller. Seam là toàn cục nên thiếu nó thì một lần mở
  /// screen cũ có thể ghi trạng thái sang lần mở sau.
  int _generation = 0;

  @override
  bool get isReady => _isReady;

  @override
  String? get errorMessage => _error;

  @override
  bool get supportsLiveViewfinder => true;

  @override
  bool get canSwitchCamera => _cameras.length > 1;

  @override
  Future<void> initialize() async {
    final generation = ++_generation;
    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (error) {
      debugPrint('Error listing cameras: $error');
      cameras = const <CameraDescription>[];
    }

    if (generation != _generation) return;
    _cameras = cameras;

    // Seam sống lâu hơn một lần mở screen, nên chỉ số cũ có thể vượt danh sách
    // mới (rút sạc, đổi thiết bị).
    if (_selectedCameraIndex >= _cameras.length) _selectedCameraIndex = 0;

    if (_cameras.isEmpty) {
      _isReady = false;
      _error = 'Không tìm thấy máy ảnh trên thiết bị.';
      return;
    }

    await _setupCameraController(_cameras[_selectedCameraIndex], generation);
  }

  Future<bool> _setupCameraController(
    CameraDescription camera,
    int generation,
  ) async {
    final previous = _controller;
    _controller = null;

    // Phải giải phóng camera cũ trước khi mở camera mới, nếu không thiết bị
    // sẽ giữ cả hai và camera mới bị đen.
    if (previous != null) {
      try {
        await previous.dispose();
      } catch (_) {}
    }
    if (generation != _generation) return false;

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (generation != _generation || !identical(_controller, controller)) {
        // Screen đã rời khỏi cây widget và gọi dispose() giữa lúc khởi tạo:
        // đừng để lại một ống ngắm không chủ chiếm camera của hệ thống.
        try {
          await controller.dispose();
        } catch (_) {}
        return false;
      }
      _isReady = true;
      _error = null;
      return true;
    } on CameraException catch (error) {
      debugPrint('Camera Exception: ${error.code}, ${error.description}');
      try {
        await controller.dispose();
      } catch (_) {}
      if (identical(_controller, controller)) _controller = null;
      if (generation != _generation) return false;
      final hasCameraPermission = !error.code.contains('CameraAccessDenied');
      _isReady = false;
      _error = hasCameraPermission
          ? 'Camera đang bận hoặc không khả dụng.'
          : 'Bạn chưa cấp quyền truy cập máy ảnh.';
      return false;
    }
  }

  @override
  Future<void> useNextCamera() async {
    if (_cameras.length < 2 || _isSwitching) return;
    _isSwitching = true;
    final generation = _generation;

    final previousIndex = _selectedCameraIndex;
    final currentLensDirection = _cameras[previousIndex].lensDirection;
    var nextIndex = _cameras.indexWhere(
      (camera) => camera.lensDirection != currentLensDirection,
    );
    if (nextIndex < 0) nextIndex = (previousIndex + 1) % _cameras.length;

    _selectedCameraIndex = nextIndex;
    _isReady = false;
    _error = null;

    final success = await _setupCameraController(
      _cameras[nextIndex],
      generation,
    );
    if (!success && generation == _generation && previousIndex != nextIndex) {
      // Nếu camera mới không mở được, quay lại camera cũ để không bị màn hình đen.
      _selectedCameraIndex = previousIndex;
      _error = null;
      await _setupCameraController(_cameras[previousIndex], generation);
    }
    if (generation == _generation) _isSwitching = false;
  }

  @override
  Future<Uint8List?> capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return null;
    }
    final picture = await controller.takePicture();
    return picture.readAsBytes();
  }

  @override
  Future<({Uint8List bytes, String extension})?> pickFromGallery() =>
      _pick(ImageSource.gallery);

  Future<({Uint8List bytes, String extension})?> _pick(
    ImageSource source,
  ) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (image == null) return null;
    return (
      bytes: await image.readAsBytes(),
      extension: image.path.split('.').last.toLowerCase(),
    );
  }

  @override
  Widget buildViewfinder(BuildContext context, {double aspectRatio = 1}) {
    final controller = _controller;
    if (!_isReady || controller == null) return const SizedBox.shrink();

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ô vuông ngắm nhỏ hơn cạnh khả dụng 24 px để nền sao còn chỗ hở
          // quanh khung; vùng cắt vẫn đúng tâm preview.
          final side =
              math.min(constraints.maxWidth, constraints.maxHeight) - 24;
          return SizedBox(
            width: side,
            height: side,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _SquareCameraPreview(controller: controller),
                ),
                const _ViewfinderCorners(),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Chặn mọi công việc dở dang trước khi gỡ trạng thái.
    _generation++;
    _controller?.dispose();
    _controller = null;
    _cameras = const <CameraDescription>[];
    _isReady = false;
    _isSwitching = false;
    _error = null;
  }
}

/// Preview cắt giữa đúng ô vuông: cover vào khung rồi clip, khớp vùng mà
/// `squareBytes` cắt từ ảnh thật.
class _SquareCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _SquareCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

/// Khung ngắm pixel: guide vuông đúng vùng cắt, 4 góc đậm, không áp filter hay
/// làm mờ ảnh xem trước.
class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  static const double _side = 24;

  @override
  Widget build(BuildContext context) {
    final edge = BorderSide(color: context.palette.feedInk, width: 3);
    Widget bracket(bool left, bool top) => Container(
      width: _side,
      height: _side,
      decoration: BoxDecoration(
        border: Border(
          left: left ? edge : BorderSide.none,
          top: top ? edge : BorderSide.none,
          right: left ? BorderSide.none : edge,
          bottom: top ? BorderSide.none : edge,
        ),
      ),
    );

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Preview vẽ BoxFit.cover nên vùng cắt vuông luôn phủ kín cạnh nhỏ
          // của khung: guide là ô vuông nội tiếp, ảnh thật lấy dư hai bên.
          final guide = math.min(constraints.maxWidth, constraints.maxHeight);
          return Center(
            child: SizedBox(
              width: guide,
              height: guide,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: bracket(true, true)),
                  Positioned(top: 0, right: 0, child: bracket(false, true)),
                  Positioned(bottom: 0, left: 0, child: bracket(true, false)),
                  Positioned(bottom: 0, right: 0, child: bracket(false, false)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

PhotoCapture photoCapture = CameraPluginPhotoCapture();
