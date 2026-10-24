# Ghi chú review

Nơi tổng hợp ghi chú review **không chặn merge**. Agent không tự xử lý các ghi chú ở đây trừ khi chúng
đã được đưa vào một task. Quy tắc review: [`docs/tasks/README.md`](tasks/README.md#quy-tắc-review).

Cách dùng file này:

- **Còn mở** — mỗi mục một dòng: việc gì, task liên quan, ai xử lý. Đây là phần duy nhất cần đọc thường xuyên.
- **Kiểm tra trên thiết bị** — các UI cần owner chạy thử trên Android, gộp làm một lần trước mỗi mốc phát hành.
- **Lịch sử** — mỗi task đã review còn 1–3 dòng kết luận và quyết định. Chi tiết nằm trong PR tương ứng.

Mẫu ghi một lần review mới (thêm lên đầu phần *Lịch sử*, ghi chú chưa xử lý thì đưa lên *Còn mở*):

```markdown
### T<x.y> — <tên task> (PR #<n>, review YYYY-MM-DD)
Kết luận: Đạt / Cần sửa trước khi merge. Xác thực: <đã chạy gì, kết quả chính>.
Quyết định: <chấp nhận / đưa vào task / bỏ qua> — <mục>.
```

---

## Còn mở

| Việc | Liên quan | Ai |
|---|---|---|
| Khi cân chỉnh độ khó AI: `tool/ai_match.dart` nên nhận `seed` để so sánh có kiểm soát (Medium/Easy hiện không seed nên ván không tái hiện được) | T3.3 · chưa gắn task | owner tạo task khi cần |

## Kiểm tra trên thiết bị (owner, trước mốc v0.5)

- [ ] Dialog phong cấp: hiện đủ 4 quân, chọn đúng, chạm ngoài để hủy (T2.3)
- [ ] Danh sách nước đi cuộn theo nước mới; quân bị ăn và chênh lệch `+N` (T2.4)
- [ ] Nút Đi lại: disable đầu ván, đi lại đúng (T2.5)

---

## Lịch sử

### Quyết định owner (2026-10-24)
- Chấp nhận: `GamePage.startPosition` (T2.3); `Fen.format` chuẩn hóa thứ tự quyền nhập thành (T2.1);
  `San.format` ném `ArgumentError` khi ô xuất phát trống (T2.4); quiescence chuyển fail-soft trong PR T3.3.
- Đưa vào T3.0: các mục ở bảng *Còn mở*.
- Bỏ qua: các nit phong cách / hiệu năng biên (liệt kê theo task bên dưới).
- Quy trình: chỉ merge sau review; không tạo nhánh chồng; PR của task tự đổi trạng thái thành `done`.

### Quy ước owner (2026-10-23)
- Review **đạt, có thể merge** → reviewer kèm câu lệnh giao task tiếp theo cho agent ở cuối phần review.

### T3.3 — Mức độ khó + service `ChessAi` chạy Isolate (PR #10, review 2026-10-23/24)
Kết luận: code đạt đặc tả; số liệu `ai_match` ban đầu Medium thua Easy **0–1–9** → tìm ra **lỗi của T3.2**:
điểm nút gốc của các nước bị cắt tỉa chỉ là cận trên (quiescence trả đúng bằng biên) nên `randomMarginCp`
chọn cả nước rất tệ (Medium đi `Qd3` mất hậu; thế có hậu treo chỉ ăn 1/30 seed).
Sửa trong PR #10: nút gốc tìm với cận dưới `alpha - randomMarginCp - 1` + test hồi quy. Sau sửa:
Medium–Easy 10–0, Hard–Medium 10–0; 125/125 test.
Bỏ qua: `IsolateChessAi` không có timeout — `search` đã tự dừng theo `timeLimit`, và isolate của `Isolate.run`
không hủy được từ ngoài; kết quả cũ do T3.4 bỏ qua theo `gameId`/`ply`.

### T3.2 — Thuật toán tìm nước đi (PR #9, review 2026-10-23, re-review sau `074d9a8`)
Kết luận: đạt sau khi sửa trong PR: thiếu quân = hòa 0 trong search (K+N–K, K+B–K, 2 tượng cùng màu ô = 0;
K+B–K+B khác màu ô = 20; K+R–K = 505), test mate-in-2 thuần, thứ tự sắp xếp nước, `rootScores` theo độ sâu
hoàn thành, bỏ dead code `isRoot`. 118/118 test.
Đưa vào T3.0: khóa lặp lại trong search khác ngữ nghĩa en passant của engine.
*(Lỗi chấm điểm nút gốc với `randomMarginCp` không được phát hiện ở review này — xem T3.3.)*

### T3.1 — Bàn cờ nội bộ tốc độ cao cho AI (PR #8, review 2026-10-23)
Kết luận: đạt. `perft_bench` 4,865,609 node / ~570 ms (mục tiêu < 10 s); 103/103 test.
Đưa vào T3.0: getter `board` trả mảng nội bộ sửa được.
Bỏ qua: bảng `_Zobrist` static lazy init; khóa en passant chỉ theo cột; `_moveBuffers` 64 ply rồi cấp phát mới;
ghi `undo.capturedPiece` 2 lần khi bắt tốt qua đường.

### T2.5 — Đi lại (PR #7, review 2026-10-23)
Kết luận: đạt (PR bị merge trước khi review — đã thêm luật "chỉ merge sau review").
Đưa vào T3.0: test undo khi đang chọn quân / chờ phong cấp. Bỏ qua: guard `history.length <= 1` lặp ở 2 chỗ.

### T2.4 — SAN, danh sách nước đi, quân bị ăn (PR #6, review 2026-10-23)
Kết luận: đạt. Đưa vào T3.0: nước phong cấp thiếu quân (`e7e8`) — kiểm tra bằng `ChessRules.isLegalMove`
thay vì `Move.fromUci` (không có thế cờ). Để Giai đoạn 5: `MoveList` cuộn bằng `jumpTo`.
Chấp nhận: `San.format` ném `ArgumentError`.

### T2.3 — Chọn quân khi phong cấp (PR #5, review 2026-10-23)
Kết luận: đạt. Chấp nhận: tham số `GamePage.startPosition`. Đưa vào T3.0: test dialog hiện đủ 4 lựa chọn.
Quy trình: nhánh T2.1 → T2.3 từng xếp chồng — đã merge theo thứ tự, đã thêm luật không tạo nhánh chồng.

### T2.2 — Luật hòa (PR #4, review 2026-10-23)
Kết luận: đạt. Đưa vào T3.0: `positionRepetitionKey` chép ~30 dòng của `Fen.format`.
Bỏ qua: `_ => SoundEffect.move` thay cho `GameStatus.playing =>`; chưa test thiếu quân hỗn hợp (K+B–K+N).

### T2.1 — FEN đầy đủ (PR #3, review 2026-10-23)
Kết luận: đạt. Đưa vào T3.0: `Fen.parse` chấp nhận chữ số liền nhau (`44`, `17`); số magic `49/56`.
Chấp nhận: quyền nhập thành không theo thứ tự được chuẩn hóa khi `format`.
