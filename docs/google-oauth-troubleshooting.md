# Sửa lỗi Google OAuth: "Unsupported provider: provider is not enabled"

> Ngày chẩn đoán: 2026-10-26. Áp dụng cho project Supabase
> `https://rhfrdtluwitnbeikmzsz.supabase.co`.

## 1. Triệu chứng

Trong app đã cài APK, bấm **Tiếp tục với Google** sẽ mở trình duyệt và dừng ở trang JSON:

```json
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: provider is not enabled"}
```

URL trên thanh địa chỉ bắt đầu bằng:

```text
https://rhfrdtluwitnbeikmzsz.supabase.co/auth/v1/authorize?provider=google&...
```

## 2. Nguyên nhân gốc

Supabase Auth từ chối yêu cầu OAuth **trước khi chuyển sang Google**, vì provider Google
chưa được bật trong project.

Bằng chứng từ endpoint công khai `/auth/v1/settings`:

```text
external: {
  apple: false,
  azure: false,
  facebook: false,
  github: false,
  google: false,   ← nguyên nhân
  ...
}
email: true
mailer_autoconfirm: false
```

- Lỗi nằm ở **cấu hình server Supabase**, không nằm trong mã Dart, APK, keystore hay
  quyền Internet của điện thoại.
- Chạy trên emulator hay cài APK đều dùng chung một `SUPABASE_URL`; cả hai sẽ nhận cùng
  lỗi khi `external.google = false`.
- Trên emulator, đăng nhập email/mật khẩu vẫn hoạt động vì provider `email` đang bật.
  Điều này chứng minh app kết nối Supabase bình thường; chỉ riêng Google bị chặn.
- APK release hiện ký bằng debug keystore và **không dùng Google Sign-In SDK native**.
  Vì vậy SHA-1/SHA-256 fingerprint **không phải** nguyên nhân. App dùng OAuth trình duyệt
  (`signInWithOAuth`), nên không cần `google-services.json`.

## 3. Cách sửa (làm theo đúng thứ tự)

### Bước 1 — Tạo OAuth Client trên Google Cloud Console

1. Vào <https://console.cloud.google.com> → chọn/tạo project.
2. **APIs & Services → OAuth consent screen**:
   - Chọn **External** (nếu dùng tài khoản Gmail cá nhân).
   - Điền tên app, email hỗ trợ, email liên hệ.
   - Thêm scope `.../auth/userinfo.email` và `.../auth/userinfo.profile`.
   - Khi app chưa publish, thêm tài khoản Google dùng để test vào **Test users**.
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
4. Application type: **Web application** (không chọn Android/iOS).
5. **Authorized redirect URIs**, thêm chính xác:

   ```text
   https://rhfrdtluwitnbeikmzsz.supabase.co/auth/v1/callback
   ```

6. Lưu lại **Client ID** và **Client Secret** (secret chỉ hiển thị đầy đủ một lần).

> Đây là redirect URI của Supabase, không phải deep link của app. Deep link
> `io.supabase.pixket://login-callback/` được cấu hình ở bước 3.

### Bước 2 — Bật Google provider trong Supabase

1. Supabase Dashboard → project `rhfrdtluwitnbeikmzsz` → **Authentication → Providers**.
2. Chọn **Google** → bật **Enable Sign In**.
3. Dán **Client ID** và **Client Secret** vừa tạo.
4. Bấm **Save**.

### Bước 3 — Cấu hình URL cho app mobile

Supabase Dashboard → **Authentication → URL Configuration**:

- **Site URL**: URL web của bạn, hoặc tạm để `http://localhost:3000` nếu chỉ dùng mobile.
- **Redirect URLs**, thêm:

  ```text
  io.supabase.pixket://login-callback/
  ```

- Nếu chạy Flutter web, thêm cả `http://localhost:<port>/**`.

Deep link này đã có trong
[`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml):

```xml
<intent-filter android:autoVerify="false">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.pixket" android:host="login-callback" />
</intent-filter>
```

Nếu đổi scheme/host, phải sửa đồng thời:

- `AndroidManifest.xml`
- `redirectTo` trong `lib/data/repositories/auth_repository.dart`
- Redirect URLs trong Supabase Dashboard

### Bước 4 — Kiểm tra lại cấu hình

Từ máy tính, gọi endpoint settings với anon key trong `.env`
(không in key ra terminal/chat):

```bash
set -a; source .env; set +a
curl -s "https://rhfrdtluwitnbeikmzsz.supabase.co/auth/v1/settings" \
  -H "apikey: $SUPABASE_ANON_KEY"
```

Kết quả phải có:

```json
"external": { "google": true }
```

Chạy lại app, bấm Google. Nếu vẫn lỗi, xem mục 4.

## 4. Lỗi thường gặp sau khi đã bật provider

| Hiện tượng | Nguyên nhân | Cách sửa |
| --- | --- | --- |
| `redirect_uri_mismatch` | Redirect URI ở Google Cloud sai | Phải đúng `https://<ref>.supabase.co/auth/v1/callback` |
| `redirect_to` / `redirect_uri` không hợp lệ trong app | Deep link chưa allowlist | Thêm `io.supabase.pixket://login-callback/` vào Redirect URLs |
| `access_denied` | App OAuth đang ở chế độ Testing và tài khoản không nằm trong Test users | Thêm test user hoặc publish consent screen |
| `Provider is not enabled` vẫn còn | Chưa Save provider hoặc đang xem nhầm project | Kiểm tra đúng project-ref và gọi lại `/auth/v1/settings` |
| Đăng nhập xong không quay về app | Deep link không mở được | Kiểm tra `adb shell am start -a android.intent.action.VIEW -d "io.supabase.pixket://login-callback/"` và cấu hình manifest |
| Đăng ký email xong không đăng nhập được | `mailer_autoconfirm = false` | Xác nhận email, hoặc tắt **Confirm email** khi test |

## 5. Cải thiện đã thêm trong app

Từ phiên bản 2.1, trước khi mở trình duyệt, app gọi `/auth/v1/settings` và kiểm tra
`external.google`:

- Nếu `false`: hiện SnackBar tiếng Việt hướng dẫn bật provider, **không mở trình duyệt**.
- Nếu không kiểm tra được do mạng: vẫn cho phép thử đăng nhập để không chặn người dùng.
- Nếu `true`: mở trình duyệt như bình thường.

Mã liên quan:

- [`lib/data/repositories/auth_repository.dart`](../lib/data/repositories/auth_repository.dart)
  — `isGoogleProviderEnabled()`, `signInWithGoogle()`
- [`lib/providers/auth_provider.dart`](../lib/providers/auth_provider.dart)
  — `_humanReadableError()`
- [`lib/screens/auth/login_screen.dart`](../lib/screens/auth/login_screen.dart)
  — hiển thị SnackBar lỗi

## 6. Vì sao lỗi chỉ thấy trên điện thoại?

Bản chất lỗi không phụ thuộc thiết bị. Có thể trước đây trên emulator bạn:

- đã đăng nhập bằng email và có session sẵn, hoặc
- đã test Google trên một project Supabase khác đã bật provider, hoặc
- chỉ mở màn đăng nhập mà chưa hoàn tất vòng OAuth.

APK chỉ đóng gói cùng URL/key và cùng mã gọi `signInWithOAuth`; nó không tạo ra lỗi
`provider is not enabled`. Sau khi bật Google provider và cấu hình redirect như trên,
cùng APK đó sẽ đăng nhập được trên cả emulator lẫn điện thoại.
