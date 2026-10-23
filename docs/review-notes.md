# Ghi chú review

Tổng hợp các ghi chú, nit và việc cần chỉnh (không chặn merge) từ các lần review task.
Mỗi task có một mục; các ghi chú đã xử lý được đánh dấu `[x]`.

Ghi chú không nằm trong phạm vi của task — owner quyết định xử lý hoặc bỏ qua,
khi xử lý nên gói vào một task/phần việc phù hợp (thường là task tiếp theo hoặc task dọn dẹp riêng).

---

## T3.2 — Thuật toán tìm nước đi (review 2026-10-23)

**Kết luận:** Đạt về tổng thể; có **1 lệch thiết kế bắt buộc cần sửa** (mục 1) — khuyến nghị sửa
trong PR trước khi merge vì là văn bản "Thiết kế bắt buộc", tuy ảnh hưởng thực tiễn nhỏ.

**Xác thực độc lập:** halfmove=100 → score 0 vs halfmove=0 → 505 (luật 50 nước trong search hoạt động);
deterministic không seed (no rng config) ✅; mate in 1 back-rank → d1d8 score 99999 ✅.
117/117 test pass, analyze/format sạch, APK build OK.

### Cần quyết định / xử lý

- [x] **[Nên sửa trong PR]** Thiếu quân **không** được tính hòa 0 trong search. Đặc tả: "Hòa (lặp lại
      tính cả history của ván, luật 50 nước, **thiếu quân**) = 0" — `isDraw` chỉ check 50 nước + lặp.
      Xác thực: K+N vs K trả score **330** thay vì 0. Đề xuất: thêm check thiếu quân vào `isDraw`
      (tái dùng logic 4 trường hợp của `ChessRules.isInsufficientMaterial`) + test.
- [x] Tiêu chí "chiếu hết 2 nước ở ≥ 3 thế": test #2 (`k7/8/1K6/8/8/8/1Q6/8 w`) chỉ assert
      "tìm thấy mate" trong khi thế đó có **mate in 1** — không chứng minh mate in 2. Nên thay bằng
      thế mate in 2 thuần (không có mate in 1).

### Không bắt buộc

- [x] Thứ tự sắp xếp nước: code xếp **phong cấp (800k) trên ăn quân (100k+)**, đặc tả ghi
      "ăn quân theo MVV-LVA → phong cấp". Chỉ ảnh hưởng hiệu quả sắp xếp, không ảnh hưởng đúng sai.
- [x] `rootScores` không xóa giữa các vòng iterative deepening — khi timeout giữa một depth,
      map chứa điểm trộn hai depth (ảnh hưởng biên cho `randomMarginCp`). bestMove/bestScore vẫn
      lấy từ depth hoàn thành nên đúng đặc tả.
- [ ] Khóa lặp lại trong search dùng zobrist thô (ô ep luôn tính khi có), hơi khác ngữ nghĩa khóa
      engine (chỉ tính ep khi bắt được) — chấp nhận được, T3.2 không bắt buộc chuẩn hóa.
- [x] `_negamax` có check `isRoot = ply == 0` nhưng hàm không bao giờ được gọi với ply 0 — dead code.

---

## T3.1 — Bàn cờ nội bộ tốc độ cao cho AI (review 2026-10-23)

**Kết luận:** Đạt, có thể merge. PR #8 mở đúng mẫu, có benchmark. Review trước merge lần này ✅.

**Xác thực độc lập:** chạy lại `fvm dart run tool/perft_bench.dart` → 4,865,609 nodes / 576ms
(~8.4M nps), khớp PR (564ms), xa dưới mục tiêu 10s. 103/103 test pass, analyze/format sạch, APK build OK.

### Không bắt buộc

- [ ] Getter `board` trả trực tiếp `Int8List` nội bộ (mutable) — chỉ dùng trong test; nếu dùng ngoài
      AI nên trả bản copy/unmodifiable để tránh sửa ngoài ý muốn.
