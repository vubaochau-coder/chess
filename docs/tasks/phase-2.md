# Giai đoạn 2 — Hoàn thiện lõi game

Mục tiêu giai đoạn: luật cờ đầy đủ theo FIDE (trừ đồng hồ), ghi nước đi, đi lại.
Chế độ chơi vẫn là 2 người cùng máy. Không làm AI, không làm cài đặt trong giai đoạn này.

Quy ước chung cho cả giai đoạn:
- Mọi logic luật nằm trong `lib/core/engine/` (thuần Dart, có test). Bloc chỉ gọi engine.
- Perft test hiện có phải luôn xanh, không sửa giá trị kỳ vọng.
- Text UI tiếng Việt đúng như ghi trong đặc tả.

---

## T2.1 — FEN đầy đủ (parse/format)

**Mục tiêu:** đọc/ghi thế cờ bằng FEN đủ 6 trường; thay thế `ChessUtils`.

**Thiết kế bắt buộc**
- File mới `lib/core/engine/fen.dart`:
  ```dart
  abstract final class Fen {
    static const String initial =
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    static GamePosition parse(String fen);      // ném FormatException nếu sai
    static String format(GamePosition position); // luôn xuất đủ 6 trường
  }
  ```
- File mới `lib/core/engine/square.dart`:
  ```dart
  int squareFromName(String name);  // 'e4' -> 36; sai định dạng -> FormatException
  String squareName(int square);    // 36 -> 'e4'; ngoài 0..63 -> RangeError
  ```
- `GamePosition` thêm 2 field: `halfmoveClock` (int, mặc định 0) và `fullmoveNumber` (int, mặc định 1).
- `ChessRules.applyMove` cập nhật: `halfmoveClock` về 0 khi đi tốt hoặc ăn quân, ngược lại +1;
  `fullmoveNumber` +1 sau nước đi của **Đen**.
- `GamePosition.initial()` dùng `Fen.parse(Fen.initial)`.
- `parse` chấp nhận FEN 4 trường (thiếu 2 trường đồng hồ → mặc định `0 1`). Ném `FormatException` khi:
  số hàng ≠ 8; một hàng không đủ/thừa 8 ô; ký tự lạ; lượt đi không phải `w`/`b`; quyền nhập thành có ký tự
  ngoài `KQkq` hoặc lặp; ô en passant không ở hàng 3/6; đồng hồ không phải số nguyên ≥ 0
  (`fullmoveNumber` ≥ 1); mỗi bên không có đúng 1 vua.
- `format` ghi quyền nhập thành theo thứ tự `KQkq`, `-` khi rỗng; en passant dạng `e3` hoặc `-`.

**Phạm vi**
- Tạo `fen.dart`, `square.dart`; sửa `chess_rules.dart` như trên.
- **Xóa** `lib/core/engine/chess_utils.dart`, thay mọi chỗ dùng (kể cả trong test) bằng `Fen`.
- Test helper `fromFen` trong `test/core/engine/chess_rules_test.dart` thay bằng `Fen.parse`.

**Ngoài phạm vi:** luật hòa (T2.2), SAN (T2.4), UI nhập/xuất FEN.

**File được sửa:** `lib/core/engine/**`, `lib/features/game/bloc/**` (chỉ đổi import/khởi tạo nếu cần),
`test/core/engine/**`, `docs/architecture.md` (cập nhật danh sách file engine).

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Round-trip `format(parse(f)) == f` cho ít nhất 6 FEN: thế ban đầu; sau `1.e4`
      (`rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1`); kiwipete; thế tàn cuộc perft #3;
      một thế không còn quyền nhập thành; một thế có `fullmoveNumber` > 1.
- [ ] Mỗi trường hợp lỗi liệt kê ở trên có ít nhất 1 test `throwsFormatException`.
- [ ] Test đồng hồ: sau `1.e4` → `0 1`, lượt đen; sau `1...Nf6` → `1 2`; sau một nước ăn quân → halfmove `0`.
- [ ] `squareFromName`/`squareName` có test cho a8=0, h8=7, a1=56, h1=63, e4=36 và đầu vào sai.
- [ ] Không còn tham chiếu nào tới `ChessUtils`.

---

## T2.2 — Luật hòa: 50 nước, lặp 3 lần, thiếu quân

**Mục tiêu:** ván cờ tự kết thúc hòa theo 3 luật; hiển thị lý do hòa.

**Thiết kế bắt buộc**
- `GameStatus` thành:
  ```dart
  enum GameStatus {
    playing, check, checkmate, stalemate,
    drawFiftyMove, drawRepetition, drawInsufficientMaterial;

    bool get isGameOver => this != playing && this != check;
    bool get isDraw => isGameOver && this != checkmate;
  }
  ```
- Hàm mới `ChessRules.gameStatus(List<GamePosition> history)` đánh giá phần tử cuối với thứ tự ưu tiên:
  `checkmate` → `stalemate` → `drawInsufficientMaterial` → `drawFiftyMove` (`halfmoveClock >= 100`) →
  `drawRepetition` → `check` → `playing`.
