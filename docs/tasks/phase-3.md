# Giai đoạn 3 — PvE (Easy / Medium / Hard)

Mục tiêu giai đoạn: chơi với máy ở 3 mức độ, có màn hình chọn chế độ, đầu hàng, lưu ván.

Quy ước chung:
- AI **tự viết bằng Dart**, nằm trong `lib/core/ai/`, thuần Dart, **không** dùng Stockfish hay code/engine
  bên ngoài, không copy code có giấy phép GPL.
- AI không bao giờ chạy trên UI isolate.
- Chỉ hỗ trợ Android (Dart VM, `int` 64-bit) — không cần tương thích web.

---

## T3.0 — Dọn dẹp sau review (engine, SearchBoard, test)

**Mục tiêu:** xử lý các ghi chú review đã được owner chọn trong `docs/review-notes.md` (quyết định 2026-10-24),
trước khi AI được nối vào game. Không thêm tính năng.

**Thiết kế bắt buộc**
1. **Khóa lặp lại dùng lại `Fen.format`** — `ChessRules.positionRepetitionKey(GamePosition)` giữ nguyên chữ ký và
   hành vi, nhưng tạo khóa từ 4 trường đầu của `Fen.format(pos)`, trong đó trường en passant thay bằng `-` khi bên
   đang đi không có nước bắt tốt qua đường hợp lệ. Xóa phần code serialize bàn cờ/nhập thành bị chép lại.
2. **`Fen.parse` chặt hơn** — hai chữ số liền nhau trong phần bố trí quân (vd. `44`, `17`) → `FormatException`.
   Thay số magic `49`/`56` bằng hằng có tên (vd. `'1'.codeUnitAt(0)`).
3. **Khóa Zobrist của `SearchBoard` chỉ tính en passant khi có thể bắt** — chỉ XOR khóa en passant khi bên đang đi
   có tốt đứng ở ô kề (cùng hàng, cột ±1) với tốt vừa đi 2 ô. Áp dụng nhất quán ở `computeZobristKey`,
   `fromPosition`, `makeMove`, `unmakeMove`. Không đổi `_enPassantCol` và sinh nước đi (chỉ đổi khóa).
   Mục đích: phát hiện lặp lại trong search khớp ngữ nghĩa với engine.
4. **`ChessRules.isLegalMove(GamePosition position, Move move)`** — `true` khi và chỉ khi `move.to` thuộc
   `legalMoves(position, move.from)` **và** `move.promotion != null` đúng khi `isPromotionMove(...)`
   (nước phong cấp thiếu quân hoặc nước thường có quân phong cấp → `false`). Dùng cho T3.7.
   `Move.fromUci` giữ nguyên (không có thế cờ nên không kiểm tra được).
5. **`SearchBoard.board`** trả `_board.asUnmodifiableView()` thay vì mảng nội bộ.
6. **Bổ sung test còn thiếu**: dialog phong cấp hiển thị đúng 4 `PieceView`; undo khi đang chọn quân; undo khi
   đang chờ phong cấp (đều xóa `selected`, `legalTargets`, `pendingPromotion`).

**Ngoài phạm vi:** các ghi chú được đánh dấu "bỏ qua" trong `docs/review-notes.md`; `MoveList` cuộn mượt
(Giai đoạn 5); đổi thuật toán search, bảng tham số, đánh giá thế cờ; mọi thay đổi UI.

**File được sửa:** `lib/core/engine/chess_rules.dart`, `lib/core/engine/fen.dart`, `lib/core/ai/search_board.dart`,
`test/**`, `docs/review-notes.md` (chỉ đánh dấu các mục T3.0 đã xử lý).

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Toàn bộ test hiện có (perft engine, perft `SearchBoard`, draw rules, search) vẫn xanh, không sửa giá trị kỳ vọng.
- [ ] `positionRepetitionKey` không còn code serialize riêng; test: 2 thế chỉ khác ô en passant không bắt được
      có cùng khóa, khác ô en passant bắt được thì khác khóa.
