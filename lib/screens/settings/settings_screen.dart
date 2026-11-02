import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/app_info.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_chip.dart';
import '../../widgets/pixel/pixel_dialog.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_screen_header.dart';
import '../categories/manage_categories_screen.dart';
import '../trash/trash_screen.dart';
import 'csv_export_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final authState = ref.watch(authProvider);
    final palette = context.palette;

    final user = authState.user;
    final email = user?.email;
    final name = (user?.userMetadata?['full_name'] as String?)?.trim();
    final displayName = (name == null || name.isEmpty)
        ? (email != null ? email.split('@').first : 'Bạn')
        : name;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: PixelScreenHeader(
              title: 'CÀI ĐẶT',
              subtitle: AppInfo.tagline,
              onBackTap: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            // SingleChildScrollView + Column thay cho ListView: mục cố định và
            // ít, dựng hết một lượt để mọi panel đều được render (không lazy).
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfilePanel(displayName: displayName, email: email),
                  pixelGroupHeader('DỮ LIỆU'),
                  _NavRow(
                    glyph: 'download',
                    label: 'Xuất CSV (sao lưu)',
                    onTap: () => showCsvExportSheet(context),
                  ),
                  _NavRow(
                    glyph: 'tag',
                    label: 'Quản lý danh mục',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ManageCategoriesScreen(),
                      ),
                    ),
                  ),
                  _NavRow(
                    glyph: 'trash',
                    label: 'Thùng rác',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TrashScreen(),
                      ),
                    ),
                  ),
                  pixelGroupHeader('GIAO DIỆN & HIỆU ỨNG'),
                  _ThemeRow(isDarkMode: isDarkMode),
                  const _EffectRow(
                    settingKey: 'fx_stars',
                    glyph: 'sparkle',
                    label: 'Nền sao (chế độ tối)',
                    hint: 'Chấm sao nhấp nháy trên nền đêm',
                  ),
                  const _EffectRow(
                    settingKey: 'fx_rainbow_rule',
                    glyph: 'grid',
                    label: 'Vệt cầu vồng dưới header',
                    hint: 'Dải 6 màu chạy ngang đầu màn hình',
                  ),
                  const _EffectRow(
                    settingKey: 'fx_capture_sweep',
                    glyph: 'camera',
                    label: 'Cầu vồng quét khi chụp',
                    hint: 'Chuyển cảnh sau khi bấm chụp',
                  ),
                  const _EffectRow(
                    settingKey: 'fx_confetti',
                    glyph: 'gift',
                    label: 'Pháo giấy khi lưu',
                    hint: '24 ô bay lên khi lưu khoản chi',
                  ),
                  const _EffectRow(
                    settingKey: 'fx_mosaic',
                    glyph: 'grid',
                    label: 'Lật mosaic khi đổi mục',
                    hint: 'Lưới ô lật khi chuyển tab',
                  ),
                  const _EffectRow(
                    settingKey: 'chart_spend_ramp',
                    glyph: 'chart',
                    label: 'Biểu đồ tô theo mức chi',
                    hint: 'Tắt để tô theo danh mục như cũ',
                  ),
                  pixelGroupHeader('TÀI KHOẢN'),
                  _NavRow(
                    glyph: 'logout',
                    label: 'Đăng xuất',
                    ink: palette.danger,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                  pixelGroupHeader('VỀ APP'),
                  const _AboutPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final yes = await showPixelConfirm(
    context,
    title: 'ĐĂNG XUẤT?',
    message: 'Bạn cần đăng nhập lại để xem dữ liệu trên cloud.',
    confirmLabel: 'ĐĂNG XUẤT',
    cancelLabel: 'HỦY',
    danger: false,
  );
  if (!yes) return;
  await ref.read(authProvider.notifier).signOut();
}

class _ProfilePanel extends StatelessWidget {
  final String displayName;
  final String? email;

  const _ProfilePanel({required this.displayName, this.email});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final connected = SupabaseConfig.isInitialized;

    return PixelPanel(
      background: palette.mint,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.mintStrong,
                  border: Border.all(color: palette.lineStrong, width: 3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                    style: text.displaySmall?.copyWith(color: palette.onAccent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        displayName,
                        style: text.titleLarge?.copyWith(
                          color: palette.onAccent,
                        ),
                      ),
                    ),
                    Text(
                      email ?? 'Tài khoản đám mây',
                      style: text.bodySmall?.copyWith(color: palette.onAccent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppIcon(
                name: connected ? 'cloud' : 'cloudOff',
                size: 32,
                color: palette.onAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  connected
                      ? 'Đang kết nối Supabase'
                      : 'Chưa cấu hình Supabase. Kiểm tra biến môi trường.',
                  style: text.bodySmall?.copyWith(color: palette.onAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeRow extends ConsumerWidget {
  final bool isDarkMode;

  const _ThemeRow({required this.isDarkMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return PixelPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          AppIcon(
            name: isDarkMode ? 'moon' : 'sun',
            size: 32,
            color: palette.inkMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ tối',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  isDarkMode ? 'Nền tối, chữ sáng' : 'Nền kem, chữ đậm',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: palette.inkMuted),
                ),
              ],
            ),
          ),
          PixelChip(
            key: const ValueKey('darkModeToggle'),
            label: isDarkMode ? 'TỐI' : 'SÁNG',
            icon: isDarkMode ? 'moon' : 'sun',
            selected: isDarkMode,
            showCheck: false,
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
    );
  }
}

class _EffectRow extends ConsumerWidget {
  final String settingKey;
  final String glyph;
  final String label;
  final String hint;

  const _EffectRow({
    required this.settingKey,
    required this.glyph,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final effects = ref.watch(effectsProvider);
    final on = switch (settingKey) {
      'fx_stars' => effects.stars,
      'fx_rainbow_rule' => effects.rainbowRule,
      'fx_capture_sweep' => effects.captureSweep,
      'fx_confetti' => effects.confetti,
      'fx_mosaic' => effects.mosaic,
      _ => effects.chartSpendRamp,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PixelPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            AppIcon(name: glyph, size: 32, color: palette.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    hint,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ),
            ),
            // Chỉ chip mang key: nếu _EffectRow cùng key thì find.byKey trả 2 widget.
            PixelChip(
              key: ValueKey(settingKey),
              label: on ? 'BẬT' : 'TẮT',
              icon: on ? 'check' : 'close',
              selected: on,
              showCheck: false,
              onTap: () =>
                  ref.read(effectsProvider.notifier).set(settingKey, !on),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String glyph;
  final String label;
  final VoidCallback onTap;
  final Color? ink;

  const _NavRow({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = ink ?? palette.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PixelPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            AppIcon(name: glyph, size: 32, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppIcon(name: 'chevronRight', size: 16, color: palette.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return PixelPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.mint,
                  border: Border.all(color: palette.lineStrong, width: 3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: AppIcon(
                    name: 'wallet',
                    size: 32,
                    color: palette.onAccent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppInfo.name, style: text.titleLarge),
                    Text(
                      AppInfo.aboutLabel,
                      style: text.bodySmall?.copyWith(color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mỗi khoản chi cần một ảnh. Ảnh lưu ở bucket private, chỉ bạn đọc '
            'được qua đường dẫn ký tạm.',
            style: text.bodySmall?.copyWith(color: palette.inkMuted),
          ),
        ],
      ),
    );
  }
}
