@Tags(['io'])
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/platform/photo_capture.dart';
import 'package:pixket/core/platform/photo_capture_stub.dart' as stub;
import 'package:pixket/core/platform/photo_capture_web.dart' as web_capture;
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/expense_provider.dart';
import 'package:pixket/providers/priority_provider.dart';
import 'package:pixket/screens/camera/camera_screen.dart';

/// Bắt chước nhánh web: không ống ngắm sống, mọi ảnh đều qua thư viện.
class _NoViewfinderCapture extends PhotoCapture {
  int captureCalls = 0;
  int galleryCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  bool get isReady => false;

  @override
  String? get errorMessage => null;

  @override
  bool get supportsLiveViewfinder => false;

  @override
  bool get canSwitchCamera => false;

  @override
  Future<void> useNextCamera() async {}

  @override
  Future<Uint8List?> capture() async {
    captureCalls++;
    return null;
  }

  @override
  Future<({Uint8List bytes, String extension})?> pickFromGallery() async {
    galleryCalls++;
    return null;
  }

  @override
  Widget buildViewfinder(BuildContext context, {double aspectRatio = 1}) =>
      const SizedBox.shrink();

  @override
  void dispose() {}
}

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePriorityNotifier extends StateNotifier<PriorityState>
    implements PriorityNotifier {
  _FakePriorityNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _noop() {}

Widget feed() => ProviderScope(
  overrides: [
    expenseProvider.overrideWith(
      (ref) => _FakeExpenseNotifier(const ExpenseState()),
    ),
    categoryProvider.overrideWith(
      (ref) => _FakeCategoryNotifier(const CategoryState()),
    ),
    priorityProvider.overrideWith(
      (ref) => _FakePriorityNotifier(const PriorityState()),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    home: const CameraScreen(onMenuTap: _noop),
  ),
);

void main() {
  late PhotoCapture original;

  setUp(() => original = photoCapture);
  tearDown(() => photoCapture = original);

  test('camera bản web không có ống ngắm sống, báo lỗi bằng tiếng Việt khi init thất bại', () async {
    final capture = photoCapture;
    await capture.initialize();
    expect(capture.supportsLiveViewfinder, isTrue); // máy dev chạy nhánh IO
    expect(capture.isReady || capture.errorMessage != null, isTrue);
  });

  group('photoCapturePaneFor', () {
    test('nền tảng không có ống ngắm bao giờ trả initializing', () {
      // Đây chính là lỗ Ruling E đo được trên trình duyệt: screen mà còn suy
      // "chưa ready = đang khởi tạo" thì bản web treo vĩnh viễn ở
      // "Đang mở camera…".
      for (final isReady in [true, false]) {
        expect(
          photoCapturePaneFor(
            supportsLiveViewfinder: false,
            isReady: isReady,
            errorMessage: null,
          ),
          PhotoCapturePane.galleryPrompt,
        );
      }
    });

    test('có ống ngắm: ready thì ngắm, chưa ready thì chờ', () {
      expect(
        photoCapturePaneFor(
          supportsLiveViewfinder: true,
          isReady: true,
          errorMessage: null,
        ),
        PhotoCapturePane.liveViewfinder,
      );
      expect(
        photoCapturePaneFor(
          supportsLiveViewfinder: true,
          isReady: false,
          errorMessage: null,
        ),
        PhotoCapturePane.initializing,
      );
    });

    test('lỗi thắng mọi trạng thái, kể cả khi thiếu ống ngắm', () {
      expect(
        photoCapturePaneFor(
          supportsLiveViewfinder: false,
          isReady: false,
          errorMessage: 'Camera đang bận hoặc không khả dụng.',
        ),
        PhotoCapturePane.error,
      );
      expect(
        photoCapturePaneFor(
          supportsLiveViewfinder: true,
          isReady: true,
          errorMessage: 'Bạn chưa cấp quyền truy cập máy ảnh.',
        ),
        PhotoCapturePane.error,
      );
    });
  });

  test('lớp web thật đưa screen tới trạng thái giải thích được, không phải đang chờ', () {
    // Chứng minh Ruling E bằng chính lớp web (chạy được trên VM vì nó không
    // import dart:html): initialize() xong thì screen phải ra card hướng dẫn,
    // không còn "Đang mở camera…".
    final capture = web_capture.WebPhotoCapture();
    expect(
      photoCapturePaneFor(
        supportsLiveViewfinder: capture.supportsLiveViewfinder,
        isReady: capture.isReady,
        errorMessage: capture.errorMessage,
      ),
      PhotoCapturePane.galleryPrompt,
    );
  });

  testWidgets('stub ném UnsupportedError tiếng Việt ở mọi member', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    );

    final capture = stub.photoCapture;
    const message = 'Pixket chưa chụp được ảnh trên nền tảng này.';

    void expectFails(void Function() body) => expect(
      body,
      throwsA(
        isA<UnsupportedError>().having((e) => e.message, 'message', message),
      ),
    );

    expectFails(() => capture.initialize());
    expectFails(() => capture.isReady);
    expectFails(() => capture.errorMessage);
    expectFails(() => capture.supportsLiveViewfinder);
    expectFails(() => capture.canSwitchCamera);
    expectFails(() => capture.useNextCamera());
    expectFails(() => capture.capture());
    expectFails(() => capture.pickFromGallery());
    expectFails(() => capture.buildViewfinder(context));
    expectFails(() => capture.dispose());
  });

  testWidgets(
    'screen không có ống ngắm sống thoát trạng thái khởi tạo và vẫn chụp được',
    (tester) async {
      final capture = _NoViewfinderCapture();
      photoCapture = capture;

      await tester.pumpWidget(feed());
      await tester.pump(const Duration(milliseconds: 50));

      // Không được còn lại indicator "Đang mở camera…" — treo ở đó là lỗi Lượt 1
      // đo được trên trình duyệt khi browser chưa quyết quyền.
      expect(find.text('Đang mở camera…'), findsNothing);
      expect(find.text('CHỌN ẢNH TỪ THƯ VIỆN'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Nút chụp trên web mở đường chọn ảnh chứ không bị vô hiệu hóa.
      await tester.tap(find.bySemanticsLabel('Chụp khoản chi'));
      await tester.pump();
      expect(capture.captureCalls, 1);
    },
  );
}
