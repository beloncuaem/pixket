# Yêu cầu và phạm vi dự án Chi Tiêu (v2.2)

> Cập nhật: 2026-10-26.

## 1. Mục tiêu

Ứng dụng di động giúp một cá nhân ghi nhận, phân loại và theo dõi chi tiêu hằng ngày.
Mỗi khoản chi có thể đính kèm ảnh hóa đơn; ảnh được hiển thị thành nhật ký dạng lướt
giống Locket. Toàn bộ dữ liệu tài chính và ảnh được lưu trực tiếp trên Supabase;
ứng dụng bắt buộc đăng nhập và không lưu bản sao tài chính trên thiết bị.

## 2. Người dùng

Người dùng cá nhân theo dõi chi tiêu bằng VND theo ngày/tuần/tháng/năm, phân loại theo
danh mục và mức độ cần thiết. Người dùng phải đăng nhập email/Google; không có chế độ
khách hay ngoại tuyến.

## 3. Yêu cầu chức năng

| Mã | Yêu cầu | Trạng thái |
| --- | --- | --- |
| FR-01 | Chụp ảnh bằng camera hoặc chọn ảnh từ thư viện. | Đã có |
| FR-02 | Tạo khoản chi gồm ảnh, mô tả, số tiền, danh mục, mức độ cần thiết, thời điểm. | Đã có |
| FR-03 | Phân loại độ cần thiết: Thiết yếu, Rất cần, Cần vừa, Chưa cần. | Đã có |
| FR-04 | Hiển thị tổng chi hôm nay/tuần/tháng và danh sách khoản chi; xóa mềm. | Đã có |
| FR-05 | Quản lý danh mục: mặc định, thêm và xóa danh mục tùy chỉnh. | Đã có |
| FR-06 | Ngân sách tổng hoặc theo danh mục; hiển thị tiến độ sử dụng. | Đã có |
| FR-07 | Thống kê theo ngày/tuần/tháng/năm/khoảng ngày tự chọn. | Đã có |
| FR-08 | Biểu đồ theo danh mục và mức độ cần thiết; nhận xét tổng quan. | Đã có |
| FR-09 | Chuyển giao diện sáng/tối. | Đã có |
| FR-10 | Nhật ký ảnh kiểu Locket: trang camera đầu tiên, lướt dọc xem ảnh đã chụp. | Đã có |
| FR-11 | Điều hướng bằng nút 3 gạch + drawer, không dùng thanh tab đáy. | Đã có |
| FR-12 | Đăng nhập/đăng ký email & mật khẩu qua Supabase Auth. | Đã có |
| FR-13 | Đăng nhập Google OAuth qua trình duyệt, quay về app bằng deep link. | Đã có, phụ thuộc cấu hình Supabase/Google Cloud |
| FR-14 | Bắt buộc đăng nhập; không có chế độ khách/ngoại tuyến. | Đã có |
| FR-15 | Lưu trực tiếp lên cloud, không có đồng bộ thủ công hay fallback SQLite. | Đã có |
| FR-16 | Lưu ảnh hóa đơn lên Supabase Storage và hiển thị lại từ cloud. | Đã có |
| FR-17 | Khôi phục khoản chi từ thùng rác. | Đã có |
| FR-18 | Kiểm tra Google provider trước khi mở trình duyệt để báo lỗi rõ ràng. | Đã có |
| FR-19 | Xem ảnh dạng lưới trong nhật ký và nhảy tới đúng ảnh trong feed. | Đã có |
| FR-20 | Hiển thị "Quá ngân sách: X" thay vì số còn lại âm khi vượt hạn mức. | Đã có |

## 4. Quy tắc dữ liệu

