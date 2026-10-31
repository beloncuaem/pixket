import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../categories/manage_categories_screen.dart';
import '../trash/trash_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // App Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradientDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi Tiêu App',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.user?.email ?? 'Tài khoản đám mây',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cloud Account Section
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.cloud_done_outlined, color: AppColors.primary),
                  title: Text('Dữ liệu trên Cloud'),
                  subtitle: Text(
                    'Mọi khoản chi, danh mục và ngân sách được lưu trực tiếp trên Supabase.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.priority3,
                  ),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: AppColors.priority3),
                  ),
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Preferences & Features
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Chế độ tối'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: isDarkMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Quản lý danh mục'),
                  leading: const Icon(Icons.label_outline_rounded),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageCategoriesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Thùng rác'),
                  leading: const Icon(Icons.delete_outline_rounded),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TrashScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              AppInfo.aboutLabel,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
