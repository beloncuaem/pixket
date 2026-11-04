# Web Platform Boundary (Plan 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Làm app Pixket chạy đúng trong trình duyệt bằng cách nhốt mọi code chỉ-chạy-trên-mobile vào các seam `*_io.dart`, và đổi đơn vị ảnh từ đường dẫn tệp sang `Uint8List`.

**Architecture:** Mỗi capability (cắt vuông, draft, camera, lưu gallery, render ảnh, notification) là một nhóm 4 file `x.dart` (conditional export) + `x_io.dart` + `x_web.dart` + `x_stub.dart`. Code chung chỉ nói chuyện với nhau bằng bytes và handle chuỗi mờ. Một boundary test quét `lib/` giữ cho cấu trúc đó không bị phá hồi quy.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13.5, `dart:js_interop`, `package:web` 1.1.1, `image` 4.12.0, Supabase storage, Riverpod 2.6.1, `flutter_test` (VM + `--platform chrome`).

**Spec:** `docs/superpowers/specs/2026-11-04-web-platform-boundary-design.md` (plan này là arguments của spec đó). Spec cha: `docs/superpowers/specs/2026-11-04-pwa-design.md` — mục 3, 5, 5.1, 7, 12 là quyết định đã chốt.

## Global Constraints

- Flutter không nằm trên PATH: mọi lệnh dùng `/c/flutter/bin/flutter` (máy này, Git Bash).
- `flutter analyze` và `flutter test` phải xanh ở **mọi commit**. Baseline trước khi bắt đầu: **405 pass / 7 skip / 0 fail**, 59 file `*_test.dart`, trên `main` = `0eb211e` (sau commit spec Plan 2; code y hệt `01dd660`).
- Không nâng/hạ package nào. Ngoại lệ duy nhất được phép thêm: `web: ^1.1.1` (đã có trong `pubspec.lock` như một transitive của Flutter SDK).
- Không gỡ `sqflite`, không nâng `flutter_local_notifications` 18 → 22, không đụng `flutter_secure_storage`, không sửa `supabase_setup.sql` / schema / RLS.
- Doc comment và chuỗi hiển thị cho người dùng bằng tiếng Việt, theo giọng hiện có của repo. Không đổi bất kỳ chuỗi tiếng Việt nào đã tồn tại — `notification_service.dart:50-51` và `save_to_gallery.dart:24-33` phải giữ nguyên văn.
- Ranh giới nghiệm thu: `dart:io`, `package:flutter_cache_manager`, `package:cached_network_image`, `package:gal`, `package:camera`, `package:flutter_local_notifications` chỉ được phép xuất hiện trong file có tên kết thúc `_io.dart` dưới `lib/`.
- `kIsWeb` được phép ở code chung (guard runtime); nó không bị rule nào chạm tới.
- Build web phải compile sạch ở **mọi commit** (`flutter build web` exit 0) — kể cả khi Task 0 đã chỉ ra rằng compile không chứng minh được hành vi, nó vẫn là điều kiện cần.
- Làm việc trên branch trong worktree `.worktrees/web-boundary`, một commit mỗi bước được đánh số. **Không push, không merge, không tạo PR** — đó là quyết định của chủ dự án.
- `flutter pub get` làm bẩn `windows/flutter/` (CRLF): trước khi `git add`, chạy `git checkout -- windows/flutter/` nếu `git status` liệt kê các file đó.
- Không dán signed URL có token, không dán nội dung `.env` vào audit report hay commit message.

---

## File structure

```
lib/core/utils/
  square_image.dart          // POST: conditional export + re-export core
  square_image_core.dart     // NEW: hằng số + isSquareImagePath + cropToSquareBytes (pure)
  square_image_io.dart       // NEW: squareBytes qua compute + writeSquareCopy (tạm trú, xóa ở Task 2)
  square_image_web.dart      // NEW: createImageBitmap + OffscreenCanvas
  square_image_stub.dart     // NEW: nhánh mặc định, ném UnsupportedError
lib/core/platform/
  local_draft_store.dart     // conditional export
  local_draft_store_core.dart// abstract class LocalDraftStore
  local_draft_store_io.dart  // ghi tệp tạm
  local_draft_store_web.dart // Map<String, Uint8List> trong phiên
  local_draft_store_stub.dart
  photo_capture.dart / _core / _io / _web / _stub
  gallery_saver.dart / _io / _web / _stub
  receipt_notifier.dart / _core? _io / _web / _stub
  receipt_cache_image.dart / _io / _web / _stub   // ReceiptCacheImage + ReceiptLocalImage
  receipt_cache.dart / _io / _web / _stub         // clearReceiptCache + evictReceiptImage
test/unit/web_platform_boundary_test.dart         // NEW: ratchet allowlist
test/web/square_bytes_web_test.dart               // NEW: chạy với --platform chrome
test/web/local_draft_store_web_test.dart          // NEW: chạy với --platform chrome
```

`square_image.dart` giữ nguyên vị trí (theo spec cha mục 5) để `supabase_storage_service.dart` và các test hiện có không phải đổi import.

## Rulings taken while writing this plan

Các quyết định dưới đây không có trong spec; plan chọn một cách và ghi lý do để reviewer phản biện được.

1. **`ReceiptImageSource.localFile` đổi thành `localDraft`, không phải `localBytes`** (spec cha mục 7.4 gợi ý `localBytes`). Lý do: giá trị mang theo vẫn là `String?` handle, đặt tên `localBytes` cho một chuỗi sẽ mô tả sai kiểu. Widget nhận thêm tham số `Uint8List? localBytes` riêng.
2. **`ReceiptLocalImage` nằm chung nhóm seam với `ReceiptCacheImage`**, render `Image.file` trên `_io` khi không có bytes. Lý do: nếu bỏ hẳn nhánh tệp, các dòng `image_url` legacy là đường dẫn filesystem trên Android sẽ tụt xuống placeholder — vi phạm tiêu chí "Android không đổi hành vi".
3. **Draft trên IO ghi vào `Directory.systemTemp/pixket_drafts`**, không còn ghi cạnh tệp gốc. Lý do: `path_provider` đã bị gỡ ở Plan 1 nên không còn `getTemporaryDirectory()`; trên Android `Directory.systemTemp` chính là thư mục cache của app.
4. **`x_stub.dart` là điều kiện mặc định bắt buộc của conditional export**, implementation ném `UnsupportedError` với chuỗi tiếng Việt. Nó không chạy trên 4 nền tảng mục tiêu; nó tồn tại để `x.dart` có nhánh fallback và để một nền tảng chưa hỗ trợ thì thất bại loudly thay vì âm thầm.
5. **Web draft dùng handle `pixket-draft://<n>.jpg`, bytes giữ trong `Map`**, không dùng `URL.createObjectURL`. Lý do: không cần blob URL vì preview render từ bytes, và tránh phải revoke khi hết phiên.

---

## Task 0: Audit runtime — đo trước khi sửa

Không viết code. Đây là bước mà spec Plan 2 mục 5 yêu cầu làm trước, vì dart2js im lặng: thứ duy nhất cho biết web gãy ở đâu là chạy thật.

**Files:**
- Create: `docs/superpowers/audits/2026-11-04-web-runtime-audit.md`
- Create (scratch, không commit): `build/web` (đã có sau bước 1)

**Interfaces:**
- Consumes: không.
- Produces: bảng lỗi thật, dùng để xác nhận hoặc đảo thứ tự Task 2..6, và là bảng đối chiếu ở cuối Task 7.

- [ ] **Step 1: Build và serve**

```bash
cd .worktrees/web-boundary
/c/flutter/bin/flutter build web --debug   # kỳ vọng: exit 0, "√ Built build\web". BUỘC --debug:
                                           # bản release tắt debugPrint (main.dart:15-17) nên chuỗi
                                           # "Unsupported operation: ..." biến mất khỏi console
python -m http.server --directory build/web 3000   # chạy nền; 3000 là cổng Supabase OAuth callback
```

- [ ] **Step 2: Lượt 1 — chưa đăng nhập**

Mở `http://localhost:8080` bằng Chromium của Playwright MCP (máy này **không có Google Chrome**, chỉ có Edge ở `C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe`). Với mỗi màn, ghi lại **toàn bộ console message** (`list_console_messages`) và chụp màn hình (`take_screenshot`):

1. App boot: màn onboarding hiện ra chưa, font pixel có load không.
2. Bấm "đã có tài khoản" → màn login.
3. Nhập email sai → bấm đăng nhập.
4. Bấm "Tiếp tục với Google".
5. Mở lại trang với `localStorage` đã có phiên (giả sử đã đăng nhập) → màn hình chính.

- [ ] **Step 3: Lượt 2 — có đăng nhập thật**

Nhờ chủ dự án đăng nhập một lần (~15 phút) trên trình duyệt đó, rồi đi qua từng mục và ghi console + screenshot: feed, chụp/chọn ảnh, form khoản chi, lưu, sửa, xóa, vĩnh viễn xóa, danh mục, mức độ, ngân sách, thống kê, cài đặt, thùng rác, nút tải ảnh, chuyển dark/light.

