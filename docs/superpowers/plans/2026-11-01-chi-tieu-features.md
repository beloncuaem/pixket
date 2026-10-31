# Tính năng nghiệp vụ implementation plan (Plan 3/4) — formatter, ngày giờ, quên mật khẩu, CSV

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm 4 tính năng người dùng đã chốt — nhập tiền tự chấm nhóm nghìn, chỉnh ngày giờ khoản chi, quên mật khẩu qua email, xuất CSV/sao lưu — mà không phá vỡ luồng cloud-only hiện tại.

**Architecture:** Mọi logic có thể sai đều tách thành helper thuần (không import Flutter/Supabase) và unit test trước; UI chỉ còn là lớp mỏng gọi helper. Quên mật khẩu đi theo PKCE flow sẵn có của `supabase_flutter` và deep link `io.supabase.chitieu://login-callback/` đã được khai báo trong `AndroidManifest.xml:34-39`; app gate đọc cờ `recoveryMode` do sự kiện `PASSWORD_RECOVERY` đặt. CSV do `CsvBuilder` thuần dựng chuỗi (RFC 4180 + BOM), `CsvExportService` chịu trách nhiệm phân trang qua `ExpenseRepository.getExpenses(limit:, offset:)`, ghi file tạm và mở share sheet.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13.5 (đã xác minh bằng `flutter --version`), `intl`, `flutter/services` cho `TextInputFormatter`, `supabase_flutter ^2.8.3` (gotrue 2.27.3), `path_provider ^2.1.5` (đã có), `share_plus 13.3.1` (dependency mới duy nhất — đã xác minh `flutter pub add share_plus --dry-run` resolve đúng 13.3.1 với môi trường này), Riverpod 2.6.1 StateNotifier.

**Spec:** `docs/superpowers/specs/2026-11-01-chi-tieu-pixel-redesign-design.md`

**Depends on:**
- Plan 1 `docs/superpowers/plans/2026-11-01-cloud-signed-url-keepalive.md` — cần `ExpenseRepository.getExpenses({limit, offset})` (Task 5 Plan 1) cho phân trang CSV, và `Expense.imagePath` giờ là storage path.
- Plan 2 `docs/superpowers/plans/2026-11-01-pixel-foundation.md` — cần `context.palette` (AppPalette), component kit `PixelTextField`/`showPixelSheet`/`showPixelSnackBar`, và `AppIcon`.

## Global Constraints

- Trả lời và viết UI copy bằng tiếng Việt; giữ thuật ngữ kỹ thuật tiếng Anh.
- **Không** dùng `AppColors` trong code mới — nó đã `@Deprecated` từ Plan 2. Màu lấy từ `context.palette` (Plan 2 Task 2).
- **Không** dùng `Icons.*` (Material icon) hay emoji làm icon trong code mới: mọi icon là `AppIcon(name: '<glyph>', size:)` với key nằm trong registry Plan 2 Task 5/6, size chỉ 16/32/48. Lý do: Plan 4 Task 14 có gate test assert `lib/` **không còn chuỗi `Icons.`** — code của plan này cũng phải tuân thủ ngay từ đầu.
- Dependency mới duy nhất: `share_plus`. `path_provider` đã có trong `pubspec.yaml:13`. Không thêm package nào khác.
- Số tiền là VND nguyên, tối đa 12 chữ số (`999.999.999.999`); không hỗ trợ số thập phân ở ô nhập.
- Mọi helper parsing/formatting phải thuần Dart, **không** import `package:flutter/material.dart` (chỉ `flutter/services` cho formatter), để unit test chạy offline.
- Test không gọi mạng, không gọi Supabase. Không khởi tạo `Supabase.instance`.
- Không commit/push/PR khi chưa được ủy quyền rõ ràng. Không sửa git config, không bỏ qua hook.
- Không in `.env`, `SUPABASE_URL` hay `SUPABASE_ANON_KEY` ra log/mã nguồn/tài liệu. Flow quên mật khẩu chỉ dùng **anon key do SDK tự gắn** và deep link redirect; không dùng `service_role`.
- Chống dò email: thông báo gửi link đặt lại mật khẩu luôn trung tính, không tiết kiệm email tồn tại hay không.
- `flutter` **không** nằm trong PATH của Git Bash trên máy này; đường dẫn đã xác minh: `/c/flutter/bin/flutter`. Mỗi lệnh bên dưới chạy với `export PATH="$PATH:/c/flutter/bin"` hoặc dùng đường dẫn tuyệt đối.
- Baseline test: plan này phải **tăng** số test, không được làm giảm hay xóa assertion; sửa test cũ chỉ khi hành vi đổi có chủ đích và ghi rõ lý do.

## File Structure

| File | Tác vụ | Trách nhiệm |
| --- | --- | --- |
| Create `lib/core/utils/amount_input_formatter.dart` | 1 | `ThousandsSeparatorInputFormatter` — chặn ký tự lạ, chèn dấu chấm, giữ con trỏ |
| Modify `lib/core/utils/currency_formatter.dart` | 1 | Thêm `parseInput(String)` và `toEditableText(num)` |
| Modify `test/unit/formatters_test.dart` | 1, 3 | Nhóm test mới cho parse/format/giới hạn ngày |
| Modify `lib/screens/camera/expense_form_sheet.dart` | 2, 4 | Ô tiền dùng formatter; trường ngày/giờ |
| Modify `lib/screens/budget/budget_screen.dart` | 2 | 2 ô ngân sách dùng formatter + `parseInput` |
| Modify `lib/screens/home/home_screen.dart` | 2 | 2 ô lọc min/max dùng formatter + `parseInput` |
| Create `lib/core/utils/expense_date_limits.dart` | 3 | Hàm thuần: khoảng ngày hợp lệ, chặn tương lai, `combine` |
| Create `lib/screens/camera/expense_datetime_field.dart` | 4 | Widget chọn ngày + giờ + "Bây giờ", độc lập test |
| Create `test/widget/amount_input_test.dart` | 2 | Formatter hoạt động trong `TextField` thật |
| Create `test/widget/expense_datetime_field_test.dart` | 4 | Nhãn ngày/giờ và reset "Bây giờ" |
| Modify `lib/data/repositories/auth_repository.dart` | 5 | `resetPassword` có `redirectTo`; thêm `updatePassword` |
| Modify `lib/providers/auth_provider.dart` | 5 | `recoveryMode`, `sendPasswordResetEmail`, `setNewPassword` |
| Modify `test/unit/auth_and_supabase_test.dart` | 5 | Assert `recoveryMode` trong state |
| Create `lib/screens/auth/forgot_password_sheet.dart` | 6 | Form nhập email + gửi link |
| Modify `lib/screens/auth/login_screen.dart` | 6 | Link "Quên mật khẩu?" |
| Create `lib/screens/auth/reset_password_screen.dart` | 7 | Nhập mật khẩu mới khi `recoveryMode` |
| Modify `lib/app.dart` | 7 | `decideHomeTarget` thuần + route theo `recoveryMode` |
| Create `test/unit/auth_gate_recovery_test.dart` | 7 | Bảng quyết định routing |
| Create `lib/core/utils/csv_builder.dart` | 8 | `escapeField`, `buildCsv` (RFC 4180 + BOM, CRLF) |
| Create `test/unit/csv_builder_test.dart` | 8 | Escape, header, thứ tự cột, BOM |
| Create `lib/data/repositories/csv_export_service.dart` | 9 | Phân trang, ghi file tạm, share sheet |
| Create `test/unit/csv_export_service_test.dart` | 9 | Pagination với repository fake |
| Create `lib/screens/settings/csv_export_sheet.dart` | 10 | Chọn khoảng thời gian + nút xuất |
| Modify `lib/screens/settings/settings_screen.dart` | 10 | Mục "Xuất CSV (sao lưu)" |
| Modify `README.md`, `docs/requirements.md` | 11 | FR-24..FR-27, ghi chú xác minh thủ công |

---

### Task 1: Formatter nhập tiền và hàm đọc lại số

**Files:**
- Create: `lib/core/utils/amount_input_formatter.dart`
- Modify: `lib/core/utils/currency_formatter.dart`
- Test: `test/unit/formatters_test.dart` (thêm 2 group mới)

**Interfaces:**
- Consumes: không phụ thuộc task trước.
- Produces:
  - `class ThousandsSeparatorInputFormatter extends TextInputFormatter` với constructor `const ThousandsSeparatorInputFormatter({int maxDigits = 12})`.
  - `static String ThousandsSeparatorInputFormatter.groupDigits(String digits)` — `'1500000'` → `'1.500.000'`.
  - `static int ThousandsSeparatorInputFormatter.countDigitsBefore(String text, int cursor)`.
  - `static int ThousandsSeparatorInputFormatter.offsetAfterDigitCount(String formatted, int digitCount)`.
  - `static double? CurrencyFormatter.parseInput(String raw)`.
  - `static String CurrencyFormatter.toEditableText(num amount)` — seed controller khi sửa bản ghi.

- [ ] **Step 1: Viết test trước khi có code**

Thêm vào cuối `test/unit/formatters_test.dart` (giữ nguyên các group cũ):

