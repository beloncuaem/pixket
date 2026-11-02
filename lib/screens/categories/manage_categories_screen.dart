import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/category.dart';
import '../../providers/category_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_badge.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_dialog.dart';
import '../../widgets/pixel/pixel_empty_state.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_screen_header.dart';
import '../../widgets/pixel/pixel_star_field.dart';
import '../../widgets/pixel/pixel_text_field.dart';
import 'category_glyph_grid.dart';

/// Trả về null khi tên hợp lệ; so sánh trùng không phân biệt hoa thường.
String? validateCategoryName(String raw, List<String> existingNames) {
  final name = raw.trim();
  if (name.isEmpty) return 'Nhập tên danh mục.';
  final lower = name.toLowerCase();
  for (final existing in existingNames) {
    if (existing.toLowerCase() == lower) {
      return 'Danh mục “$name” đã tồn tại.';
    }
  }
  return null;
}

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) async {
    final selfId = category?.id;
    final existingNames = [
      for (final item in ref.read(categoryProvider).categories)
        if (selfId == null || item.id != selfId) item.name,
    ];
    await showPixelDialog<void>(
      context: context,
      title: category == null ? 'DANH MỤC MỚI' : 'SỬA DANH MỤC',
      content: _CategoryForm(category: category, existingNames: existingNames),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final shouldDelete = await showPixelConfirm(
      context,
      title: 'XÓA DANH MỤC?',
      message:
          'Các khoản chi thuộc “${category.name}” sẽ chuyển sang “Khác”. '
          'Ngân sách của danh mục này sẽ bị xóa.',
      confirmLabel: 'XÓA',
    );
    if (shouldDelete && category.id != null) {
      await ref.read(categoryProvider.notifier).deleteCategory(category.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final state = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: PixelStarField()),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: PixelScreenHeader(
                  title: 'QUẢN LÝ DANH MỤC',
                  subtitle: '${state.categories.length} danh mục',
                  onBackTap: () => Navigator.of(context).pop(),
                  trailing: AppIcon(
                    name: 'tag',
                    size: 32,
                    color: palette.inkMuted,
                  ),
                ),
              ),
              Expanded(
                child: state.isLoading && state.categories.isEmpty
                    ? const Center(
                        child: PixelLoading(label: 'Đang tải danh mục'),
                      )
                    : state.categories.isEmpty
                    ? const PixelEmptyState(
                        glyph: 'tag',
                        title: 'Chưa có danh mục',
                        message: 'Thêm danh mục để phân loại khoản chi.',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        children: [
                          if (state.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PixelPanel(
                                background: palette.butter,
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    AppIcon(
                                      name: 'alert',
                                      size: 32,
                                      color: palette.butterInk,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        state.errorMessage!,
                                        style: text.bodyMedium?.copyWith(
                                          color: palette.butterInk,
                                        ),
                                      ),
                                    ),
                                    PixelButton(
                                      label: 'THỬ LẠI',
                                      variant: PixelButtonVariant.secondary,
                                      icon: 'refresh',
                                      onPressed: () => ref
                                          .read(categoryProvider.notifier)
                                          .loadCategories(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          for (final category in state.categories)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _CategoryRow(
                                category: category,
                                onEdit: () => _showCategoryDialog(
                                  context,
                                  ref,
                                  category: category,
                                ),
                                onDelete: () =>
                                    _confirmDelete(context, ref, category),
                              ),
                            ),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: PixelButton(
                    key: const ValueKey('addCategoryButton'),
                    label: 'THÊM DANH MỤC',
                    icon: 'plus',
                    expanded: true,
                    onPressed: () => _showCategoryDialog(context, ref),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final accent = palette.accentForCategory(category.name);

    return PixelPanel(
      key: ValueKey('category-row-${category.id}'),
      padding: const EdgeInsets.all(12),
      onTap: category.isDefault ? null : onEdit,
      child: Row(
        children: [
          AppIcon(
            name: IconHelper.normalizeIconKey(category.icon),
            size: 32,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(category.name, style: text.titleMedium),
                ),
                Text(
                  category.isDefault
                      ? 'Danh mục hệ thống'
                      : 'Chạm để chỉnh sửa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: palette.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (category.isDefault)
            const PixelBadge(glyph: 'lock', label: 'MẶC ĐỊNH')
          else ...[
            PixelIconButton(
              icon: 'edit',
              tooltip: 'Sửa danh mục',
              onPressed: onEdit,
            ),
            const SizedBox(width: 8),
            PixelIconButton(
              icon: 'trash',
              tooltip: 'Xóa danh mục',
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryForm extends ConsumerStatefulWidget {
  final Category? category;
  final List<String> existingNames;

  const _CategoryForm({required this.category, required this.existingNames});

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.category?.name ?? '',
  );
  late String _icon = IconHelper.normalizeIconKey(
    widget.category?.icon ?? 'dotsThreeOutline',
  );
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = validateCategoryName(_name.text, widget.existingNames);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final name = _name.text.trim();
    setState(() => _isSaving = true);
    final notifier = ref.read(categoryProvider.notifier);
    final category = widget.category;
    if (category == null) {
      await notifier.addCategory(name, _icon);
    } else {
      await notifier.updateCategory(category.copyWith(name: name, icon: _icon));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pixelGroupHeader('Biểu tượng'),
          CategoryGlyphGrid(
            selected: _icon,
            onChanged: (value) => setState(() => _icon = value),
          ),
          const SizedBox(height: 16),
          PixelTextField(
            key: const ValueKey('categoryNameField'),
            label: 'Tên danh mục',
            hint: 'Ví dụ: Cà phê, Du lịch',
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'HỦY',
                  variant: PixelButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  label: 'LƯU',
                  icon: 'check',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
