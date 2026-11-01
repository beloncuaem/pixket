import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_snack_bar.dart';
import '../../widgets/pixel/pixel_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .signUpWithEmail(
          _emailController.text,
          _passwordController.text,
          fullName: _nameController.text.trim(),
        );
    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        showPixelSnackBar(context, error, tone: PixelTone.danger);
      }
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final busy = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        leading: PixelIconButton(
          icon: 'back',
          tooltip: 'Quay lại',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tạo tài khoản mới',
                    style: text.headlineSmall?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bắt đầu ghi chi tiêu và đồng bộ ảnh hóa đơn lên Cloud',
                  style: text.bodySmall?.copyWith(color: palette.inkMuted),
                ),
                const SizedBox(height: 24),

                PixelPanel(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PixelTextField(
                          key: const Key('registerNameField'),
                          label: 'Họ và tên',
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập họ tên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        PixelTextField(
                          key: const Key('registerEmailField'),
                          label: 'Email',
                          hint: 'you@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!value.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        PixelTextField(
                          key: const Key('registerPasswordField'),
                          label: 'Mật khẩu',
                          controller: _passwordController,
                          obscureToggle: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu từ 6 ký tự trở lên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        PixelTextField(
                          key: const Key('registerConfirmField'),
                          label: 'Xác nhận mật khẩu',
                          controller: _confirmPasswordController,
                          obscureToggle: true,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        PixelButton(
                          key: const Key('registerSubmitButton'),
                          label: 'ĐĂNG KÝ',
                          icon: 'check',
                          expanded: true,
                          isLoading: busy,
                          onPressed: busy ? null : _handleRegister,
                        ),
                      ],
                    ),
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