```dart
  group('CurrencyFormatter.parseInput', () {
    test('reads grouped and punctuated VND text', () {
      expect(CurrencyFormatter.parseInput('1.500.000'), 1500000);
      expect(CurrencyFormatter.parseInput('1,500,000'), 1500000);
      expect(CurrencyFormatter.parseInput('  35 000 ₫'), 35000);
      expect(CurrencyFormatter.parseInput('0'), 0);
    });

    test('returns null when no digit exists', () {
      expect(CurrencyFormatter.parseInput(''), isNull);
      expect(CurrencyFormatter.parseInput('abc'), isNull);
      expect(CurrencyFormatter.parseInput('   '), isNull);
    });

    test('toEditableText seeds controllers with grouped digits', () {
      expect(CurrencyFormatter.toEditableText(1500000), '1.500.000');
      expect(CurrencyFormatter.toEditableText(35000.6), '35.001');
      expect(CurrencyFormatter.toEditableText(0), '');
    });
  });

  group('ThousandsSeparatorInputFormatter', () {
    const formatter = ThousandsSeparatorInputFormatter();

    TextEditingValue edit(String from, String to, {int? cursor}) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: from,
          selection: TextSelection.collapsed(offset: from.length),
        ),
        TextEditingValue(
          text: to,
          selection: TextSelection.collapsed(offset: cursor ?? to.length),
        ),
      );
    }

    test('groups every three digits', () {
      expect(edit('', '3').text, '3');
      expect(edit('35', '35000').text, '35.000');
      expect(edit('150000', '1500000').text, '1.500.000');
    });

    test('drops non digits pasted from elsewhere', () {
      expect(edit('', '1,234,567 đ').text, '1.234.567');
    });

    test('strips leading zeros', () {
      expect(edit('', '007').text, '7');
      expect(edit('0', '').text, '');
    });

    test('refuses more than maxDigits', () {
      final result = edit('123.456.789.012', '123.456.789.0123');
      expect(result.text, '123.456.789.012');
    });

    test('reformats when appending a digit at the end', () {
      final result = edit('35.000', '35.0001');
      expect(result.text, '350.001');
      expect(result.selection.extentOffset, result.text.length);
    });

    test('keeps the caret in place when typing in the middle', () {
      // '35.000' + chèn '0' ngay sau ký tự đầu -> '350.000', con trỏ sau số 3.
      final result = edit('35.000', '305.000', cursor: 3);
      expect(result.text, '305.000');
      expect(result.selection.extentOffset, 3);
    });

    test('static helpers round-trip digit counting', () {
      expect(ThousandsSeparatorInputFormatter.groupDigits('1234567'), '1.234.567');
      expect(
        ThousandsSeparatorInputFormatter.countDigitsBefore('1.234.5', 6),
        4,
      );
      expect(
        ThousandsSeparatorInputFormatter.offsetAfterDigitCount('1.234.567', 4),
        6,
      );
    });
  });
```

- [ ] **Step 2: Chạy test, chắc chắn FAIL vì thiếu symbol**

Run: `flutter test test/unit/formatters_test.dart`
Expected: FAIL — `Undefined name 'ThousandsSeparatorInputFormatter'` và `CurrencyFormatter.parseInput`/`toEditableText` không tồn tại.

- [ ] **Step 3: Viết `amount_input_formatter.dart`**

```dart
import 'package:flutter/services.dart';

/// Chỉ nhận chữ số và chèn dấu chấm nhóm nghìn khi người dùng gõ.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) {
      return oldValue;
    }
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = groupDigits(digits);
    final typedDigits = countDigitsBefore(
      newValue.text,
      newValue.selection.end,
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: offsetAfterDigitCount(formatted, typedDigits),
      ),
    );
  }

  static String groupDigits(String digits) {
    final groups = <String>[];
    var rest = digits;
    while (rest.length > 3) {
      groups.insert(0, rest.substring(rest.length - 3));
      rest = rest.substring(0, rest.length - 3);
    }
    groups.insert(0, rest);
    return groups.join('.');
  }

  static int countDigitsBefore(String text, int cursor) {
    if (cursor <= 0) return 0;
    final end = cursor > text.length ? text.length : cursor;
    var count = 0;
    for (var i = 0; i < end; i++) {
      if (_isDigit(text.codeUnitAt(i))) count++;
    }
    return count;
  }

  static int offsetAfterDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted.codeUnitAt(i))) {
        seen++;
        if (seen == digitCount) return i + 1;
      }
    }
    return formatted.length;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
```

- [ ] **Step 4: Thêm `parseInput` và `toEditableText` vào `CurrencyFormatter`**

`lib/core/utils/currency_formatter.dart` trở thành:

```dart
import 'package:intl/intl.dart';

import 'amount_input_formatter.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  /// Đọc một chuỗi tiền do người dùng nhập (bỏ mọi ký tự ngoài chữ số).
  /// Trả null khi không còn chữ số nào.
  static double? parseInput(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  /// Chuỗi đã nhóm nghìn để seed TextEditingController; rỗng khi amount <= 0.
  static String toEditableText(num amount) {
    final rounded = amount.round();
    if (rounded <= 0) return '';
    return ThousandsSeparatorInputFormatter.groupDigits(rounded.toString());
  }
}
```

- [ ] **Step 5: Chạy test đến PASS**

Run: `flutter test test/unit/formatters_test.dart`
Expected: PASS, gồm cả 4 test cũ của `CurrencyFormatter.format` và `DateFormatter`.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit (chỉ khi người dùng ủy quyền)**

```bash
git add lib/core/utils/amount_input_formatter.dart lib/core/utils/currency_formatter.dart test/unit/formatters_test.dart
git commit -m "feat: add thousands separator input formatter and amount parser"
```

---

### Task 2: Bind formatter vào 5 ô nhập tiền và bỏ 6 chỗ parse thủ công

**Files:**
- Modify: `lib/screens/camera/expense_form_sheet.dart:41-43, 66-68, 205-222`
- Modify: `lib/screens/budget/budget_screen.dart:42-44, 50-52, 74, 82, 227-236, 337-345`
- Modify: `lib/screens/home/home_screen.dart:1088-1106, 1127-1128`
- Test: `test/widget/amount_input_test.dart` (create)

**Interfaces:**
- Consumes: `ThousandsSeparatorInputFormatter`, `CurrencyFormatter.parseInput`, `CurrencyFormatter.toEditableText` (Task 1).
- Produces: không API mới; toàn bộ ô tiền trong app nhận format và parse như nhau.

- [ ] **Step 1: Viết widget test cho hành vi gõ số**

Create `test/widget/amount_input_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/utils/amount_input_formatter.dart';
import 'package:chi_tieu/core/utils/currency_formatter.dart';

void main() {
  Future<TextEditingController> pumpAmountField(
    WidgetTester tester, {
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: const [ThousandsSeparatorInputFormatter()],
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('typing 1500000 shows grouped digits', (tester) async {
    final controller = await pumpAmountField(tester);
    await tester.enterText(find.byType(TextField), '1500000');
    await tester.pump();
    expect(controller.text, '1.500.000');
  });

  testWidgets('existing value seeds grouped and still parses', (tester) async {
    final controller = await pumpAmountField(
      tester,
      initial: CurrencyFormatter.toEditableText(35000),
    );
    expect(controller.text, '35.000');
    expect(CurrencyFormatter.parseInput(controller.text), 35000);
  });

  testWidgets('empty field parses to null, not zero', (tester) async {
    final controller = await pumpAmountField(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(controller.text, '');
    expect(CurrencyFormatter.parseInput(controller.text), isNull);
  });
}
```

- [ ] **Step 2: Chạy test — PASS từ đầu vì code Task 1 đã đủ**

Run: `flutter test test/widget/amount_input_test.dart`
Expected: PASS. (Test này chốt hành vi để các bước sau không hồi quy.)

- [ ] **Step 3: Sửa `expense_form_sheet.dart`**

Thêm import:

```dart
import '../../core/utils/amount_input_formatter.dart';
import '../../core/utils/currency_formatter.dart';
```

Seed controller (thay `text: expense?.amount.toInt().toString() ?? ''`):

```dart
    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : CurrencyFormatter.toEditableText(expense.amount),
    );
```

Thay khối parse trong `_saveExpense` (`:66-74`):

```dart
    final amount = CurrencyFormatter.parseInput(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền phải lớn hơn 0.')),
      );
      return;
    }
```

Thay trường nhập số tiền (`:205-222`):

```dart
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Số tiền (VND)',
                      hintText: '35.000',
                      suffixText: '₫',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = CurrencyFormatter.parseInput(
                        value ?? '',
                      );
                      return amount == null || amount <= 0
                          ? 'Nhập số tiền lớn hơn 0'
                          : null;
                    },
                  ),
```

- [ ] **Step 4: Sửa `budget_screen.dart`**

Thêm import `../../core/utils/amount_input_formatter.dart` (đã có `currency_formatter.dart` ở `:7`).

Seed (`:42-44` và `:50-52`):

```dart
      _totalBudgetController.text = CurrencyFormatter.toEditableText(
        budgetState.totalBudget!.amount,
      );
```

```dart
        _categoryControllers[cat.id!] = TextEditingController(
          text: CurrencyFormatter.toEditableText(amount ?? 0),
        );
```

Parse trong `_saveBudget` (`:74` và `:82`):

```dart
        final total = CurrencyFormatter.parseInput(
          _totalBudgetController.text,
        );
```

```dart
          final val = CurrencyFormatter.parseInput(controller.text);
```

Cả hai đều đi kèm `?? 0.0` / `val != null && val > 0` như logic cũ — giữ nguyên nhánh hiện tại, chỉ đổi cách lấy số.

Hai `TextField` (`:227-236`, `:337-345`) thêm:

```dart
            inputFormatters: const [ThousandsSeparatorInputFormatter()],
```

và đổi `hintText: '5000000'` → `hintText: '5.000.000'`.

- [ ] **Step 5: Sửa `home_screen.dart` (lọc min/max)**

Thêm import `../../core/utils/amount_input_formatter.dart` (`currency_formatter.dart` đã có sẵn ở `home_screen.dart:8`).

Hai `TextField` (`:1088-1106`) thêm `inputFormatters: const [ThousandsSeparatorInputFormatter()],`.

Thay parse khi áp dụng bộ lọc (`:1127-1128`):

```dart
                          minAmount: CurrencyFormatter.parseInput(
                            _minController.text,
                          ),
                          maxAmount: CurrencyFormatter.parseInput(
                            _maxController.text,
                          ),
```

