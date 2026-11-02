import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/password_policy.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_snack_bar.dart';
import '../../widgets/pixel/pixel_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final ok = await ref
        .read(authProvider.notifier)
        .setNewPassword(_passwordController.text);
    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      ref.read(authProvider.notifier).exitRecoveryMode();
      showPixelSnackBar(
        context,
        'Mật khẩu mới đã có hiệu lực.',
        tone: PixelTone.success,
      );
      return;
    }
    final error = ref.read(authProvider).errorMessage;
    showPixelSnackBar(
      context,
      error ?? 'Không thể đổi mật khẩu. Thử lại sau.',
      tone: PixelTone.danger,
    );
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Nhập lại mật khẩu để xác nhận';
    if (value != _passwordController.text) {
      return 'Mật khẩu nhập lại chưa khớp';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: PixelPanel(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mật khẩu mới',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Link đặt lại mật khẩu đã hoạt động. Chọn mật khẩu mới cho tài khoản của bạn.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: palette.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    PixelTextField(
                      key: const Key('newPasswordField'),
                      controller: _passwordController,
                      label: 'Mật khẩu mới',
                      obscureToggle: true,
                      validator: (value) {
                        return PasswordPolicy.validate(value ?? '');
                      },
                    ),
                    const SizedBox(height: 12),
                    PixelTextField(
                      key: const Key('confirmPasswordField'),
                      controller: _confirmController,
                      label: 'Nhập lại mật khẩu',
                      obscureToggle: true,
                      validator: _validateConfirm,
                    ),
                    const SizedBox(height: 20),
                    PixelButton(
                      label: 'Đặt lại mật khẩu',
                      isLoading: _busy,
                      onPressed: _busy ? null : _submit,
                    ),
                    const SizedBox(height: 8),
                    PixelButton(
                      label: 'Hủy',
                      variant: PixelButtonVariant.ghost,
                      onPressed: () =>
                          ref.read(authProvider.notifier).exitRecoveryMode(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
