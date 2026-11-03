// Sinh 6 ảnh demo cho README từ đúng widget pixel hiện tại, headless nên không
// cần thiết bị hay emulator. Mặc định skip để `flutter test` và CI không ghi file.
// Chạy: PIXKET_GEN_SHOTS=1 flutter test test/tool/demo_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/navigation/app_section.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/budget.dart';
import 'package:pixket/data/models/category.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/data/models/priority_level.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/providers/budget_provider.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/expense_provider.dart';
import 'package:pixket/providers/priority_provider.dart';
import 'package:pixket/providers/statistics_provider.dart';
import 'package:pixket/screens/budget/budget_screen.dart';
import 'package:pixket/screens/camera/feed_photo_page.dart';
import 'package:pixket/screens/categories/manage_categories_screen.dart';
import 'package:pixket/screens/home/home_screen.dart';
import 'package:pixket/screens/statistics/statistics_screen.dart';
import 'package:pixket/widgets/app_drawer.dart';
import 'package:pixket/widgets/pixel/pixel_star_field.dart';

const _outDir = 'docs/screenshots';

// 360×800 logical, nhân 2 để lưới pixel không bị resample lẻ.
const _logicalSize = Size(360, 800);
const _devicePixelRatio = 3.0;
const _pixelRatio = 2.0;

/// Toàn bộ số liệu dưới đây là mồi demo tự đặt trong file này; không lấy từ tài
/// khoản hay sổ chi thật.
final _now = DateTime(2026, 11, 3, 14, 30);

final _categories = [
  Category(id: 1, name: 'Ăn uống', icon: 'forkKnife'),
  Category(id: 2, name: 'Đi lại', icon: 'car'),
  Category(id: 3, name: 'Giải trí', icon: 'gameController'),
  Category(id: 4, name: 'Học tập', icon: 'graduationCap'),
  Category(id: 5, name: 'Nhà ở', icon: 'house'),
];

const _priorities = [
  PriorityLevel(id: 0, name: 'Thiết yếu', colorValue: 0xFF7BD8A8, sortOrder: 0),
  PriorityLevel(id: 1, name: 'Rất cần', colorValue: 0xFF8FC7F5, sortOrder: 1),
  PriorityLevel(id: 2, name: 'Cần vừa', colorValue: 0xFFF5D68A, sortOrder: 2),
  PriorityLevel(id: 3, name: 'Chưa cần', colorValue: 0xFFF5A0A0, sortOrder: 3),
];

List<Expense> _expenses() => [
  Expense(
    id: 1,
    caption: 'Cà phê sáng',
    amount: 45000,
    categoryId: 1,
    priority: 2,
    createdAt: _now,
  ),
  Expense(
    id: 2,
    caption: 'Xe bus',
    amount: 15000,
    categoryId: 2,
    priority: 1,
    createdAt: _now.subtract(const Duration(hours: 3)),
  ),
  Expense(
    id: 3,
    caption: 'Vé xem phim',
    amount: 120000,
    categoryId: 3,
    priority: 3,
    createdAt: _now.subtract(const Duration(days: 1, hours: 2)),
  ),
  Expense(
    id: 4,
    caption: 'Sách giáo trình',
    amount: 250000,
    categoryId: 4,
    priority: 0,
    createdAt: _now.subtract(const Duration(days: 2)),
  ),
  Expense(
    id: 5,
    caption: 'Tiền nhà',
    amount: 1500000,
    categoryId: 5,
    priority: 0,
    createdAt: _now.subtract(const Duration(days: 4)),
  ),
];

ExpenseState _expenseState() => ExpenseState(
  expenses: _expenses(),
  todayTotal: 60000,
  weekTotal: 1930000,
  monthTotal: 1930000,
);

BudgetState _budgetState() => BudgetState(
  month: '2026-11',
  totalBudget: Budget(id: 1, amount: 3000000, month: '2026-11'),
  totalSpent: 1930000,
  categoryBudgets: const {
    1: 600000,
    2: 200000,
    3: 300000,
    4: 400000,
    5: 1500000,
  },
);

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