`_minController`/`_maxController` khai báo ở `home_screen.dart:965-966` và gán trong `_FilterSheetState.initState` (`home_screen.dart:974-979`, class tên là `_FilterSheetState` chứ không phải `_ExpenseFilterSheetState`), hiện dùng `widget.initial.minAmount?.toInt().toString() ?? ''` — số thô không có dấu chấm. Thay đúng 6 dòng đó thành:

```dart
    _minController = TextEditingController(
      text: CurrencyFormatter.toEditableText(widget.initial.minAmount ?? 0),
    );
    _maxController = TextEditingController(
      text: CurrencyFormatter.toEditableText(widget.initial.maxAmount ?? 0),
    );
```

`toEditableText(0)` trả `''` (test Step 1 Task 1) nên bộ lọc trống và bộ lọc `0` cho cùng một kết quả — không đổi hành vi.

- [ ] **Step 6: Grep chốt — không còn parse thủ công**

Run: `grep -rn "double.tryParse\|replaceAll(',', '')" lib/`
Expected: **không có kết quả** trong `lib/screens/`. Nếu còn, sửa tiếp; `intl` không tự sinh ra kết quả này.

Run: `grep -rn "TextInputType.number" lib/`
Expected: 5 dòng, tất cả đều kèm `inputFormatters: const [ThousandsSeparatorInputFormatter()]` trong cùng block. Kiểm tra bằng:
`grep -rn -A 1 "TextInputType.number" lib/`

- [ ] **Step 7: Chạy toàn bộ test**

Run: `flutter test`
Expected: PASS. Các test cũ `formatters_test.dart`, `models_test.dart`, `screens_test.dart` vẫn xanh.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/screens/camera/expense_form_sheet.dart lib/screens/budget/budget_screen.dart lib/screens/home/home_screen.dart test/widget/amount_input_test.dart
git commit -m "feat: group thousands in all amount inputs"
```

---

### Task 3: Helper thuần cho giới hạn ngày giờ khoản chi

**Files:**
- Create: `lib/core/utils/expense_date_limits.dart`
- Test: `test/unit/formatters_test.dart` (thêm group `ExpenseDateLimits`)

**Interfaces:**
- Consumes: không.
- Produces:
  - `static DateTime ExpenseDateLimits.firstDate(DateTime now)` — `now` trừ 10 năm, giữ nguyên tháng/ngày.
  - `static DateTime ExpenseDateLimits.lastDate(DateTime now)` — `now`.
  - `static DateTime? ExpenseDateLimits.validate(DateTime value, DateTime now, {Duration tolerance})` — null nếu hợp lệ, ngược lại chuỗi lỗi tiếng Việt.
  - `static DateTime ExpenseDateLimits.combine(DateTime date, int hour, int minute)`.
  - `static DateTime ExpenseDateLimits.clampToAllowedRange(DateTime value, DateTime now)`.

- [ ] **Step 1: Viết test**

Thêm vào cuối `test/unit/formatters_test.dart` và import `package:chi_tieu/core/utils/expense_date_limits.dart` ở đầu file:

```dart
  group('ExpenseDateLimits', () {
    final now = DateTime(2026, 10, 26, 14, 30);

    test('firstDate is ten years back', () {
      expect(ExpenseDateLimits.firstDate(now), DateTime(2016, 10, 26));
    });

    test('lastDate is now', () {
      expect(ExpenseDateLimits.lastDate(now), now);
    });

    test('future beyond one minute tolerance is rejected', () {
      expect(
        ExpenseDateLimits.validate(now.add(const Duration(seconds: 30)), now),
        isNull,
      );
      expect(
        ExpenseDateLimits.validate(now.add(const Duration(minutes: 5)), now),
        'Không thể ghi nhận khoản chi trong tương lai.',
      );
    });

    test('dates before firstDate are rejected', () {
      expect(
        ExpenseDateLimits.validate(DateTime(2000, 1, 1), now),
        'Khoản chi không thể cũ hơn 10 năm.',
      );
    });

    test('combine keeps the calendar day but swaps the clock', () {
      expect(
        ExpenseDateLimits.combine(DateTime(2026, 5, 20, 9, 5), 21, 45),
        DateTime(2026, 5, 20, 21, 45),
      );
    });

    test('clamp pulls an out-of-range value back inside', () {
      expect(
        ExpenseDateLimits.clampToAllowedRange(
          now.add(const Duration(hours: 2)),
          now,
        ),
        now,
      );
      expect(
        ExpenseDateLimits.clampToAllowedRange(DateTime(1999, 1, 1), now),
        ExpenseDateLimits.firstDate(now),
      );
    });
  });
```

- [ ] **Step 2: Chạy test — FAIL vì thiếu file**

Run: `flutter test test/unit/formatters_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:chi_tieu/core/utils/expense_date_limits.dart'`.

- [ ] **Step 3: Viết implementation**

```dart
/// Giới hạn ngày giờ cho khoản chi: không tương lai, không quá 10 năm.
class ExpenseDateLimits {
  const ExpenseDateLimits._();

  static DateTime firstDate(DateTime now) =>
      DateTime(now.year - 10, now.month, now.day);

  static DateTime lastDate(DateTime now) => now;

  /// null khi hợp lệ; ngược lại là thông báo lỗi tiếng Việt.
  static String? validate(
    DateTime value,
    DateTime now, {
    Duration tolerance = const Duration(minutes: 1),
  }) {
    if (value.isAfter(now.add(tolerance))) {
      return 'Không thể ghi nhận khoản chi trong tương lai.';
    }
    if (value.isBefore(firstDate(now))) {
      return 'Khoản chi không thể cũ hơn 10 năm.';
    }
    return null;
  }

  static DateTime combine(DateTime date, int hour, int minute) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  static DateTime clampToAllowedRange(
    DateTime value,
    DateTime now, {
    Duration tolerance = const Duration(minutes: 1),
  }) {
    if (value.isAfter(now)) return now;
    if (value.isBefore(firstDate(now))) return firstDate(now);
    return value;
  }
}
```

- [ ] **Step 4: Chạy test đến PASS**

Run: `flutter test test/unit/formatters_test.dart`
Expected: PASS toàn bộ group `ExpenseDateLimits`.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/core/utils/expense_date_limits.dart test/unit/formatters_test.dart
git commit -m "feat: add pure date range limits for expense entries"
```

---

### Task 4: Trường chọn ngày giờ trong `ExpenseFormSheet`

**Files:**
- Create: `lib/screens/camera/expense_datetime_field.dart`
- Modify: `lib/screens/camera/expense_form_sheet.dart:24-46, 48-127, 193-223`
- Test: `test/widget/expense_datetime_field_test.dart` (create)

**Interfaces:**
- Consumes: `ExpenseDateLimits` (Task 3), `DateFormatter.formatDate`/`formatTime`, `context.palette` (Plan 2 Task 2 — các field `mintInk`, `inkMuted`, `danger` đều có trong `AppPalette`).
- Produces:
  - `class ExpenseDateTimeField extends StatelessWidget` với `ExpenseDateTimeField({required DateTime value, required ValueChanged<DateTime> onChanged, String label = 'Ngày giờ ghi nhận', DateTime? maxNow})`.
  - `ExpenseFormSheet` lưu `_occurredAt` và truyền vào `Expense(createdAt:)` / `copyWith(createdAt:)`.

- [ ] **Step 1: Viết widget test**

Create `test/widget/expense_datetime_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/theme/app_palette.dart';
import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/screens/camera/expense_datetime_field.dart';

void main() {
  DateTime? captured;
  final fixed = DateTime(2026, 5, 20, 8, 5);

  Future<void> pump(WidgetTester tester) async {
    captured = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ExpenseDateTimeField(
            value: fixed,
            maxNow: DateTime(2026, 10, 26, 14, 30),
            onChanged: (v) => captured = v,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the stored date and time', (tester) async {
    await pump(tester);
    expect(find.text('20/05/2026'), findsOneWidget);
    expect(find.text('08:05'), findsOneWidget);
    expect(find.text('Bây giờ'), findsOneWidget);
  });

  testWidgets('Bây giờ emits a clamped timestamp', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Bây giờ'));
    await tester.pump();
    expect(captured, DateTime(2026, 10, 26, 14, 30));
  });

  testWidgets('date and time are separate tap targets of at least 48dp', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(OutlinedButton), findsNWidgets(2));
    for (final button in find.byType(OutlinedButton).evaluate().toList()) {
      final size = tester.getSize(find.byWidget(button));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.getSize(find.text('Bây giờ')).height, greaterThan(0));
  });
}
```

Ghi chú: `AppTheme.light` đã mang `extensions: [AppPalette.light]` sau Plan 2 Task 3, nên widget dùng `context.palette` hợp lệ trong test.

- [ ] **Step 2: Chạy test — FAIL vì thiếu file**

Run: `flutter test test/widget/expense_datetime_field_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Viết widget**

