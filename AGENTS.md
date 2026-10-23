# AGENTS.md

Hướng dẫn cho AI agent (Claude Code, Codex, Copilot…) và người mới làm việc trên repo này.
Đọc hết file này trước khi sửa code. Kế hoạch tổng thể nằm ở [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Tổng quan

- Game cờ vua viết bằng **Flutter**, nền tảng chính là **Android** (các nền tảng khác chưa được bảo trì).
- App id: **`com.chauvb.chess`** — **không bao giờ đổi** (đã chốt cho Google Play).
- State management: **bloc / flutter_bloc**.
- Hiện có: chơi 2 người trên cùng máy, đầy đủ luật (nhập thành, bắt tốt qua đường, phong cấp Hậu,
  chiếu, chiếu hết, hết nước đi).

## Môi trường

| Công cụ | Phiên bản |
|---|---|
| Flutter | 3.47.7 stable (Dart 3.13) |
| Java | 17+ |
| Android Gradle Plugin / Gradle | 9.1 / 9.3 (Kotlin DSL) |

## Lệnh thường dùng

```bash
flutter pub get
dart format lib test            # format (CI kiểm tra bằng --set-exit-if-changed)
flutter analyze                 # phải "No issues found!" — kể cả info
flutter test                    # toàn bộ test
flutter run                     # chạy trên thiết bị / emulator
flutter build apk --release     # APK
flutter build appbundle         # AAB để upload Google Play
```

## Cấu trúc thư mục

```
lib/
  main.dart, app.dart           # entry point, MaterialApp
  core/
    engine/                     # LUẬT CỜ — thuần Dart, KHÔNG import Flutter
      chess_rules.dart          #   sinh nước đi hợp lệ, applyMove, trạng thái ván
      chess_utils.dart          #   đọc/ghi phần bố trí quân của FEN
      position_model.dart       #   Position(x, y)
    audio/chess_sounds.dart     # đường dẫn file âm thanh
  features/
    game/                       # màn chơi
      bloc/                     #   ChessGameBloc + event + state
      models/                   #   model quân cờ (vẽ quân), ChessType, factory Chess()
      painter/                  #   CustomPainter: bàn cờ, ô chọn, gợi ý, ô bị chiếu
      view/                     #   màn hình (ChessTable)
      widgets/                  #   widget con (BoardGame, lớp quân cờ GameState)
  theme/colors.dart             # màu sắc
test/                           # cấu trúc song song với lib/
docs/ROADMAP.md                 # lộ trình
```

Tính năng mới đặt trong `lib/features/<tên>/` với cùng bố cục (`bloc/`, `view/`, `widgets/`, `models/`).
Logic không phụ thuộc UI (AI, lưu trữ…) đặt trong `lib/core/`.

## Mô hình dữ liệu bàn cờ (quan trọng)

- Bàn cờ là `List<String>` 64 phần tử, **index = x * 8 + y**.
  - `x` là hàng: **0 = hàng 8** (phía quân đen), **7 = hàng 1** (phía quân trắng).
  - `y` là cột: 0 = cột a … 7 = cột h.
  - Ví dụ: e1 = 60, e8 = 4, a8 = 0, h1 = 63.
- Ký hiệu quân theo FEN: chữ hoa = trắng (`K Q R B N P`), chữ thường = đen, `''` = ô trống.
- `GamePosition` (bất biến) = bàn cờ + lượt đi + quyền nhập thành (`'KQkq'`) + ô en passant.
- Luồng một nước đi: UI gửi `SquareTappedEvent(index)` → bloc gọi `ChessRules.legalMoves` /
  `ChessRules.applyMove` / `ChessRules.status` → emit state mới. **UI không tự tính luật.**

## Quy tắc code

Lint được ép bởi `analysis_options.yaml` (strict-casts, strict-inference, strict-raw-types).
Ngoài những gì lint bắt, cần tuân theo:

1. **Import tuyệt đối** `package:chess/...`, không dùng import tương đối (trừ `part`/`part of`).
2. **`lib/core/engine/` thuần Dart** — không import `package:flutter`, để test nhanh và chạy được trong `Isolate`.
3. Khai báo kiểu trả về cho mọi hàm/method; ưu tiên `final`, `const`.
4. Không dùng `print` — dùng `debugPrint` khi cần debug tạm, và xóa trước khi commit.
5. Đặt tên: file `snake_case.dart`, class `PascalCase`, biến/hàm `camelCase`.
6. Text hiển thị cho người dùng: **tiếng Việt**. Tên biến/hàm: tiếng Anh. Comment: tiếng Việt hoặc tiếng Anh,
   chỉ viết khi giải thích *tại sao*, không mô tả lại code.
7. State của bloc bất biến, có `copyWith`, kế thừa `Equatable`.
8. Không thêm package mới khi chưa cần thiết; nếu thêm, ghi lý do trong mô tả PR.
9. Asset (âm thanh, hình quân cờ, font) phải có **giấy phép cho phép phát hành thương mại**; ghi nguồn khi thêm.

## Test

- Mọi thay đổi trong `lib/core/engine/` phải giữ **toàn bộ test perft** (`test/core/engine/chess_rules_test.dart`) xanh.
  Perft so số nước đi với giá trị chuẩn nên bắt được gần như mọi lỗi luật.
- Bug fix trong engine: thêm test tái hiện bug trước.
- Logic bloc mới: viết test cho bloc (có thể dùng `bloc_test`).

## Android & phát hành

- Cấu hình Gradle ở `android/` dùng Kotlin DSL (`*.gradle.kts`).
- Ký bản release: tạo `android/key.properties` (đã gitignore):
  ```properties
  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=/đường/dẫn/upload-keystore.jks
  ```
  Không có file này thì bản release được ký bằng debug key (chỉ dùng để chạy thử, **không upload được**).
- **Không bao giờ commit** keystore (`*.jks`, `*.keystore`), `key.properties`, mật khẩu hay API key.
- Version trong `pubspec.yaml` dạng `X.Y.Z+N`; `N` (versionCode) phải tăng mỗi lần upload lên Play.

## Definition of done

Một thay đổi chỉ coi là xong khi:

- [ ] `dart format --set-exit-if-changed lib test` không đổi gì
- [ ] `flutter analyze` → No issues found
- [ ] `flutter test` pass
- [ ] Đã chạy thử trên Android (emulator hoặc máy thật) nếu thay đổi UI / native
- [ ] Cập nhật `docs/ROADMAP.md` (đánh dấu mục đã xong) và file này nếu đổi kiến trúc / quy ước

## Không được làm

- Đổi `applicationId` / `namespace` (`com.chauvb.chess`).
- Sửa luật cờ mà không chạy perft test.
- Đặt logic luật cờ trong widget.
- Commit file build, keystore, `local.properties`.
- Dùng asset không rõ giấy phép.