- [ ] **Step 4: Viết báo cáo**

Mỗi lỗi một dòng, đúng mẫu này (chuỗi lỗi ghi **nguyên văn**, không paraphrase):

```markdown
| Màn / hành động | Chuỗi lỗi nguyên văn | Nguyên nhân dự đoán | Mức | Plan |
|---|---|---|---|---|
| Feed, ảnh đã upload | `MissingPluginException(...flutter_cache_manager...)` | `pixel_receipt_image.dart:160` | Chặn luồng | Task 5 |
```

Mức = `Chặn luồng` (không đi tiếp được) / `Sẹt góc` (một tính năng hỏng) / `Mỹ thuật` (log gây nhiễu). Ở cuối file ghi lại: phiên bản flutter, commit đang audit, danh sách màn đã đi qua, và những màn **chưa** đi qua kèm lý do.

- [ ] **Step 5: Không sửa code, và không tự mở rộng phạm vi**

Nếu audit lộ ra chỗ gãy ngoài 6 seam đã định, thêm dòng vào báo cáo với `Plan = NGOÀI PHẠM VI + mô tả` và báo cho chủ dự án ở cuối task; không tự ý viết task mới trong plan này.

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/audits/2026-11-04-web-runtime-audit.md
git commit -m "docs: audit runtime ban dau cua ban web"
```

---

## Task 1: Boundary test có allowlist thắt dần

Test này là chốt chống hồi quy **duy nhất** chạy tự động cho cấu trúc platform (vì compiler im lặng). Nó phải xanh ngay từ đầu, nên nó mang theo allowlist của hiện tại; mỗi task sau xóa bớt một dòng, và Task 7 xóa sạch.

**Files:**
- Create: `test/unit/web_platform_boundary_test.dart`

**Interfaces:**
- Consumes: không.
- Produces: ba hằng số allowlist (`_ioOnlyImports`, `_cacheManagerFiles`, `_pluginFiles`) mà Task 2..7 phải thu hẹp, và luật R1–R3 mà mọi task sau phải tuân.

- [ ] **Step 1: Viết test**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Build web compile sạch kể cả khi có `dart:io` (dart2js stub), nên thứ duy
/// nhất giữ cho app không crash trên trình duyệt là test cấu trúc này.
///
/// Allowlist là cơ chế thắt dần: nó khai những chỗ còn nợ. Một tệp đã được bọc
/// mà vẫn nằm trong allowlist cũng làm test đỏ, để không ai nợ thay cho không.
void main() {
  List<String> libFiles() => Directory('lib')
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => p.endsWith('.dart'))
      .toList();

  List<String> importing(List<String> files, List<String> needles) => [
    for (final path in files)
      if (needles.any((n) => File(path).readAsStringSync().contains(n))) path,
  ];

  void expectBoundary({
    required List<String> found,
    required Set<String> allowed,
    required String rule,
  }) {
    final violations = found
        .where((p) => !p.endsWith('_io.dart') && !allowed.contains(p))
        .toList();
    expect(violations, isEmpty, reason: '$rule: còn file chung chạm boundary ($violations).');
    final stale = allowed.where((p) => !found.contains(p)).toList();
    expect(stale, isEmpty, reason: '$rule: allowlist cũ, xóa $stale khỏi danh sách nợ.');
  }

  final files = libFiles();

  test('R1: dart:io chỉ trong *_io.dart', () {
    expectBoundary(
      found: importing(files, ["import 'dart:io'"]),
      allowed: {
        'lib/core/utils/save_to_gallery.dart',
        'lib/core/utils/square_image.dart',
        'lib/data/repositories/expense_repository.dart',
        'lib/data/repositories/supabase_storage_service.dart',
        'lib/providers/expense_provider.dart',
        'lib/screens/camera/camera_screen.dart',
        'lib/screens/camera/expense_form_sheet.dart',
        'lib/widgets/pixel/pixel_receipt_image.dart',
      },
      rule: 'R1',
    );
  });

  test('R2: flutter_cache_manager và cached_network_image chỉ trong *_io.dart', () {
    expectBoundary(
      found: importing(files, [
        "package:flutter_cache_manager",
        "package:cached_network_image",
      ]),
      allowed: {
        'lib/app.dart',
        'lib/providers/expense_provider.dart',
        'lib/widgets/pixel/pixel_receipt_image.dart',
      },
      rule: 'R2',
    );
  });

  test('R3: gal, camera, flutter_local_notifications chỉ trong *_io.dart', () {
    expectBoundary(
      found: importing(files, [
        "package:gal/gal.dart",
        "package:camera/camera.dart",
        "package:flutter_local_notifications",
      ]),
      allowed: {
        'lib/core/services/notification_service.dart',
        'lib/core/utils/save_to_gallery.dart',
        'lib/screens/camera/camera_screen.dart',
      },
      rule: 'R3',
    );
  });
}
```

- [ ] **Step 2: Chạy test**

Run: `/c/flutter/bin/flutter test test/unit/web_platform_boundary_test.dart`
Expected: `+3: All tests passed!` — đỏ ở bước này nghĩa là một trong các đường dẫn allowlist sai, hãy sửa đường dẫn cho khớp `grep -rln "dart:io" lib`, **không** sửa nghiệp vụ.

- [ ] **Step 3: Chạy toàn bộ suite để chắc không đụng**

Run: `/c/flutter/bin/flutter test`
Expected: `408 pass / 7 skip / 0 fail` (405 baseline + 3 test mới).

- [ ] **Step 4: Commit**

```bash
git add test/unit/web_platform_boundary_test.dart
git commit -m "test: boundary test cho ranhx giới dart:io va plugin"
```

---

## Task 2: Bytes pipeline — `squareBytes` + `LocalDraftStore` + upload nhận bytes

Đây là task lớn nhất và là chỗ duy nhất đổi chữ ký công khai. Sau nó, `lib/` **không còn file nào ngoài
`_io.dart` import `dart:io` — trừ đúng một file `lib/widgets/pixel/pixel_receipt_image.dart`**
*(Ruling A: file này thuộc seam render của Task 5, nên allowlist R1 chỉ rỗng ở Task 5, không phải ở
đây)*, và mọi ảnh đi trong app là `Uint8List` + handle chuỗi mờ. `flutter build web` vẫn sạch và
`writeSquareCopy` biến mất.

**Files:**
- Modify: `pubspec.yaml` (thêm `web: ^1.1.1` vào `dependencies`)
- Create: `lib/core/utils/square_image_core.dart`, `square_image_io.dart`, `square_image_web.dart`, `square_image_stub.dart`
- Modify: `lib/core/utils/square_image.dart` (còn 2 dòng export)
- Create: `lib/core/platform/local_draft_store.dart`, `_core.dart`, `_io.dart`, `_web.dart`, `_stub.dart`
- Modify: `lib/core/utils/save_to_gallery.dart` (`File(path)` → store), `lib/data/repositories/supabase_storage_service.dart:20-55`, `lib/data/repositories/expense_repository.dart:54-72`, `lib/providers/expense_provider.dart:192`, `lib/screens/camera/camera_screen.dart:155-187`, `lib/screens/camera/expense_form_sheet.dart:114-135,168-181`
- Test: `test/unit/square_image_test.dart`, `test/unit/expense_repository_write_test.dart:277-289`, `test/unit/save_to_gallery_test.dart:45-47`, `test/widget/expense_form_pixel_test.dart`, `test/web/square_bytes_web_test.dart`, `test/web/local_draft_store_web_test.dart`
- Modify: `test/unit/web_platform_boundary_test.dart` (allowlist R1 → `const {'lib/widgets/pixel/pixel_receipt_image.dart'}`)

**Interfaces:**
- Consumes: Task 1 (giữ allowlist đỏ là fail).
- Produces:
  - `Future<Uint8List?> squareBytes(Uint8List source)` — null khi không giải mã được; `squareImageSide`/`squareImageQuality`/`squareImageSuffix`/`isSquareImagePath`/`cropToSquareBytes` giữ nguyên chữ ký và vị trí import (`package:pixket/core/utils/square_image.dart`).
  - `abstract class LocalDraftStore` với `Future<String> save(Uint8List bytes, {required String extension, required bool squared})`, `Future<Uint8List?> readBytes(String handle)`, `Future<bool> exists(String handle)`, `Future<void> delete(String handle)`; global `LocalDraftStore localDraftStore`.
  - `Future<String> SupabaseStorageService.uploadReceiptImage(Uint8List bytes, {required String extension, required bool squared})`.

- [ ] **Step 1: Thêm dependency web**

`pubspec.yaml`, dưới `gal: ^2.3.3`:

```yaml
  web: ^1.1.1
```

Run: `/c/flutter/bin/flutter pub get` → Expected: `Got dependencies!`. Run tiếp `git checkout -- windows/flutter/` rồi `git status --porcelain` → Expected: không có file `windows/` nào còn modified.

