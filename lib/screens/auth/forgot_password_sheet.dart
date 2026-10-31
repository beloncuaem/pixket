import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_sheet.dart';
import '../../widgets/pixel/pixel_snack_bar.dart';
import '../../widgets/pixel/pixel_text_field.dart';

const String _neutralSuccessCopy =
    'Nếu email này có tài khoản, chúng mình đã gửi link đặt lại mật khẩu. '
    'Mở hộp thư (kể cả thư mục spam) và bấm link trong 60 phút.';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final sent = await ref
        .read(authProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());
    if (!mounted) return;
    setState(() => _sending = false);

    final authState = ref.read(authProvider);
    showPixelSnackBar(
      context,
      sent
          ? _neutralSuccessCopy
          : (authState.errorMessage ??
                'Không thể gửi email. Thử lại sau ít phút.'),
      tone: sent ? PixelTone.info : PixelTone.danger,
    );
    if (sent) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      // showPixelSheet đã bù viewInsets của bàn phím nên chỉ cần khoảng trống
      // cuối để nút không dính mép panel.
      padding: const EdgeInsets.only(bottom: 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nhập email bạn dùng để đăng ký. Link đặt lại mật khẩu sẽ gửi về hộp thư.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: palette.inkMuted),
            ),
            const SizedBox(height: 16),
            PixelTextField(
              key: const Key('resetEmailField'),
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              hint: 'name@example.com',
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Vui lòng nhập email';
                if (!text.contains('@')) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 16),
            PixelButton(
              label: 'Gửi link đặt lại',
              isLoading: _sending,
              onPressed: _sending ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showForgotPasswordSheet(BuildContext context) async {
  await showPixelSheet<void>(
    context: context,
    title: 'Quên mật khẩu',
    builder: (_) => const ForgotPasswordSheet(),
  );
}
