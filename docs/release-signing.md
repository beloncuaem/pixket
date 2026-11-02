# Ký release APK cho Pixket

Trước đây `android/app/build.gradle.kts` ký bản release bằng debug key. Giờ nó đọc
`android/keystore.properties` (đã nằm trong `.gitignore`) và chỉ rơi về debug key
khi file đó vắng mặt — khi đó build in cảnh báo và ghi chú thẳng vào job summary.

## 1. Tạo keystore (chạy một lần, trên máy bạn)

```powershell
keytool -genkeypair -v `
  -keystore android/app-release.keystore `
  -alias pixket-release `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -storepass "<password-cua-ban>" `
  -keypass "<password-cua-ban>"
```

`keytool` đi kèm JDK 17 mà dự án đã dùng (`actions/setup-java` đang đặt `java-version: '17'`).

Git SHA-1 của keystore — cần cho bước 3:

```powershell
keytool -list -v -keystore android/app-release.keystore -alias pixket-release
```

## 2. Khai báo với Gradle và GitHub

Tạo `android/keystore.properties` (KHÔNG commit):

```properties
storeFile=app-release.keystore
storePassword=<password-cua-ban>
keyAlias=pixket-release
keyPassword=<password-cua-ban>
```

Base64 hoá keystore để đưa lên CI (PowerShell):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app-release.keystore")) |
  Set-Clipboard
```

Vào **repo → Settings → Secrets and variables → Actions → New repository secret**, tạo 4 secret:

| Secret | Giá trị |
|---|---|
| `PIXKET_KEYSTORE_BASE64` | chuỗi base64 vừa copy |
| `PIXKET_KEYSTORE_PASSWORD` | `storePassword` |
| `PIXKET_KEY_ALIAS` | `pixket-release` |
| `PIXKET_KEY_PASSWORD` | `keyPassword` |

`SUPABASE_URL` và `SUPABASE_ANON_KEY` giữ nguyên như cũ.

## 3. Google OAuth và Supabase (bắt buộc sau khi đổi tên app)

`applicationId` đã đổi từ `com.chitieu.chi_tieu` sang `com.pixket.app` và deep link
scheme đổi sang `io.supabase.pixket`. Cả hai đều được đăng ký ở ngoài repo, nên phải
cập nhật tay, nếu không đăng nhập Google và Quên mật khẩu sẽ chết:

1. **Google Cloud Console → Credentials → OAuth client Android**: xóa client cũ, tạo
   mới với Package name `com.pixket.app` + SHA-1 của keystore ở bước 1.
2. **Supabase → Authentication → URL Configuration**: thêm
   `io.supabase.pixket://login-callback/` vào *Redirect URLs* (xoá bản `chitieu` cũ).
3. **Supabase → Authentication → Providers → Google**: kiểm tra `Client ID`/`Secret`
   vẫn trỏ đúng OAuth client vừa tạo.
4. Chạy lại `supabase_setup.sql` trên project đang chạy (nó idempotent) để lấy phần
   `REVOKE` bảng tạm migration.

## 4. Kiểm chứng sau khi ký

Bật R8 (`isMinifyEnabled = true`) chỉ lộ lỗi thật trên thiết bị, không lộ ở bước build.
Sau khi có keystore, cài bản mới lên máy đã cài bản cũ và test đủ bốn đường:
camera/chụp hóa đơn, share CSV, thông báo ngân sách, đăng nhập Google + Quên mật khẩu.

`isShrinkResources` cố tình để `false`: `flutter_local_notifications` tham chiếu
`@mipmap/ic_launcher` bằng chuỗi lúc runtime nên resource shrinking sẽ xoá mất icon.
