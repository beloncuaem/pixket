# Tính năng Bạn bè (Friends) — Plan

**Goal:** Cho phép các user khác nhau xem ảnh + thông tin hóa đơn của nhau (kiểu Locket), kèm đổi avatar và biệt danh. Không lộ thống kê/tổng chi tiêu.

**Stack:** Flutter + Riverpod + Supabase (PostgreSQL RLS + Storage). Cloud-only, không SQLite.

## Quyết định đã chốt

- Quan hệ: **mutual friends** (gửi lời mời → chấp nhận).
- Hiển thị khi xem ảnh bạn bè: ảnh + caption + số tiền + danh mục + mức độ + ngày. Không có thống kê/tổng.
- Avatar lưu ở bucket **public** `avatars` (đọc công khai, ghi trong thư mục của chính mình).
- Biệt danh lưu cột `profiles.nickname`.
- Tìm bạn bằng **email** qua RPC `find_user_by_email` (tránh lộ toàn bộ profiles).

## Schema (supabase_setup.sql)

- `profiles`: thêm `nickname TEXT`, `avatar_url TEXT` (đã có) — avatar lưu path `<user_id>/avatar.jpg` hoặc URL public.
- Bảng `friendships`:
  - `id`, `requester_id`, `addressee_id`, `status` ('pending'/'accepted'/'declined'), `created_at`.
  - UNIQUE(requester_id, addressee_id).
- RLS `friendships`: insert chỉ requester = auth.uid(); select/update nếu requester hoặc addressee = auth.uid(); delete nếu requester hoặc addressee = auth.uid().
- RLS `expenses`: thêm policy SELECT cho bạn bè đã accepted (user_id nằm trong danh sách bạn).
- RLS `profiles`: cho phép bạn bè accepted đọc nickname/avatar (không đọc email? email là PII — RPC trả tối thiểu).
- Storage bucket `avatars` (public): policy insert/update/delete chỉ trong thư mục `auth.uid()`; read public.
- Storage bucket `expense-receipts`: thêm policy SELECT cho bạn bè accepted (để ký URL).
- RPC `find_user_by_email(email)` security definer: trả `id, nickname, avatar_url` nếu user tồn tại và không phải chính mình; không lộ email.

## Phases

### Phase 0 — Schema & RLS
- Sửa `supabase_setup.sql`: thêm bảng, policy, bucket, RPC. Idempotent.
- Chạy SQL trên Supabase. Verify.

### Phase 1 — Data layer
- `lib/data/models/friendship.dart`: `Friendship`, `FriendProfile`.
- `lib/data/repositories/friend_repository.dart`: `sendRequest(email)`, `listFriends()`, `listPendingRequests()`, `accept(id)`, `decline(id)`, `remove(friendId)`.
- `lib/data/repositories/profile_repository.dart`: `getProfile()`, `updateNickname()`, `uploadAvatar(Uint8List)`.
- Mở rộng `ExpenseRepository`: `getExpensesForUsers(List<String> userIds)` (ký URL như hiện tại).

### Phase 2 — Providers
- `friendProvider`, `pendingRequestsProvider`, `profileProvider`.

### Phase 3 — UI
- Màn hình feed bạn bè (Locket-style PageView dọc) trong `lib/screens/friends/`, tái dùng `PixelReceiptImage`, overlay avatar + nickname.
- Màn hình quản lý bạn bè (danh sách, lời mời, thêm bằng email) trong settings hoặc drawer.
- Chỉnh avatar/biệt danh trong settings.
- Nút mở feed bạn bè ở drawer.

### Phase 4 — Tests
- Unit: repo (mock Supabase), provider state.
- Widget: feed bạn bè render ảnh + info, không có tổng chi tiêu; request flow.
- Boundary: không thêm `dart:io` ngoài `*_io.dart`.

### Phase 5 — Docs
- Cập nhật README/project-structure.

## Rủi ro & giới hạn

- RLS friends read trên expenses cho phép client tự tổng hợp → chỉ enforce "không UI thống kê" ở app; chấp nhận cho MVP.
- Signed URL bạn bè TTL 1h; ký lại khi load.
- Avatar bucket public → avatar ai cũng xem được (đúng kỳ vọng mạng xã hội).
- Tìm bạn bằng email cần RPC security definer; không dùng RLS broad trên profiles để tránh lộ danh sách user.

## Không làm (YAGNI)

- Không chat, không thông báo push real-time, không feed tổng hợp nhiều nguồn, không follower count, không block/report (để Plan sau nếu cần).
- Không offline cache bạn bè.

## Thứ tự thực hiện

0 → 1 → 2 → 3 → 4 → 5. Mỗi phase một commit. Chạy `flutter analyze` + `flutter test` sau mỗi phase.