StatisticsState _statisticsState() => StatisticsState(
  categoryTotals: const {1: 45000, 2: 15000, 3: 120000, 4: 250000, 5: 1500000},
  priorityTotals: const {0: 1750000, 1: 15000, 2: 45000, 3: 120000},
  dailyTotals: {
    for (var daysAgo = 4; daysAgo >= 0; daysAgo--)
      _dayKey(_now.subtract(Duration(days: daysAgo))): const <double>[
        1500000,
        0,
        250000,
        120000,
        60000,
      ][4 - daysAgo],
  },
  totalAmount: 1930000,
  insights: const ['Nhà ở chiếm 78% tổng chi tháng này.'],
);

class _StubExpense extends StateNotifier<ExpenseState> implements ExpenseNotifier {
  _StubExpense(super.state);
  @override
  Future<void> refreshDashboard() async {}
  @override
  Future<void> addExpense(Expense expense) async {}
  @override
  Future<void> updateExpense(Expense expense) async {}
  @override
  Future<void> moveToTrash(int id) async {}
  @override
  Future<void> restoreExpense(int id) async {}
  @override
  Future<void> permanentlyDeleteExpense(Expense expense) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCategory extends StateNotifier<CategoryState> implements CategoryNotifier {
  _StubCategory(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPriority extends StateNotifier<PriorityState> implements PriorityNotifier {
  _StubPriority(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubBudget extends StateNotifier<BudgetState> implements BudgetNotifier {
  _StubBudget(super.state);
  @override
  Future<void> loadBudgets(String month, {bool checkAlerts = false}) async {}
  @override
  Future<void> refreshCurrentMonthAfterExpenseChange() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubStatistics extends StateNotifier<StatisticsState>
    implements StatisticsNotifier {
  _StubStatistics(super.state);
  @override
  Future<void> loadStatistics(DateTime from, DateTime to) async {}
  @override
  Future<void> refreshStatistics() async {}
  @override
  Future<void> generateInsights(DateTime from, DateTime to) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAuth extends StateNotifier<AppAuthState> implements AuthNotifier {
  _StubAuth(super.state);
  @override
  void exitRecoveryMode() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSettings extends StateNotifier<AppSettingsState>
    implements AppSettingsNotifier {
  _StubSettings(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Override đủ cho cả 6 màn; màn nào không dùng tới thì bỏ qua không sao.
List<Override> _overrides() => [
  expenseProvider.overrideWith((ref) => _StubExpense(_expenseState())),
  categoryProvider.overrideWith(
    (ref) => _StubCategory(CategoryState(categories: _categories)),
  ),
  priorityProvider.overrideWith(
    (ref) => _StubPriority(const PriorityState(levels: _priorities)),
  ),
  budgetProvider.overrideWith((ref) => _StubBudget(_budgetState())),
  statisticsProvider.overrideWith((ref) => _StubStatistics(_statisticsState())),
  authProvider.overrideWith(
    (ref) => _StubAuth(const AppAuthState(status: AuthStatus.authenticated)),
  ),
  appSettingsProvider.overrideWith(
    (ref) => _StubSettings(
      const AppSettingsState(isLoading: false, onboardingComplete: true),
    ),
  ),
];

/// Giống hệt khung MainScreen dựng quanh mỗi section: nền canvas + sao, vì
/// BudgetScreen để Scaffold trong suốt.
class _Stage extends StatefulWidget {
  const _Stage({required this.screen, this.drawer});

  final Widget screen;
  final Widget? drawer;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (widget.drawer != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scaffoldKey.currentState?.openDrawer(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.palette.canvas,
      drawer: widget.drawer,
      body: Stack(
        children: [
          const Positioned.fill(child: PixelStarField()),
          Positioned.fill(child: widget.screen),
        ],
      ),
    );
  }
}

Widget _demoDrawer() => AppDrawer(
  selected: AppSection.feed,
  onSelectSection: (_) {},
  onOpenCategories: () {},
  onOpenTrash: () {},
  onOpenSettings: () {},
  onToggleTheme: () {},
  onLogout: () async {},
  displayName: 'Pixket',
  email: 'demo@pixket.app',
  isDarkMode: true,
);

/// Ảnh "chụp hoá đơn" chỉ để feed demo có một tệp ảnh thật: vẽ bằng Canvas rồi
/// ghi ra temp, nhờ vậy không phải commit thêm binary vào repo.
Future<String> _writeDemoPhoto() async {
  const w = 360.0, h = 480.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();

  paint.color = const Color(0xFF3A2A20);
  canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), paint);
  // Vân gỗ.
  paint.color = const Color(0xFF2F2118);
  for (var y = 24.0; y < h; y += 48) {
    canvas.drawRect(Rect.fromLTWH(0, y, w, 4), paint);
  }
  // Tờ hoá đơn.
  paint.color = const Color(0xFFF2EFE6);
  canvas.drawRect(const Rect.fromLTWH(96, 64, 168, 300), paint);
  paint.color = const Color(0xFF8A8A8A);
  for (var i = 0; i < 9; i++) {
    canvas.drawRect(
      Rect.fromLTWH(112, 96 + i * 24, i.isEven ? 100 : 136, 6),
      paint,
    );
  }
  paint.color = const Color(0xFF2B2118);
  canvas.drawRect(const Rect.fromLTWH(112, 312, 136, 10), paint);
  // Ly cà phê.
  paint.color = const Color(0xFFEFEAE0);
  canvas.drawCircle(const Offset(96, 408), 44, paint);
  paint.color = const Color(0xFF6F4E37);
  canvas.drawCircle(const Offset(96, 408), 30, paint);
  paint.color = const Color(0xFFEFEAE0);
  canvas.drawCircle(const Offset(96, 408), 12, paint);

  final image = await recorder.endRecording().toImage(w.round(), h.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}pixket-demo-photo.png',
  );
  await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  return file.path;
}

bool _fontsLoaded = false;

/// Widget test mặc định render bằng font Ahem (khối đen). Nạp VT323 và
/// BeVietnamPro từ asset để ảnh demo hiện đúng chữ của app.
Future<void> _loadPixelFonts(WidgetTester tester) async {
  if (_fontsLoaded) return;
  await tester.runAsync(() async {
    final families = {
      'VT323': const ['assets/fonts/VT323-Regular.ttf'],
      'BeVietnamPro': const [
        'assets/fonts/BeVietnamPro-Regular.ttf',
        'assets/fonts/BeVietnamPro-Medium.ttf',
        'assets/fonts/BeVietnamPro-SemiBold.ttf',
        'assets/fonts/BeVietnamPro-Bold.ttf',
      ],
    };
    for (final entry in families.entries) {
      for (final asset in entry.value) {
        final data = await rootBundle.load(asset);
        await ui.loadFontFromList(
          data.buffer.asUint8List(),
          fontFamily: entry.key,
        );
      }
    }
  });
  _fontsLoaded = true;
}

void _usePhoneView(WidgetTester tester) {
  tester.view.physicalSize = _logicalSize * _devicePixelRatio;
  tester.view.devicePixelRatio = _devicePixelRatio;
  // Mép trên/dưới để SafeArea chừa chỗ cho HUD như màn điện thoại.
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 12);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Future<void> _capture(
  WidgetTester tester,
  String fileName, {
  required Widget screen,
  Widget? drawer,
  Future<void> Function(WidgetTester tester)? settle,
}) async {
  final boundary = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: RepaintBoundary(
          key: boundary,
          child: _Stage(screen: screen, drawer: drawer),
        ),
      ),
    ),
  );
  // PixelStarField và PixelLoading repeat vô hạn nên không được pumpAndSettle;
  // bơm từng khung một cho ramp biểu đồ, hiệu ứng mở drawer và keep-out của nền
  // sao chạy xong trước khi chụp.
  await tester.pump();
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (settle != null) await settle(tester);
  await tester.pump();

  final png = await tester.runAsync(() async {
    final renderBoundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundary),
    );
    final image = await renderBoundary.toImage(pixelRatio: _pixelRatio);
    expect(
      image.width,
      (_logicalSize.width * _pixelRatio).round(),
      reason: '$fileName sai chiều rộng',
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  });
  expect(png, isNotNull, reason: '$fileName không mã hoá được PNG');

  await tester.runAsync(
    () => File('$_outDir/$fileName').writeAsBytes(png!, flush: true),
  );
  debugPrint('đã ghi $_outDir/$fileName');
}

void _noop() {}

void main() {
  final enabled = Platform.environment['PIXKET_GEN_SHOTS'] == '1';
  final outDir = Directory(_outDir);

  setUp(() async {
    if (!enabled) return;
    if (!await outDir.exists()) await outDir.create(recursive: true);
  });

  testWidgets('01 nhật ký ảnh', (tester) async {
    await _loadPixelFonts(tester);
    _usePhoneView(tester);
    final photoPath = (await tester.runAsync(_writeDemoPhoto))!;
    // CameraScreen bị loại khỏi ảnh demo: plugin camera không tồn tại trong
    // flutter_test nên trang chỉ hiện "Đang mở camera…". FeedPhotoPage là đúng
    // một trang trong PageView của nhật ký.
    await _capture(
      tester,
      '01-feed.png',
      screen: FeedPhotoPage(
        expense: _expenses().first.copyWith(imagePath: photoPath),
        category: _categories.first,
        priority: _priorities[2],
        onEdit: _noop,
        onDelete: _noop,
      ),
      settle: (tester) async {
        // FileImage cần I/O thật để giải mã nên phải chờ ngoài FakeAsync; bơm
        // nhiều vòng vì ảnh chỉ xuất hiện sau khi stream ảnh báo xong.
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
      },
    );
  }, skip: !enabled);

  testWidgets('02 dashboard', (tester) async {
    await _loadPixelFonts(tester);
    _usePhoneView(tester);
    await _capture(
      tester,
      '02-dashboard.png',
      screen: const HomeScreen(
        onMenuTap: _noop,
        onOpenBudget: _noop,
        onOpenFeed: _noop,
      ),
    );
  }, skip: !enabled);

  testWidgets('03 statistics', (tester) async {
    await _loadPixelFonts(tester);
    _usePhoneView(tester);
    await _capture(
      tester,
      '03-statistics.png',
      screen: const StatisticsScreen(onMenuTap: _noop),
      settle: (tester) => tester.pump(const Duration(milliseconds: 400)),
    );
  }, skip: !enabled);

  testWidgets('04 budget', (tester) async {
    await _loadPixelFonts(tester);
    _usePhoneView(tester);
    await _capture(
      tester,
      '04-budget.png',
      screen: const BudgetScreen(onMenuTap: _noop),
    );
  }, skip: !enabled);

  testWidgets('05 drawer', (tester) async {
    await _loadPixelFonts(tester);
    _usePhoneView(tester);
    await _capture(
      tester,
      '05-drawer.png',
      screen: const HomeScreen(
        onMenuTap: _noop,
        onOpenBudget: _noop,
        onOpenFeed: _noop,
      ),
      drawer: _demoDrawer(),
    );
  }, skip: !enabled);

  testWidgets('06 quản lý danh mục', (tester) async {
    await _loadPixelFonts(tester);
    _usePhoneView(tester);
    // LoginScreen bị loại: trong flutter_test SupabaseConfig chưa init nên màn
    // nào cũng dính card cảnh báo ".env", không tái hiện được trạng thái thật.
    await _capture(
      tester,
      '06-categories.png',
      screen: const ManageCategoriesScreen(),
    );
  }, skip: !enabled);
}