- [ ] Test `Fen.parse` ném `FormatException` với `44`, `17`, `116` trong một hàng.
- [ ] Test Zobrist: thế sau `1.e4` (không có tốt đen ở d4/f4) có cùng `zobristKey` với cùng bố trí nhưng en passant
      `-`; thế có tốt đen ở d4 sau `1.e4` thì khác. Kiểm tra khóa tăng dần == khóa tính lại tại mọi node perft
      kiwipete độ sâu 3 vẫn đạt.
- [ ] Test `isLegalMove`: nước hợp lệ, nước không hợp lệ, phong cấp thiếu quân, nước thường kèm quân phong cấp.
- [ ] Test ghi vào `SearchBoard.board` ném `UnsupportedError`.
- [ ] 3 test bổ sung ở mục 6.

---

## T3.1 — Bàn cờ nội bộ tốc độ cao cho AI

**Mục tiêu:** biểu diễn bàn cờ có thể đi/hoàn tác nước tại chỗ, đủ nhanh cho tìm kiếm.
Engine công khai (`ChessRules`, `GamePosition`) **giữ nguyên**, UI vẫn dùng nó.

**Thiết kế bắt buộc**
- `lib/core/ai/search_board.dart` — `final class SearchBoard`:
  - Ô cờ: `Int8List(64)`, cùng quy ước index như engine (a8 = 0, h1 = 63).
  - Mã quân: 0 = trống; trắng 1..6 = P N B R Q K; đen 9..14 = p n b r q k (`code & 8` là màu đen).
  - Nước đi mã hóa thành `int`: bit 0–5 `from`, 6–11 `to`, 12–14 quân phong cấp (0 = không,
    2 = N, 3 = B, 4 = R, 5 = Q), 15–18 cờ (ăn quân, en passant, nhập thành, đi 2 ô).
  - API:
    ```dart
    factory SearchBoard.fromPosition(GamePosition position);
    bool get whiteToMove;
    int get zobristKey;                       // cập nhật tăng dần trong makeMove/unmakeMove
    int get halfmoveClock;
    void generateLegalMoves(List<int> out);   // xóa out rồi thêm nước hợp lệ
    void generateCaptures(List<int> out);     // chỉ nước ăn quân + phong cấp, đều hợp lệ
    void makeMove(int move);
    void unmakeMove();                        // hoàn tác nước gần nhất (dùng stack nội bộ)
    bool isInCheck();
    Move toMove(int move);                    // đổi sang Move của engine (T2.4)
    int fromMove(Move move);                  // ngược lại; nước không hợp lệ -> ArgumentError
    ```
  - Zobrist: bảng khóa sinh từ `Random(20261023)` (seed cố định), ghép 2 số 32-bit thành 64-bit.
- `tool/perft_bench.dart`: in thời gian perft độ sâu 5 từ thế ban đầu (chạy bằng `fvm dart run tool/perft_bench.dart`).

**Ngoài phạm vi:** đánh giá thế cờ, tìm kiếm (T3.2), thay đổi engine công khai.

**File được sửa:** `lib/core/ai/**`, `test/core/ai/**`, `tool/perft_bench.dart`, `docs/architecture.md`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Perft của `SearchBoard` khớp số chuẩn: thế ban đầu độ sâu 4 = 197281; kiwipete độ sâu 3 = 97862;
      `8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -` độ sâu 5 = 674624.
- [ ] Test: tại mọi node của perft kiwipete độ sâu 3, `zobristKey` tăng dần bằng khóa tính lại từ đầu, và
      `makeMove` + `unmakeMove` trả về đúng khóa + bàn cờ ban đầu.
- [ ] Test `generateCaptures` ⊆ `generateLegalMoves` tại các node perft.
- [ ] Ghi kết quả `tool/perft_bench.dart` (máy, thời gian) trong PR; mục tiêu perft(5) < 10 giây.

