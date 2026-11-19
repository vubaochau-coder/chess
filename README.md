# Chess

Game cờ vua cho **Android** viết bằng Flutter: chơi với máy (AI tự viết bằng Dart, 3 mức độ) hoặc 2 người
cùng máy, đủ luật cờ vua chuẩn, có bài hướng dẫn cho người mới. Giao diện tiếng Việt.

- App id: `com.chauvb.chess`
- Nền tảng: chỉ Android (các thư mục `ios/`, `web/`, `linux/`, `macos/`, `windows/` không được duy trì)

## Tính năng

**Chơi cờ**

- Chơi với máy (PvE) với 3 mức **Dễ / Trung bình / Khó**, chọn cầm quân Trắng, Đen hoặc ngẫu nhiên.
- Chơi 2 người cùng máy (PvP), có tùy chọn tự lật bàn sau mỗi nước.
- Đủ luật: nhập thành, bắt tốt qua đường, phong cấp (chọn Hậu/Xe/Tượng/Mã), chiếu hết, hết nước đi.
- Hòa tự động: luật 50 nước, lặp lại 3 lần, không đủ quân chiếu hết.
- Danh sách nước đi theo ký hiệu SAN, hiển thị quân bị ăn.
- Đi lại (undo), gợi ý nước đi khi chơi với máy, đầu hàng.
- Tự lưu ván đang chơi và tiếp tục khi mở lại app.

**Tùy biến**

- Chế độ sáng / tối.
- 5 màu bàn cờ: Gỗ, Xanh lá, Xanh dương, Xám, Tím.
- 4 bộ quân: Cổ điển, Gỗ, Phẳng, Hiện đại.
- Bật/tắt tọa độ, nước đi hợp lệ, tô nước vừa đi, hiệu ứng chuyển động.
- Âm thanh (có chỉnh âm lượng) và rung.

**Học chơi cờ**

- 17 bài: cách đi từng quân, luật đặc biệt, chiếu hết và hòa, mẹo cơ bản.
- Bàn cờ tương tác để thử, thử thách có chấm điểm, lưu tiến độ.

## Công nghệ

| Thành phần | Lựa chọn |
|---|---|
| Framework | Flutter 3.47.7 (Dart 3.13), quản lý phiên bản qua [FVM](https://fvm.app) |
| State management | `bloc` / `flutter_bloc` (Bloc cho màn hình, Cubit cho phần đơn giản) |
| Điều hướng | `Navigator` + `MaterialPageRoute` |
| Lưu trữ | `shared_preferences` |
| Âm thanh | `audioplayers` |
| Đồ họa quân cờ | SVG qua `flutter_svg`, `chess_vectors_flutter` |
| Build Android | AGP 9.1 / Gradle 9.3 (Kotlin DSL), R8 cho bản release |

### Engine và AI

Toàn bộ luật cờ và AI viết bằng **Dart thuần** trong `lib/core/`, không phụ thuộc Flutter và không dùng
engine bên ngoài (không Stockfish).

- **Engine luật** (`lib/core/engine/`): sinh nước đi hợp lệ, FEN, SAN; kiểm chứng bằng perft test.
- **AI** (`lib/core/ai/`): bàn cờ nội bộ `Int8List` với Zobrist hash và make/unmake tại chỗ; tìm kiếm
  alpha-beta có giới hạn thời gian, quiescence search, transposition table, killer move.
  AI chạy trong **Isolate** riêng nên giao diện không bị giật khi máy đang nghĩ.
- Mức độ khó điều chỉnh qua độ sâu, thời gian nghĩ và độ ngẫu nhiên (mức Dễ cố tình đi sai đôi lúc).

## Cấu trúc thư mục

```
lib/
  core/        # thuần Dart: engine, ai, game, settings, storage, audio, tutorial, credits
  features/    # game, home, settings, tutorial — mỗi feature gồm bloc/cubit + view + widgets
  theme/       # theme app, màu bàn cờ, bộ quân
test/          # song song với lib/
tool/          # perft_bench.dart, ai_match.dart (đấu AI các mức với nhau), distribute.sh
docs/          # kiến trúc, lộ trình, đặc tả task
```

Chi tiết xem [docs/architecture.md](docs/architecture.md).

## Bắt đầu

Yêu cầu [FVM](https://fvm.app) 3.x và Java 17+. Mọi lệnh Flutter đều chạy qua `fvm`.

```bash
fvm install
```

```bash
fvm flutter pub get --enforce-lockfile
```

```bash
fvm flutter run
```

### Lệnh thường dùng

```bash
fvm dart format lib test                 # format
fvm flutter analyze                      # phải "No issues found!"
fvm flutter test                         # chạy toàn bộ test
fvm flutter build apk --release          # build APK
fvm flutter build appbundle              # build AAB cho Google Play
fvm dart run tool/perft_bench.dart       # benchmark engine
fvm dart run tool/ai_match.dart          # cho các mức AI đấu với nhau
```

Bản release cần file `android/key.properties` và keystore (không commit vào repo).

## CI

- **CI** (`.github/workflows/ci.yml`): kiểm tra version Flutter khớp `.fvmrc`, `pub get --enforce-lockfile`,
  format, analyze, test.
- **Distribute** (`.github/workflows/distribute.yml`): build APK release đã ký và đẩy lên Firebase App
  Distribution cho tester.

## Đóng góp

Dự án phát triển theo task có đặc tả sẵn. Trước khi làm bất cứ việc gì, đọc theo thứ tự:

1. [AGENTS.md](AGENTS.md) — quy tắc bắt buộc (cho cả người và AI agent)
2. [docs/architecture.md](docs/architecture.md) — kiến trúc và chuẩn code
3. [docs/tasks/README.md](docs/tasks/README.md) — quy trình và danh sách task
4. [docs/ROADMAP.md](docs/ROADMAP.md) — lộ trình tổng thể

## Giấy phép tài nguyên

Nguồn gốc và giấy phép của quân cờ, âm thanh, icon được kê khai trong
[assets/LICENSES.md](assets/LICENSES.md). Trong app, xem tại **Cài đặt → Giới thiệu**.
