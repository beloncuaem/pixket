import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_info.dart';
import '../core/navigation/app_section.dart';

class AppDrawer extends StatelessWidget {
  final AppSection selected;
  final ValueChanged<AppSection> onSelectSection;
  final VoidCallback onOpenCategories;
  final VoidCallback onOpenTrash;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onLogout;
  final VoidCallback onToggleTheme;
  final String displayName;
  final String? email;
  final bool isDarkMode;

  const AppDrawer({
    super.key,
    required this.selected,
    required this.onSelectSection,
    required this.onOpenCategories,
    required this.onOpenTrash,
    required this.onOpenSettings,
    required this.onToggleTheme,
    required this.displayName,
    required this.onLogout,
    required this.isDarkMode,
    this.email,
  });

  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 316,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F19), Color(0xFF111C2E), Color(0xFF07231D)],
          ),
          border: Border(right: BorderSide(color: Color(0x1FFFFFFF))),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chi Tiêu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Nhật ký chi tiêu của bạn',
                            style: TextStyle(
                              color: Color(0xFF8FA3BF),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _ProfileCard(
                  displayName: displayName,
                  email: email,
                  onLogout: () => _closeThen(context, () => onLogout()),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    const _SectionLabel('KHÔNG GIAN'),
                    for (final section in AppSection.values)
                      _DrawerTile(
                        icon: section.icon,
                        label: section.label,
                        selected: section == selected,
                        onTap: () =>
                            _closeThen(context, () => onSelectSection(section)),
                      ),
                    const SizedBox(height: 18),
                    const _SectionLabel('TIỆN ÍCH'),
                    _DrawerTile(
                      icon: Icons.category_rounded,
                      label: 'Quản lý danh mục',
                      onTap: () => _closeThen(context, onOpenCategories),
                    ),
                    _DrawerTile(
                      icon: Icons.delete_sweep_rounded,
                      label: 'Thùng rác',
                      onTap: () => _closeThen(context, onOpenTrash),
                    ),
                    _DrawerTile(
                      icon: Icons.settings_rounded,
                      label: 'Cài đặt',
                      onTap: () => _closeThen(context, onOpenSettings),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0x1AFFFFFF), height: 24),
                    _DrawerTile(
                      icon: isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      label: isDarkMode
                          ? 'Chuyển giao diện sáng'
                          : 'Chuyển giao diện tối',
                      onTap: () => _closeThen(context, onToggleTheme),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 10, 24, 18),
                child: Text(
                  AppInfo.aboutLabel,
                  style: TextStyle(
                    color: Color(0xFF5C6B82),
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String displayName;
  final String? email;
  final VoidCallback onLogout;

  const _ProfileCard({
    required this.displayName,
    required this.onLogout,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? 'C'
        : displayName.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.captureButtonGradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email ?? 'Tài khoản đám mây',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF93A4BC),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Cloud Sync',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: onLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFFF8A9B),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5F718D),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFFB9C6D8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected ? AppColors.primaryLight : foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
