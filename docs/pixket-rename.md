# Đổi tên dự án sang Pixket — những việc còn lại ngoài repo

Commit rename đã đổi toàn bộ identifier trong mã: package Dart `pixket`,
`applicationId`/`namespace` `com.pixket.app`, bundle id iOS `com.pixket.app`, deep link
scheme `io.supabase.pixket`, SQLite `pixket.db`, brand hiển thị `Pixket`, tên workflow
artifact `pixket-release-apk`, tên file export `pixket_*.csv`. Ba việc sau nằm ngoài
git nên phải làm tay.

## 1. Đổi tên repository trên GitHub

`gh` trên máy này chưa đăng nhập nên không đổi hộ được. Làm tay:

1. Mở `https://github.com/beloncuaem/chi_tieu/settings` → mục **Repository name** →
   nhập `pixket` → **Rename**.
2. GitHub tự redirect người ghé qua URL cũ, nhưng remote của máy bạn thì không. Chạy:

   ```powershell
   git remote set-url origin https://github.com/beloncuaem/pixket.git
   git fetch origin
   ```

3. Image `README` dùng URL `raw.githubusercontent.com/beloncuaem/pixket/...` nên chỉ
   hiển thị sau khi rename xong.

## 2. Đổi tên thư mục local

Phiên làm việc đang neo vào thư mục này nên không tự đổi được (đường dẫn sẽ gãy giữa
chừng). Đóng IDE và terminal đang mở trong thư mục trước, rồi:

```powershell
cd C:\Users\ASUS\Documents\code\project
Rename-Item -Path .\chi_tieu -NewName pixket
cd .\pixket
flutter clean
flutter pub get
```

`flutter clean` là bắt buộc: `android/app/build/` và `.dart_tool/` đang giữ đường dẫn
cũ. Nếu IDE vẫn nhớ project cũ, xóa rồi mở lại từ `C:\Users\ASUS\Documents\code\project\pixket`.

## 3. Google Cloud + Supabase (không làm là mất đăng nhập)

Đổi `applicationId` và scheme deep link làm hỏng hai cấu hình đăng ký ở ngoài repo.
Làm theo mục 3 của [release-signing.md](release-signing.md), cụ thể:

- Google Cloud Console → Credentials → Android OAuth client: **Package name** phải là
  `com.pixket.app`, **SHA-1** lấy từ keystore ký release.
- Supabase → Authentication → URL Configuration → Redirect URLs: thêm
  `io.supabase.pixket://login-callback/`.
- Chạy lại `supabase_setup.sql` (idempotent) trên project đang chạy.

## 4. Người dùng đang cài bản cũ

Vì chữ ký đổi (debug key → release key, và package name đổi), bản cũ **không cập nhật
đè được**. Người dùng phải gỡ cài đặt rồi cài APK mới; dữ liệu local trong SQLite
 (`app_settings`, `priority_levels`) mất, còn dữ liệu chi tiêu trên Supabase vẫn nguyên
 vì nó gắn với tài khoản. Nói rõ điều này khi gửi link APK đợt tới.

## 5. Rollback nếu cần

Branch `backup/pre-pixket-rename` trỏ đúng commit trước rename (`58022ab`). Để quay lại:

```powershell
git diff --stat backup/pre-pixket-rename HEAD   # xem phạm vi thay đổi
git revert --no-commit 58022ab..HEAD && git commit  # hoàn tác có kiểm soát
```