---

## T3.2 — Thuật toán tìm nước đi

**Mục tiêu:** hàm tìm nước đi tốt nhất có giới hạn độ sâu/thời gian và tham số tạo độ "người".

**Thiết kế bắt buộc**
- `lib/core/ai/evaluation.dart`: điểm theo góc nhìn bên đang đi (centipawn).
  - Vật chất: P 100, N 320, B 330, R 500, Q 900.
  - Bảng điểm vị trí: bộ "Simplified Evaluation Function" (Tomasz Michniewski) cho 6 loại quân;
    vua dùng bảng tàn cuộc khi cả hai bên không còn hậu, hoặc bên còn hậu chỉ còn tối đa 1 quân nhẹ.
- `lib/core/ai/search.dart`:
  ```dart
  final class SearchConfig {
    const SearchConfig({required this.maxDepth, this.timeLimit, this.useQuiescence = true,
        this.useTranspositionTable = true, this.randomMarginCp = 0, this.blunderChance = 0, this.seed});
    final int maxDepth; final Duration? timeLimit; final bool useQuiescence;
    final bool useTranspositionTable; final int randomMarginCp; final double blunderChance; final int? seed;
  }
  final class SearchResult { final Move bestMove; final int scoreCp; final int depthReached; final int nodes; }
  SearchResult search(List<GamePosition> history, SearchConfig config); // history.last là thế hiện tại
  ```
  - Negamax + alpha-beta, iterative deepening từ độ sâu 1 tới `maxDepth`; dừng khi hết `timeLimit`
    (kiểm tra mỗi 2048 node); trả nước tốt nhất của độ sâu **đã hoàn thành** gần nhất (độ sâu 1 luôn hoàn thành).
  - Sắp xếp nước: nước từ transposition table → ăn quân theo MVV-LVA → phong cấp → 2 killer move mỗi ply → còn lại.
  - Quiescence (khi bật): chỉ xét `generateCaptures`, có stand-pat.
  - Transposition table (khi bật): 2^18 phần tử, lưu bằng mảng song song (`Int64List`), luôn ghi đè.
  - Điểm chiếu hết: `100000 - ply`. Hòa (lặp lại tính cả `history` của ván, luật 50 nước, thiếu quân) = 0.
  - Chỉ có 1 nước hợp lệ → trả ngay, không tìm.
  - Ngẫu nhiên (dùng `Random(seed)` nếu có seed):
    - với xác suất `blunderChance`: chọn ngẫu nhiên đều một nước hợp lệ;
    - ngược lại nếu `randomMarginCp > 0`: chọn ngẫu nhiên đều trong các nước gốc có điểm ≥ điểm tốt nhất − margin
      (ở độ sâu hoàn thành cuối cùng);
    - ngược lại: nước tốt nhất.

**Ngoài phạm vi:** opening book, endgame tablebase, đa luồng, Isolate (T3.3), null-move/LMR.

**File được sửa:** `lib/core/ai/**`, `test/core/ai/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Tìm đúng chiếu hết 1 nước ở ≥ 5 thế (vd. `6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1` → `Rd8#`).
- [ ] Tìm đúng chiếu hết 2 nước ở ≥ 3 thế với `maxDepth: 4`.
- [ ] Ăn quân bị treo, không để hậu bị treo trong ≥ 3 thế kiểm tra.
- [ ] Luôn trả nước hợp lệ (kiểm tra trên 50 thế ngẫu nhiên sinh bằng cách đi ngẫu nhiên có seed).
- [ ] Với `timeLimit: 300ms` từ thế ban đầu, trả kết quả trong ≤ 400ms (test được gắn tag `slow`).
- [ ] Cùng `seed` → cùng kết quả.

---

## T3.3 — Mức độ khó + service `ChessAi` chạy Isolate