Create `lib/screens/camera/expense_datetime_field.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/expense_date_limits.dart';

/// Hai nút chọn ngày và giờ kèm nút reset "Bây giờ".
class ExpenseDateTimeField extends StatelessWidget {
  const ExpenseDateTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Ngày giờ ghi nhận',
    this.maxNow,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String label;

  /// Inject mốc "hiện tại" để test được deterministic; mặc định là `DateTime.now()`.
  final DateTime? maxNow;

  Future<void> _pickDate(BuildContext context) async {
    final now = maxNow ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ExpenseDateLimits.clampToAllowedRange(value, now),
      firstDate: ExpenseDateLimits.firstDate(now),
      lastDate: ExpenseDateLimits.lastDate(now),
      helpText: 'Chọn ngày khoản chi',
    );
    if (picked == null) return;
    onChanged(
      ExpenseDateLimits.combine(picked, value.hour, value.minute),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      helpText: 'Chọn giờ khoản chi',
    );
    if (picked == null) return;
    onChanged(ExpenseDateLimits.combine(value, picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickDate(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(DateFormatter.formatDate(value)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(DateFormatter.formatTime(value)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                final now = maxNow ?? DateTime.now();
                onChanged(ExpenseDateLimits.clampToAllowedRange(now, now));
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: palette.mintInk,
              ),
              child: const Text('Bây giờ'),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Chạy test đến PASS**

Run: `flutter test test/widget/expense_datetime_field_test.dart`
Expected: PASS cả 3 test. Nếu test "Bây giờ" fail vì `clampToAllowedRange` trả `now` có giây > 0, thì `maxNow` đã truyền `DateTime(2026, 10, 26, 14, 30)` không giây — so sánh `DateTime` là so sánh tuyệt đối, nên giữ nguyên; không được nới assertion.

- [ ] **Step 5: Nối vào `ExpenseFormSheet`**

Thêm import:

```dart
import '../../core/utils/expense_date_limits.dart';
import 'expense_datetime_field.dart';
```

State (sau `late int _selectedPriority;`):

```dart
  late DateTime _occurredAt;
  DateTime? _dateError;
```

`initState`:

```dart
    _occurredAt = expense?.createdAt ?? DateTime.now();
```

Trong `_saveExpense`, ngay sau khi lấy được `amount` hợp lệ (Task 2 Step 3), chèn bước kiểm tra:

```dart
    final now = DateTime.now();
    final dateError = ExpenseDateLimits.validate(_occurredAt, now);
    if (dateError != null) {
      setState(() => _dateError = dateError);
      return;
    }
    setState(() => _dateError = null);
```

Và truyền `createdAt` vào cả hai nhánh:

```dart
        final updated = widget.expense!.copyWith(
          caption: _captionController.text.trim(),
          amount: amount,
          categoryId: categoryId,
          priority: _selectedPriority,
          createdAt: _occurredAt,
        );
```

```dart
        final newExpense = Expense(
          caption: _captionController.text.trim(),
          amount: amount,
          categoryId: categoryId,
          priority: _selectedPriority,
          imagePath: sourceImagePath,
          createdAt: _occurredAt,
        );
```

Chèn widget vào form, ngay sau trường số tiền (`:` kế tiếp là `const SizedBox(height: 20)` trước khối "Danh mục"):

```dart
                  const SizedBox(height: 16),
                  ExpenseDateTimeField(
                    value: _occurredAt,
                    onChanged: (value) => setState(() {
                      _occurredAt = value;
                      _dateError = ExpenseDateLimits.validate(
                        value,
                        DateTime.now(),
                      );
                    }),
                  ),
                  if (_dateError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _dateError!,
                      style: TextStyle(
                        color: context.palette.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
```

Thêm import `../../core/theme/app_palette.dart` cho `context.palette`.

- [ ] **Step 6: Kiểm tra `copyWith` cho phép `createdAt`**

Run: `grep -n "DateTime? createdAt" lib/data/models/expense.dart`
Expected: có 2 dòng (field + tham số `copyWith`). `Expense.copyWith(createdAt:)` đã tồn tại — không cần sửa model.

- [ ] **Step 7: Chạy test + analyze**

Run: `flutter test && flutter analyze`
Expected: PASS / `No issues found!`

- [ ] **Step 8: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/screens/camera/expense_datetime_field.dart lib/screens/camera/expense_form_sheet.dart test/widget/expense_datetime_field_test.dart
git commit -m "feat: let users edit the date and time of an expense"
```

---

### Task 5: Repository + provider cho luồng quên mật khẩu

**Files:**
- Modify: `lib/data/repositories/auth_repository.dart:117-126`
- Modify: `lib/providers/auth_provider.dart` (`AppAuthState`, `_listenAuth`, method mới, `_humanReadableError`)
- Test: `test/unit/auth_and_supabase_test.dart`

**Interfaces:**
- Consumes: `supabase_flutter` GOTRUE APIs đã xác minh: `GoTrueClient.resetPasswordForEmail(String email, {String? redirectTo, String? captchaToken})` trả `Future<void>` (gotrue-2.27.3 `lib/src/gotrue_client.dart:1116-1120`) và `GoTrueClient.updateUser(UserAttributes attributes, {String? emailRedirectTo})` trả `Future<UserResponse>` (`:891-893`), `UserAttributes({String? password, ...})` (`lib/src/types/user_attributes.dart:3-34`), `AuthChangeEvent.passwordRecovery` (`lib/src/constants.dart:39`).
- Produces:
  - `static const String AuthRepository.recoveryRedirect = 'io.supabase.chitieu://login-callback/';`
  - `Future<void> AuthRepository.resetPassword(String email, {String redirectTo = recoveryRedirect})`
  - `Future<void> AuthRepository.updatePassword(String newPassword)`
  - `AppAuthState.recoveryMode` (`bool`, default `false`)
  - `Future<bool> AuthNotifier.sendPasswordResetEmail(String email)`
  - `Future<bool> AuthNotifier.setNewPassword(String password)`
  - `void AuthNotifier.exitRecoveryMode()`

- [ ] **Step 1: Viết test state**

Sửa group `Auth State Tests` trong `test/unit/auth_and_supabase_test.dart` (thêm 2 test mới, giữ nguyên 3 test cũ):

```dart
    test('AppAuthState defaults recoveryMode to false', () {
      const state = AppAuthState();
      expect(state.recoveryMode, isFalse);
    });

    test('copyWith turns recoveryMode on and off again', () {
      const state = AppAuthState();
      final recovering = state.copyWith(
        status: AuthStatus.authenticated,
        recoveryMode: true,
      );
      expect(recovering.recoveryMode, isTrue);

      final done = recovering.copyWith(recoveryMode: false);
      expect(done.recoveryMode, isFalse);
      expect(done.status, AuthStatus.authenticated);
    });
```

Run: `flutter test test/unit/auth_and_supabase_test.dart`
Expected: FAIL — `No named parameter with the name 'recoveryMode'`.

- [ ] **Step 2: Thêm cờ `recoveryMode` và bắt event PASSWORD_RECOVERY**

Trong `AppAuthState` thêm field + constructor + copyWith:

```dart
  final bool recoveryMode;

  const AppAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isConfigured = false,
    this.recoveryMode = false,
  });

  AppAuthState copyWith({
    AuthStatus? status,
    sb.User? user,
    String? errorMessage,
    bool? isConfigured,
    bool? recoveryMode,
    bool clearUser = false,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      errorMessage: errorMessage,
      isConfigured: isConfigured ?? this.isConfigured,
      recoveryMode: recoveryMode ?? this.recoveryMode,
    );
  }
```

Trong `_listenAuth`, đổi thân `stream.listen` thành (giữ logic session cũ, thêm xử lý event):

```dart
      _authSubscription = stream.listen((data) {
        final session = data.session;
        if (data.event == sb.AuthChangeEvent.passwordRecovery) {
          // Deep link đã đổi code thành session: ưu tiên màn đặt lại mật khẩu.
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: session?.user,
            recoveryMode: true,
            errorMessage: null,
          );
          return;
        }
        if (session != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: session.user,
            errorMessage: null,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            recoveryMode: false,
            errorMessage: null,
          );
        }
      });
```

- [ ] **Step 3: Thêm 3 method trong `AuthNotifier`**

Chèn phía trên `signOut()`:

```dart
  /// Gửi email đặt lại mật khẩu. Luôn trả về thông điệp trung tính để
  /// không tiết kiệm email nào tồn tại trong hệ thống.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repo.resetPassword(email);
      state = state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> setNewPassword(String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repo.updatePassword(password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        recoveryMode: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        recoveryMode: true,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  void exitRecoveryMode() {
    state = state.copyWith(recoveryMode: false);
  }
```

Thêm nhánh vào `_humanReadableError` (đặt cạnh các nhánh cũ):

```dart
    if (raw.contains('AuthSessionMissingException') ||
        raw.contains('Session missing') ||
        raw.contains('valid session')) {
      return 'Phiên đặt lại mật khẩu đã hết hạn. Hãy bấm "Quên mật khẩu" một lần nữa.';
    }
    if (raw.contains('For security purposes') ||
        raw.contains('requires reauthentication')) {
      return 'Cần đăng nhập lại trước khi đổi mật khẩu.';
    }
```

- [ ] **Step 4: Sửa `AuthRepository`**

Thay `resetPassword` (`:117-126`) và thêm `updatePassword`:

```dart
  /// Deep link đã khai báo trong AndroidManifest.xml (`io.supabase.chitieu`).
  static const String recoveryRedirect = 'io.supabase.chitieu://login-callback/';

  Future<void> resetPassword(
    String email, {
    String redirectTo = recoveryRedirect,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase chưa được cấu hình. Vui lòng kiểm tra file .env',
      );
    }
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase chưa được cấu hình. Vui lòng kiểm tra file .env',
      );
    }
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự.');
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }
```

`UserAttributes` và `AuthChangeEvent` đã có sẵn qua `import 'package:supabase_flutter/supabase_flutter.dart';` (`auth_repository.dart:6`, `auth_provider.dart:4` dưới alias `sb.`) vì `supabase_flutter` re-export `package:supabase/supabase.dart` → gotrue. Không cần thêm import mới; nếu analyzer vẫn báo thiếu symbol, dán nguyên văn lỗi và dừng để xử lý.

- [ ] **Step 5: Chạy test đến PASS**

Run: `flutter test test/unit/auth_and_supabase_test.dart`
Expected: PASS (5 test cũ + 2 test mới).

Run: `flutter test && flutter analyze`
Expected: PASS / `No issues found!`

- [ ] **Step 6: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/data/repositories/auth_repository.dart lib/providers/auth_provider.dart test/unit/auth_and_supabase_test.dart
git commit -m "feat: wire password recovery state and API calls"
```

---

### Task 6: Sheet "Quên mật khẩu" và link trong màn đăng nhập

**Files:**
- Create: `lib/screens/auth/forgot_password_sheet.dart`
- Modify: `lib/screens/auth/login_screen.dart:283-330` (khối "Chưa có tài khoản?")
- Test: `test/widget/forgot_password_sheet_test.dart` (create)

**Interfaces:**
- Consumes: `AuthNotifier.sendPasswordResetEmail` (Task 5), `showPixelSheet`/`showPixelSnackBar`/`PixelTextField`/`PixelButton` (Plan 2 Task 8).
- Produces: `Future<void> showForgotPasswordSheet(BuildContext context)`.

- [ ] **Step 1: Viết widget test với notifier giả**

Create `test/widget/forgot_password_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/screens/auth/forgot_password_sheet.dart';

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
    expect(
      find.textContaining('Nếu email này có tài khoản'),
      findsOneWidget,
    );
    expect(find.textContaining('Không tìm thấy tài khoản'), findsNothing);
  });
}
```

- [ ] **Step 2: Chạy test — FAIL vì thiếu file**

Run: `flutter test test/widget/forgot_password_sheet_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../forgot_password_sheet.dart'`.