- [ ] **Step 2: Tách lõi pure Dart của cắt vuông**

Tạo `lib/core/utils/square_image_core.dart` bằng cách **dời nguyên văn dòng 2-45 của `square_image.dart` hiện tại** (bỏ `import 'dart:io';` ở dòng 1, giữ `dart:math`, `dart:typed_data`, `package:image/image.dart as img`, và toàn bộ doc comment tiếng Việt). File này chứa: `squareImageSide`, `squareImageQuality`, `squareImageSuffix`, `isSquareImagePath`, `cropToSquareBytes`.

- [ ] **Step 3: Viết failing test cho `squareBytes`**

Trong `test/unit/square_image_test.dart`, thêm group (dùng helper `jpeg(w, h)` đã có ở đầu file):

```dart
  group('squareBytes (nền IO)', () {
    test('trả bytes vuông đúng cạnh squareImageSide cho ảnh to', () async {
      final out = await squareBytes(jpeg(2000, 1500));
      expect(out, isNotNull);
      final decoded = img.decodeImage(out!)!;
      expect(decoded.width, squareImageSide);
      expect(decoded.height, squareImageSide);
    });

    test('ảnh nhỏ hơn cạnh chuẩn vẫn vuông, không phóng lên', () async {
      final out = await squareBytes(jpeg(300, 200));
      final decoded = img.decodeImage(out!)!;
      expect(decoded.width, 200);
      expect(decoded.height, 200);
    });

    test('bytes rác trả null để caller giữ ảnh gốc', () async {
      expect(await squareBytes(Uint8List.fromList([1, 2, 3, 4])), isNull);
    });

    test('squareBytes cho kết quả giống hệt cropToSquareBytes', () async {
      final source = jpeg(1800, 1200);
      expect(await squareBytes(source), equals(cropToSquareBytes(source)));
    });
  });
```

Run: `/c/flutter/bin/flutter test test/unit/square_image_test.dart`
Expected: FAIL — `squareBytes` chưa được định nghĩa (hoặc `Error: Not found: 'squareBytes'`).

- [ ] **Step 4: Viết ba implementation + export**

`lib/core/utils/square_image.dart` thay toàn bộ nội dung bằng:

```dart
export 'square_image_core.dart';
export 'square_image_stub.dart'
    if (dart.library.io) 'square_image_io.dart'
    if (dart.library.js_interop) 'square_image_web.dart';
```

`lib/core/utils/square_image_io.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;

import 'square_image_core.dart';

/// Cắt vuông trên mobile/desktop. Decode + encode mất ~1s với ảnh 12 MP nên chạy
/// trên isolate, nhờ animation của mống mắt sau khi chụp không bị giật.
Future<Uint8List?> squareBytes(Uint8List source) =>
    compute(cropToSquareBytes, source);
```

`lib/core/utils/square_image_stub.dart`:

```dart
import 'dart:typed_data';

/// Nhánh mặc định của conditional export — chỉ chạy trên nền tảng không có
/// `dart.library.io` lẫn `dart.library.js_interop`. Throwing loudly có chủ đích:
/// âm thầm trả nguyên trạng sẽ cho ra ảnh chữ nhật sai tỷ lệ.
Future<Uint8List?> squareBytes(Uint8List source) =>
    throw UnsupportedError('Pixket chưa có trình cắt ảnh vuông cho nền tảng này.');
```

`lib/core/utils/square_image_web.dart` — dùng đúng các identifier đã kiểm chứng trong `web-1.1.1` (`web.Blob`, `web.BlobPropertyBag`, `web.window.createImageBitmap` là thành viên của `Window` chứ không phải hàm top-level, `web.ImageBitmapOptions`, `web.OffscreenCanvas`, `web.OffscreenCanvasRenderingContext2D`, `web.ImageEncodeOptions`):

```dart
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'square_image_core.dart';

/// Cắt vuông bằng pipeline đồ họa gốc của trình duyệt: `createImageBitmap` với
/// `imageOrientation: 'from-image'` đọc EXIF và xoay ảnh hộ ta (tương đương
/// `img.bakeOrientation`), `OffscreenCanvas` cắt giữa, `convertToBlob` nén JPEG.
/// Không chạy trên isolate nào cả vì đây là code native của browser — mà trên
/// web `compute()` vốn chạy cùng thread, nên cách này mới không đơ UI.
Future<Uint8List?> squareBytes(Uint8List source) async {
  final blob = web.Blob(
    <JSAny>[source.toJS].toJS,
    web.BlobPropertyBag(type: 'image/jpeg'),
  );
  final bitmap = await web.window
      .createImageBitmap(
        blob,
        web.ImageBitmapOptions(imageOrientation: 'from-image'),
      )
      .toDart;

  final side = math.min(bitmap.width, bitmap.height);
  if (side <= 0) return null;

  final canvas = web.OffscreenCanvas(squareImageSide, squareImageSide);
  final context =
      canvas.getContext('2d') as web.OffscreenCanvasRenderingContext2D?;
  if (context == null) return null;
  context.drawImage(
    bitmap,
    (bitmap.width - side) ~/ 2,
    (bitmap.height - side) ~/ 2,
    side,
    side,
    0,
    0,
    squareImageSide,
    squareImageSide,
  );

  final encoded = await canvas
      .convertToBlob(
        web.ImageEncodeOptions(
          type: 'image/jpeg',
          quality: squareImageQuality / 100,
        ),
      )
      .toDart;
  final buffer = await encoded.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}
```

Nếu `flutter analyze` báo lỗi kiểu ở bất kỳ dòng nào trên, **đừng đoán**: đọc định nghĩa thật trong pub cache, ví dụ

```bash
grep -rn -B4 -A12 "extension type ImageBitmap\." ~/.local/... # đường dẫn máy này:
sed -n '12390,12430p' "/c/Users/ASUS/AppData/Local/Pub/Cache/hosted/pub.dev/web-1.1.1/lib/src/dom/html.dart"
```

- [ ] **Step 5: Chạy test cắt vuông**

Run: `/c/flutter/bin/flutter test test/unit/square_image_test.dart`
Expected: PASS, số test tăng thêm 4.

- [ ] **Step 6: Viết failing test cho draft store trên IO**

Tạo `test/unit/local_draft_store_test.dart`:

```dart
@Tags(['io'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/platform/local_draft_store.dart';
import 'package:pixket/core/platform/local_draft_store_io.dart';
import 'package:pixket/core/utils/square_image.dart';

Uint8List tinyJpeg() => Uint8List.fromList(<int>[
  // JPEG tối thiểu do package image sinh ra, dùng lại helper của test cắt vuông
  // không được ở đây vì file test không share fixture → tự sinh:
  0xFF, 0xD8, 0xFF, 0xD9,
]);

void main() {
  late Directory dir;
  late IoLocalDraftStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pixket_draft_test');
    store = IoLocalDraftStore(dir: dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('save rồi readBytes trả đúng bytes', () async {
    final bytes = tinyJpeg();
    final handle = await store.save(bytes, extension: 'jpg', squared: false);
    expect(await store.readBytes(handle), bytes);
    expect(await store.exists(handle), isTrue);
  });

  test('squared: true đặt marker squareImageSuffix vào handle', () async {
    final handle = await store.save(tinyJpeg(), extension: 'jpg', squared: true);
    expect(isSquareImagePath(handle), isTrue);
  });

  test('handle không tồn tại: exists false, readBytes null, delete không ném', () async {
    final ghost = '${dir.path}/pixket_khong_co.jpg';
    expect(await store.exists(ghost), isFalse);
    expect(await store.readBytes(ghost), isNull);
    await store.delete(ghost);
  });

  test('delete rồi thì không đọc được nữa', () async {
    final handle = await store.save(tinyJpeg(), extension: 'png', squared: false);
    await store.delete(handle);
    expect(await store.exists(handle), isFalse);
  });
}
```

Run: `/c/flutter/bin/flutter test test/unit/local_draft_store_test.dart`
Expected: FAIL — không tìm thấy `package:pixket/core/platform/local_draft_store_io.dart`.

- [ ] **Step 7: Viết draft store**

`lib/core/platform/local_draft_store_core.dart`:

```dart
import 'dart:typed_data';

/// Ảnh tạm giữa lúc chụp và lúc upload. `handle` là chuỗi mờ: trên mobile là
/// đường dẫn tệp, trên web là key trong bộ nhớ phiên. Code chung **không** được
/// giả định hình thức nào của nó ngoài `storagePathOf(handle) == null`.
abstract class LocalDraftStore {
  const LocalDraftStore();

  /// Ghi [bytes] và trả handle. `squared: true` để tên mang marker
  /// [squareImageSuffix] nhờ đó `isSquareImagePath` chặn việc cắt lần hai.
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  });

  /// null khi handle không còn trỏ tới tệp/blob nào (đã upload, đã xóa, hoặc
  /// handle legacy của máy khác).
  Future<Uint8List?> readBytes(String handle);

  Future<bool> exists(String handle);

  /// Không ném khi handle vắng mặt: gọi từ `dispose()` và từ luồng xóa ảnh.
  Future<void> delete(String handle);
}
```

