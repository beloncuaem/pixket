import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/app_info.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_divider.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_snack_bar.dart';
import '../../widgets/pixel/pixel_star_field.dart';
import '../../widgets/pixel/pixel_text_field.dart';
import 'forgot_password_sheet.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!value.contains('@')) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    // Không áp sàn 8 ký tự ở đây: tài khoản tạo trước đó có thể đang dùng
    // mật khẩu 6-7 ký tự, chặn ở màn đăng nhập sẽ tự khoá họ ngoài app.
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .signInWithEmail(_emailController.text, _passwordController.text);
    if (!mounted) return;
    if (success) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }
    final error = ref.read(authProvider).errorMessage;
    if (error != null) {
      showPixelSnackBar(context, error, tone: PixelTone.danger);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final launched = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (launched) {
      showPixelSnackBar(
        context,
        'Đã mở trình duyệt. Hoàn tất đăng nhập Google rồi quay lại app.',
      );
      return;
    }
    final error = ref.read(authProvider).errorMessage;
    if (error != null) {
      showPixelSnackBar(context, error, tone: PixelTone.danger);
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
      body: Stack(
        children: [
          const Positioned.fill(child: PixelStarField()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: palette.mint,
                          border: Border.all(
                            color: palette.lineStrong,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: AppIcon(
                            name: 'camera',
                            size: 32,
                            color: palette.onAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppInfo.name,
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(color: palette.ink),
                      ),
                    ),
                    Text(
                      'Đăng nhập để đồng bộ chi tiêu của bạn trên Cloud',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: palette.inkMuted),
                    ),
                    const SizedBox(height: 24),

                    if (!authState.isConfigured) ...[
                      PixelPanel(
                        background: palette.butter,
                        borderColor: palette.lineStrong,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            AppIcon(
                              name: 'alert',
                              size: 32,
                              color: palette.butterInk,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                SupabaseConfig.initializationError ?? 'Chưa cấu hình Supabase trong file .env. Vui lòng thêm SUPABASE_URL và SUPABASE_ANON_KEY để kết nối.',
                                style: text.bodySmall?.copyWith(
                                  color: palette.butterInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    PixelPanel(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PixelTextField(
                              key: const Key('loginEmailField'),
                              label: 'Email',
                              hint: 'you@example.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              suffixGlyph: 'mail',
                            ),
                            const SizedBox(height: 12),
                            PixelTextField(
                              key: const Key('loginPasswordField'),
                              label: 'Mật khẩu',
                              controller: _passwordController,
                              obscureToggle: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: PixelButton(
                                key: const Key('forgotPasswordButton'),
                                label: 'Quên mật khẩu?',
                                variant: PixelButtonVariant.ghost,
                                onPressed: () =>
                                    showForgotPasswordSheet(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            PixelButton(
                              key: const Key('loginSubmitButton'),
                              label: 'ĐĂNG NHẬP',
                              icon: 'logout',
                              expanded: true,
                              isLoading: busy,
                              onPressed: busy ? null : _handleLogin,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const PixelDivider(),
                    Center(
                      child: Text(
                        'HOẶC',
                        style: text.labelSmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PixelButton(
                      label: 'Tiếp tục với Google',
                      icon: 'user',
                      variant: PixelButtonVariant.secondary,
                      expanded: true,
                      onPressed: busy ? null : _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 12),
                    PixelButton(
                      label: 'Chưa có tài khoản? Đăng ký',
                      variant: PixelButtonVariant.ghost,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
