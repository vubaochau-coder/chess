# Giai đoạn 6 — PvP

Chỉ **T6.1** đã sẵn sàng triển khai. PvP online **chưa được lên kế hoạch**: không agent nào được bắt đầu
bất kỳ phần nào của nó (chọn backend, thêm Firebase/Supabase, đăng nhập, quyền INTERNET…) cho tới khi owner
tạo đặc tả riêng.

---

## T6.1 — Đồng hồ đánh cờ (chơi 2 người cùng máy)

**Thiết kế bắt buộc**
- `lib/core/game/time_control.dart`: `final class TimeControl { final Duration initial; final Duration increment; }`
  với các preset: không giới hạn (`null`), `1+0`, `3+2`, `5+0`, `10+0`, `15+10` (phút + giây cộng thêm).
- `GameConfig` thêm `timeControl` (`TimeControl?`, mặc định `null`). Chỉ dùng khi `mode == pvp`.
- `lib/core/game/chess_clock.dart`: `ChessClock` thuần Dart, dựa trên `Stopwatch` (inject được nguồn thời gian để test):
  `start()`, `switchSide()` (cộng increment cho bên vừa đi), `pause()`, `resume()`,
  `Duration remaining(PieceColor side)` tính tại thời điểm gọi. Không dùng `Timer` bên trong.
- Bloc: đồng hồ bắt đầu sau nước đầu tiên của Trắng. Bloc đặt một `Timer` tới thời điểm hết giờ của bên đang đi;
  hết giờ → event private `_ClockFlagged`. `GameStatus` thêm `whiteTimeout`, `blackTimeout` và
  `drawTimeoutInsufficientMaterial` (hết giờ nhưng đối phương không đủ quân chiếu hết → hòa).
  Text: `Trắng hết giờ - Đen thắng`, `Đen hết giờ - Trắng thắng`, `Hòa - hết giờ nhưng không đủ quân`.
- Ván có đồng hồ: nút Đi lại bị disable; không lưu ván (T3.7 gọi `clear` khi bắt đầu ván có đồng hồ).
- Tạm dừng đồng hồ khi app vào nền (`AppLifecycleListener` trong `GameView` gửi event `ClockPaused`/`ClockResumed`).
- UI: `ChessClockView` hiển thị `mm:ss` (dưới 10 giây hiển thị `ss.d`) phía trên và dưới bàn cờ, bên đang chạy được
  tô nổi bật. Chỉ widget đồng hồ tự cập nhật bằng `Ticker` cục bộ (mỗi frame đọc `remaining`), không emit state theo giây.
- `HomeView`: khi chọn `2 người`, hiện thêm lựa chọn `Thời gian` (`Không giới hạn`, `1+0`, `3+2`, `5+0`, `10+0`, `15+10`).

**Ngoài phạm vi:** đồng hồ cho chế độ pve, PvP online, cấu hình thời gian tùy ý.

**File được sửa:** `lib/core/game/**`, `lib/core/engine/chess_rules.dart` (chỉ enum `GameStatus`), `lib/features/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test `ChessClock` với nguồn thời gian giả: trừ giờ đúng bên, increment, pause/resume.
- [ ] Test bloc với `fakeAsync`: hết giờ → đúng `GameStatus`; trường hợp hòa do thiếu quân.
- [ ] Widget test: đồng hồ hiển thị đúng định dạng, đổi bên sau mỗi nước.
- [ ] Thử trên Android: đưa app vào nền 10 giây, quay lại đồng hồ không bị trừ.