**Thiết kế bắt buộc**
- `lib/core/ai/ai_level.dart`:
  ```dart
  enum AiLevel { easy, medium, hard; SearchConfig get config; }
  ```
  | Mức | maxDepth | timeLimit | quiescence | TT | randomMarginCp | blunderChance |
  |---|---|---|---|---|---|---|
  | easy | 2 | 300 ms | false | false | 150 | 0.15 |
  | medium | 4 | 1000 ms | true | true | 30 | 0 |
  | hard | 64 | 2500 ms | true | true | 0 | 0 |
- `lib/core/ai/chess_ai.dart`:
  ```dart
  abstract interface class ChessAi {
    Future<Move> chooseMove(List<GamePosition> history, AiLevel level);
  }
  final class IsolateChessAi implements ChessAi { ... }
  ```
  `IsolateChessAi` chạy `search` bằng `Isolate.run` và luôn mất **tối thiểu 400 ms**
  (`Future.wait` với `Future.delayed`) để nước đi của máy không xuất hiện tức thì.
- Đăng ký trong `ChessApp`: `RepositoryProvider<ChessAi>(create: (_) => IsolateChessAi())`.

**Ngoài phạm vi:** dùng AI trong bloc/UI (T3.4), chỉnh bảng tham số.

**File được sửa:** `lib/core/ai/**`, `lib/app.dart`, `test/core/ai/**`, `tool/ai_match.dart`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test bảng tham số đúng như trên.
- [ ] Test `IsolateChessAi` trả nước hợp lệ và không sớm hơn 400 ms.
- [ ] `tool/ai_match.dart`: cho 2 mức đấu nhau N ván (đổi màu luân phiên, tối đa 150 nước/ván, ghi kết quả).
      Ghi trong PR kết quả 10 ván medium–easy và 10 ván hard–medium; kỳ vọng mức cao thắng ≥ 7/10
      (không đạt → báo owner, **không** tự chỉnh bảng tham số).

---

## T3.4 — Tích hợp AI vào game bloc

**Thiết kế bắt buộc**
- `lib/core/game/game_config.dart` (thuần Dart, dùng chung cho storage ở T3.7):
  ```dart
  enum GameMode { pvp, pve }
  enum PieceColor { white, black }
  final class GameConfig extends Equatable {
    const GameConfig({required this.mode, this.humanColor = PieceColor.white, this.level = AiLevel.medium});
    const GameConfig.pvp() : ...;
    final GameMode mode; final PieceColor humanColor; final AiLevel level;
  }
  ```
- `ChessGameBloc({required SoundPlayer soundPlayer, required ChessAi ai, required GameConfig config, GamePosition? startPosition})`.
- State thêm: `config`, `gameId` (int, tăng mỗi `NewGameRequested`), `isAiThinking` (bool).
- Sau mỗi lần emit mà `mode == pve`, ván chưa kết thúc và tới lượt máy → bloc tự `add` event private
  `_AiMoveRequested(gameId, ply)` (`ply = moves.length`). Handler đăng ký với transformer `restartable()`:
  emit `isAiThinking: true` → `await ai.chooseMove(history, level)` → nếu `gameId`/`ply` không còn khớp
  state hiện tại thì **bỏ kết quả**; ngược lại đi nước như người (SAN, âm thanh, trạng thái), `isAiThinking: false`.
- Khi `pve`: `SquareTapped` bị bỏ qua nếu `isAiThinking` hoặc không phải lượt người.
- `NewGameRequested` khi người cầm Đen → máy đi trước.
- `UndoRequested` khi `pve`: quay lại tới lượt người gần nhất có nước người đã đi (thường 2 ply; 1 ply nếu máy
  đang nghĩ). Không có nước người nào để undo → không làm gì; nút undo disable trong trường hợp này.
- Lật bàn: `ChessBoard` nhận `flipped` (bool). Khi `pve` và người cầm Đen → `flipped: true`
  (hiển thị ô `63 - index`; chạm, lớp tô màu, quân cờ đều phải đổi theo).