`lib/core/platform/local_draft_store_io.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'local_draft_store_core.dart';

/// Draft giữ trên đĩa để người dùng chụp xong, tắt app trước khi upload vẫn còn
/// (spec cha mục 5.1.1). `path_provider` đã bị gỡ nên lấy `Directory.systemTemp`:
/// trên Android biến môi trường TMPDIR trỏ thẳng vào thư mục cache của app.
class IoLocalDraftStore extends LocalDraftStore {
  IoLocalDraftStore({Directory? dir}) : _dir = dir;

  final Directory? _dir;

  Directory get _root {
    final dir = _dir;
    if (dir != null) return dir;
    final root = Directory(
      '${Directory.systemTemp.path}/pixket_drafts',
    );
    if (!root.existsSync()) root.createSync(recursive: true);
    return root;
  }

  String _name(String extension, bool squared) =>
      'pixket_${DateTime.now().microsecondsSinceEpoch}'
      '${squared ? squareImageSuffix : '.$extension'}';

  @override
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  }) async {
    final file = File('${_root.path}/${_name(extension, squared)}');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<Uint8List?> readBytes(String handle) async {
    final file = File(handle);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> exists(String handle) => File(handle).exists();

  @override
  Future<void> delete(String handle) async {
    final file = File(handle);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Không làm mất luồng chính vì một tệp tạm không xóa được.
      }
    }
  }
}
```

(File này import `square_image.dart` để lấy `squareImageSuffix` — nhớ thêm `import '../utils/square_image.dart';`.)

`lib/core/platform/local_draft_store_web.dart`:

```dart
import 'dart:typed_data';

import '../utils/square_image.dart';
import 'local_draft_store_core.dart';

/// Draft web chỉ sống trong phiên: reload là mất, chấp nhận theo spec cha mục 13.
/// Không dùng blob URL vì preview render từ bytes, khỏi phải revoke.
class WebLocalDraftStore extends LocalDraftStore {
  final Map<String, Uint8List> _drafts = {};
  int _counter = 0;

  @override
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  }) async {
    final suffix = squared ? '_sq' : '';
    final handle = 'pixket-draft://${_counter++}$suffix.$extension';
    _drafts[handle] = bytes;
    return handle;
  }

  @override
  Future<Uint8List?> readBytes(String handle) async => _drafts[handle];

  @override
  Future<bool> exists(String handle) async => _drafts.containsKey(handle);

  @override
  Future<void> delete(String handle) async => _drafts.remove(handle);
}
```

`lib/core/platform/local_draft_store_stub.dart`:

```dart
import 'dart:typed_data';

import 'local_draft_store_core.dart';

LocalDraftStore localDraftStore = const _UnsupportedLocalDraftStore();

class _UnsupportedLocalDraftStore extends LocalDraftStore {
  const _UnsupportedLocalDraftStore();

  Never _fail() => throw UnsupportedError(
    'Pixket chưa lưu được ảnh tạm trên nền tảng này.',
  );

  @override
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  }) => _fail();

  @override
  Future<Uint8List?> readBytes(String handle) => _fail();

  @override
  Future<bool> exists(String handle) => _fail();

  @override
  Future<void> delete(String handle) => _fail();
}
```

`lib/core/platform/local_draft_store.dart`:

```dart
export 'local_draft_store_core.dart';
export 'local_draft_store_stub.dart'
    if (dart.library.io) 'local_draft_store_io.dart'
    if (dart.library.js_interop) 'local_draft_store_web.dart';
```

Ở cuối `local_draft_store_io.dart` và `local_draft_store_web.dart` thêm global để code chung dùng:

```dart
LocalDraftStore localDraftStore = IoLocalDraftStore();   // bản _io
LocalDraftStore localDraftStore = WebLocalDraftStore();  // bản _web
```

- [ ] **Step 8: Chạy test draft store**

Run: `/c/flutter/bin/flutter test test/unit/local_draft_store_test.dart`
Expected: PASS 4 test.

- [ ] **Step 9: `uploadReceiptImage` nhận bytes**

`lib/data/repositories/supabase_storage_service.dart`: bỏ `import 'dart:io';` (dòng 1), thay thân hàm `uploadReceiptImage` (dòng 20-55) bằng:

```dart
  /// Tải ảnh lên storage, trả về path dạng `<user_id>/<file>` (không trả URL).
  Future<String> uploadReceiptImage(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  }) async {
    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('Vui lòng đăng nhập để lưu ảnh lên Cloud.');
    }

    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
    // Marker `_sq` đi thẳng vào tên object để biết ảnh nào đã vuông mà không
    // cần thêm cột vào bảng expenses.
    final marker = squared ? '_sq' : '';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${bytes.length}$marker.$extension';
    final storagePath = '${user.id}/$fileName';

    await client.storage
        .from(bucketName)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return storagePath;
  }
```

`uploadSquareBytes` (dòng 58-77) giữ nguyên — nó là đường migrate ảnh legacy, không ai gọi từ UI.

- [ ] **Step 10: Sửa test repository cho chữ ký mới**

`test/unit/expense_repository_write_test.dart`: group `writeSquareCopy` (dòng 277-289) viết lại thành test qua draft store + `squareBytes`, vì `writeSquareCopy` sẽ bị xóa ở bước 12:

```dart
  test('draft đã vuông (_sq) được repository upload mà không cắt lại', () async {
    final store = IoLocalDraftStore(dir: tempDir);
    final handle = await store.save(
      jpegOf(1200, 1200),
      extension: 'jpg',
      squared: true,
    );
    expect(isSquareImagePath(handle), isTrue);

    final uploaded = await repository.saveExpense(
      expenseId: null,
      imageSource: handle,
      values: expenseValues,
    );
    expect(uploaded, isNotNull);
    expect(capturedUploadCalls.single.squared, isTrue);
  });
```

`jpegOf(w, h)` và `capturedUploadCalls` là helper/fake **đã có** trong file này (dòng 1-80) — đọc phần đầu file để lấy đúng tên fake storage đang dùng, và sửa fake đó cho khớp chữ ký mới ở bước 9 (tham số `bytes/extension/squared` thay vì `localFilePath`). Nếu fake đang `noSuchMethod` thì không phải sửa gì.

- [ ] **Step 11: `_resolveImage` đọc qua store**

`lib/data/repositories/expense_repository.dart`: bỏ `import 'dart:io';`, thay dòng 54-72 bằng:

```dart
  Future<({String? path, bool uploaded})> _resolveImage(String? source) async {
    final value = source?.trim();
    if (value == null || value.isEmpty) return (path: null, uploaded: false);

    final stored = storagePathOf(value);
    if (stored != null) return (path: stored, uploaded: false);

    final bytes = await localDraftStore.readBytes(value);
    if (bytes != null) {
      // Chốt chặn cuối cho tỉ lệ vuông: mọi đường ghi ảnh đều đi qua đây, kể cả
      // khi UI gửi lên một ảnh chưa cắt.
      final squared = isSquareImagePath(value)
          ? bytes
          : await squareBytes(bytes) ?? bytes;
      final extension = value.split('.').last.toLowerCase();
      return (
        path: await _storage.uploadReceiptImage(
          squared,
          extension: extension,
          squared: isSquareImagePath(value) || !identical(squared, bytes),
        ),
        uploaded: true,
      );
    }

    throw StateError('Không tìm thấy ảnh để tải lên Cloud.');
  }
```

(`identical(squared, bytes)` chỉ để biết `squareBytes` có thật sự cắt hay trả null; nếu thấy tối nghĩa thì thay bằng biến `final didSquare = !isSquare && await squareBytes(bytes) != null;` — reviewer sẽ chọn cách đọc gọn hơn.)

- [ ] **Step 12: Camera, form sheet, provider dùng handle + bytes; xóa `writeSquareCopy`**

`lib/screens/camera/camera_screen.dart`: bỏ `import 'dart:io';` và `import '../../core/utils/square_image.dart';` → `import '../../core/platform/local_draft_store.dart';` + `import '../../core/utils/square_image.dart';` (vẫn cần cho `squareBytes`). Thay khối 154-162:

```dart
      final picture = await _controller!.takePicture();
      if (!mounted) return;
      final bytes = await picture.readAsBytes();
      final squared = await squareBytes(bytes);
      final draft = await localDraftStore.save(
        squared ?? bytes,
        extension: 'jpg',
        squared: squared != null,
      );
      // Phi thuyền bay qua không chặn luồng: cắt ảnh xong là mở form ngay.
      PixelShipFlight.launch(context);
      if (mounted) _openExpenseForm(imagePath: draft);
```

Thay `_pickFromGallery` (dòng 171-187) bằng cùng hình dạng, dùng `await image.readAsBytes()` thay `File(image.path)`, extension lấy từ `image.path.split('.').last.toLowerCase()`.

