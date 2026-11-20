# PWA Deploy cho iOS (Plan 3) — Plan chi tiết

**Goal:** Đưa Pixket lên web (GitHub Pages) để bạn bè cài như app trên iPhone (Safari → Add to Home Screen), không cần cert Apple, không reinstall. Kết hợp với tính năng bạn bè để cả hai xem ảnh chi tiêu của nhau.

**Stack:** Flutter web (đã build xanh ở Plan 2), GitHub Actions, GitHub Pages, Supabase (Auth/DB/Storage).

**Phụ thuộc:** Plan 2 (web-boundary) đã hoàn thành và committed tại nhánh local `web-boundary` (HEAD `97b961c`): 451 test pass, boundary R1–R3 rỗng, `flutter build web --release --base-href /pixket/` xanh.

---

## Phase 0 — Merge & push (quyết định của chủ dự án)

- [ ] Review diff `web-boundary` → `main` (git diff main..web-boundary).
- [ ] Merge `web-boundary` vào `main` (local, không force).
- [ ] Push `main` lên origin (10 commit cũ + Plan 2).
- [ ] (Tuỳ chọn) Push nhánh `web-boundary` lên origin để giữ lịch sử/PR.

**Rủi ro:** conflict do `.graphifyignore` untracked; xử lý thủ công. Không push nếu chưa review.

## Phase 1 — GitHub Pages deployment

- [ ] Tạo workflow `.github/workflows/deploy-pages.yml` (hoặc mở rộng `build-web.yml`):
  - Trigger: push main + workflow_dispatch.
  - Build: `flutter build web --release --base-href /pixket/` (với `MSYS_NO_PATHCONV` không cần trên ubuntu).
  - Upload `build/web` như Pages artifact.
  - Deploy bằng `actions/deploy-pages@v4`.
- [ ] Bật GitHub Pages trong repo settings: Source = GitHub Actions.
- [ ] Kiểm tra URL: `https://beloncuaem.github.io/pixket/`.
- [ ] Verify `.env` không bị lộ: workflow tạo `.env` từ secrets (đã làm trong build-web.yml). Lưu ý `.env` được đóng gói vào `build/web/assets/.env` (public) — chỉ được chứa anon key (đã assert trong CI). Không đặt service_role.

## Phase 2 — Supabase cấu hình cho web

- [ ] Supabase Dashboard → Authentication → URL Configuration:
  - Site URL: `https://beloncuaem.github.io/pixket/`
  - Redirect URLs: thêm `https://beloncuaem.github.io/pixket/**` và `http://localhost:*` (dev).
- [ ] Google OAuth (nếu dùng): thêm redirect URL web vào Google Cloud Console; Supabase Google provider redirect URI đã có.
- [ ] CORS: Supabase mặc định cho phép origin của Site URL; verify bằng request từ Pages.
- [ ] Storage bucket `expense-receipts`: policy read cho owner + friends (Phase của friends feature) — nếu chưa làm friends, giữ owner-only.

## Phase 3 — iOS PWA verification

- [ ] Mở URL trên Safari iPhone → Add to Home Screen → icon xuất hiện.
- [ ] Launch từ home screen → chạy standalone (không thanh địa chỉ).
- [ ] Đăng nhập email/password (và Google nếu bật).
- [ ] Camera: chọn/chụp ảnh qua `image_picker` (input capture) — verify không crash.
- [ ] Feed dọc, drawer, điều hướng, ảnh signed URL hiển thị.
- [ ] Tải ảnh về máy (web download) — verify file JPEG xuất hiện.
- [ ] Ngân sách cảnh báo: chấp nhận no-op trên iOS (hoặc test Web Push nếu iOS 16.4+).
- [ ] Kiểm tra storage eviction: reload sau lâu → app vẫn load từ Supabase (không mất dữ liệu vì cloud-only).

## Phase 4 — Friends feature (kết hợp)

- [ ] Triển khai plan `2026-11-21-friends-feature.md` (Phase 0 DB/RLS trước).
- [ ] Feed bạn bè kiểu Locket trên web: PageView dọc ảnh bạn bè + overlay avatar/nickname.
- [ ] Đổi avatar/biệt danh trong settings (web upload avatar lên bucket `avatars`).

## Phase 5 — Docs & polish

- [ ] Cập nhật README: link PWA, hướng dẫn Add to Home Screen trên iOS, giới hạn (no push, no offline).
- [ ] Cập nhật `docs/project-structure.md`: thêm web/PWA notes.
- [ ] Thêm `docs/ios-pwa.md` (nếu cần): các bước cài + troubleshooting.

## Rủi ro & giới hạn

- iOS PWA không có background push thực sự; budget alert có thể không hoạt động → ghi rõ trong docs.
- `flutter build web` đóng gói `.env` public (chỉ anon key) — đã assert trong CI; không đặt secret khác.
- GitHub Pages base path `/pixket/` phải khớp `--base-href` và Supabase redirect.
- Web Push trên iOS yêu cầu HTTPS + user gesture + iOS 16.4+; không bắt buộc cho MVP.

## Thứ tự thực hiện

0 (merge/push) → 1 (Pages) → 2 (Supabase) → 3 (test iPhone) → 4 (friends) → 5 (docs).

Mỗi phase một commit. Chạy `flutter analyze` + `flutter test` sau Phase 0/1 (Phase 3–4 test trên thiết bị).