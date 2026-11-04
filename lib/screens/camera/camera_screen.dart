import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/platform/local_draft_store.dart';
import '../../core/platform/photo_capture.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/square_image.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/priority_provider.dart';
import '../../widgets/hamburger_button.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/feed_hud.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_ship_flight.dart';
import '../../widgets/pixel/pixel_star_field.dart';
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
  bool _isCapturing = false;
  bool _isSwitchingCamera = false;

  final PageController _pageController = PageController();
  int _pageIndex = 0;

  /// Trạng thái hiển thị suy ra từ seam, không nhân bản sang screen — screen
  /// mà tự nhớ "đang khởi tạo" thì bản web treo ở indicator.
  PhotoCapturePane get _pane {
    // Đang đổi thị kính: seam đã tắt ống ngắm trong lúc mở camera mới, nhưng
    // screen phải ẩn frame cũ ngay khi người dùng bấm chứ không chờ await xong.
    if (_isSwitchingCamera) return PhotoCapturePane.initializing;
    return photoCapturePaneFor(
      supportsLiveViewfinder: photoCapture.supportsLiveViewfinder,
      isReady: photoCapture.isReady,
      errorMessage: photoCapture.errorMessage,
    );
  }

  @override
  void initState() {
    super.initState();
    _openCapture();
  }

  Future<void> _openCapture() async {
    await photoCapture.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    photoCapture.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    final pane = _pane;
    if (pane == PhotoCapturePane.initializing ||
        pane == PhotoCapturePane.error) {
      _showSnackBar('Camera chưa sẵn sàng. Hãy chọn ảnh từ thư viện.');
      return;
    }

    // Seam còn đang chụp dở thì bỏ qua cú bấm này *trước khi* screen đổi trạng
    // thái: làm ngược lại là nút chụp bị mờ mất một frame dù không có ảnh nào
    // được chụp (giữ đúng thứ tự màn camera cũ).
    if (photoCapture.isTakingPicture) return;

    setState(() => _isCapturing = true);
    try {
      final bytes = await photoCapture.capture();
      if (bytes == null || !mounted) return;
      final squared = await squareBytes(bytes);
      final draft = await localDraftStore.save(
        squared ?? bytes,
        extension: 'jpg',
        squared: squared != null,
      );
      if (!mounted) return;
      // Phi thuyền bay qua không chặn luồng: cắt ảnh xong là mở form ngay.
      PixelShipFlight.launch(context);
      _openExpenseForm(imagePath: draft);
    } catch (error) {
      debugPrint('Error taking picture: $error');
      if (mounted) _showSnackBar('Không thể chụp ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await photoCapture.pickFromGallery();
      if (picked == null || !mounted) return;
      final squared = await squareBytes(picked.bytes);
      final draft = await localDraftStore.save(
        squared ?? picked.bytes,
        extension: picked.extension,
        squared: squared != null,
      );
      if (!mounted) return;
      await _openExpenseForm(imagePath: draft);
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
    if (!photoCapture.canSwitchCamera || _isCapturing || _isSwitchingCamera) {
      return;
    }
    setState(() => _isSwitchingCamera = true);

    await photoCapture.useNextCamera();
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
                  final pane = _pane;
                  return _CameraFeedPage(
                    pane: pane,
                    viewfinder: pane == PhotoCapturePane.liveViewfinder
                        ? photoCapture.buildViewfinder(context)
                        : null,
                    errorMessage: photoCapture.errorMessage,
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
                  photoIndex: index,
                  photoCount: photos.length,
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
                  PixelIconButton(
                    icon: 'grid',
                    tooltip: 'Xem lưới ảnh',
                    onPressed: _openPhotoGrid,
                    background: palette.feedPanel,
                    borderColor: palette.feedInk,
                    iconColor: palette.feedInk,
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
    final pane = _pane;
    // Trên nền tảng không có ống ngắm sống, nút chụp mở đường chọn ảnh của
    // trình duyệt nên vẫn phải bấm được; chỉ hai trạng thái chờ/lỗi mới tắt.
    final canShoot =
        !_isCapturing &&
        pane != PhotoCapturePane.initializing &&
        pane != PhotoCapturePane.error;
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
                    // Không có camera thứ hai thì slot thứ ba nghỉ chứ không
                    // biến thành lối thứ hai mở cùng một thư viện (web đã có
                    // nút dải phim + card hướng dẫn); ô 48 px vẫn giữ máy chụp
                    // ở giữa HUD.
                    if (photoCapture.canSwitchCamera)
                      PixelIconButton(
                        icon: 'refresh',
                        tooltip: 'Đổi camera',
                        onPressed: _switchCamera,
                        background: palette.feedPanel,
                        borderColor: palette.feedInk,
                        iconColor: palette.feedInk,
                      )
                    else
                      const SizedBox(width: 48),
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
  final PhotoCapturePane pane;
  final Widget? viewfinder;
  final String? errorMessage;
  final bool hasPhotos;
  final VoidCallback onPickFromGallery;

  const _CameraFeedPage({
    required this.pane,
    required this.viewfinder,
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
          const Positioned.fill(child: PixelStarField()),
          if (viewfinder != null) Positioned.fill(child: viewfinder!),
          if (pane == PhotoCapturePane.initializing)
            const Center(child: PixelLoading(label: 'Đang mở camera…')),
          if (pane == PhotoCapturePane.error)
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
          if (pane == PhotoCapturePane.galleryPrompt)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _FeedNoticeCard(
                  glyph: 'filmStrip',
                  title: 'Chọn ảnh từ thư viện',
                  message: 'Pixket chưa mở được ống ngắm trong trình duyệt. Chụp bằng camera của hệ thống rồi chọn ảnh đó, hoặc chọn hóa đơn đã có sẵn.',
                  actionLabel: 'MỞ THƯ VIỆN ẢNH',
                  onAction: onPickFromGallery,
                ),
              ),
            ),
          if (!hasPhotos && pane == PhotoCapturePane.liveViewfinder)
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

/// Nút chụp: ô vuông nền đêm, viền kem 4 px, dấu cộng kem — đồng bộ với các
/// nút HUD quanh nó thay vì khối lục nổi bật.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed, required this.enabled});

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ink = enabled ? palette.feedInk : palette.feedMuted;
    return Semantics(
      button: true,
      label: 'Chụp khoản chi',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: palette.feedPanel,
            border: Border.all(color: ink, width: 4),
          ),
          child: Center(
            child: AppIcon(name: 'plus', size: 32, color: ink),
          ),
        ),
      ),
    );
  }
}
