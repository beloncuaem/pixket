import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_section.dart';
import '../core/theme/app_palette.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pixel/pixel_star_field.dart';
import 'budget/budget_screen.dart';
import 'camera/camera_screen.dart';
import 'categories/manage_categories_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
import 'statistics/statistics_screen.dart';
import 'trash/trash_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

/// Vùng mép trái nhận vuốt trên màn CHỤP, tránh xung đột gesture của camera.
const double _edgeSwipeWidth = 24;

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppSection _section = AppSection.feed;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _selectSection(AppSection section) {
    if (_section == section) return;
    setState(() => _section = section);
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).signOut();
  }

  Widget _buildSection(AppSection section) {
    return switch (section) {
      AppSection.feed => CameraScreen(
        key: const ValueKey('section-feed'),
        onMenuTap: _openDrawer,
      ),
      AppSection.dashboard => HomeScreen(
        key: const ValueKey('section-dashboard'),
        onMenuTap: _openDrawer,
        onOpenBudget: () => _selectSection(AppSection.budget),
        onOpenFeed: () => _selectSection(AppSection.feed),
      ),
      AppSection.statistics => StatisticsScreen(
        key: const ValueKey('section-statistics'),
        onMenuTap: _openDrawer,
      ),
      AppSection.budget => BudgetScreen(
        key: const ValueKey('section-budget'),
        onMenuTap: _openDrawer,
      ),
    };
  }

  double _swipeDx = 0;

  void _onSwipeStart(DragStartDetails details) => _swipeDx = 0;

  void _onSwipeUpdate(DragUpdateDetails details) =>
      _swipeDx += details.delta.dx;

  /// Mở drawer khi vuốt đủ xa hoặc đủ nhanh — không nhảy tab trực tiếp.
  void _onSwipeEnd(DragEndDetails details) {
    final far = _swipeDx.abs() > 40;
    final fast = (details.primaryVelocity?.abs() ?? 0) > 180;
    _swipeDx = 0;
    if (far || fast) _openDrawer();
  }

  /// Màn CHỤP chỉ nhận vuốt từ mép trái; các màn còn lại vuốt ở bất kỳ đâu.
  Widget _withSwipeToOpenDrawer(
    Widget child, {
    required Key key,
    required bool edgeOnly,
  }) {
    if (edgeOnly) {
      return Stack(
        key: key,
        children: [
          child,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _edgeSwipeWidth,
            child: GestureDetector(
              key: const ValueKey('edge-swipe-area'),
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onSwipeStart,
              onHorizontalDragUpdate: _onSwipeUpdate,
              onHorizontalDragEnd: _onSwipeEnd,
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onSwipeStart,
      onHorizontalDragUpdate: _onSwipeUpdate,
      onHorizontalDragEnd: _onSwipeEnd,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authState.user;
    final email = user?.email;
    final name = (user?.userMetadata?['full_name'] as String?)?.trim();
    final displayName = (name == null || name.isEmpty)
        ? (email != null ? email.split('@').first : 'Bạn')
        : name;
    final still = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.palette.canvas,
      drawer: AppDrawer(
        selected: _section,
        onSelectSection: _selectSection,
        onOpenCategories: () => _push(const ManageCategoriesScreen()),
        onOpenTrash: () => _push(const TrashScreen()),
        onOpenSettings: () => _push(const SettingsScreen()),
        onLogout: _handleLogout,
        onToggleTheme: () => ref.read(themeProvider.notifier).toggleTheme(),
        displayName: displayName,
        email: email,
        isDarkMode:
            themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system && isDark),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PixelStarField()),
          AnimatedSwitcher(
            duration: still ? Duration.zero : const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final scale = Tween<double>(begin: 0.98, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            child: _withSwipeToOpenDrawer(
              _buildSection(_section),
              key: ValueKey('swipe-${_section.name}'),
              edgeOnly: _section == AppSection.feed,
            ),
          ),
        ],
      ),
    );
  }
}
