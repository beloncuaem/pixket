import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/friend_provider.dart';
import '../../widgets/pixel/pixel_panel.dart';

class ProfileEditPanel extends ConsumerStatefulWidget {
  const ProfileEditPanel({super.key});

  @override
  ConsumerState<ProfileEditPanel> createState() => _ProfileEditPanelState();
}

class _ProfileEditPanelState extends ConsumerState<ProfileEditPanel> {
  final _nickController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final v = _nickController.text.trim();
    if (v.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateNickname(v);
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu biệt danh.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(bytes);
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ảnh đại diện.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (_nickController.text.isEmpty) {
      _nickController.text = profile.valueOrNull?.nickname ?? '';
    }
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HỒ SƠ BẠN BÈ',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: profile.valueOrNull?.avatarUrl != null
                    ? NetworkImage(profile.valueOrNull!.avatarUrl!)
                    : null,
                child: profile.valueOrNull?.avatarUrl == null
                    ? const Text('?')
                    : null,
              ),
              FilledButton.tonal(
                onPressed: _saving ? null : _pickAvatar,
                child: const Text('Đổi ảnh đại diện'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nickController,
            decoration: const InputDecoration(
              labelText: 'Biệt danh',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _saveNickname,
            child: const Text('Lưu biệt danh'),
          ),
        ],
      ),
    );
  }
}