- Lặp lại: so khóa thế cờ = 4 trường đầu của FEN (bố trí, lượt, nhập thành, en passant), trong đó ô
  en passant **chỉ tính khi bên đang đi thực sự có nước bắt tốt qua đường hợp lệ**, ngược lại coi là `-`.
  Hòa khi khóa của thế cuối xuất hiện ≥ 3 lần trong `history`.
- Thiếu quân (chỉ các trường hợp sau, ngoài ra là đủ quân): K–K; K+B–K; K+N–K; chỉ còn vua và tượng
  (bất kỳ số lượng, hai bên) mà mọi tượng cùng màu ô.
- `ChessRules.status(position)` giữ nguyên chữ ký (dùng cho perft/test).
- Bloc dùng `ChessRules.gameStatus(history)` thay cho `ChessRules.status`; `ChessGameState.isGameOver`
  trả về `status.isGameOver`.
- Text trong `GameStatusBar`:
  - `drawFiftyMove` → `Hòa - luật 50 nước`
  - `drawRepetition` → `Hòa - lặp lại 3 lần`
  - `drawInsufficientMaterial` → `Hòa - không đủ quân chiếu hết`
  - các trạng thái cũ giữ nguyên text.
- Âm thanh: mọi trạng thái kết thúc ván dùng `SoundEffect.gameEnd`.

**Ngoài phạm vi:** đề nghị hòa, xin hòa, đồng hồ, lặp 5 lần / 75 nước.

**File được sửa:** `lib/core/engine/**`, `lib/features/game/bloc/**`, `lib/features/game/widgets/game_status_bar.dart`,
`test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test engine cho từng loại hòa, gồm: lặp lại bằng đi đi lại lại mã (Nf3 Nf6 Ng1 Ng8 ×2);
      trường hợp ô en passant khác nhau nhưng không bắt được → vẫn tính lặp lại;
      chiếu hết đúng ở nước có `halfmoveClock` = 100 → `checkmate` (ưu tiên hơn hòa);
      K+N+N–K **không** phải thiếu quân; K+B–K+B khác màu ô **không** phải thiếu quân.
- [ ] Test bloc: lặp lại 3 lần qua `SquareTapped` → `drawRepetition`, chạm tiếp bị bỏ qua.
- [ ] Widget test: text hiển thị đúng cho ít nhất 1 trạng thái hòa mới.

---

## T2.3 — Chọn quân khi phong cấp

**Mục tiêu:** khi tốt lên hàng cuối, người chơi chọn Hậu/Xe/Tượng/Mã.

**Thiết kế bắt buộc**
- Engine: thêm `static bool ChessRules.isPromotionMove(GamePosition position, int from, int to)`.
  `applyMove(..., promotion:)` nhận `'q' | 'r' | 'b' | 'n'` (chữ thường; engine tự đổi hoa cho quân trắng).
- State thêm field `pendingPromotion` kiểu `LastMove?` (`(from, to)`).
- Bloc:
  - `SquareTapped` vào ô đích hợp lệ mà `isPromotionMove` → emit state có `pendingPromotion`, **chưa đi quân**,
    giữ `selected`, không phát âm thanh.
  - Khi `pendingPromotion != null`: mọi `SquareTapped` bị bỏ qua.
  - Event mới `PromotionPieceSelected(String piece)` (`'q'|'r'|'b'|'n'`, khác → `ArgumentError`):
    đi nước phong cấp, xóa `pendingPromotion`, âm thanh theo quy tắc hiện có (`promote` nếu không chiếu/kết thúc).
  - Event mới `PromotionCancelled`: xóa `pendingPromotion` và `selected`, không đi quân.
- UI:
  - Widget mới `lib/features/game/widgets/promotion_dialog.dart`: `AlertDialog` tiêu đề `Phong cấp`,
    4 nút `PieceView` theo thứ tự Hậu, Xe, Tượng, Mã đúng màu bên đang đi; trả về `'q'|'r'|'b'|'n'`
    qua `Navigator.pop`.
  - `GameView` bọc nội dung bằng `BlocListener` với
    `listenWhen: (p, c) => p.pendingPromotion == null && c.pendingPromotion != null`;
    mở dialog bằng `showDialog` (`barrierDismissible: true`); kết quả `null` → `PromotionCancelled`,
    ngược lại `PromotionPieceSelected`.

**Ngoài phạm vi:** tự động phong Hậu theo cài đặt, phong cấp kéo-thả, animation.

**File được sửa:** `lib/core/engine/chess_rules.dart`, `lib/features/game/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test bloc: phong Mã/Xe/Tượng/Hậu cho cả trắng và đen ra đúng quân; hủy thì bàn cờ không đổi;
      chạm khi đang chờ phong cấp bị bỏ qua; phong cấp kèm ăn quân và kèm chiếu.
- [ ] Widget test: đi tốt tới hàng cuối → dialog hiện 4 lựa chọn; chọn Mã → ô đích là `N`;
      bấm ra ngoài → hủy.