- [ ] `_Zobrist` là static mutable state với lazy init — thực chất là bảng hằng, chấp nhận được cho
      hiệu năng; chỉ ghi nhận để nhất quán về phong cách.
- [ ] Zobrist en passant chỉ dùng cột (không full-square) — đủ đúng cho TT nhờ `sideToMove`; nếu T3.2
      tái dùng khóa này cho phát hiện lặp lại trong search sẽ hơi khác ngữ nghĩa khóa engine
      (engine chỉ tính ô ep khi bắt được) — T3.2 tính hòa qua engine history nên không vấn đề.
- [ ] `_moveBuffers` 64 ply, ply ≥ 64 thì fallback cấp phát list mới (đúng, chỉ chậm hơn) — depth 64 +
      quiescence có thể vượt; an toàn, chỉ ghi nhận.
- [ ] `makeMove` với en passant ghi `undo.capturedPiece` 2 lần (lưu `_board[to]` rồi ghi đè bằng
      tốt bị ăn) — vô hại, hơi khó đọc.

---

## T2.5 — Đi lại (undo) (review 2026-10-23)

**Kết luận:** Đạt. *Lưu ý: PR #7 đã được merge trước khi review — không phát hiện vấn đề cần sửa,
nhưng về quy trình nên để review xong mới merge.*

### Cần quyết định / xử lý

- [ ] **[Owner]** Bảng trạng thái trong `docs/tasks/README.md` trên main vẫn ghi T2.1…T2.5 = `review`
      (T2.5 được nhánh này đổi thành `review` trong lúc nó đã merge). Cần owner cập nhật tất cả thành
      `done` — Giai đoạn 2 đã đủ 5/5 task merge.

### Không bắt buộc

- [ ] Guard `history.length <= 1` xuất hiện ở cả bloc handler và `state.undo()` (return `this`) —
      nhân đôi vô hại, có thể bỏ một chỗ.
- [ ] Chưa có test cho undo khi đang có ô đang chọn / đang chờ phong cấp giữa ván — ngoài tiêu chí
      nghiệm thu; hành vi theo code là xóa selection + pendingPromotion (đúng ý đặc tả).

---

## T2.4 — Ký hiệu SAN, danh sách nước đi, quân bị ăn (review 2026-10-23)

**Kết luận:** Đạt, có thể merge. PR #6 đã mở đúng mẫu, base `main` đúng (T2.1–T2.3 đã merge qua #3/#4/#5).

### Cần quyết định / xử lý

- [ ] **[Owner]** Bảng trạng thái trong `docs/tasks/README.md` trên main vẫn ghi T2.1/T2.2/T2.3 =
      `review` — việc đổi thành `done` là việc của owner sau khi merge (theo quy trình), cần cập nhật.
- [ ] DoD yêu cầu chạy thử trên Android khi task đổi UI — có UI mới (MoveList, CapturedPieces);
      reviewer không xác thực được, owner cần chạy thử.

### Không bắt buộc

- [ ] `Move.fromUci('e7e8')` (nước phong cấp thiếu ký tự quân) được chấp nhận — đặc tả không yêu cầu
      từ chối, chỉ ghi nhận độ lỏng.
- [ ] `MoveList` cuộn tới cuối bằng `jumpTo` (giật) — có thể đổi `animateTo` để mượt hơn nếu muốn.
- [ ] `San.format` ném `ArgumentError` khi ô xuất phát trống — đặc tả không nói gì; hành vi hợp lý,
      chỉ ghi nhận để nhất quán với `Fen.parse` (ném `FormatException`).

---

## T2.3 — Chọn quân khi phong cấp (review 2026-10-23)

**Kết luận:** Đạt, có thể merge.

### Cần quyết định / xử lý

