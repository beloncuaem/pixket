import 'dart:async';
import 'dart:typed_data';

// Test này phải dựng được cảnh "người dùng đã quay sang camera trước", mà trên
// VM thì plugin camera không khởi tạo nổi, nên nó giả đúng interface của plugin.
// `camera_platform_interface` là dependency bắc cầu của `camera`, không có trong
// pubspec — thêm nó vào pubspec là việc của task khác.
// ignore: depend_on_referenced_packages
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/platform/photo_capture.dart';
import 'package:pixket/core/platform/photo_capture_io.dart' as io_capture;
import 'package:pixket/core/platform/photo_capture_stub.dart' as stub;
import 'package:pixket/core/platform/photo_capture_web.dart' as web_capture;
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/expense_provider.dart';
import 'package:pixket/providers/priority_provider.dart';
import 'package:pixket/screens/camera/camera_screen.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';

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
  bool get isTakingPicture => false;

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
  Widget buildViewfinder(BuildContext context) => const SizedBox.shrink();

  @override
  void dispose() {}
}

/// Camera plugin giả, đúng hai thị kính. `flutter test` chạy trên VM nên plugin
/// thật không mở được camera (`availableCameras()` không có channel), và muốn
/// dựng cảnh "người dùng đã quay sang camera trước" thì phải giả từ tầng này.
class _TwoLensCameraPlatform extends CameraPlatform {
  static const CameraDescription back = CameraDescription(
    name: 'camera sau',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );
  static const CameraDescription front = CameraDescription(
    name: 'camera trước',
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 270,
  );

  /// Thứ tự camera seam đã xin mở — bằng chứng duy nhất đọc được của
  /// `_selectedCameraIndex` từ ngoài library.
  final List<CameraDescription> opened = <CameraDescription>[];

  int _nextCameraId = 0;

  @override
  Future<List<CameraDescription>> availableCameras() async =>
      const <CameraDescription>[back, front];

  @override
  Future<int> createCamera(
    CameraDescription description,
    ResolutionPreset? resolutionPreset, {
    bool enableAudio = false,
  }) async {
    opened.add(description);
    return _nextCameraId++;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {}

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream<CameraInitializedEvent>.fromIterable([
        CameraInitializedEvent(
          cameraId,
          1080,
          1920,
          ExposureMode.auto,
          false,
          FocusMode.auto,
          false,
        ),
      ]);

  // `CameraController` nghe stream này bằng `.first` rồi bỏ đi: stream rỗng sẽ
  // ném StateError không ai await, nên nó phải mở và không bao giờ phát.
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      Stream<CameraErrorEvent>.fromFuture(Completer<CameraErrorEvent>().future);

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream<DeviceOrientationChangedEvent>.empty(broadcast: true);

  @override
  Future<void> dispose(int cameraId) async {}
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
    expectFails(() => capture.isTakingPicture);
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

      // Không có camera thứ hai thì slot thứ ba của HUD nghỉ lại thành chỗ
      // trống: một lối vào thư viện duy nhất, đừng cho hai nút cùng việc.
      expect(find.byType(PixelIconButton), findsOneWidget);
    },
  );

  test('quay lại màn camera phải mở lại camera đầu danh sách, không giữ thị kính cũ', () async {
    // Seam là toàn cục nên `_selectedCameraIndex` sống lâu hơn screen. Không
    // reset nó trong dispose() thì người dùng quay camera trước, thoát màn
    // hình, mở lại vẫn đứng ở camera trước — và nếu `availableCameras()` trả
    // thứ tự khác thì đó là mở nhầm thị kính mà không ai thấy.
    final platform = _TwoLensCameraPlatform();
    final realPlatform = CameraPlatform.instance;
    CameraPlatform.instance = platform;
    addTearDown(() => CameraPlatform.instance = realPlatform);

    final capture = io_capture.CameraPluginPhotoCapture();
    await capture.initialize();
    expect(capture.isReady, isTrue);
    expect(platform.opened, [_TwoLensCameraPlatform.back]);

    await capture.useNextCamera();
    expect(platform.opened, [
      _TwoLensCameraPlatform.back,
      _TwoLensCameraPlatform.front,
    ]);

    capture.dispose();
    // Seam fire-and-forget `CameraController.dispose()`: cho nó chạy xong trên
    // camera giả trước khi trả CameraPlatform.instance về plugin thật.
    await Future<void>.delayed(Duration.zero);

    await capture.initialize();
    expect(
      platform.opened.last,
      _TwoLensCameraPlatform.back,
      reason: 'lần mở thứ hai vẫn dùng camera người dùng lần trước đã quay',
    );

    capture.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  test('screen thứ hai mở ống ngắm khi screen cũ chưa dispose thì assert bật ở debug', () async {
    // Hai screen cùng giữ một ống ngắm là hai controller cùng chiếm camera của
    // hệ thống; thà fail ngay ở debug còn hơn im lặng để cả hai cùng sống.
    final platform = _TwoLensCameraPlatform();
    final realPlatform = CameraPlatform.instance;
    CameraPlatform.instance = platform;
    addTearDown(() => CameraPlatform.instance = realPlatform);

    final capture = io_capture.CameraPluginPhotoCapture();
    await capture.initialize();
    await expectLater(capture.initialize(), throwsAssertionError);

    // dispose() đúng hợp đồng thì mở lại bình thường, không còn controller cũ.
    capture.dispose();
    await Future<void>.delayed(Duration.zero);
    await capture.initialize();
    expect(capture.isReady, isTrue);

    capture.dispose();
    await Future<void>.delayed(Duration.zero);
  });
}