- `GameStatusBar`: khi `isAiThinking` hiển thị `Máy đang nghĩ…` kèm `CircularProgressIndicator` cỡ 16.
- `GamePage({required GameConfig config})`. Trong giai đoạn này `ChessApp` mở `GamePage(config: GameConfig.pvp())`
  (màn chọn chế độ là T3.5).

**Ngoài phạm vi:** màn chọn chế độ (T3.5), gợi ý nước đi, lật bàn thủ công (T4.3).

**File được sửa:** `lib/core/game/**`, `lib/features/game/**`, `lib/app.dart`, `test/**`.

**Package được phép:** `bloc_concurrency: 0.3.0`.

**Tiêu chí nghiệm thu** (test dùng `MockChessAi` + `Completer` để điều khiển thời điểm trả kết quả)
- [ ] Người đi → máy đi tự động; trong lúc máy nghĩ chạm bị bỏ qua.
- [ ] `NewGameRequested`/`UndoRequested` trong lúc máy nghĩ → kết quả cũ bị bỏ, không áp vào ván mới.
- [ ] Người cầm Đen → máy đi trước; bàn cờ lật (widget test kiểm tra quân trắng nằm phía trên).
- [ ] Undo trong pve quay về đúng lượt người.
- [ ] Chế độ pvp hoạt động như trước (test cũ vẫn xanh).

---

## T3.5 — Màn hình chính chọn chế độ

**Thiết kế bắt buộc**
- `lib/features/home/`: `view/home_page.dart` (`HomePage` tạo `HomeCubit`, `HomeView` là UI),
  `cubit/home_cubit.dart` với `HomeState { GameMode mode; AiLevel level; ColorChoice colorChoice; }`,
  `enum ColorChoice { white, black, random }`. Mặc định: pve, medium, white. Không lưu lựa chọn.
- UI (từ trên xuống): tiêu đề `Cờ vua`; `SegmentedButton` chế độ (`Chơi với máy` / `2 người`);
  khi pve thêm `SegmentedButton` mức độ (`Dễ` / `Trung bình` / `Khó`) và màu quân (`Trắng` / `Đen` / `Ngẫu nhiên`);
  `FilledButton` `Bắt đầu` → `Navigator.push(MaterialPageRoute(builder: (_) => GamePage(config: ...)))`.
  `random` được quyết định lúc bấm Bắt đầu.
- `ChessApp.home` = `HomePage`. `GameView` có `AppBar` (nút back mặc định) với tiêu đề:
  pvp → `2 người`; pve → `Máy - Dễ` / `Máy - Trung bình` / `Máy - Khó`.

**Ngoài phạm vi:** tiếp tục ván (T3.7), cài đặt (T4.1), thống kê, hồ sơ người chơi.

**File được sửa:** `lib/features/home/**`, `lib/features/game/view/**`, `lib/app.dart`, `test/**`, `docs/architecture.md`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test cubit cho mọi thay đổi lựa chọn.
- [ ] Widget test: chọn pve + Khó + Đen → Bắt đầu → `GamePage` nhận đúng `GameConfig`; chọn `2 người` thì ẩn mức độ/màu.
- [ ] Bấm back từ màn chơi về màn chính.

---

## T3.6 — Đầu hàng

**Thiết kế bắt buộc**
- `GameStatus` thêm `whiteResigned`, `blackResigned` (`isGameOver` true, `isDraw` false).
- Event `ResignRequested`: pvp → bên đang tới lượt đầu hàng; pve → người chơi đầu hàng (kể cả khi máy đang nghĩ,
  kết quả máy bị bỏ). Ván đã kết thúc → không làm gì. Âm thanh `gameEnd`.
- UI: `IconButton(Icons.flag, tooltip: 'Đầu hàng')` cùng hàng với nút Ván mới / Đi lại, disable khi ván kết thúc;
  bấm → `AlertDialog` `Đầu hàng?` với nút `Hủy` / `Đầu hàng`.