`lib/screens/camera/expense_form_sheet.dart`: bỏ `import 'dart:io';`. Dòng 129-135 → `await localDraftStore.delete(sourceImagePath);`. `dispose()` (dòng 168-181) → `unawaited(localDraftStore.delete(draftPath));` (bỏ luôn `existsSync`, delete đã tự kiểm tra) và thêm `import 'dart:async';` nếu chưa có.

`lib/providers/expense_provider.dart`: dòng 189-195 → `await localDraftStore.delete(local);`, bỏ `import 'dart:io';`.

`lib/core/utils/save_to_gallery.dart`: dòng 51-57 → `return localDraftStore.readBytes(path);` (bỏ `File`, bỏ `exists` + `StateError('không tìm thấy $path')` — `_readBytes` trả null thì caller đã báo 'Khoản chi này chưa có ảnh để tải.'), bỏ `import 'dart:io';`.

`lib/core/utils/square_image_io.dart`: **xóa** `writeSquareCopy` (không cho vào `_io` như dự tính đầu — sau bước này không còn caller nào, và spec cha mục 7.1 ghi rõ nó bị xóa).

`test/unit/web_platform_boundary_test.dart`: allowlist R1 →
`const <String>{'lib/widgets/pixel/pixel_receipt_image.dart'}` *(Ruling A — file này là seam render,
Task 5 mới xóa được; comment trong test ghi rõ "owned by Task 5")*.

- [ ] **Step 13: Chạy toàn bộ**

Run: `/c/flutter/bin/flutter analyze`
Expected: `No issues found!`.
Run: `/c/flutter/bin/flutter test`
Expected: pass, 0 fail; số test so với Task 1 chỉ tăng không giảm.
Run: `/c/flutter/bin/flutter build web`
Expected: exit 0, `√ Built build\web`.

- [ ] **Step 14: Parity test cho bản web**

Tạo `test/web/square_bytes_web_test.dart`:

```dart
@Tags(['web'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pixket/core/utils/square_image.dart';

Uint8List jpegOf(int w, int h) =>
    img.encodeJpg(img.Image(width: w, height: h)..fill(color: img.ColorRgb8(200, 30, 30)));

void main() {
  test('web squareBytes cắt đúng cạnh và trả JPEG hợp lệ', () async {
    final out = await squareBytes(jpegOf(2000, 1500));
    expect(out, isNotNull);
    final decoded = img.decodeImage(out!)!;
    expect(decoded.width, squareImageSide);
    expect(decoded.height, squareImageSide);
  });

  test('web squareBytes trả null cho bytes rác', () async {
    expect(await squareBytes(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}
```

Chạy (xem Task 7 Step 2 về `CHROME_EXECUTABLE`):

```bash
CHROME_EXECUTABLE="C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
  /c/flutter/bin/flutter test --platform chrome test/web
```
Expected: PASS. Nếu runner từ chối Edge, ghi rõ vào `docs/superpowers/audits/` là parity chưa chạy qua runner và để ngỏ bước này cho Task 7 — **không** xóa test.

