import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/priority_provider.dart';
import '../../widgets/hamburger_button.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/feed_hud.dart';
import '../../widgets/pixel/pixel_badge.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_panel.dart';
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
    await openExpenseForm(context, imagePath: imagePath, expense: expense);
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

    final categoriesById = <int, Category>{
      for (final category in ref.read(categoryProvider).categories)
        if (category.id != null) category.id!: category,
    };
    final selectedIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            FeedGridScreen(expenses: photos, categoriesById: categoriesById),
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
      backgroundColor: context.palette.feedBg,
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
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
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
        decoration: BoxDecoration(gradient: hudTopGradient(palette)),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
            child: Row(
              children: [
                HamburgerButton(onTap: widget.onMenuTap, light: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'NHẬT KÝ ${DateFormat('MM/yyyy').format(DateTime.now())}',
                          style: text.titleMedium?.copyWith(
                            color: palette.feedInk,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 120),
                        child: Text(
                          subtitle,
                          key: ValueKey(subtitle),
                          style: text.bodySmall?.copyWith(
                            color: palette.feedMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (photos.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelBadge(
                        glyph: 'filmStrip',
                        label: isCameraPage
                            ? '${photos.length} ảnh'
                            : '$_pageIndex/${photos.length}',
                        ink: palette.feedInk,
                      ),
                      PixelIconButton(
                        icon: 'grid',
                        tooltip: 'Xem lưới ảnh',
                        onPressed: _openPhotoGrid,
                        background: palette.feedPanel,
                        borderColor: palette.feedInk,
                        iconColor: palette.feedInk,
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraControls({required List<Expense> photos}) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final canShoot = _isCameraInitialized && !_isCapturing;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: hudBottomGradient(palette)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  photos.isEmpty
                      ? 'Chụp khoảnh khắc chi tiêu đầu tiên'
                      : 'Vuốt lên để xem ${photos.length} khoảnh khắc',
                  textAlign: TextAlign.center,
                  style: text.labelLarge?.copyWith(color: palette.feedMuted),
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppIcon(
                    name: 'chevronDown',
                    size: 18,
                    color: palette.feedMuted,
                    semanticLabel: 'Vuốt lên',
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PixelIconButton(
                      icon: 'filmStrip',
                      tooltip: 'Chọn ảnh từ thư viện',
                      onPressed: _pickFromGallery,
                      background: palette.feedPanel,
                      borderColor: palette.feedInk,
                      iconColor: palette.feedInk,
                    ),
                    _ShutterButton(onPressed: _takePicture, enabled: canShoot),
                    if (_cameras.length > 1)
                      PixelIconButton(
                        icon: 'refresh',
                        tooltip: 'Đổi camera',
                        onPressed: _switchCamera,
                        background: palette.feedPanel,
                        borderColor: palette.feedInk,
                        iconColor: palette.feedInk,
                      )
                    else
                      PixelIconButton(
                        icon: 'plus',
                        tooltip: 'Chọn ảnh từ thư viện',
                        onPressed: _pickFromGallery,
                        background: palette.feedPanel,
                        borderColor: palette.feedInk,
                        iconColor: palette.feedInk,
                      ),
                  ],
                ),
              ],
            ),
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
    final palette = context.palette;
    return ColoredBox(
      color: palette.feedBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null)
            _FullScreenCameraPreview(controller: controller!)
          else
            ColoredBox(color: palette.feedPanel),
          if (controller != null) const _ViewfinderCorners(),
          if (isInitializing && controller == null)
            const Center(child: PixelLoading(label: 'Đang mở camera…')),
          if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _FeedNoticeCard(
                  glyph: 'cloudOff',
                  title: 'Camera chưa sẵn sàng',
                  message: errorMessage!,
                  actionLabel: 'CHỌN ẢNH TỪ THƯ VIỆN',
                  onAction: onPickFromGallery,
                ),
              ),
            ),
          if (!hasPhotos && errorMessage == null && controller != null)
            const Align(
              alignment: Alignment(0, -0.08),
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _FeedNoticeCard(
                    glyph: 'sparkle',
                    title: 'Bắt đầu nhật ký chi tiêu',
                    message: 'Mỗi bức ảnh là một khoảnh khắc. Chụp hóa đơn hoặc chọn ảnh để lưu lại khoản chi.',
                  ),
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
  final String glyph;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FeedNoticeCard({
    required this.glyph,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return PixelPanel(
      background: palette.feedPanel,
      borderColor: palette.feedInk,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(name: glyph, size: 32, color: palette.feedInk),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(color: palette.feedInk),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: palette.feedMuted,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            PixelButton(
              label: actionLabel!,
              icon: 'filmStrip',
              variant: PixelButtonVariant.secondary,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Khung ngắm pixel: 4 góc vuông đậm, không áp filter hay làm mờ ảnh xem trước.
class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  static const double _inset = 20;
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
      child: Stack(
        children: [
          Positioned(top: _inset, left: _inset, child: bracket(true, true)),
          Positioned(top: _inset, right: _inset, child: bracket(false, true)),
          Positioned(bottom: _inset, left: _inset, child: bracket(true, false)),
          Positioned(
            bottom: _inset,
            right: _inset,
            child: bracket(false, false),
          ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed, required this.enabled});

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: 'Chụp khoản chi',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: enabled ? palette.mint : palette.feedPanel,
            border: Border.all(color: palette.feedInk, width: 4),
          ),
          child: Center(
            child: AppIcon(
              name: 'camera',
              size: 32,
              color: enabled ? palette.onAccent : palette.feedMuted,
            ),
          ),
        ),
      ),
    );
  }
}
