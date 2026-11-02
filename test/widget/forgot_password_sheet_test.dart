import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/screens/auth/forgot_password_sheet.dart';

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  _FakeAuthNotifier([super.state = const AppAuthState()]);

  final List<String> requested = [];
  bool shouldFail = false;

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    requested.add(email);
    if (shouldFail) {
      state = state.copyWith(
        errorMessage: 'Không thể kết nối máy chủ. Kiểm tra mạng và thử lại.',
      );
      return false;
    }
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<_FakeAuthNotifier> openSheet(WidgetTester tester) async {
    final notifier = _FakeAuthNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showForgotPasswordSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return notifier;
  }

  testWidgets('renders email field and send button', (tester) async {
    await openSheet(tester);
    expect(find.text('Quên mật khẩu'), findsOneWidget);
    expect(find.byKey(const Key('resetEmailField')), findsOneWidget);
    expect(find.text('Gửi link đặt lại'), findsOneWidget);
  });

  testWidgets('valid email triggers the reset request', (tester) async {
    final notifier = await openSheet(tester);
    await tester.enterText(find.byKey(const Key('resetEmailField')), 'a@b.co');
    await tester.tap(find.text('Gửi link đặt lại'));
    await tester.pumpAndSettle();
    expect(notifier.requested, ['a@b.co']);
  });

  testWidgets('empty email shows a visible label error, no request', (
    tester,
  ) async {
    final notifier = await openSheet(tester);
    await tester.tap(find.text('Gửi link đặt lại'));
    await tester.pumpAndSettle();
    expect(notifier.requested, isEmpty);
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
  });

  testWidgets('success copy stays neutral about the account', (tester) async {
    await openSheet(tester);
    await tester.enterText(find.byKey(const Key('resetEmailField')), 'a@b.co');
    await tester.tap(find.text('Gửi link đặt lại'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nếu email này có tài khoản'), findsOneWidget);
    expect(find.textContaining('Không tìm thấy tài khoản'), findsNothing);
  });
}