- Mỗi khoản chi phải có mô tả, số tiền, danh mục và thời điểm tạo.
- Khoản chi mới phải có ảnh chụp/chọn từ thư viện; ảnh không thể thay đổi sau khi đã lưu.
- Danh mục mặc định được seed sẵn trên Supabase và không được xóa.
- Không lưu khoản chi, danh mục, ngân sách hay ảnh hóa đơn trên thiết bị.
- Ảnh chụp/chọn chỉ tồn tại tạm trong lúc nhập; sau khi upload thành công hoặc khi hủy form,
  tệp tạm được xóa khỏi máy.
- Ngân sách lưu theo tháng `yyyy-MM`; có thể là ngân sách tổng hoặc theo danh mục.
  Mỗi tháng chỉ có một ngân sách tổng; khi lưu, client chọn dòng mới nhất và dọn dòng trùng.
- Xóa khoản chi là xóa mềm (`deleted_at`); dữ liệu vẫn phục hồi được từ thùng rác.
- Tiền tệ hiển thị theo định dạng Việt Nam (VND).
- Dữ liệu cloud được bảo vệ bởi Row Level Security theo `user_id`.

## 5. Yêu cầu phi chức năng

- Bắt buộc đăng nhập; dữ liệu tài chính chỉ đọc/ghi trên Supabase.
- Khi mất mạng hoặc cloud lỗi, app báo lỗi và không lưu khoản chi (không fallback SQLite).
- Chỉ dùng SQLite cho tùy chọn onboarding và danh sách mức độ cần thiết.
- Giao diện Material 3, hỗ trợ sáng/tối, phông Be Vietnam Pro.
- Ảnh được upload ngay khi lưu khoản chi và không giữ bản sao trên máy.
- Không đưa khóa bí mật vào mã nguồn; chỉ dùng `SUPABASE_URL` và anon/publishable key từ `.env`.
- Deep link OAuth: scheme `io.supabase.chitieu`, host `login-callback`.
- Mọi thay đổi phải chạy `flutter analyze` và `flutter test` trước khi bàn giao.

## 6. Phạm vi chưa triển khai

- OCR/nhận diện hóa đơn; ảnh chỉ là tệp đính kèm.
- Thay ảnh của khoản chi đã lưu (hiện chỉ sửa được ghi chú, số tiền, danh mục, mức độ).
- Đồng bộ hai chiều tự động theo thời gian thực và xử lý xung đột nâng cao.
- Xuất báo cáo CSV/PDF hoặc chia sẻ dữ liệu.
- Đăng nhập Apple/Facebook và các provider OAuth khác.

## 7. Điều kiện cấu hình bên ngoài

- Bật **Email** provider (mặc định) trong Supabase Authentication → Providers.
- Muốn dùng Google: bật **Google** provider, cấu hình Client ID/Secret từ Google Cloud
  và allowlist redirect URL. Xem `docs/google-oauth-troubleshooting.md`.
- Nếu bật "Confirm email", người dùng đăng ký phải xác nhận email trước khi đăng nhập.
- Chạy `supabase_setup.sql` để tạo bảng, RLS và bucket `expense-receipts`.
- Từ v2.2 bucket `expense-receipts` là **private**: phải chạy lại `supabase_setup.sql`
  rồi cài bản app mới. Bản app cũ (dùng public URL) sẽ không còn xem được ảnh.

## 8. Tiêu chí nghiệm thu đã xác minh

- `flutter analyze`: không có issue nào.
- `flutter test`: 66/66 bài pass.
- `flutter build apk --debug`: build thành công sau đợt sửa camera, ngân sách và thùng rác.
- Emulator Android API 35:
  - Onboarding và cấp quyền camera/thông báo hoạt động.
  - Đăng nhập email sai hiển thị "Email hoặc mật khẩu không chính xác." từ Supabase,
    chứng minh app kết nối được backend.
  - Không thể vào app khi chưa đăng nhập (không còn chế độ khách).
  - Feed Locket, nút 3 gạch, drawer và 4 khu vực điều hướng hiển thị đúng.
  - Google OAuth bị chặn bởi cấu hình provider (`external.google = false`) và nay được
    app báo rõ trước khi mở trình duyệt.
