import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_section.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_drawer.dart';
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

    return Scaffold(
      key: _scaffoldKey,
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _buildSection(_section),
      ),
    );
  }
}