- [ ] Không còn chỗ nào phong cấp mặc định Hậu ngoài các test engine có sẵn.

---

## T2.4 — Ký hiệu SAN, danh sách nước đi, quân bị ăn

**Mục tiêu:** hiển thị lịch sử nước đi dạng `1. e4 e5 2. Nf3` và quân đã bị ăn.

**Thiết kế bắt buộc**
- `lib/core/engine/move.dart`:
  ```dart
  final class Move extends Equatable {
    const Move(this.from, this.to, {this.promotion});
    final int from;
    final int to;
    final String? promotion;              // 'q'|'r'|'b'|'n' hoặc null
    String toUci();                       // 'e2e4', 'e7e8q'
    static Move fromUci(String uci);      // FormatException nếu sai
  }
  ```
  (`equatable` là package thuần Dart, được dùng trong `lib/core/`.)
- `lib/core/engine/san.dart`: `abstract final class San { static String format(GamePosition before, Move move); }`
  - Quân: `K Q R B N`; tốt không có chữ.
  - Phân biệt (disambiguation) khi ≥ 2 quân cùng loại cùng màu đi hợp lệ tới cùng ô: thêm cột; nếu cột trùng
    thêm hàng; nếu cả hai trùng thêm cả cột và hàng.
  - Ăn quân: `x`; tốt ăn ghi cột xuất phát (`exd5`), bắt tốt qua đường ghi như ăn thường (`exd6`).
  - Nhập thành: `O-O`, `O-O-O`. Phong cấp: `e8=Q` (chữ hoa).
  - Hậu tố: `#` nếu chiếu hết, `+` nếu chiếu.
- State: thêm `moves: List<MoveRecord>` với
  `final class MoveRecord extends Equatable { final Move move; final String san; final String? captured; }`
  (`captured` là ký hiệu quân bị ăn, kể cả en passant). Bất biến: `moves.length == history.length - 1`.
  Field `lastMove` bị thay bằng getter suy ra từ `moves.last` (giữ kiểu `LastMove?`).
- Widget mới:
  - `widgets/move_list.dart` — `MoveList`: `ListView` ngang, cao 40, hiển thị `1. e4 e5 2. Nf3 …`,
    nước mới nhất in đậm và tự cuộn tới cuối khi có nước mới. Đặt giữa `GameStatusBar` và nút.
  - `widgets/captured_pieces.dart` — `CapturedPieces(color:)`: hàng `PieceView` cỡ 20 các quân của
    `color` đã bị ăn, sắp xếp Q R B N P, kèm chênh lệch vật chất `+N` ở bên đang hơn
    (giá trị P=1, N=3, B=3, R=5, Q=9). Phía trên bàn cờ: quân trắng bị ăn; phía dưới: quân đen bị ăn.
  - Cả hai dùng `BlocSelector` chọn `state.moves` (list bất biến, so identity).

**Ngoài phạm vi:** bấm vào nước đi để xem lại thế cờ, xuất PGN, chú thích nước đi.

**File được sửa:** `lib/core/engine/**`, `lib/features/game/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test SAN ≥ 15 trường hợp: mỗi loại quân, ăn quân, tốt ăn, en passant, cả hai kiểu nhập thành,
      phong cấp có/không ăn, chiếu `+`, chiếu hết `#`, phân biệt theo cột, theo hàng, theo cả hai.
- [ ] `Move.toUci`/`fromUci` round-trip, kể cả phong cấp; đầu vào sai ném `FormatException`.
- [ ] Test bloc: sau "fool's mate" `moves.map((m) => m.san)` = `['f3', 'e5', 'g4', 'Qh4#']`.
- [ ] Widget test: danh sách nước hiển thị đúng sau vài nước; quân bị ăn và `+N` hiển thị đúng.

---

## T2.5 — Đi lại (undo)

**Mục tiêu:** quay lại 1 nước (chế độ 2 người).

**Thiết kế bắt buộc**
- Event mới `UndoRequested`: bỏ phần tử cuối của `history` và `moves`; xóa `selected`, `legalTargets`,
  `pendingPromotion`; tính lại `status`, `checkSquare`. Được undo cả khi ván đã kết thúc.
  Khi `history.length == 1` → không làm gì. Không phát âm thanh.
- UI: `IconButton(Icons.undo, tooltip: 'Đi lại')` đặt cùng hàng với nút `Ván mới`; bị disable khi
  `history.length == 1` (dùng `BlocSelector` chọn `bool`).

**Ngoài phạm vi:** redo, undo nhiều bước một lúc, hành vi undo khi chơi với máy (T3.4).

**File được sửa:** `lib/features/game/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test bloc: undo sau nước thường, sau nhập thành, sau phong cấp, sau chiếu hết (ván chơi tiếp được);
      undo ở thế ban đầu không emit state.
- [ ] Widget test: nút disable ở đầu ván, enable sau 1 nước, bấm thì bàn cờ trở lại.
