import 'package:flutter/material.dart';

import '../core/config/supabase_config.dart';
import '../core/constants/app_info.dart';
import '../core/navigation/app_section.dart';
import '../core/theme/app_palette.dart';
import 'pixel/app_icon.dart';
import 'pixel/pixel_divider.dart';
import 'pixel/pixel_logo.dart';

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
    final palette = context.palette;
    return Drawer(
      width: 316,
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(
            right: BorderSide(color: palette.lineStrong, width: 3),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    // Mark thương hiệu thay avatar chữ 'P' (cùng cỡ 40 nên không
                    // đổi layout); avatar của người dùng nằm ở _ProfileCard.
                    const PixelLogo(size: 40, mono: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppInfo.name.toUpperCase(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            AppInfo.tagline,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: palette.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: AppIcon(
                        name: 'close',
                        size: 20,
                        color: palette.ink,
                        semanticLabel: 'Đóng menu',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProfileCard(
                  displayName: displayName,
                  email: email,
                  onLogout: () => _closeThen(context, () => onLogout()),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    const _SectionLabel('KHÔNG GIAN'),
                    for (final section in AppSection.values)
                      _DrawerTile(
                        glyph: section.glyph,
                        label: section.label,
                        selected: section == selected,
                        onTap: () =>
                            _closeThen(context, () => onSelectSection(section)),
                      ),
                    const SizedBox(height: 16),
                    const _SectionLabel('TIỆN ÍCH'),
                    _DrawerTile(
                      glyph: 'tag',
                      label: 'Quản lý danh mục',
                      onTap: () => _closeThen(context, onOpenCategories),
                    ),
                    _DrawerTile(
                      glyph: 'trash',
                      label: 'Thùng rác',
                      onTap: () => _closeThen(context, onOpenTrash),
                    ),
                    _DrawerTile(
                      glyph: 'settings',
                      label: 'Cài đặt',
                      onTap: () => _closeThen(context, onOpenSettings),
                    ),
                    const PixelDivider(),
                    _DrawerTile(
                      glyph: isDarkMode ? 'moon' : 'sun',
                      label: 'Giao diện tối',
                      onTap: onToggleTheme,
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (_) => onToggleTheme(),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    AppIcon(
                      name: SupabaseConfig.isInitialized ? 'cloud' : 'cloudOff',
                      size: 16,
                      color: palette.inkMuted,
                      semanticLabel: SupabaseConfig.isInitialized
                          ? 'Đã kết nối đám mây'
                          : 'Chưa kết nối đám mây',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppInfo.aboutLabel,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: palette.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô avatar vuông bo góc nhẹ, nền mint chữ đậm — không dùng ảnh.
class _Avatar extends StatelessWidget {
  final String letter;
  const _Avatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.mint,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.lineStrong, width: 2),
      ),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            letter.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: palette.onAccent),
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
    final palette = context.palette;
    final initial = displayName.trim().isEmpty
        ? AppInfo.name[0]
        : displayName.trim()[0];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.lineStrong, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Avatar(letter: initial),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    email ?? 'Tài khoản đám mây',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.inkMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AppIcon(name: 'cloud', size: 14, color: palette.mintInk),
                      const SizedBox(width: 5),
                      Text(
                        'Cloud Sync',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: palette.mintInk),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: onLogout,
              icon: AppIcon(
                name: 'logout',
                size: 20,
                color: palette.danger,
                semanticLabel: 'Đăng xuất',
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: context.palette.inkMuted, letterSpacing: 1.4),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final String glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerTile({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = selected ? palette.onAccent : palette.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected ? palette.mint : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border(
                  left: BorderSide(
                    color: selected ? palette.lineStrong : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  AppIcon(name: glyph, size: 20, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(color: fg),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
