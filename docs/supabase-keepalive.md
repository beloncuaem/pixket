# Giữ Supabase hoạt động (free tier)

Supabase free tier **tạm dừng project sau 7 ngày không có hoạt động**. Project bị pause thì
app không đăng nhập, không đọc/ghi dữ liệu được nữa. Repo này có workflow GitHub Actions
`.github/workflows/supabase-keepalive.yml` gọi REST API mỗi 2 ngày một lần.

## 1. Bật workflow

1. Mở repo trên GitHub -> **Settings -> Secrets and variables -> Actions -> New repository secret**.
2. Tạo hai secret (tên đúng như dưới đây, phân biệt hoa thường):
   - `SUPABASE_URL`: ví dụ `https://<project-ref>.supabase.co`
   - `SUPABASE_ANON_KEY`: **anon / publishable key** (key an toàn để nhúng client).
3. Không dùng `service_role` key ở bất kỳ đâu trong workflow hay app.

## 2. Chạy thử bằng tay

1. **Actions -> Supabase keep-alive -> Run workflow**.
2. Mở log job `Giữ dự án Supabase hoạt động`, dòng cuối phải là `HTTP 200`.
   - `HTTP 400/401/404`: sai URL hoặc sai key.
   - `HTTP 403`: RLS/policy từ chối — kiểm tra đã chạy `supabase_setup.sql` chưa.
3. Lần đầu chạy, GitHub sẽ hỏi xác nhận chạy workflow; bấm **Approve and run**.

## 3. Lịch chạy

- `cron: '0 3 */2 * *'` — 03:00 UTC cách ngày, tức mỗi 2 ngày.
- GitHub **tự tắt schedule của repo không có commit nào trong 60 ngày**. Vì vậy:
  - Commit hoặc "This repo is active" không phải giải pháp lâu dài.
  - Hãy bật thêm phương án dự phòng bên dưới.

## 4. Dự phòng: cron-job.org

1. Tạo account tại <https://cron-job.org>.
2. **Create cronjob** -> Schedule: `Every 2 days`, 03:00.
3. **HTTP request**: `GET https://<project-ref>.supabase.co/rest/v1/categories?select=id&limit=1`
4. **Header**:
   - `apikey: <SUPABASE_ANON_KEY>`
   - `Authorization: Bearer <SUPABASE_ANON_KEY>`
5. **Expected Response Code**: `200`.
6. Bật **Execution history** để kiểm tra khi app báo lỗi mạng.

Khóa anon/publishable được đặt trong service ngoài là chấp nhận được vì nó vốn đã nằm
trong `.env` của app; tuyệt đối không đặt `service_role` key ở đây.

## 5. Khi project đã bị pause

1. Supabase Dashboard -> **Project settings -> General -> Restore project** (hoặc Unpause).
2. Chạy workflow tay một lần để xác nhận còn sống.
3. Nếu restore không khả dụng (project bị xóa), tạo project mới, chạy lại
   `supabase_setup.sql` và cập nhật `.env` — ảnh trong Storage của project cũ không tự về.