- Text: `Trắng đầu hàng - Đen thắng` / `Đen đầu hàng - Trắng thắng`.
- Sau khi đầu hàng, nút Đi lại bị disable.

**Ngoài phạm vi:** đề nghị hòa, thống kê thắng/thua.

**File được sửa:** `lib/core/engine/chess_rules.dart` (chỉ enum `GameStatus`), `lib/features/game/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test bloc cho pvp (cả 2 màu) và pve (kể cả khi máy đang nghĩ).
- [ ] Widget test: hủy trong dialog không đổi gì; xác nhận → text kết quả đúng, các nút disable đúng.

---

## T3.7 — Lưu và tiếp tục ván đang chơi

**Thiết kế bắt buộc**
- `lib/core/storage/saved_game.dart`: `final class SavedGame` gồm `startFen` (String), `moves` (List<String> UCI),
  `config` (`GameConfig`). JSON viết tay bằng `dart:convert`:
  `{"version": 1, "startFen": "...", "moves": ["e2e4", ...], "mode": "pve", "humanColor": "black", "level": "hard"}`.
- `lib/core/storage/game_repository.dart`:
  ```dart
  abstract interface class GameRepository {
    SavedGame? load();          // dữ liệu hỏng/không hợp lệ -> trả null và xóa dữ liệu
    Future<void> save(SavedGame game);
    Future<void> clear();
  }
  final class SharedPrefsGameRepository implements GameRepository { // dùng SharedPreferencesWithCache, key 'saved_game_v1'
  ```
  `load` phải **chơi lại toàn bộ nước đi** qua engine từ `startFen`, kiểm tra từng nước bằng
  `ChessRules.isLegalMove` (T3.0); gặp nước không hợp lệ → coi như không có ván lưu.
- `main()`: `WidgetsFlutterBinding.ensureInitialized()`, tạo `SharedPreferencesWithCache` (allowList chỉ gồm key trên),
  truyền `SharedPrefsGameRepository` vào `ChessApp(gameRepository: ...)`, đăng ký bằng `RepositoryProvider<GameRepository>`.
- Bloc nhận `GameRepository` (inject) và `SavedGame? restore`. Sau mỗi nước đi (người hoặc máy), undo, ván mới:
  gọi `save` (không await); khi ván kết thúc (mọi trạng thái `isGameOver`) gọi `clear`.
  Ván khôi phục ở lượt máy → máy đi tiếp.
- `HomeState` thêm `hasSavedGame`; nếu có, hiện nút `Tiếp tục ván đang chơi` (phía trên nút Bắt đầu) mở
  `GamePage` từ ván lưu. Khi quay về từ `GamePage` (`await Navigator.push`) gọi `HomeCubit.refresh()`.
- Bắt đầu ván mới từ màn chính ghi đè ván lưu.

**Ngoài phạm vi:** nhiều ván lưu, lịch sử ván đã chơi, đồng bộ cloud.

**File được sửa:** `lib/core/storage/**`, `lib/main.dart`, `lib/app.dart`, `lib/features/**`, `test/**`, `docs/architecture.md`.

**Package được phép:** `shared_preferences: 2.5.6`; dev: `shared_preferences_platform_interface: 2.4.2`
(chỉ dùng `InMemorySharedPreferencesAsync` trong test).

**Tiêu chí nghiệm thu**
- [ ] Test repository: lưu → đọc lại đúng; JSON hỏng, version lạ, nước đi không hợp lệ → `null` và dữ liệu bị xóa.
- [ ] Test bloc: lưu sau mỗi nước/undo; xóa khi ván kết thúc; khôi phục ở lượt máy thì máy đi tiếp.
- [ ] Widget test màn chính: có ván lưu → hiện nút Tiếp tục; không có → ẩn.
- [ ] Thử thực tế trên Android: đi vài nước, tắt hẳn app, mở lại → tiếp tục đúng thế cờ.
