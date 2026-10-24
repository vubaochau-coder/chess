# Kiến trúc

Tài liệu này là **chuẩn bắt buộc**. Code mới phải theo đúng các mẫu ở đây; code hiện có trong
`lib/features/game/` là ví dụ tham chiếu.

## 1. Các lớp (layer)

```
┌────────────────────────────────────────────────────────────┐
│ UI  lib/features/<feature>/{view,widgets,painter}          │  Flutter widget, chỉ hiển thị + gửi event
├────────────────────────────────────────────────────────────┤
│ State  lib/features/<feature>/bloc                         │  Bloc/Cubit: điều phối, giữ state bất biến
├────────────────────────────────────────────────────────────┤
│ Core  lib/core/                                            │
│   engine/   luật cờ, FEN, SAN       (thuần Dart)           │
│   ai/       tìm nước đi cho máy     (thuần Dart, Isolate)  │
│   game/     GameConfig, đồng hồ     (thuần Dart)           │
│   settings/ AppSettings             (thuần Dart)           │
│   audio/    SoundPlayer             (plugin audioplayers)  │
│   storage/  repository lưu trữ      (shared_preferences)   │
└────────────────────────────────────────────────────────────┘
```

"Thuần Dart" nghĩa là không import `package:flutter`; được dùng package thuần Dart đã có trong
`pubspec.yaml` (vd. `equatable`).

Chiều phụ thuộc chỉ đi **xuống**: UI → bloc → core. Core không biết đến bloc hay widget.
Feature không import nội bộ của feature khác (chỉ dùng qua `lib/core/` hoặc truyền dữ liệu qua constructor).

### Cấu trúc thư mục

```
lib/
  main.dart                 # chỉ khởi tạo (ensureInitialized, load repository) rồi runApp
  app.dart                  # ChessApp: RepositoryProvider cho service dùng chung + MaterialApp
  core/
    engine/                 # chess_rules.dart, fen.dart, square.dart
    audio/                  # sound_effect.dart, sound_player.dart
    ai/                     # (Giai đoạn 3) SearchBoard, search, ChessAi
    game/                   # (Giai đoạn 3) GameConfig, (Giai đoạn 6) ChessClock
    settings/               # app_settings.dart
    storage/                # saved_game.dart, game_repository.dart, settings_repository.dart
  features/
    game/
      bloc/                 # chess_game_bloc.dart (+ part event/state)
      view/                 # game_page.dart: GamePage (tạo bloc) + GameView (UI thuần)
      widgets/              # chess_board.dart, piece_view.dart, game_status_bar.dart
      painter/              # board_painter.dart, highlight_painter.dart
    home/
      cubit/                # home_cubit.dart (+ part home_state.dart)
      view/                 # home_page.dart: HomePage (tạo cubit) + HomeView (UI thuần)
    settings/               # cubit/settings_cubit.dart, view/settings_page.dart
  theme/
test/                       # song song với lib/, helper dùng chung ở test/helpers/
```

## 2. Mô hình dữ liệu bàn cờ

- `List<String>` 64 phần tử, **index = x * 8 + y**.
  - `x` = hàng: **0 là hàng 8** (phía đen), **7 là hàng 1** (phía trắng).
  - `y` = cột: 0 = a … 7 = h. Ví dụ: a8 = 0, h8 = 7, e8 = 4, e1 = 60, a1 = 56, h1 = 63.
- Ký hiệu quân theo FEN: hoa = trắng (`K Q R B N P`), thường = đen, `''` = ô trống.
- `GamePosition` (bất biến): `board`, `whiteToMove`, `castling` (`'KQkq'`), `enPassant` (int?).
  Không bao giờ sửa `board` tại chỗ; mọi thay đổi tạo `GamePosition` mới qua `ChessRules.applyMove`.
- API engine công khai: `ChessRules.legalMoves`, `applyMove`, `status`, `isInCheck`, `pseudoMoves`.
  Task nào cần đổi API này sẽ ghi rõ trong đặc tả.
- `SearchBoard` (`lib/core/ai/search_board.dart`): Bàn cờ nội bộ tốc độ cao cho AI (`Int8List(64)`,
  mã hóa nước đi `int`, Zobrist hash 64-bit, `makeMove`/`unmakeMove` khôi phục tại chỗ phục vụ tìm kiếm).


## 3. Dependency injection

- Service dùng chung toàn app (`SoundPlayer`, các repository, `ChessAi`) được tạo **một lần** trong
  `ChessApp` bằng `RepositoryProvider` (có `dispose` nếu cần giải phóng), rồi truyền vào bloc qua constructor:

  ```dart
  BlocProvider(
    create: (context) => ChessGameBloc(soundPlayer: context.read<SoundPlayer>()),
    child: const GameView(),
  )
  ```