- [ ] **Step 3: Viết sheet**

Create `lib/screens/auth/forgot_password_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_sheet.dart';
import '../../widgets/pixel/pixel_snackbar.dart';
import '../../widgets/pixel/pixel_text_field.dart';

const String _neutralSuccessCopy =
    'Nếu email này có tài khoản, chúng mình đã gửi link đặt lại mật khẩu. '
    'Mở hộp thư (kể cả thư mục spam) và bấm link trong 60 phút.';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
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
          : (authState.errorMessage ?? 'Không thể gửi email. Thử lại sau ít phút.'),
      tone: sent ? PixelTone.info : PixelTone.danger,
    );
    if (sent) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nhập email bạn dùng để đăng ký. Link đặt lại mật khẩu sẽ gửi về hộp thư.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.inkMuted,
              ),
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
```

`showPixelSheet` (Plan 2 Task 8) tự render `title` ở đầu sheet, nên `ForgotPasswordSheet` chỉ bắt đầu bằng đoạn hướng dẫn email — test ở Step 1 tìm `'Quên mật khẩu'` đúng một lần, từ wrapper.

Trước khi chạy test, xác minh một lần các import/đường dẫn component: `grep -rn "class PixelTextField\|Future<T?> showPixelSheet\|void showPixelSnackBar\|enum PixelTone\|class PixelButton" lib/widgets/pixel/` — nếu thiếu symbol nào nghĩa là Plan 2 chưa xong task tương ứng, dừng và hoàn tất Plan 2 trước; không thay component pixel bằng widget Material tự chế.

- [ ] **Step 4: Chạy test đến PASS**

Run: `flutter test test/widget/forgot_password_sheet_test.dart`
Expected: PASS 4 test. Nếu test 4 fail do copy bị ngắt dòng khác, sửa **chuỗi trong code** cho đúng test, không nới matcher.

- [ ] **Step 5: Thêm link trong `LoginScreen`**

Chèn ngay trên hàng "Chưa có tài khoản?" (`:283`):

```dart
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showForgotPasswordSheet(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 44),
                      ),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  const SizedBox(height: 8),
```

Thêm import `import 'forgot_password_sheet.dart';`.

- [ ] **Step 6: Chạy test screen cũ + analyze**

Run: `flutter test test/widget/ && flutter analyze`
Expected: PASS / `No issues found!` (`test/widget/screens_test.dart` không đụng LoginScreen nên không đổi.)

- [ ] **Step 7: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/screens/auth/forgot_password_sheet.dart lib/screens/auth/login_screen.dart test/widget/forgot_password_sheet_test.dart
git commit -m "feat: add forgot password sheet with neutral email copy"
```

---

### Task 7: Màn đặt lại mật khẩu và app gate theo `recoveryMode`

**Files:**
- Create: `lib/screens/auth/reset_password_screen.dart`
- Modify: `lib/app.dart:22-24, 58-76`
- Test: `test/unit/auth_gate_recovery_test.dart` (create), `test/widget/reset_password_screen_test.dart` (create)

**Interfaces:**
- Consumes: `AppAuthState.recoveryMode` + `AuthNotifier.setNewPassword`/`exitRecoveryMode` (Task 5), component kit Plan 2.
- Produces:
  - `enum HomeTarget { loading, onboarding, login, resetPassword, main }`
  - `HomeTarget decideHomeTarget({required bool onboardingComplete, required AppAuthState auth})`
  - `class ResetPasswordScreen extends ConsumerStatefulWidget`

- [ ] **Step 1: Viết unit test bảng quyết định**

Create `test/unit/auth_gate_recovery_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/app.dart';
import 'package:chi_tieu/providers/auth_provider.dart';

void main() {
  test('onboarding wins over everything else', () {
    expect(
      decideHomeTarget(
        onboardingComplete: false,
        auth: const AppAuthState(status: AuthStatus.authenticated),
      ),
      HomeTarget.onboarding,
    );
  });

  test('recovery mode wins over the normal authenticated route', () {
    expect(
      decideHomeTarget(
        onboardingComplete: true,
        auth: const AppAuthState(
          status: AuthStatus.authenticated,
          recoveryMode: true,
        ),
      ),
      HomeTarget.resetPassword,
    );
  });

  test('authenticated without recovery goes to main', () {
    expect(
      decideHomeTarget(
        onboardingComplete: true,
        auth: const AppAuthState(status: AuthStatus.authenticated),
      ),
      HomeTarget.main,
    );
  });

  test('every non-authenticated status shows login', () {
    for (final status in [
      AuthStatus.initial,
      AuthStatus.unauthenticated,
      AuthStatus.loading,
      AuthStatus.error,
    ]) {
      expect(
        decideHomeTarget(
          onboardingComplete: true,
          auth: AppAuthState(status: status),
        ),
        HomeTarget.login,
      );
    }
  });
}
```

- [ ] **Step 2: Chạy test — FAIL vì thiếu `decideHomeTarget`/`HomeTarget`**

Run: `flutter test test/unit/auth_gate_recovery_test.dart`
Expected: FAIL — `Undefined name 'decideHomeTarget'`.

- [ ] **Step 3: Tách quyết định ra khỏi `build`**

Trong `lib/app.dart`, thay `shouldShowLoginScreen` (`:22-24`) bằng:

```dart
enum HomeTarget { loading, onboarding, login, resetPassword, main }

/// Routing ưu tiên: onboarding > đặt lại mật khẩu > đăng nhập > app chính.
HomeTarget decideHomeTarget({
  required bool onboardingComplete,
  required AppAuthState auth,
}) {
  if (!onboardingComplete) return HomeTarget.onboarding;
  if (auth.recoveryMode && auth.status == AuthStatus.authenticated) {
    return HomeTarget.resetPassword;
  }
  if (auth.status != AuthStatus.authenticated) return HomeTarget.login;
  return HomeTarget.main;
}
```

Trong `_AppHome.build`, thay ba `if` cuối (`:66-76`) bằng switch trên target:

```dart
    final target = decideHomeTarget(
      onboardingComplete: settings.onboardingComplete,
      auth: authState,
    );

    return switch (target) {
      HomeTarget.onboarding => const OnboardingScreen(),
      HomeTarget.resetPassword => const ResetPasswordScreen(),
      HomeTarget.login => const LoginScreen(),
      HomeTarget.main => const MainScreen(),
      HomeTarget.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    };
```

và đặt `if (settings.isLoading) return const Scaffold(...)` cũ thành `if (settings.isLoading) return const HomeTargetLoading();`, với:

```dart
class HomeTargetLoading extends StatelessWidget {
  const HomeTargetLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
```

Thêm `import 'screens/auth/reset_password_screen.dart';`.

Ghi chú: `HomeTarget.loading` tồn tại để switch đủ nhánh; đường đi thực tế vẫn do `settings.isLoading` quyết — giữ cả hai để switch không im lặng bỏ sót.

- [ ] **Step 4: Chạy unit test đến PASS**

Run: `flutter test test/unit/auth_gate_recovery_test.dart && flutter test test/unit/auth_gate_test.dart`
Expected: PASS. `auth_gate_test.dart` test `shouldShowLoginScreen` — hàm đó đã bị thay; **xóa các test tham chiếu `shouldShowLoginScreen`** trong `auth_gate_test.dart` và thay bằng test tương đương gọi `decideHomeTarget`:

```dart
    expect(
      decideHomeTarget(
        onboardingComplete: true,
        auth: AppAuthState(status: status),
      ) !=
        HomeTarget.main,
      isTrue,
    );
```

(Giữ nguyên ý nghĩa test gốc: mọi status chưa authenticated đều không được vào app chính.)

- [ ] **Step 5: Viết widget test màn đặt lại mật khẩu**

Create `test/widget/reset_password_screen_test.dart`:

```dart
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
  testWidgets('rejects a short password and does not submit', (tester) async {
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

    await tester.enterText(find.byKey(const Key('newPasswordField')), '123');
    await tester.enterText(find.byKey(const Key('confirmPasswordField')), '123');
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pump();

    expect(notifier.submitted, isEmpty);
    expect(find.text('Mật khẩu từ 6 ký tự trở lên'), findsOneWidget);
  });

