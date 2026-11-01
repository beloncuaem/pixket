import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/screens/auth/reset_password_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  _FakeAuthNotifier([super.state = const AppAuthState(recoveryMode: true)]);

  final List<String> submitted = [];
  bool exits = false;

  @override
  Future<bool> setNewPassword(String password) async {
    submitted.add(password);
    return true;
  }

  @override
  void exitRecoveryMode() => exits = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<_FakeAuthNotifier> pumpScreen(WidgetTester tester) async {
    final notifier = _FakeAuthNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ResetPasswordScreen(),
        ),
      ),
    );
    return notifier;
  }

  testWidgets('rejects a short password and does not submit', (tester) async {
    final notifier = await pumpScreen(tester);
    await tester.enterText(find.byKey(const Key('newPasswordField')), '123');
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      '123',
    );
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pump();

    expect(notifier.submitted, isEmpty);
    expect(find.text('Mật khẩu từ 6 ký tự trở lên'), findsOneWidget);
  });

  testWidgets('mismatch blocks submit', (tester) async {
    final notifier = await pumpScreen(tester);
    await tester.enterText(
      find.byKey(const Key('newPasswordField')),
      'secret1',
    );
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      'secret2',
    );
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pump();

    expect(notifier.submitted, isEmpty);
    expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);
  });

  testWidgets('valid password submits and leaves recovery mode', (
    tester,
  ) async {
    final notifier = await pumpScreen(tester);
    await tester.enterText(
      find.byKey(const Key('newPasswordField')),
      'secret1',
    );
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      'secret1',
    );
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pumpAndSettle();

    expect(notifier.submitted, ['secret1']);
    expect(notifier.exits, isTrue);
  });
}