- Bloc **không tự tạo** service, không gọi plugin trực tiếp, không dùng singleton/biến toàn cục.
- Mỗi service có **interface** (`abstract interface class`) để test bằng mock (`mocktail`).
- Service cần khởi tạo bất đồng bộ (vd. `SharedPreferences`) được load trong `main()` trước `runApp`,
  rồi truyền vào `ChessApp` qua constructor.

## 4. Chuẩn Bloc

### Event

```dart
sealed class ChessGameEvent extends Equatable {
  const ChessGameEvent();
  @override
  List<Object?> get props => [];
}

final class SquareTapped extends ChessGameEvent {
  const SquareTapped(this.index);
  final int index;
  @override
  List<Object?> get props => [index];   // BẮT BUỘC liệt kê mọi field
}
```

- `sealed` base + `final class` cho từng event, constructor `const`.
- Tên event mô tả **điều đã xảy ra** ở UI (`SquareTapped`, `UndoRequested`), không phải lệnh nội bộ.
- Event nội bộ (vd. kết quả AI) đặt tên bắt đầu bằng `_` và để private trong file bloc.

### State

- `final class XxxState extends Equatable`, mọi field `final`, constructor `const`.
- `props` liệt kê **mọi** field.
- Collection trong state là bất biến theo quy ước: **không bao giờ** `state.list.add(...)`; luôn tạo list
  mới (`[...old, item]`). Nhờ vậy so sánh bằng identity rẻ và `BlocSelector` chính xác.
- Giá trị suy ra tốn chi phí (vd. ô vua bị chiếu) tính **một lần trong bloc** khi chuyển state và lưu vào
  state; widget không tự tính lại trong `build`.
- Chuyển trạng thái bằng method có tên rõ nghĩa (`afterMove`, `withSelection`, `withoutSelection`) hoặc
  `copyWith` có xử lý được việc đặt field nullable về `null`. Không dùng `copyWith` kiểu
  `x ?? this.x` cho field nullable cần xóa.
- Không có field `isLoading` nếu state ban đầu tính được đồng bộ — truyền vào `super(...)`.

### Bloc

- Handler đồng bộ khi có thể. Handler bất đồng bộ (AI) phải:
  - dùng transformer phù hợp từ `bloc_concurrency` (task sẽ ghi rõ);
  - bỏ qua kết quả cũ khi state đã đổi (vd. so `gameId`/số nước đi trước khi emit).
- Không giữ `BuildContext`, không gọi `Navigator`/`showDialog` trong bloc. Việc một lần (mở hộp thoại,
  điều hướng) do UI xử lý bằng `BlocListener` với `listenWhen`.
- Side effect (âm thanh, lưu trữ) gọi qua service đã inject; không `await` âm thanh.
- Bloc không `dispose` service được inject (không sở hữu chúng).

## 5. Quy tắc hiệu năng (bắt buộc)

1. **Không dùng `BlocBuilder` không có `buildWhen` bao quanh widget lớn.** Ưu tiên `BlocSelector` chọn
   đúng phần dữ liệu cần; giá trị được chọn phải so sánh được (record, enum, primitive, list bất biến).
2. **Rebuild nhỏ nhất có thể**: mỗi ô quân cờ tự select `(board[index], selected == index)`; status bar chỉ
   select `(status, whiteToMove)`. Thêm thông tin mới → thêm selector mới, không mở rộng builder có sẵn.
3. Phần vẽ tĩnh nằm trong `RepaintBoundary` riêng. `CustomPainter.shouldRepaint` **phải so sánh field**,
   không bao giờ `return true` cố định. Painter nhận kích thước từ `size`, không giữ `cellSize`.
4. Widget dùng `const` constructor khi có thể; không tạo closure/list lớn trong `build` nếu tránh được.
5. Xử lý chạm một lần ở cấp bàn cờ (tính ô từ tọa độ) — không bọc 64 ô bằng `InkWell`/`GestureDetector`.
6. Tính toán nặng (AI, perft) **không chạy trên UI isolate** — dùng `Isolate.run` qua service `ChessAi`.
7. Không gọi `MediaQuery.of(context)` ở widget sâu; dùng `LayoutBuilder` hoặc `MediaQuery.sizeOf`.
8. Animation dùng widget implicit (`AnimatedPositioned`, `AnimatedScale`…) hoặc `AnimationController`
   cục bộ; không emit state bloc theo từng frame.

## 6. Thêm một tính năng mới (checklist)

1. Logic không phụ thuộc UI → `lib/core/<module>/` + test thuần Dart.
2. Service có side effect → interface + implementation trong `lib/core/`, đăng ký ở `ChessApp`.
3. Màn hình → `lib/features/<feature>/` với `view/<feature>_page.dart` (tạo bloc) và `<Feature>View` (UI).
4. Bloc/Cubit theo mục 4, test bằng `bloc_test`.
5. Widget theo mục 5, widget test cho tương tác chính.
6. Cập nhật tài liệu này nếu thêm layer/service/thư mục mới.
