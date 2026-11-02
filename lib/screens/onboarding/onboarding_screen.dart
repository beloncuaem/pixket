import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_star_field.dart';

/// Ba glyph mở màn, lấy từ registry đã có (không thêm glyph mới).
const List<String> onboardingGlyphs = ['wallet', 'cloud', 'chart'];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardingPage(
      glyph: 'wallet',
      title: 'Chào mừng đến với Pixket',
      description: 'Ghi lại khoản chi bằng ảnh và theo dõi ngân sách của bạn mọi lúc, mọi nơi.',
    ),
    _OnboardingPage(
      glyph: 'cloud',
      title: 'Đồng bộ an toàn trên Cloud',
      description: 'Mỗi khoản chi cần một ảnh từ camera hoặc thư viện. Ảnh và dữ liệu được đồng bộ trên Cloud; máy chỉ giữ bản đệm tạm để xem nhanh.',
    ),
    _OnboardingPage(
      glyph: 'chart',
      title: 'Không vượt quá ngân sách',
      description: 'Bạn có thể nhận cảnh báo một lần ở các mốc 80%, 90% và 100% ngân sách tháng.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await Permission.camera.request();
    await NotificationService.instance.requestPermission();
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isLastPage = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: PixelStarField()),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: PixelButton(
                      label: 'BỎ QUA',
                      variant: PixelButtonVariant.ghost,
                      onPressed: _finish,
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (_, index) => _pages[index],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.all(4),
                      color: index == _page ? palette.ink : palette.line,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: PixelButton(
                      key: const ValueKey('onboarding-next'),
                      label: isLastPage ? 'BẮT ĐẦU' : 'TIẾP TỤC',
                      icon: isLastPage ? 'check' : 'chevronRight',
                      expanded: true,
                      onPressed: isLastPage
                          ? _finish
                          : () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String glyph;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.glyph,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final panelColor = switch (glyph) {
      'wallet' => palette.mint,
      'cloud' => palette.sky,
      _ => palette.butter,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PixelPanel(
            background: panelColor,
            padding: const EdgeInsets.all(28),
            child: AppIcon(
              name: glyph,
              size: 64,
              color: palette.onAccent,
              secondary: palette.mintInk,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: palette.inkMuted),
          ),
        ],
      ),
    );
  }
}
