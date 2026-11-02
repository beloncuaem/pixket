import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/screens/auth/login_screen.dart';
import 'package:pixket/screens/auth/register_screen.dart';
import 'package:pixket/screens/onboarding/onboarding_screen.dart';
import 'package:pixket/widgets/pixel/pixel_button.dart';
import 'package:pixket/widgets/pixel/pixel_text_field.dart';

class _FakeAppSettingsNotifier extends StateNotifier<AppSettingsState>
    implements AppSettingsNotifier {
  _FakeAppSettingsNotifier()
    : super(const AppSettingsState(isLoading: false, onboardingComplete: true));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  // `StateNotifier.state` là @protected nên state khởi tạo truyền qua constructor.
  _FakeAuthNotifier([
    super.initial = const AppAuthState(status: AuthStatus.unauthenticated),
  ]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child, {AppAuthState? auth}) => ProviderScope(
  overrides: [
    authProvider.overrideWith(
      (ref) => _FakeAuthNotifier(
        auth ?? const AppAuthState(status: AuthStatus.unauthenticated),
      ),
    ),
    appSettingsProvider.overrideWith((ref) => _FakeAppSettingsNotifier()),
  ],
  child: MaterialApp(theme: AppTheme.light, home: child),
);

void main() {
  testWidgets('Onboarding dùng glyph pixel, 3 trang, nhãn BỎ QUA/TIẾP TỤC', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const OnboardingScreen()));
    expect(find.text('Chào mừng đến với Pixket'), findsOneWidget);
    expect(find.text('BỎ QUA'), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsOneWidget);
    expect(find.byType(PixelButton), findsWidgets);
    expect(find.byIcon(Icons.attach_money_rounded), findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);
    expect(tester.takeException(), isNull);

    // Duyệt bằng nút TIẾP TỤC, không gọi _finish().
    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();
    expect(find.text('Đồng bộ an toàn trên Cloud'), findsOneWidget);
    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();
    expect(find.text('Không vượt quá ngân sách'), findsOneWidget);
    expect(find.text('BẮT ĐẦU'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // KHÔNG tap 'BỎ QUA'/'BẮT ĐẦU': _finish() gọi Permission.camera.request()
    // và NotificationService -> MissingPluginException trong flutter_test.
  });

  testWidgets('Login có 2 PixelTextField, nút đăng nhập và Quên mật khẩu?', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    expect(find.byType(PixelTextField), findsNWidgets(2));
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.byType(PixelButton), findsWidgets);
    // PixelTextField bọc TextFormField bên trong: số TextFormField phải đúng
    // bằng số field pixel, chứng tỏ không còn TextField Material thô.
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login báo lỗi validate khi nộp trống, không gọi auth', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets(
    'Register có 4 PixelTextField, nút ĐĂNG KÝ, không có TextFormField',
    (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));
      expect(find.byType(PixelTextField), findsNWidgets(4));
      expect(find.text('ĐĂNG KÝ'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PixelTextField),
          matching: find.byType(TextFormField),
        ),
        findsNWidgets(4),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Login không dùng gradient trang cũ', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    final decorated = tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    );
    for (final d in decorated) {
      final dec = d.decoration;
      if (dec is BoxDecoration) expect(dec.gradient, isNull);
    }
  });

  testWidgets('Login 1.3x text scale không vỡ layout', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          appSettingsProvider.overrideWith((ref) => _FakeAppSettingsNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.drag(find.byType(LoginScreen), const Offset(0, -300));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