- [ ] **Step 15: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/utils lib/core/platform lib/data lib/providers lib/screens test
git commit -m "feat!: anh em pipeline anh go qua bytes va tach dart:io sau seam"
```

---

## Task 3: `PhotoCapture` — ống ngắm và chọn ảnh

`camera` không được import thẳng trong screen nữa; screen phải ngừng nhập plugin trực tiếp. Sau task
này allowlist R3 chỉ còn `save_to_gallery.dart` (gal) và `notification_service.dart`.

*(Sửa theo Lượt 1 audit — Ruling E:)* giả định "`camera` plugin không có web" trong bản plan đầu là
**sai**: `camera_web` có đăng ký plugin và ống ngắm chạy thật 1280x720 trên web. Nhưng `takePicture()`
**chưa đo**, và Lượt 1 còn đo được: khi browser chưa quyết quyền (`permission = 'prompt'`) thì bản web
**treo vĩnh viễn ở màn "Đang mở camera…"** — indicator đó là `camera_screen.dart:564`, và screen không
tự xin quyền (không có `permission_handler` trong file này), nên `getUserMedia` bị từ chối là không bao
giờ hết trạng thái khởi tạo. Vì vậy `_web.dart` vẫn giữ `image_picker` làm đường an toàn (không tự bật
ống ngắm, không xin quyền lúc mở screen, và phải có đường thoát khỏi trạng thái "Đang mở camera…");
`camera_web` chỉ được cân nhắc ở Plan 3, sau khi đo được `takePicture()` — **không** nới task này thành
"port camera_web".

**Files:**
- Create: `lib/core/platform/photo_capture.dart`, `_core.dart`, `_io.dart`, `_web.dart`, `_stub.dart`
- Modify: `lib/screens/camera/camera_screen.dart` (dòng 1-210 và phần build widget dùng `CameraPreview`)
- Modify: `test/unit/web_platform_boundary_test.dart`
- Test: `test/unit/photo_capture_test.dart`

**Interfaces:**
- Consumes: `squareBytes`, `localDraftStore` (Task 2).
- Produces:

```dart
/// Bắt mọi cách lấy ảnh hóa đơn: ống ngắm, chuyển camera, chọn từ thư viện.
abstract class PhotoCapture {
  Future<void> initialize();
  bool get isReady;
  String? get errorMessage;
  bool get supportsLiveViewfinder;
  bool get canSwitchCamera;      // Ruling: thay cho gate `_cameras.length > 1` cũ trong screen
  bool get isTakingPicture;      // Ruling M: screen phải đọc được TRƯỚC khi setState(_isCapturing)
  Future<void> useNextCamera();
  void dispose();                // seam global, không có thì camera bị chiếm sau khi thoát screen
  /// null khi người dùng hủy.
  Future<Uint8List?> capture();
  Future<({Uint8List bytes, String extension})?> pickFromGallery();
  Widget buildViewfinder(BuildContext context);   // Ruling L: `aspectRatio` đã xóa — framing vuông
                                                   // là bất biến của `squareBytes`, giữ tham số = API nói dối
}
PhotoCapture photoCapture = ...;  // per-platform global
```

Interface này là **thứ đã đo**, không phải dự tính: Task 3 giao `4fbef23` + `f711379`,
`flutter test` = 433 pass / 8 skip, R3 allowlist = `{save_to_gallery.dart, notification_service.dart}`.

- [ ] **Step 1: Test failing cho `_io`**

`test/unit/photo_capture_test.dart`:

```dart
@Tags(['io'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/platform/photo_capture.dart';

void main() {
  test('camera bản web không có ống ngắm sống, báo lỗi bằng tiếng Việt khi init thất bại', () async {
    final capture = photoCapture;
    await capture.initialize();
    expect(capture.supportsLiveViewfinder, isTrue);   // máy dev chạy nhánh IO
    expect(capture.isReady || capture.errorMessage != null, isTrue);
  });
}
```

Run: `/c/flutter/bin/flutter test test/unit/photo_capture_test.dart` → Expected: FAIL (không tìm thấy module).

- [ ] **Step 2: Viết 5 file seam**

`_core.dart`: abstract class ở trên. `_io.dart`: dời **nguyên văn** logic đang có trong `camera_screen.dart` (dòng 42-107: `_controller`, `_cameras`, `_isCameraInitialized`, `_isCameraInitializing`, `_hasCameraPermission`, `_selectedCameraIndex`, `_initializeCamera`, `_setupCameraController`, `dispose` của controller, `_switchCamera`, `CameraPreview`) vào `class CameraPluginPhotoCapture extends PhotoCapture`; `capture()` = `takePicture()` + `readAsBytes()`; `pickFromGallery()` = `_picker.pickImage(...)` (giữ `maxWidth: 1600, maxHeight: 1600, imageQuality: 80`) + `readAsBytes()`; `buildViewfinder()` trả đúng widget screen đang render (đọc phần `build` hiện tại để bê sang, không viết lại style). `_web.dart`: `supportsLiveViewfinder = false`, `isReady = false`, `capture()` = `pickFromGallery()` với `ImageSource.camera`, `buildViewfinder()` = `SizedBox.shrink()`. `_stub.dart`: mọi method ném `UnsupportedError('Pixket chưa chụp được ảnh trên nền tảng này.')`. `_core.dart` + `_web.dart` + `_stub.dart` không được import `package:camera`.

`photo_capture.dart`: conditional export 3 nhánh như Task 2.

- [ ] **Step 3: `camera_screen` chỉ dùng seam**

Xóa khỏi screen: `import 'package:camera/camera.dart';`, `import 'package:image_picker/image_picker.dart';`, `CameraController`, `availableCameras`, `ImagePicker`, `CameraPreview`. Screen giữ nguyên pixel UI, gọi `photoCapture.initialize()` trong `initState`, `photoCapture.buildViewfinder(context, aspectRatio: ...)`, `photoCapture.capture()` / `.pickFromGallery()`, và `photoCapture.useNextCamera()`. Khi `supportsLiveViewfinder == false` thì screen render một tấm card pixel hướng dẫn "Chọn ảnh từ thư viện" thay vùng ngắm (đọc palette qua `context.palette` như phần còn lại của screen).

`lib/screens/onboarding/onboarding_screen.dart:52`: bọc lại

```dart
    if (!kIsWeb) await Permission.camera.request();
```

kèm comment: trên web browser tự hỏi quyền lúc `<input capture>` mở, xin trước là thừa.

- [ ] **Step 4: Verify**

`/c/flutter/bin/flutter analyze` → sạch.
`/c/flutter/bin/flutter test` → pass.
`/c/flutter/bin/flutter test test/widget/expense_form_pixel_test.dart test/widget/feed_photo_test.dart` → pass (2 file này render các màn đụng ảnh).
`/c/flutter/bin/flutter build web` → exit 0.
Allowlist R3 → `{lib/core/utils/save_to_gallery.dart, lib/core/services/notification_service.dart}`, R1 vẫn `const {}`.

- [ ] **Step 5: Commit**

```bash
git add lib/core/platform lib/screens test
git commit -m "feat: tach ong ngam camera sau seam PhotoCapture"
```

---

## Task 4: `GallerySaver` — lưu ảnh về máy, và bỏ lỗi bị nuốt

**Files:**
- Create: `lib/core/platform/gallery_saver.dart`, `_io.dart`, `_web.dart`, `_stub.dart`
- Modify: `lib/core/utils/save_to_gallery.dart`, callers của `saveReceiptToGallery` — *(Ruling B, đã
  grep lại trên worktree `8868aee`: chỉ **một** caller trong `lib/` là
  `lib/screens/camera/feed_photo_page.dart:45`; bản plan đầu ghi nhầm `pixel_share_row.dart` — file đó
  không import `gal` và không gọi hàm này)*, `test/unit/save_to_gallery_test.dart`, allowlist R1/R3,
  `test/unit/web_platform_boundary_test.dart`

**Interfaces:**
- Consumes: `localDraftStore` (Task 2) cho nhánh đọc bytes.
- Produces:

```dart
abstract class GallerySaver {
  /// null khi thành công; ngược lại là thông báo tiếng Việt cho người dùng.
  Future<String?> saveImage(Uint8List bytes, {required String name});
  bool get isSupported;
}
GallerySaver gallerySaver = ...;
```

- [ ] **Step 1: Test failing — lỗi nền tảng phải nói thật**

Thêm vào `test/unit/save_to_gallery_test.dart` (file này đã có fake `http.Client`):

```dart
  test('nền tảng không lưu được ảnh thì nói đúng lý do, không nói chung chung', () async {
    final message = await saveReceiptToGallery(
      signedUrl: 'https://example.test/a.jpg',
      bytes: Uint8List.fromList([1, 2, 3]),
      name: 'a.jpg',
      client: _FakeClient(),
      saver: const _UnsupportedSaver(),
    );
    expect(message, 'Pixket không lưu được ảnh vào thư viện trên máy này.');
  });
```

với fake ở đầu file:

```dart
class _UnsupportedSaver implements GallerySaver {
  const _UnsupportedSaver();
  @override
  bool get isSupported => false;
  @override
  Future<String?> saveImage(Uint8List bytes, {required String name}) async =>
      'Pixket không lưu được ảnh vào thư viện trên máy này.';
}
```

Run: `/c/flutter/bin/flutter test test/unit/save_to_gallery_test.dart` → Expected: FAIL (tham số `bytes`/`saver` chưa tồn tại).

- [ ] **Step 2: Seam + chuyển `save_to_gallery.dart` sang bytes**

`gallery_saver_io.dart` dùng `Gal.putImageBytes`, giữ nguyên hai chuỗi tiếng Việt hiện có cho `GalException` (`save_to_gallery.dart:29-31`). `gallery_saver_web.dart`: tạo `web.URL.createObjectURL(web.Blob(...))` + `web.HTMLAnchorElement` `download` + click + `revokeObjectURL`, trả null khi thành công. `gallery_saver_stub.dart`: `isSupported = false`, `saveImage` trả chuỗi `'Pixket không lưu được ảnh vào thư viện trên máy này.'`.

`saveReceiptToGallery` chữ ký mới (`saver` tiêm để test không đụng plugin; `http.Client` đã tiêm sẵn theo tinh thần dòng 11-16):

```dart
Future<String?> saveReceiptToGallery({
  required String? signedUrl,
  required Uint8List? bytes,
  required String name,
  http.Client? client,
  GallerySaver? saver,
}) async
```

Bỏ `catch (_) { return 'Không lưu được ảnh về máy.'; }` (dòng 32-34) — thay bằng nhánh cụ thể cho `StateError` (signed URL trả non-200 / hết bytes) với chuỗi `'Không tải được ảnh từ Cloud.'`. Lý do bỏ: hiện trên web mọi lần bấm đều báo lỗi chung chung vì `MissingPluginException` bị nuốt (đã ghi ở spec Plan 2 mục 4.2).

`allowlist R3 → {lib/core/services/notification_service.dart}`; R1 vẫn rỗng.

- [ ] **Step 3: Verify + commit**

`/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test && /c/flutter/bin/flutter build web` → sạch / pass / exit 0.

```bash
git add lib/core/platform lib/core/utils lib/screens test
git commit -m "fix: luu anh ve may qua seam, bao dung ly do khi nen tang khong ho tro"
```

---

## Task 5: `ReceiptCacheImage` + `receipt_cache.dart` — render ảnh và eviction

**Files:**
- Create: `lib/core/platform/receipt_cache_image.dart`, `_io.dart`, `_web.dart`, `_stub.dart`, `receipt_cache.dart`, `_io.dart`, `_web.dart`, `_stub.dart`
- Modify: `lib/widgets/pixel/pixel_receipt_image.dart` (dòng 1-49 resolver, 144-190 render), `lib/app.dart:4,66-71`, `lib/providers/expense_provider.dart:4,187`, `test/widget/pixel_receipt_image_test.dart`, `test/unit/pixel_receipt_image_test.dart`, `test/widget/legacy_cleanup_test.dart:87-97`, allowlist **R1 và R2**
- Test mới: `test/widget/receipt_cache_image_test.dart`

**Interfaces:**
- Consumes: `localDraftStore` (Task 2).
- Produces:

```dart
class ReceiptCacheImage extends StatelessWidget {   // *_io / *_web, chữ ký giống hệt nhau
  const ReceiptCacheImage({
    required String url, String? cacheKey, double? width, double? height,
    BoxFit fit, Widget Function(BuildContext)? placeholder,
    Widget Function(BuildContext, Object)? errorBuilder, Key key,
  });
}
class ReceiptLocalImage extends StatelessWidget {
  const ReceiptLocalImage({String? handle, Uint8List? bytes, ...placeholder});
}
Future<void> clearReceiptCache();
Future<void> evictReceiptImage(String url, {String? cacheKey});
```

`ReceiptImageSource.localFile` → **`localDraft`**; `ReceiptImageTarget.localPath` → **`draftHandle`** (Ruling 1, 2 ở đầu plan). `PixelReceiptImage` nhận thêm `Uint8List? localBytes` và ưu tiên nó khi có.

- [ ] **Step 1: Test widget cho hai nhánh render**

`test/widget/receipt_cache_image_test.dart`:

```dart
  test('bytes được render trực tiếp, không cần tệp', () async {
    await tester.pumpWidget(
      MaterialApp(
        home: PixelReceiptImage(
          localBytes: tinyJpeg(),
          semanticLabel: 'Ảnh test',
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(receiptPlaceholder().runtimeType), findsNothing);
  });
```

(`tinyJpeg()` copy từ `test/unit/local_draft_store_test.dart` — test file không share fixture, nên mỗi file có bản riêng; nếu muốn gọn thì đặt vào `test/support/fixtures.dart` đã tồn tại trong repo.)

- [ ] **Step 2: Gate cũ trong `legacy_cleanup_test.dart` phải đổi nghĩa, không xóa**

Dòng 87-97: điều kiện loại trừ hiện chỉ tha cho `pixel_receipt_image.dart`. Sau task này `Image.file(` và `CachedNetworkImage(` hợp lệ trong `*_io.dart`, nên:

```dart
      final renderers = [
        for (final path in _filesContaining('Image.file('))
          if (!path.endsWith('_io.dart')) path,
        for (final path in _filesContaining('CachedNetworkImage('))
          if (!path.endsWith('_io.dart')) path,
      ];
```

- [ ] **Step 3: Implement, rồi verify**

`_io.dart`: `ReceiptCacheImage` = `CachedNetworkImage` y như `pixel_receipt_image.dart:160-177` hiện tại; `ReceiptLocalImage` = `Image.memory(bytes)` khi có bytes, `Image.file(File(handle))` khi chỉ có handle, `errorBuilder` → placeholder. `receipt_cache_io.dart`: `clearReceiptCache()` = `PaintingBinding.instance.imageCache..clear()..clearLiveImages(); await DefaultCacheManager().emptyCache();` (dời nguyên văn `app.dart:66-71`), `evictReceiptImage` = `CachedNetworkImage.evictFromCache` (dời từ `expense_provider.dart:187`). `_web.dart`: `ReceiptCacheImage` = `Image.network` với `loadingBuilder`/`errorBuilder` trả đúng placeholder hiện có; `ReceiptLocalImage` = bytes → `Image.memory`, không có bytes → placeholder; `clearReceiptCache`/`evictReceiptImage` chỉ đụng `imageCache`.

`app.dart`: bỏ `import 'package:flutter_cache_manager/flutter_cache_manager.dart';`, `_clearUserCaches()` gọi `clearReceiptCache()`. `expense_provider.dart`: bỏ import `cached_network_image`, dòng 187 → `await evictReceiptImage(url, cacheKey: storedPath);`.

Allowlist **R1 và R2** → `const <String>{}`. Đây là lúc R1 đóng lại:
`pixel_receipt_image.dart` không còn import `dart:io` vì nhánh render tệp đã dời sang
`receipt_cache_image_io.dart`.

Run: `/c/flutter/bin/flutter analyze` / `flutter test` / `flutter build web` → sạch / pass / exit 0.

- [ ] **Step 4: Audit lại nhanh bằng trình duyệt**

Chạy lại script Task 0 Step 1-2 trên bản build mới; nếu feed hiện ảnh signed URL đúng, cập nhật dòng tương ứng trong audit report sang `Đã sửa (Task 5)`.

```bash
git add lib/core/platform lib/widgets lib/app.dart lib/providers test docs
git commit -m "feat!: render anh hoa don qua seam, moi anh di qua ReceiptCacheImage"
```

---

## Task 6: `ReceiptNotifier` — cảnh báo ngân sách trên web

Bản web không crash, nó **im lặng** (spec Plan 2 mục 2), nên đây là thêm tính năng: Web Notifications API.

**Files:**
- Create: `lib/core/platform/receipt_notifier.dart`, `_core.dart`, `_io.dart`, `_web.dart`, `_stub.dart`
- Modify: `lib/core/services/notification_service.dart` (xóa, sau khi dời), `lib/main.dart:8,21`, `lib/providers/budget_provider.dart:168`, `lib/screens/onboarding/onboarding_screen.dart:53`, `test/unit/web_platform_boundary_test.dart`
- Test: `test/unit/receipt_notifier_test.dart`

**Interfaces:**
- Consumes: không (độc lập).
- Produces:

```dart
abstract class ReceiptNotifier {
  const ReceiptNotifier();
  Future<void> initialize();
  Future<void> requestPermission();
  Future<void> showBudgetAlert({required int threshold, required String monthLabel});
}
ReceiptNotifier receiptNotifier = ...;   // façade + `_core` giữ abstract, mỗi nhánh tự định nghĩa impl

// Chuỗi tiếng Việt đặt ở `_core` để hai nhánh không drift (như gallerySaveUnsupportedMessage):
const String budgetAlertTitle = 'Cảnh báo ngân sách';
String budgetAlertBody(int threshold, String monthLabel);

// Vòng ngưỡng tách khỏi notifier thành hàm top-level trong budget_provider.dart, tiêm
// repository để test không cần mạng (Ruling U — snippet `threshold:` trực tiếp không pin được
// vòng lặp mà Step 2 yêu cầu tách):
const List<int> budgetAlertThresholds = [80, 90, 100];
Future<void> notifyBudgetCrossing(
  ReceiptNotifier notifier, {
  required double usageRatio,                       // 0..1, chính là BudgetState.budgetUsagePercent
  required String monthLabel,
  required Future<bool> Function(int threshold) hasSent,
  required Future<void> Function(int threshold) markSent,
});
```

- [ ] **Step 1: `receipt_notifier_io.dart`** = dời nguyên văn `notification_service.dart` (giữ nguyên chuỗi `'Cảnh báo ngân sách'` và body `'Bạn đã sử dụng $threshold% ngân sách tháng $monthLabel.'`, giữ nguyên channel id/name `budget_alerts`/`Cảnh báo ngân sách`). `_web.dart`: `initialize()` là no-op (Notification là API có sẵn của browser); `requestPermission()` = `web.Notification.requestPermission().toDart`; `showBudgetAlert` = `web.Notification(budgetAlertTitle, web.NotificationOptions(body: budgetAlertBody(...)))`, chỉ chạy khi `web.Notification.permission == 'granted'`. `_stub.dart` ném `UnsupportedError('Pixket chưa gửi được cảnh báo trên nền tảng này.')`.
  *(Ruling V — bản này đã sửa hai chỗ không làm được như văn cũ:* `package:web` 1.1.1 **không** có `globalThis` (grep `globalThis` trong `web-1.1.1/lib` = 0 kết quả) nên phép thử `'Notification' in web.globalThis` không có binding để viết, và `JsObject` là API interop cũ. Thay bằng probe `web.Notification.permission` bọc try/catch: Safari chế độ riêng tư và non-secure context không có `Notification`, đụng vào là `TypeError`, nên "nền tảng thiếu API" phải thành *không báo được* chứ không thành lỗi lật màn ngân sách. *Ruling W:* `NotificationPermission` chỉ là `typedef = String` (`web-1.1.1/lib/src/dom/notifications.dart:25`) nên so sánh `== 'granted'` trực tiếp, dùng binding có sẵn của `package:web` cho khớp convention hai seam trước.)

- [ ] **Step 2: Test failing cho logic ngưỡng gọi seam**

`test/unit/receipt_notifier_test.dart`:

```dart
  test('vượt 92% thì báo đúng hai mốc 80 và 90, bỏ mốc 100', () async {
    expect(await _run(0.92), [(80, '11/2026'), (90, '11/2026')]);
  });
```

`_run(usageRatio, {alreadySent})` bọc nguyên vòng ngưỡng với `hasSent`/`markSent` giả; trong
`markSent` nó kiểm tra `notifier.calls.length == marked.length + 1`, tức **báo xong mới được đánh dấu** —
thứ tự đảo thì một lần báo lỗi sẽ nuốt mốc đó tới tận tháng sau. Bốn case còn lại khoá biên (đúng 80% vẫn
báo, 79% không báo), mốc đã gửi, và `budgetAlertTitle`/`budgetAlertBody` đúng từng ký tự so với bản cũ.

Đọc `budget_provider.dart:150-175` để lấy đúng hàm đang phát hiện vượt ngưỡng; nếu hiện nó nằm inline trong notifier thì tách ra thành `notifyBudgetCrossing(ReceiptNotifier notifier, {required int threshold, required String monthLabel})` trong `budget_provider.dart` và gọi nó từ chỗ cũ — test này không được bắt buộc dùng fake mạng.

- [ ] **Step 3: Wiring + verify + commit**

`main.dart:21` → `await receiptNotifier.initialize();`. `onboarding_screen.dart:53` → `await receiptNotifier.requestPermission();`, **không** bọc `if (!kIsWeb)` (Ruling T: browser không bao giờ tự hỏi quyền Notification, nên bỏ lời gọi này trên web là để cảnh báo ngân sách vĩnh viễn không bật — tự vứt tính năng Task 6 thêm vào. Spec cha mục 8 tự nó đã định `requestPermission()` → `Notification.requestPermission()`. Câu "bỏ qua cả hai lời gọi" ở spec Plan 2 mục 4.2 chỉ đúng cho camera và đã được sửa kèm lý do). `_finish()` chạy từ một nút bấm nên vẫn có user activation mà Chrome đòi. Xóa `lib/core/services/notification_service.dart` (và `lib/core/services/` khi đó rỗng, mất theo). Allowlist R3 → `const {}`.

```bash
/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test && /c/flutter/bin/flutter build web
git add lib test
git commit -m "feat: canh bao ngan sach qua seam, web dung Web Notifications"
```

---

## Task 7: Siết allowlist, CI build web, audit lại và chốt tài liệu

**Files:**
- Create: `.github/workflows/build-web.yml`, `dart_test.yaml` (khai báo tag `web`)
- Modify: `docs/superpowers/audits/2026-11-04-web-runtime-audit.md`, `docs/superpowers/specs/2026-11-04-web-platform-boundary-design.md` (bảng audit mục 5 → trạng thái thật)
- Modify: `test/unit/web_platform_boundary_test.dart` (mọi allowlist rỗng; needle R1 siết theo Step 1b)
- Modify: `analysis_options.yaml` (bật `prefer_single_quotes`), `dart format` toàn repo một lần (Step 1b)

**Interfaces:**
- Consumes: Task 2-6 xong.

- [ ] **Step 1: Allowlist rỗng**

Ba `allowed:` trong boundary test thành `const <String>{}`. Run `/c/flutter/bin/flutter test test/unit/web_platform_boundary_test.dart` → Expected: PASS (nếu còn đỏ thì một seam ở task trước chưa bọc xong — sửa task đó, không nới allowlist).

- [ ] **Step 1b: Siết chính needle của R1 (Ruling G, carry-over từ review Task 1)**

Review Task 1 đo được hai lỗ hổng *lý thuyết nhưng có thật* của needle: `import "dart:io";`
(nháy kép) và `export 'dart:io';` **không** bị bắt vì test chỉ `.contains("import 'dart:io'")`.
Không bắt buộc Task 2-6 phải né hai dạng đó, nên đóng ở đây:

```dart
      found: importing(files, [
        "import 'dart:io'",
        'import "dart:io"',
        "export 'dart:io'",
        'export "dart:io"',
      ]),
```

Ranh giới an toàn: sau khi siết, `found` phải **vẫn đúng bằng** allowlist hiện hành (lúc này đã rỗng) —
tức là không file nào trong `lib/` vừa rơi vào bốn needle mới. Nếu đỏ, file phạm phải được bọc tiếp,
không được nới allowlist. Cùng bước này bật `prefer_single_quotes` trong `analysis_options.yaml`
(đang bị comment ở dòng 33) để dạng nháy kép không quay lại được nữa, rồi chạy
`/c/flutter/bin/dart format lib test` một lần *(Ruling H: batch format ở Task 7, không format rải rác
vì sẽ tạo nhiễu trong diff, che mất diff của seam)* và `flutter analyze` phải sạch.

Kèm theo (Ruling J kéo theo): tạo **`dart_test.yaml`** ở gốc repo, vì hiện `@Tags(['web'])` trong
`test/web/*` vô hiệu (không có file khai báo tag, runner in cảnh báo) và `flutter test` trên VM **vẫn
nạp** `test/web` — đo: `flutter test test/web/` = `+8 ~1`.

```yaml
tags:
  web:
```

Không bỏ các `skip: !kIsWeb`: test web vẫn phải chạy trên VM để khoá nhánh IO, còn nhánh canvas web
chỉ được chứng minh bởi bước Chrome trong Step 2.

- [ ] **Step 1c: Bước Chrome trong CI là bằng chứng duy nhất của nhánh web (Ruling J)**

Trên máy dev này `flutter test --platform chrome` **không chạy được** (flutter_tools treo khi lái Edge;
đã chẩn đoán ở Task 0/Task 2 với smoke test `expect(1,1)` cũng chết bằng
`Connection closed before test suite loaded.`). Vì vậy, cho tới Step 2, những thứ sau **chưa từng được
chạy thật**: quy tắc cắt của `square_image_web.dart`, `getContext('2d')` có trả context thật không,
`createImageBitmap` reject hay trả bitmap rỗng với ảnh rác, façade `localDraftStore` có trả
`WebLocalDraftStore` trên web hay không, và `ReceiptLocalImage` nhánh web có đọc handle qua store để vẽ
`MemoryImage` hay không (test trong `test/web/receipt_cache_image_web_test.dart` mang `skip: !kIsWeb`
nên trên VM nó chỉ được nạp chứ không chạy). Bước Chrome trong CI là chỗ duy nhất đóng được các khoảng đó;
không có nó thì Task 2 chỉ mới chứng minh *compile được*, tức là đúng cái bẫy mà spec Plan 2 mục 2 đã
bác. Nếu CI đỏ ở một trong năm điểm đó, coi như Task 2/Task 5 chưa xong — mở lại task tương ứng, không
nới test.

- [ ] **Step 2: CI build web**

`.github/workflows/build-web.yml`:

```yaml
name: build-web
on:
  push:
    branches: [main]
  pull_request:

jobs:
  web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.47.6
          channel: stable
      - name: Tạo .env từ secrets
        run: printf 'SUPABASE_URL=${{ secrets.SUPABASE_URL }}\nSUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}\n' > .env
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test test/unit/web_platform_boundary_test.dart
      - name: Test canvas web bang Chrome that (Ruling J)
        run: flutter test --platform chrome test/web
      - run: flutter build web --release --base-href /pixket/
```

Ghi chú cho người tạo workflow: `.env` là asset bắt buộc (`pubspec.yaml:39`) nên build thiếu nó sẽ fail; **không** commit `.env`. Nếu repo chưa có secrets `SUPABASE_URL`/`SUPABASE_ANON_KEY` thì workflow đỏ — đó là việc của chủ dự án, báo rõ chứ không self-hosted thay. Kiểm tra tên biến bằng `grep -o "^[A-Z_]*" .env | sort -u` (đọc, không in giá trị).

Bẫy đã đo ở Task 7: trên **Git Bash Windows**, `--base-href /pixket/` bị MSYS tự dịch đường dẫn thành
`C:/Program Files/Git/pixket/` và `flutter build web` fail với `--base-href should start and end with /`
(exit 1, không phải lỗi code). Chạy local thì prepend `MSYS_NO_PATHCONV=1`; trên `ubuntu-latest` trong CI
không có vấn đề này (đã đo: `MSYS_NO_PATHCONV=1 flutter build web --release --base-href /pixket/` → exit 0,
`√ Built build\web`).

- [ ] **Step 3: Audit lại toàn bộ script Task 0**

Serve `build/web` mới, chạy cả hai lượt. Với mỗi dòng cũ trong báo cáo, cập nhật cột thành `Đã sửa (Task N)` / `Còn (Plan 3, lý do)`. Thêm mục "Việc còn lại cho Plan 3" ở cuối file.

Bắt buộc thêm **một dòng đo thật cho nhánh web của GallerySaver** (điều kiện review Task 4 vòng 1):
`WebGallerySaver.saveImage` không có cách nào biết browser đã tải xong hay chưa — nó chỉ biết click
có ném ra hay không — nên unit test không phân biệt được "đã lưu" với "tải hỏng". Ở bước này phải mở
feed trên trình duyệt, bấm nút tải ảnh của một khoản chi và ghi lại việc **tệp JPEG có thực sự xuất
hiện trong mục Tải xuống**, kèm tên tệp và đuôi `.jpg` do nhánh web ghép. Không đo được (thiếu người
bấm, thiếu browser) thì dòng audit ghi `Chưa đo` và chuyển thẳng sang Plan 3; **cấm** suy ra từ
"`flutter build web` exit 0".

- [ ] **Step 4: đối chiếu tiêu chí Plan 2**

Đọc spec Plan 2 mục 8 và tick từng dòng bằng bằng chứng (test name, dòng audit, output lệnh). Ghi thẳng vào spec những chỗ chứng cứ yếu — ví dụ: hành vi Android/iOS trên máy thật **chưa** chạy lại, `CHROME_EXECUTABLE` có nhận Edge hay không.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/build-web.yml docs
git commit -m "ci: build web moi push, audit lai sau khi xong boundary"
```

---

## Self-review của plan này

**Spec coverage (Plan 2 spec → task):** mục 5 audit → Task 0; mục 4.1 R1-R3 → Task 1 + Step 1 Task 7; mục 4.2 seam 1-6 → Task 2 (1, 2), Task 3 (3), Task 4 (4), Task 5 (5), Task 6 (6); mục 4.3 bytes → Task 2 Step 9-12; mục 6 thứ tự → Task 2..6 (thứ tự thật đã đổi so với bảng mục 6 vì lý do ghi dưới đây); mục 7 kiểm thử → Task 1 Step 2-3, Task 2 Step 14, Task 5 Step 1-2, Task 7 Step 2-3; mục 8 tiêu chí → Task 7 Step 4.

**Hai chỗ lệch so với spec, có chủ đích:**
1. Spec mục 6 tách `squareBytes` và `LocalDraftStore` thành hai bước, giữa chúng là `PhotoCapture`. Plan gộp `squareBytes` + `LocalDraftStore` + upload bytes vào Task 2 vì `writeSquareCopy(File) → File` đang là **cùng một thao tác** ở cả hai đầu pipeline: cắt rồi ghi tệp cạnh nguồn. Tách làm hai commit sẽ để `flutter build web` trong trạng thái gọi một symbol chỉ tồn tại ở nhánh IO (web không export `writeSquareCopy`) — tức là tự gây đỏ build ở giữa plan.
2. Spec mục 4.2 gọi seam #5 là `ReceiptCacheImage` với một widget; plan thêm `ReceiptLocalImage` cùng nhóm (Ruling 2) để không mất khả năng render tệp local trên Android.

**Placeholder scan:** không còn "TBD"/"làm tương tự"; mỗi chỗ có code thật hoặc chỉ dẫn dời nguyên văn kèm số dòng nguồn. Hai nơi cho người thực hiện *chọn* cách viết (`_resolveImage` bước 11, onboarding bước 6 Step 3) vì spec để ngỏ; reviewer quyết, và cả hai đều đã có code mẫu.

**Type consistency:** `squareBytes` luôn `Future<Uint8List?>`; `localDraftStore.save(bytes, {extension, squared})` giống nhau ở Task 2/3/4; `uploadReceiptImage(bytes, {extension, squared})` khớp Task 2 Step 9 và Step 11; `ReceiptImageSource.localDraft` + `draftHandle` dùng nhất quán Task 5; `clearReceiptCache`/`evictReceiptImage` khớp Task 5 Step 3.
