import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/priority_provider.dart';
import '../../widgets/hamburger_button.dart';
import 'expense_form_sheet.dart';
import 'feed_grid_screen.dart';
import 'feed_helpers.dart';
import 'feed_photo_page.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;

  const CameraScreen({super.key, this.onMenuTap});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = true;
  bool _hasCameraPermission = true;
  String? _cameraError;
  int _selectedCameraIndex = 0;
  bool _isCapturing = false;
  bool _isSwitchingCamera = false;

  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (error) {
      debugPrint('Error listing cameras: $error');
      cameras = [];
    }

    if (!mounted) return;
    _cameras = cameras;

    if (_cameras.isEmpty) {
      setState(() {
        _isCameraInitializing = false;
        _cameraError = 'Không tìm thấy máy ảnh trên thiết bị.';
      });
      return;
    }

    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<bool> _setupCameraController(CameraDescription camera) async {
    final previous = _controller;
    _controller = null;

    // Phải giải phóng camera cũ trước khi mở camera mới, nếu không thiết bị
    // sẽ giữ cả hai và camera mới bị đen.
    if (previous != null) {
      try {
        await previous.dispose();
      } catch (_) {}
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        _controller = null;
        await controller.dispose();
        return false;
      }
      setState(() {
        _isCameraInitialized = true;
        _isCameraInitializing = false;
        _hasCameraPermission = true;
        _cameraError = null;
      });
      return true;
    } on CameraException catch (error) {
      debugPrint('Camera Exception: ${error.code}, ${error.description}');
      try {
        await controller.dispose();
      } catch (_) {}
      if (identical(_controller, controller)) _controller = null;
      if (!mounted) return false;
      setState(() {
        _isCameraInitialized = false;
        _isCameraInitializing = false;
        _hasCameraPermission = !error.code.contains('CameraAccessDenied');
        _cameraError = _hasCameraPermission
            ? 'Camera đang bận hoặc không khả dụng.'
            : 'Bạn chưa cấp quyền truy cập máy ảnh.';
      });
      return false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    if (_controller == null || !_controller!.value.isInitialized) {
      _showSnackBar('Camera chưa sẵn sàng. Hãy chọn ảnh từ thư viện.');
      return;
    }
    if (_controller!.value.isTakingPicture) return;

    setState(() => _isCapturing = true);
    try {
      final picture = await _controller!.takePicture();
      if (!mounted) return;
      await _openExpenseForm(imagePath: picture.path);
    } catch (error) {
      debugPrint('Error taking picture: $error');
      if (mounted) _showSnackBar('Không thể chụp ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        await _openExpenseForm(imagePath: image.path);
      }
    } catch (error) {
      debugPrint('Error picking image: $error');
      if (mounted) _showSnackBar('Không thể mở thư viện ảnh.');
    }
  }

  Future<void> _openExpenseForm({String? imagePath, Expense? expense}) async {
    final countBefore = buildFeedPhotos(ref.read(expenseProvider).expenses)
        .length;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormSheet(imagePath: imagePath, expense: expense),
    );
    if (!mounted) return;

    final photos = buildFeedPhotos(ref.read(expenseProvider).expenses);
    if (expense == null &&
        photos.length > countBefore &&
        _pageController.hasClients) {
      await _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing || _isSwitchingCamera) return;
    setState(() => _isSwitchingCamera = true);

    final previousIndex = _selectedCameraIndex;
    final currentLensDirection = _cameras[previousIndex].lensDirection;
    var nextIndex = _cameras.indexWhere(
      (camera) => camera.lensDirection != currentLensDirection,
    );
    if (nextIndex < 0) nextIndex = (previousIndex + 1) % _cameras.length;

    setState(() {
      _selectedCameraIndex = nextIndex;
      _isCameraInitialized = false;
      _isCameraInitializing = true;
      _cameraError = null;
    });

    final success = await _setupCameraController(_cameras[nextIndex]);
    if (!success && mounted && previousIndex != nextIndex) {
      // Nếu camera mới không mở được, quay lại camera cũ để không bị màn hình đen.
      setState(() {
        _selectedCameraIndex = previousIndex;
        _isCameraInitializing = true;
        _cameraError = null;
      });
      await _setupCameraController(_cameras[previousIndex]);
    }
    if (mounted) setState(() => _isSwitchingCamera = false);
  }

  Future<void> _moveToTrash(Expense expense) async {
    final id = expense.id;
    if (id == null) return;
    await ref.read(expenseProvider.notifier).moveToTrash(id);
    if (!mounted) return;

    final remaining = buildFeedPhotos(ref.read(expenseProvider).expenses)
        .length;
    final lastPage = remaining;
    if (_pageIndex > lastPage && _pageController.hasClients) {
      _pageController.jumpToPage(lastPage);
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Đã chuyển khoảnh khắc vào thùng rác.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () =>
              ref.read(expenseProvider.notifier).restoreExpense(id),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openPhotoGrid() async {
    final photos = buildFeedPhotos(ref.read(expenseProvider).expenses);
    if (photos.isEmpty) return;

    final selectedIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FeedGridScreen(photos: photos),
      ),
    );
    if (!mounted || selectedIndex == null || !_pageController.hasClients) {
      return;
    }

    await _pageController.animateToPage(
      selectedIndex + 1,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final categories = ref.watch(categoryProvider).categories;
    final priorities = ref.watch(priorityProvider).levels;
    final photos = buildFeedPhotos(expenseState.expenses);
    final categoryMap = {
      for (final category in categories) category.id: category,
    };
    final priorityMap = {
      for (final priority in priorities) priority.id: priority,
    };

    if (_pageIndex > photos.length && _pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(photos.length);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.feedBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: 1 + photos.length,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CameraFeedPage(
                    controller: _isCameraInitialized ? _controller : null,
                    isInitializing: _isCameraInitializing,
                    errorMessage: _cameraError,
                    hasPhotos: photos.isNotEmpty,
                    onPickFromGallery: _pickFromGallery,
                  );
                }

                final expense = photos[index - 1];
                final category = categoryMap[expense.categoryId];
                final priority = priorityMap[expense.priority];
                return FeedPhotoPage(
                  key: ValueKey('feed-photo-${expense.id ?? index}-$index'),
                  expense: expense,
                  category: category,
                  priority: priority,
                  onEdit: () => _openExpenseForm(expense: expense),
                  onDelete: () => _moveToTrash(expense),
                );
              },
            ),
            _buildTopBar(photos),
            if (_pageIndex == 0) _buildCameraControls(photos: photos),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(List<Expense> photos) {
    final isCameraPage = _pageIndex == 0;
    final currentPhoto = !isCameraPage && _pageIndex - 1 < photos.length
        ? photos[_pageIndex - 1]
        : null;
    final subtitle = currentPhoto != null
        ? '${DateFormatter.formatDate(currentPhoto.createdAt)} • ${DateFormatter.formatTime(currentPhoto.createdAt)}'
        : 'Nhật ký chi tiêu hôm nay';

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.feedTopGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
            child: Row(
              children: [
                HamburgerButton(onTap: widget.onMenuTap, light: true),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Chi Tiêu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          subtitle,
                          key: ValueKey(subtitle),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (photos.isNotEmpty)
                  _CountBadge(
                    label: isCameraPage
                        ? '${photos.length} ảnh'
                        : '$_pageIndex/${photos.length}',
                    icon: Icons.grid_view_rounded,
                    onTap: _openPhotoGrid,
                  )
                else
                  const SizedBox(width: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraControls({required List<Expense> photos}) {
    final canShoot = _isCameraInitialized && !_isCapturing;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 26),
        decoration: const BoxDecoration(gradient: AppColors.feedBottomGradient),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                photos.isEmpty
                    ? 'Chụp khoảnh khắc chi tiêu đầu tiên'
                    : 'Vuốt lên để xem ${photos.length} khoảnh khắc',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RoundOverlayButton(
                    icon: Icons.photo_library_rounded,
                    tooltip: 'Chọn ảnh từ thư viện',
                    onTap: _pickFromGallery,
                  ),
                  _ShutterButton(
                    enabled: canShoot,
                    busy: _isCapturing,
                    onTap: _takePicture,
                  ),
                  if (_cameras.length > 1)
                    _RoundOverlayButton(
                      icon: Icons.flip_camera_ios_rounded,
                      tooltip: 'Đổi camera',
                      onTap: _switchCamera,
                    )
                  else
                    _RoundOverlayButton(
                      icon: Icons.add_a_photo_rounded,
                      tooltip: 'Chọn ảnh từ thư viện',
                      onTap: _pickFromGallery,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraFeedPage extends StatelessWidget {
  final CameraController? controller;
  final bool isInitializing;
  final String? errorMessage;
  final bool hasPhotos;
  final VoidCallback onPickFromGallery;

  const _CameraFeedPage({
    required this.controller,
    required this.isInitializing,
    required this.errorMessage,
    required this.hasPhotos,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null)
            _FullScreenCameraPreview(controller: controller!)
          else
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.pageGradientDark),
            ),
          if (isInitializing && controller == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: _FeedNoticeCard(
                  icon: Icons.no_photography_rounded,
                  title: 'Camera chưa sẵn sàng',
                  message: errorMessage!,
                  actionLabel: 'Chọn ảnh từ thư viện',
                  onAction: onPickFromGallery,
                ),
              ),
            ),
          if (!hasPhotos && errorMessage == null && controller != null)
            const Align(
              alignment: Alignment(0, -0.08),
              child: IgnorePointer(
                child: _FeedNoticeCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Bắt đầu nhật ký chi tiêu',
                  message: 'Mỗi bức ảnh là một khoảnh khắc. Chụp hóa đơn hoặc chọn ảnh để lưu lại khoản chi.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullScreenCameraPreview extends StatelessWidget {
  final CameraController controller;
  const _FullScreenCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _FeedNoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FeedNoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 23),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.photo_library_rounded, size: 17),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CountBadge({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundOverlayButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundOverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.13),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.55,
        child: Container(
          width: 86,
          height: 86,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.5),
            color: Colors.black.withValues(alpha: 0.18),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.captureButtonGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }
}