  testWidgets('mismatch blocks submit', (tester) async {
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

    await tester.enterText(find.byKey(const Key('newPasswordField')), 'secret1');
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      'secret2',
    );
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pump();

    expect(notifier.submitted, isEmpty);
    expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);
  });

  testWidgets('valid password submits and leaves recovery mode', (tester) async {
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

    await tester.enterText(find.byKey(const Key('newPasswordField')), 'secret1');
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
```

Run: `flutter test test/widget/reset_password_screen_test.dart`
Expected: FAIL — thiếu file `reset_password_screen.dart`.

- [ ] **Step 6: Viết `ResetPasswordScreen`**

Create `lib/screens/auth/reset_password_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_snackbar.dart';
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.inkMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    PixelTextField(
                      key: const Key('newPasswordField'),
                      controller: _passwordController,
                      label: 'Mật khẩu mới',
                      obscureToggle: true,
                      validator: (value) {
                        final text = value ?? '';
                        if (text.isEmpty) return 'Vui lòng nhập mật khẩu';
                        if (text.length < 6) {
                          return 'Mật khẩu từ 6 ký tự trở lên';
                        }
                        return null;
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
```

Chữ ký `PixelTextField` đã chốt ở Plan 2 Task 8: `const PixelTextField({super.key, required this.label, ..., this.obscureToggle = false})`. Tham số bật nút che mật khẩu đúng tên `obscureToggle` (bool, default `false`) và constructor đã có `super.key`, nên các test phía trên viết `PixelTextField(label: 'Mật khẩu mới', controller: c, obscureToggle: true)` nguyên văn.

- [ ] **Step 7: Chạy toàn bộ test + analyze**

Run: `flutter test && flutter analyze`
Expected: PASS / `No issues found!`.

- [ ] **Step 8: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/screens/auth/reset_password_screen.dart lib/app.dart test/unit/auth_gate_recovery_test.dart test/unit/auth_gate_test.dart test/widget/reset_password_screen_test.dart
git commit -m "feat: add reset password screen behind recovery route"
```

---

### Task 8: `CsvBuilder` thuần (RFC 4180 + BOM)

**Files:**
- Create: `lib/core/utils/csv_builder.dart`
- Test: `test/unit/csv_builder_test.dart` (create)

**Interfaces:**
- Consumes: `Expense` (`caption`, `amount`, `categoryId`, `priorityLabel`, `createdAt`, `imagePath`).
- Produces:
  - `static const String CsvBuilder.bom = '\uFEFF';`
  - `static const List<String> CsvBuilder.headers`
  - `static String CsvBuilder.escapeField(String value)`
  - `static String CsvBuilder.buildCsv({required List<Expense> expenses, required Map<int, String> categoryNames})`

- [ ] **Step 1: Viết test**

Create `test/unit/csv_builder_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/utils/csv_builder.dart';
import 'package:chi_tieu/data/models/expense.dart';

void main() {
  Expense build({
    String caption = 'Cà phê',
    double amount = 35000,
    int categoryId = 1,
    int priority = 0,
    DateTime? createdAt,
    String? imagePath,
  }) {
    return Expense(
      caption: caption,
      amount: amount,
      categoryId: categoryId,
      priority: priority,
      createdAt: createdAt ?? DateTime(2026, 5, 20, 8, 5),
      imagePath: imagePath,
    );
  }

  group('CsvBuilder.escapeField', () {
    test('leaves plain text untouched', () {
      expect(CsvBuilder.escapeField('Cà phê'), 'Cà phê');
      expect(CsvBuilder.escapeField(''), '');
    });

    test('quotes separators, quotes, and newlines', () {
      expect(CsvBuilder.escapeField('a,b'), '"a,b"');
      expect(CsvBuilder.escapeField('x"y'), '"x""y"');
      expect(CsvBuilder.escapeField('dòng 1\ndòng 2'), '"dòng 1\ndòng 2"');
      expect(CsvBuilder.escapeField('cr\r\nlf'), '"cr\r\nlf"');
    });
  });

  group('CsvBuilder.buildCsv', () {
    const names = {1: 'Ăn uống', 2: 'Nhà ở'};

    test('starts with a UTF-8 BOM then the header row', () {
      final csv = CsvBuilder.buildCsv(expenses: [build()], categoryNames: names);
      expect(csv.startsWith(CsvBuilder.bom), isTrue);
      expect(
        csv.split('\r\n').first,
        'ngày,ghi chú,số tiền,danh mục,mức độ,ảnh',
      );
    });

    test('formats one data row with rounded amount and priority label', () {
      final csv = CsvBuilder.buildCsv(expenses: [build()], categoryNames: names);
      final rows = csv.substring(CsvBuilder.bom.length).split('\r\n');
      expect(rows[1], '20/05/2026 08:05,Cà phê,35000,Ăn uống,Thiết yếu,');
      expect(rows.last, isEmpty, reason = 'CSV kết thúc bằng một dòng mới');
    });

    test('uses the category name map and falls back to "Khác"', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [build(categoryId: 99)],
        categoryNames: names,
      );
      expect(csv, contains(',Ăn uống,'));
      expect(
        CsvBuilder.buildCsv(
          expenses: [build(categoryId: 99)],
          categoryNames: const {},
        ),
        contains(',Khác,'),
      );
    });

    test('quotes a caption containing a comma', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [build(caption: 'bún, chả')],
        categoryNames: names,
      );
      expect(csv, contains('"bún, chả"'));
    });

    test('writes the storage path of the receipt image', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [build(imagePath: 'uuid-abc/receipt.jpg')],
        categoryNames: names,
      );
      expect(csv, contains('uuid-abc/receipt.jpg'));
    });

    test('empty list yields only the header', () {
      final csv = CsvBuilder.buildCsv(expenses: [], categoryNames: names);
      expect(csv, '${CsvBuilder.bom}ngày,ghi chú,số tiền,danh mục,mức độ,ảnh\r\n');
    });

    test('handles 1000 rows without a size limit problem', () {
      final csv = CsvBuilder.buildCsv(
        expenses: List.generate(1000, (_) => build()),
        categoryNames: names,
      );
      expect(csv.split('\r\n').length, 1002);
    });
  });
}
```

- [ ] **Step 2: Chạy test — FAIL vì thiếu file**

Run: `flutter test test/unit/csv_builder_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Viết implementation**

```dart
import 'package:intl/intl.dart';

import '../../data/models/expense.dart';

/// Dựng nội dung CSV theo RFC 4180, không chạm mạng hay Flutter.
class CsvBuilder {
  const CsvBuilder._();

  /// Excel trên Windows cần BOM để đọc đúng tiếng Việt.
  static const String bom = '\uFEFF';

  static const List<String> headers = [
    'ngày',
    'ghi chú',
    'số tiền',
    'danh mục',
    'mức độ',
    'ảnh',
  ];

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String escapeField(String value) {
    final mustQuote =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!mustQuote) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String buildCsv({
    required List<Expense> expenses,
    required Map<int, String> categoryNames,
  }) {
    final rows = <List<String>>[
      headers,
      for (final expense in expenses)
        [
          _dateFormat.format(expense.createdAt),
          expense.caption,
          expense.amount.round().toString(),
          categoryNames[expense.categoryId] ?? 'Khác',
          expense.priorityLabel,
          expense.imagePath ?? '',
        ],
    ];

    final buffer = StringBuffer(bom);
    buffer.writeAll(
      rows.map((row) => row.map(escapeField).join(',')),
      '\r\n',
    );
    buffer.write('\r\n');
    return buffer.toString();
  }
}
```

- [ ] **Step 4: Chạy test đến PASS**

Run: `flutter test test/unit/csv_builder_test.dart`
Expected: PASS 10 test. Nếu test "uses the category name map" fail, nghĩa là fallback trả sai — sửa implementation, không sửa test.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/core/utils/csv_builder.dart test/unit/csv_builder_test.dart
git commit -m "feat: add RFC 4180 csv builder for expense export"
```

---

### Task 9: `CsvExportService` phân trang, ghi file tạm, mở share sheet

**Files:**
- Create: `lib/data/repositories/csv_export_service.dart`
- Modify: `pubspec.yaml` (thêm `share_plus`)
- Test: `test/unit/csv_export_service_test.dart` (create)

**Interfaces:**
- Consumes: `CsvBuilder.buildCsv` (Task 8), `ExpenseRepository.getExpenses({from, to, limit, offset})` (Plan 1 Task 5), `path_provider` `getTemporaryDirectory()`, `share_plus 13.3.1` `SharePlus.instance.share(ShareParams(files: [XFile(path)], subject:, text:))` (đã xác minh `share_plus-13.3.1/lib/share_plus.dart:22-73` và `share_plus_platform_interface-7.2.0/lib/platform_interface/share_plus_platform.dart:149-156`).
- Produces:
  - `static const int CsvExportService.pageSize = 1000;`
  - `Future<List<Expense>> CsvExportService.collectRows({DateTime? from, DateTime? to})`
  - `Future<String> CsvExportService.exportFile({required List<Expense> rows, required Map<int, String> categoryNames, String? fileName})`
  - `Future<Uri> CsvExportService.buildShareUri(DateTime now)` (tên file thuần, test được)
  - `Future<void> CsvExportService.exportAndShare({DateTime? from, DateTime? to, required Map<int, String> categoryNames})`

- [ ] **Step 1: Thêm dependency**

```bash
flutter pub add share_plus
```

Run: `grep -n "share_plus" pubspec.yaml`
Expected: `  share_plus: ^13.3.1` (phiên bản do pub chọn cho Flutter 3.47.6 — đã dry-run trước, ra đúng 13.3.1). Ghi lại phiên bản thật nếu khác.

- [ ] **Step 2: Viết unit test cho phân trang và đặt tên file**

Create `test/unit/csv_export_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/utils/csv_builder.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/repositories/csv_export_service.dart';
import 'package:chi_tieu/data/repositories/expense_repository.dart';

class _PagedRepo extends ExpenseRepository {
  _PagedRepo(this.pages);

  /// Mỗi phần tử là một trang trả về theo thứ tự offset.
  final List<List<Expense>> pages;
  final List<int?> seenOffsets = [];
  final List<int?> seenLimits = [];

  @override
  Future<List<Expense>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? search,
    int? categoryId,
    int? priority,
    double? minAmount,
    double? maxAmount,
    int? limit,
    int? offset,
  }) async {
    seenOffsets.add(offset);
    seenLimits.add(limit);
    final index = seenOffsets.length - 1;
    return index < pages.length ? pages[index] : <Expense>[];
  }
}

Expense _row() => Expense(
  caption: 'Cà phê',
  amount: 25000,
  categoryId: 1,
  createdAt: DateTime(2026, 5, 20, 8),
);

void main() {
  group('CsvExportService.collectRows', () {
    test('stops as soon as a page is short', () async {
      final repo = _PagedRepo([
        List.generate(1000, (_) => _row()),
        List.generate(250, (_) => _row()),
      ]);
      final service = CsvExportService(repo);

      final rows = await service.collectRows();

      expect(rows.length, 1250);
      expect(repo.seenLimits, [1000, 1000]);
      expect(repo.seenOffsets, [0, 1000]);
    });

    test('single short page means a single query', () async {
      final repo = _PagedRepo([
        List.generate(12, (_) => _row()),
      ]);
      final service = CsvExportService(repo);

      final rows = await service.collectRows(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31),
      );

      expect(rows.length, 12);
      expect(repo.seenOffsets, [0]);
    });

    test('exact multiple of pageSize still terminates', () async {
      final repo = _PagedRepo([
        List.generate(1000, (_) => _row()),
        <Expense>[],
      ]);
      final service = CsvExportService(repo);

      final rows = await service.collectRows();

      expect(rows.length, 1000);
      expect(repo.seenOffsets, [0, 1000]);
    });
  });

  group('CsvExportService.buildFileName', () {
    test('embeds the export timestamp', () {
      expect(
        CsvExportService.buildFileName(DateTime(2026, 11, 1, 9, 4)),
        'chi_tieu_20261101_0904.csv',
      );
    });

    test('csv text written for rows carries BOM and header', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [_row()],
        categoryNames: const {1: 'Ăn uống'},
      );
      expect(csv, startsWith(CsvBuilder.bom));
      expect(csv, contains('Ăn uống'));
    });
  });
}
```

Run: `flutter test test/unit/csv_export_service_test.dart`
Expected: FAIL — thiếu `csv_export_service.dart`.

- [ ] **Step 3: Viết service**

Create `lib/data/repositories/csv_export_service.dart`:

```dart
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/csv_builder.dart';
import '../models/expense.dart';
import 'expense_repository.dart';

/// Sao lưu khoản chi ra file CSV và mở share sheet.
class CsvExportService {
  CsvExportService([ExpenseRepository? repository])
    : _repository = repository ?? ExpenseRepository();

  static const int pageSize = 1000;

  final ExpenseRepository _repository;

  Future<List<Expense>> collectRows({DateTime? from, DateTime? to}) async {
    final all = <Expense>[];
    var offset = 0;
    while (true) {
      final page = await _repository.getExpenses(
        from: from,
        to: to,
        limit: pageSize,
        offset: offset,
      );
      all.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return all;
  }

  static String buildFileName(DateTime now) =>
      'chi_tieu_${DateFormat('yyyyMMdd_HHmm').format(now)}.csv';

  /// Ghi file vào thư mục tạm và trả đường dẫn.
  Future<String> exportFile({
    required List<Expense> rows,
    required Map<int, String> categoryNames,
    String? fileName,
  }) async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/${fileName ?? buildFileName(DateTime.now())}';
    final file = File(path);
    await file.writeAsString(
      CsvBuilder.buildCsv(expenses: rows, categoryNames: categoryNames),
      flush: true,
    );
    return file.path;
  }

  /// Trả về số dòng đã ghi; hữu ích cho thông báo sau khi xuất.
  Future<({String path, int rowCount})> exportAndShare({
    DateTime? from,
    DateTime? to,
    required Map<int, String> categoryNames,
  }) async {
    final rows = await collectRows(from: from, to: to);
    final path = await exportFile(rows: rows, categoryNames: categoryNames);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        subject: 'Bản sao kê Chi Tiêu',
        text: '${rows.length} khoản chi (${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}).',
      ),
    );

    return (path: path, rowCount: rows.length);
  }
}
```

Chỉ dùng ba field đã xác minh có thật: `files`, `subject`, `text` (`share_plus_platform_interface-7.2.0/lib/platform_interface/share_plus_platform.dart:149-156`). Không bịa thêm field. `XFile` và `ShareParams` đều được `share_plus` re-export (`share_plus-13.3.1/lib/share_plus.dart:10-16`) nên một import là đủ.

- [ ] **Step 4: Chạy test đến PASS**

Run: `flutter test test/unit/csv_export_service_test.dart`
Expected: PASS 5 test.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/data/repositories/csv_export_service.dart test/unit/csv_export_service_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: add paginated csv export service with share sheet"
```

---

### Task 10: Mục "Xuất CSV" trong màn Cài đặt

**Files:**
- Create: `lib/screens/settings/csv_export_sheet.dart`
- Modify: `lib/screens/settings/settings_screen.dart:109-153`
- Test: `test/widget/csv_export_sheet_test.dart` (create)

**Interfaces:**
- Consumes: `CsvExportService` (Task 9), `showPixelSheet`/`showPixelSnackBar`/`PixelButton`/`PixelSegmented` (Plan 2 Task 8), `categoryProvider`, `expenseProvider`, `authProvider`.
- Produces: `Future<void> showCsvExportSheet(BuildContext context)`; enum nội bộ `CsvRangeChoice { month, all, custom }`.

- [ ] **Step 1: Viết widget test**

Create `test/widget/csv_export_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/screens/settings/csv_export_sheet.dart';

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier()
    : super(
        CategoryState(
          categories: [
            Category(id: 1, name: 'Ăn uống', icon: 'forkKnife', isDefault: true),
          ],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryProvider.overrideWith((ref) => _FakeCategoryNotifier()),
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showCsvExportSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers three range choices and an export button', (tester) async {
    await openSheet(tester);
    expect(find.text('Xuất CSV (sao lưu)'), findsOneWidget);
    expect(find.text('THÁNG NÀY'), findsOneWidget);
    expect(find.text('TOÀN BỘ'), findsOneWidget);
    expect(find.text('TỰ CHỌN'), findsOneWidget);
    expect(find.text('Xuất và chia sẻ'), findsOneWidget);
  });

  testWidgets('opens with a default range label even when signed out', (
    tester,
  ) async {
    await openSheet(tester);
    // Sheet không được crash khi authState.user == null và phải hiện khoảng
    // ngày mặc định (Tháng này) dưới dạng "A – B".
    expect(find.textContaining('–'), findsOneWidget);
    expect(find.text('Xuất và chia sẻ'), findsOneWidget);
  });
}

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  _FakeAuthNotifier() : super(const AppAuthState(isConfigured: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

`Category` có constructor không phải `const` (đã xác minh `lib/data/models/category.dart:7-13`) nên list danh mục không được bọc `const`.

Test cuối chỉ chốt rằng sheet mở được với auth chưa đăng nhập (không crash, hiện khoảng ngày mặc định); hành vi gọi `share_plus` không test được trong widget test vì cần plugin — Step 6 giao phần đó cho xác minh thủ công.

- [ ] **Step 2: Chạy test — FAIL vì thiếu file**

Run: `flutter test test/widget/csv_export_sheet_test.dart`
Expected: FAIL — thiếu `csv_export_sheet.dart`.

- [ ] **Step 3: Viết sheet**

Create `lib/screens/settings/csv_export_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/csv_export_service.dart';
import '../../providers/category_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_segmented.dart';
import '../../widgets/pixel/pixel_sheet.dart';
import '../../widgets/pixel/pixel_snackbar.dart';

enum CsvRangeChoice { month, all, custom }

class CsvExportSheet extends ConsumerStatefulWidget {
  const CsvExportSheet({super.key, this.service});

  final CsvExportService? service;

  @override
  ConsumerState<CsvExportSheet> createState() => _CsvExportSheetState();
}

class _CsvExportSheetState extends ConsumerState<CsvExportSheet> {
  CsvRangeChoice _choice = CsvRangeChoice.month;
  DateTimeRange? _customRange;
  bool _busy = false;

  ({DateTime from, DateTime to}) _resolveRange() {
    final now = DateTime.now();
    return switch (_choice) {
      CsvRangeChoice.month => (
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 1),
      ),
      CsvRangeChoice.custom => (
        from: _customRange?.start ?? DateTime(now.year, now.month, 1),
        to: _customRange?.end ?? now,
      ),
      CsvRangeChoice.all => (
        from: DateTime(now.year - 10, now.month, now.day),
        to: now,
      ),
    };
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10, now.month, now.day),
      lastDate: now,
      initialDateRange: _customRange,
    );
    if (picked != null) setState(() => _customRange = picked);
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final categories = ref.read(categoryProvider).categories;
      final names = <int, String>{
        for (final category in categories)
          if (category.id != null) category.id!: category.name,
      };
      final range = _resolveRange();
      final service = widget.service ?? CsvExportService();
      final result = await service.exportAndShare(
        from: range.from,
        to: range.to,
        categoryNames: names,
      );

      if (!mounted) return;
      if (result.rowCount == 0) {
        showPixelSnackBar(
          context,
          'Không có khoản chi nào trong khoảng này.',
          tone: PixelTone.info,
        );
      } else {
        Navigator.of(context).pop();
        showPixelSnackBar(
          context,
          'Đã xuất ${result.rowCount} khoản chi. Chọn nơi lưu trong hộp chia sẻ.',
          tone: PixelTone.success,
        );
      }
    } catch (error) {
      if (!mounted) return;
      showPixelSnackBar(
        context,
        'Không thể xuất CSV. Kiểm tra mạng và thử lại.',
        tone: PixelTone.danger,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final range = _resolveRange();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tải bản sao lưu toàn bộ khoản chi. Ảnh không kèm theo, chỉ ghi đường dẫn.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          PixelSegmented<CsvRangeChoice>(
            items: const [
              PixelSegmentItem(value: CsvRangeChoice.month, label: 'THÁNG NÀY'),
              PixelSegmentItem(value: CsvRangeChoice.all, label: 'TOÀN BỘ'),
              PixelSegmentItem(value: CsvRangeChoice.custom, label: 'TỰ CHỌN'),
            ],
            selected: _choice,
            onChanged: (value) => setState(() => _choice = value),
          ),
          const SizedBox(height: 12),
          if (_choice == CsvRangeChoice.custom)
            PixelButton(
              label: _customRange == null
                  ? 'Chọn khoảng thời gian'
                  : '${DateFormatter.formatDate(_customRange!.start)} – '
                        '${DateFormatter.formatDate(_customRange!.end)}',
              icon: 'calendar',
              variant: PixelButtonVariant.secondary,
              expanded: true,
              onPressed: _pickCustomRange,
            )
          else
            Text(
              '${DateFormatter.formatDate(range.from)} – ${DateFormatter.formatDate(range.to)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 16),
          PixelButton(
            label: 'Xuất và chia sẻ',
            isLoading: _busy,
            onPressed: _busy ? null : _export,
          ),
        ],
      ),
    );
  }
}

Future<void> showCsvExportSheet(BuildContext context) async {
  await showPixelSheet<void>(
    context: context,
    title: 'Xuất CSV (sao lưu)',
    builder: (_) => const CsvExportSheet(),
  );
}
```

`PixelButton` lấy nguyên văn từ Plan 2 Task 7 (`label`, `icon` là key glyph, `variant`, `expanded`, `onPressed`) — nút chọn khoảng ngày dùng `icon: 'calendar'` thay cho `Icons.calendar_today_rounded` vì Plan 4 Task 14 cấm `Icons.` trong `lib/`. `PixelSegmented<T>` và `PixelSegmentItem<T>` lấy nguyên văn từ Plan 2 Task 8 (`items`, `selected`, `onChanged`; `PixelSegmentItem({required value, required label, glyph?})` là class `const`); `showPixelSheet` tự render `title` nên body của sheet không lặp lại tiêu đề.

- [ ] **Step 4: Thêm mục vào `SettingsScreen`**

Trong `Card` "Preferences & Features", chèn `ListTile` mới sau mục "Quản lý danh mục" (`:136`) và trước divider của "Thùng rác":

```dart
                ListTile(
                  title: const Text('Xuất CSV (sao lưu)'),
                  leading: const AppIcon(name: 'download', size: 32),
                  trailing: const AppIcon(name: 'chevronRight', size: 16),
                  onTap: () => showCsvExportSheet(context),
                ),
                const Divider(height: 1),
```

Thêm `import 'csv_export_sheet.dart';` và `import '../../widgets/pixel/app_icon.dart';` (`AppIcon` **và** `PixelIconButton` cùng sống trong `app_icon.dart` — Plan 2 Task 5). Plan 4 Task 13 viết lại toàn bộ body `SettingsScreen` bằng `PixelTile`, nên `ListTile` ở bước này là trạng thái trung gian có chủ đích; giữ đúng nhãn `'Xuất CSV (sao lưu)'` vì Plan 4 test nó.

- [ ] **Step 5: Chạy test + analyze**

Run: `flutter test test/widget/csv_export_sheet_test.dart && flutter test test/widget/screens_test.dart && flutter analyze`
Expected: PASS / `No issues found!`. Nếu `screens_test.dart` fail vì đếm `ListTile`/text thay đổi, cập nhật assertion **có ghi chú lý do** (thêm mục mới là hành vi chủ đích).

- [ ] **Step 6: Xác minh thủ công (bắt buộc ghi kết quả)**

Cần thiết bị Android thật, không làm được trong môi trường này:
1. Đăng nhập, mở **Cài đặt → Xuất CSV (sao lưu) → Tháng này → Xuất và chia sẻ**.
2. Chọn "Lưu vào Tệp"/Drive, mở file bằng một app bảng tính, kiểm tra: dấu tiếng Việt hiển thị đúng (BOM hoạt động), dòng có dấu phẩy trong ghi chú vẫn nằm trong một ô, số cột khớp header.
3. Kiểm tra cùng thao tác với "Toàn bộ" khi có > 1000 khoản chi (chưa có dữ liệu thì ghi rõ "chưa kiểm chứng phân trang trên thiết bị").

- [ ] **Step 7: Commit (chỉ khi được ủy quyền)**

```bash
git add lib/screens/settings/csv_export_sheet.dart lib/screens/settings/settings_screen.dart test/widget/csv_export_sheet_test.dart
git commit -m "feat: add csv export entry in settings"
```

---

### Task 11: Build xanh, tài liệu và bàn giao

**Files:**
- Modify: `README.md`, `docs/requirements.md`

**Interfaces:**
- Consumes: toàn bộ Task 1-10.
- Produces: tài liệu FR-24..FR-27 và mục xác minh thủ công còn mở.

- [ ] **Step 1: Chạy bộ kiểm tra đầy đủ**

```bash
export PATH="$PATH:/c/flutter/bin"
flutter analyze
flutter test
flutter test --coverage
```

Expected: `No issues found!`; tất cả test PASS. Ghi lại **số test thật** từ dòng `All tests passed!`/`X tests passed`.

Run: `flutter build apk --debug`
Expected: `√ Built build\app\outputs\flutter-apk\app-debug.apk`. Nếu fail vì `share_plus` cần AGP/minSdk, dán nguyên văn lỗi và dừng — không tự hạ phiên bản package.

- [ ] **Step 2: Cập nhật `docs/requirements.md`**

Thêm 4 dòng vào bảng FR (tiếp sau FR-20/FR-23 do Plan 1 thêm):

```markdown
| FR-24 | Ô nhập tiền tự chèn dấu chấm nhóm nghìn, chặn ký tự lạ, tối đa 12 chữ số; toàn bộ chỗ đọc số dùng `CurrencyFormatter.parseInput`. | Đã có |
| FR-25 | Khoản chi chọn được ngày giờ, không nhận tương lai và không quá 10 năm, có nút "Bây giờ". | Đã có |
| FR-26 | Quên mật khẩu qua email (PKCE + deep link), màn đặt lại mật khẩu trong app, thông báo trung tính. | Đã có, cần xác minh trên thiết bị |
| FR-27 | Xuất CSV có BOM UTF-8, phân trang 1000 dòng, chia sẻ qua share sheet hệ thống. | Đã có, cần xác minh trên thiết bị |
```

- [ ] **Step 3: Cập nhật `README.md`**

Thêm mục:

```markdown
## Sao lưu & khôi phục dữ liệu

- **Xuất CSV**: Cài đặt → Xuất CSV (sao lưu). File `chi_tieu_YYYYMMDD_HHmm.csv` mở bằng Excel/LibreOffice/Google Sheets; cột `ảnh` ghi đường dẫn trong bucket `expense-receipts`, không chứa ảnh nhúng.
- **Khôi phục ảnh**: muốn mang ảnh theo sang project Supabase khác phải tải riêng từng object qua Storage API; CSV không tự tải ảnh.
- **Nhập lại CSV**: chưa hỗ trợ. CSV là bản sao lưu để đọc và để nhập tay vào công cụ khác.
```

- [ ] **Step 4: Chốt lại những gì chưa ai kiểm chứng**

Viết vào cuối README (hoặc `docs/verification.md` nếu đã tồn tại) — trung thực, không tuyên bố chung:

```markdown
## Chưa xác minh trong môi trường phát triển này

- Nhận email đặt lại mật khẩu và deep link mở lại app (cần thiết bị + hộp thư thật).
- `updateUser(password:)` có bị Supabase đòi reauthentication hay không, tùy cấu hình project.
- Share sheet trên Android và cách từng app xử lý file `.csv` (cần thiết bị).
- Hiệu năng phân trang CSV khi > 5000 khoản chi (cần dữ liệu thật).
```

Run: `flutter test && flutter analyze`
Expected: PASS / `No issues found!` (chạy lại lần cuối để chắc Step 2-3 không phá gì.)

- [ ] **Step 5: Commit (chỉ khi được ủy quyền)**

```bash
git add README.md docs/requirements.md
git commit -m "docs: describe csv export, password recovery and unverified flows"
```

---

## Chốt chặn cuối plan

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → toàn bộ PASS, số test **tăng** so với trước khi bắt đầu plan; ghi con số vào báo cáo.
- [ ] `flutter build apk --debug` → `√ Built` (hoặc dán lỗi thật, không ẩn).
- [ ] `grep -rn "double.tryParse\|replaceAll(',', '')" lib/screens/` → rỗng.
- [ ] `grep -rn "TextInputType.number" lib/screens/ | wc -l` → `5`, mỗi nơi kèm `inputFormatters`.
- [ ] `grep -rn "recoveryMode" lib/` → xuất hiện trong state, provider, app gate.
- [ ] `grep -rn "service_role\|SUPABASE_ANON_KEY" lib/ .github/ docs/superpowers/plans/2026-11-01-chi-tieu-features.md` → rỗng (kế hoạch này không nhúng key).
- [ ] Không còn `AppColors` trong 4 file mới tạo (`amount_input_formatter.dart`, `expense_datetime_field.dart`, `forgot_password_sheet.dart`, `reset_password_screen.dart`, `csv_export_sheet.dart`) — `grep -n "AppColors" <các file>` trả rỗng.
- [ ] FR-24..FR-27 có trong `docs/requirements.md`, mục "Chưa xác minh" có trong README.