- [x] **[Quy trình]** Nhánh xếp chồng 3 tầng: main ← T2.1 ← T2.2 ← T2.3 (T2.1, T2.2 vẫn `review`,
      chưa vào main). Nên merge theo thứ tự T2.1 → T2.2 → T2.3 sớm để chồng không tiếp tục cao lên.
      *(Đã xử lý: cả ba đã merge qua #3/#4/#5.)*
- [ ] `GamePage` thêm tham số `startPosition` (dùng cho widget test) — không có trong đặc tả nhưng
      nằm trong các file được phép sửa, vô hại khi không truyền. Cần owner xác nhận chấp nhận.
- [ ] DoD yêu cầu chạy thử trên Android khi task đổi UI (dialog mới là UI) — reviewer không xác thực
      được phần này; owner cần chạy thử dialog phong cấp trên thiết bị/emulator.

### Không bắt buộc

- [ ] Widget test chỉ kiểm tra 1 trong 4 lựa chọn (Mã), chưa assert dialog render đúng 4 nút
      (tiêu chí ghi "dialog hiện 4 lựa chọn"). Có thể thêm `find.byType(PieceView, findsNWidgets(4))`.

---

## T2.2 — Luật hòa: 50 nước, lặp 3 lần, thiếu quân (review 2026-10-23)

**Kết luận:** Đạt, có thể merge (sau T2.1).

### Cần quyết định / xử lý

- [ ] **[Quy trình]** T2.1 vẫn đang `review` chưa merge vào `origin/main`, nhánh `task/T2.2-draw-rules`
      xếp chồng lên commit T2.1. Quy định yêu cầu phụ thuộc `done` mới được làm. Việc cần làm:
      merge T2.1 trước, sau đó merge T2.2 (PR T2.2 để base = nhánh T2.1, hoặc đợi T2.1 vào main rồi
      rebase). Nếu owner duyệt làm chồng thì bỏ qua.
- [ ] `positionRepetitionKey` trong `lib/core/engine/chess_rules.dart` copy phần serialize bàn cờ +
      nhập thành của `Fen.format` (~30 dòng trùng). Có thể tái dùng `Fen.format` rồi chỉ ghi đè
      trường en passant. Nit bảo trì.
- [ ] `_ => SoundEffect.move` trong `chess_game_bloc.dart` bớt tường minh so với
      `GameStatus.playing =>` trước đây. An toàn vì đã early-return khi `isGameOver`, nit thôi.

### Không bắt buộc

- [ ] Chưa có test cho thế thiếu quân hỗn hợp (K+B–K+N, K+N–K+N) — rơi vào nhánh `false` mặc định,
      không bắt buộc theo đặc tả.

---

## T2.1 — FEN đầy đủ (parse/format) (review 2026-10-23)

**Kết luận:** Đạt, có thể merge.

### Cần quyết định / xử lý

- [ ] `Fen.parse` lỏng với số ô trống nhiều chữ số có tổng đúng 8: `44`, `17`, `22`… được chấp nhận
      (chuẩn FEN chỉ cho 1 chữ số). Không thuộc các case lỗi đặc tả liệt kê nên không sai, nhưng
      T2.2 dựa vào FEN — nếu muốn chặt thì xử lý luôn trong `lib/core/engine/fen.dart`.
- [ ] Castling không theo thứ tự (vd `QKkq`) được parse OK, nhưng `format` chuẩn hóa thành `KQkq`
      → round-trip đổi chuỗi với FEN không chuẩn. Đặc tả chỉ yêu cầu round-trip 6 FEN liệt kê
      nên chấp nhận được — cần owner xác nhận không vấn đề.

### Không bắt buộc

- [ ] Nit: `fen.dart` dùng số magic `49/56` kèm comment `// '1'..'8'` — có thể ghi hằng
      `'1'.codeUnitAt(0)` cho dễ đọc.
- [x] Nhánh chỉ tồn tại local lúc review — đã push, nhớ mở PR theo mẫu AGENTS.md mục 8.
      *(Đã xử lý: merge qua #3.)*
