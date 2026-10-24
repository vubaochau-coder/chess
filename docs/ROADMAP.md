# Lộ trình phát triển

Mục tiêu: game cờ vua cho **Android**, phát hành trên Google Play. App id: **`com.chauvb.chess`**.

File này là bức tranh tổng thể. **Chi tiết triển khai và trạng thái từng việc nằm trong
[`docs/tasks/`](tasks/README.md)** — agent chỉ làm theo các file đó.

## Giai đoạn 0 — Nền móng ✅ (đã xong)

- Flutter 3.47.7 qua FVM (`.fvmrc`), version package ghim cứng, CI đọc version từ `.fvmrc`
- `android/` theo template mới (AGP 9, Gradle 9, Kotlin DSL), app id `com.chauvb.chess`, ký release qua `key.properties`
- Lint chặt (`analysis_options.yaml`), cấu trúc thư mục theo tính năng
- Kiến trúc bloc chuẩn: service inject qua `RepositoryProvider`, state bất biến, rebuild theo từng ô
  (xem [`docs/architecture.md`](architecture.md))
- `AGENTS.md`, đặc tả task cho agent, CI (format, analyze, test, build APK)

## Giai đoạn 1 — Chuẩn bị phát hành → [phase-1.md](tasks/phase-1.md)

Build release thu gọn + AAB, icon/splash, thay âm thanh có giấy phép, ký app trong CI.

⚠️ Việc của owner song song: tài khoản Play Console, keystore, privacy policy, Data safety, ảnh store.
Tài khoản cá nhân mới phải chạy **closed testing ≥ 12 tester trong 14 ngày** trước khi lên production —
nên đưa bản đầu lên closed testing ngay khi xong Giai đoạn 2.

## Giai đoạn 2 — Hoàn thiện lõi game → [phase-2.md](tasks/phase-2.md)

FEN đầy đủ, luật hòa (50 nước, lặp 3 lần, thiếu quân), chọn quân phong cấp, ký hiệu SAN + danh sách nước đi
+ quân bị ăn, đi lại.

## Giai đoạn 3 — PvE → [phase-3.md](tasks/phase-3.md)

AI tự viết bằng Dart (alpha-beta, chạy Isolate) với 3 mức Dễ / Trung bình / Khó; màn hình chọn chế độ;
đầu hàng; lưu và tiếp tục ván.

## Giai đoạn 4 — Tùy biến giao diện → [phase-4.md](tasks/phase-4.md)

Màn Cài đặt, chế độ sáng/tối, 5 theme màu bàn cờ, tọa độ / gợi ý / lật bàn, bộ quân cờ.

## Giai đoạn 5 — Âm thanh & hiệu ứng → [phase-5.md](tasks/phase-5.md)

Bật/tắt âm thanh, âm lượng, rung, bộ âm thanh, animation di chuyển, kéo-thả, hiệu ứng chiếu và kết thúc ván.

## Giai đoạn 6 — PvP → [phase-6.md](tasks/phase-6.md)

Đồng hồ đánh cờ cho chế độ 2 người cùng máy. PvP online: **chưa lên kế hoạch** (cần đặc tả riêng:
backend, tài khoản, Data safety, xóa tài khoản).

## Mốc phát hành

| Version | Nội dung | Kênh |
|---|---|---|
| v0.1 | Giai đoạn 1 | Internal testing |
| v0.5 | + Giai đoạn 2, PvE (T3.1–T3.5) | Closed testing (bắt đầu đếm 14 ngày) |
| v1.0 | + phần còn lại Giai đoạn 3, Giai đoạn 4–5 | Production |
| v1.x | Giai đoạn 6 | Cập nhật |

Trước mỗi mốc, owner chạy thử trên Android theo mục *Kiểm tra trên thiết bị* trong
[`docs/review-notes.md`](review-notes.md).
