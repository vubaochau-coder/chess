# Lộ trình phát triển

Mục tiêu: hoàn thiện game cờ vua cho **Android** và phát hành trên Google Play.
App id chính thức: **`com.chauvb.chess`** (không được đổi sau lần upload đầu tiên).

Trạng thái: ✅ xong · 🚧 đang làm · ⬜ chưa làm

---

## Giai đoạn 0 — Nền móng ✅

- ✅ Nâng Flutter lên stable 3.47.7 (Dart 3.13), nâng các package
  (`flutter_bloc` 9, `bloc` 9, `equatable` 3, `flutter_lints` 6, `audioplayers` 6.8)
- ✅ Tạo lại `android/` theo template mới: Gradle 9 / AGP 9, Kotlin DSL (`*.gradle.kts`), Java 17
- ✅ Đổi app id `com.example.chess` → `com.chauvb.chess` (namespace, applicationId, package Kotlin)
- ✅ Cấu hình ký bản release qua `android/key.properties` (fallback về debug key nếu chưa có)
- ✅ Quy tắc code chặt hơn trong `analysis_options.yaml` (strict mode, package imports, final, …)
- ✅ Cấu trúc thư mục theo tính năng (`lib/core`, `lib/features`, `lib/theme`)
- ✅ Bỏ code và package không dùng (`canMoveTo`, `ChessTableModel`, `cupertino_icons`, `loading_animation_widget`, `print` debug)
- ✅ `AGENTS.md` (+ `CLAUDE.md` trỏ tới) mô tả lệnh, kiến trúc, quy ước, definition of done
- ✅ CI GitHub Actions: format, analyze, test, build APK
- ⬜ Quyết định giữ hay bỏ các nền tảng ngoài Android (ios, web, linux, macos, windows).
  Hiện vẫn giữ nhưng **không bảo trì**; bundle id iOS vẫn là `com.example.chess`.

## Giai đoạn 1 — Chuẩn bị phát hành

- ⬜ Tạo upload keystore, bật Play App Signing; thêm secrets ký app vào CI
- ⬜ Tên app, icon (`flutter_launcher_icons`), splash (`flutter_native_splash`)
- ⬜ Quy tắc version: `version: X.Y.Z+N` trong `pubspec.yaml`, `N` tăng mỗi lần upload
- ⬜ Bật R8 / shrink resources cho bản release, kiểm tra kích thước AAB
- ⬜ Play Console: tài khoản developer, privacy policy, Data safety, content rating,
  ảnh chụp màn hình, target API theo yêu cầu hiện hành
- ⬜ **Thay toàn bộ âm thanh trong `assets/audio/`** bằng nguồn có giấy phép rõ ràng
  (tên file hiện tại trùng bộ âm thanh của chess.com)
- ⬜ ⚠️ Tài khoản cá nhân mới phải chạy **closed testing ≥ 12 tester trong 14 ngày** trước khi
  lên production → đưa bản đầu lên closed testing ngay khi xong Giai đoạn 2

## Giai đoạn 2 — Hoàn thiện lõi game

- ⬜ Model nước đi đầy đủ (`from`, `to`, `promotion`)
- ⬜ Hộp thoại chọn quân phong cấp (Hậu / Xe / Tượng / Mã)
- ⬜ Undo, lịch sử nước đi dạng SAN (e4, Nf3, O-O…), quân đã bị ăn
- ⬜ Luật hòa: lặp lại 3 lần, luật 50 nước, không đủ quân chiếu hết
- ⬜ Đọc / ghi FEN đầy đủ (gồm lượt, quyền nhập thành, en passant, đếm nước)
- ⬜ Lưu và khôi phục ván đang chơi
- ⬜ Tối ưu biểu diễn bàn cờ cho AI (mảng số / 0x88), giữ bộ test perft xanh

## Giai đoạn 3 — PvE (Easy / Medium / Hard)

Hướng chọn: **tự viết AI bằng Dart** (không vướng GPL của Stockfish).

- ⬜ Minimax + alpha-beta, iterative deepening, bảng điểm vị trí quân (PST)
- ⬜ Chạy AI trong `Isolate` để không giật UI
- ⬜ Easy: độ sâu 1–2 + nhiễu ngẫu nhiên · Medium: độ sâu 3–4 · Hard: giới hạn thời gian,
  quiescence search, transposition table, move ordering
- ⬜ Màn hình bắt đầu ván: chế độ, độ khó, chọn màu quân
- ⬜ Chỉ báo "máy đang nghĩ", nút gợi ý, đầu hàng
- ⬜ (Tùy chọn sau này) mức Master bằng Stockfish nếu chấp nhận mở mã nguồn GPL-3

## Giai đoạn 4 — Tùy biến theme

- ⬜ `BoardTheme` dạng dữ liệu (ô sáng/tối, chọn, gợi ý, chiếu) + vài preset, dark mode
- ⬜ Nhiều bộ quân cờ SVG (`flutter_svg`) — kiểm tra giấy phép từng bộ
- ⬜ Lật bàn cờ, hiện tọa độ, tô nước vừa đi, bật/tắt chấm gợi ý
- ⬜ Màn Cài đặt, lưu bằng `shared_preferences`

## Giai đoạn 5 — Âm thanh & hiệu ứng

- ⬜ Nhiều bộ âm thanh, âm lượng, tắt tiếng, haptic
- ⬜ Animation di chuyển quân, kéo-thả, rung khi bị chiếu, hiệu ứng thắng
- ⬜ Xem xét thư viện âm thanh độ trễ thấp nếu `audioplayers` bị trễ

## Giai đoạn 6 — PvP (sau v1.0)

- ⬜ Local: tự lật bàn theo lượt, đồng hồ đánh cờ
- ⬜ Online: Firebase hoặc Supabase, phòng theo mã, reconnect, validate nước đi phía server
- ⬜ Cập nhật Data safety, privacy policy, chức năng xóa tài khoản

---

## Mốc phát hành

| Version | Nội dung | Kênh |
|---|---|---|
| v0.1 | Giai đoạn 0 + 1 | Internal testing |
| v0.5 | + Giai đoạn 2, PvE Easy/Medium | Closed testing (bắt đầu đếm 14 ngày) |
| v1.0 | + Hard, theme, âm thanh có giấy phép | Production |
| v1.x | PvP online | Cập nhật |
