# Task

Đây là danh sách việc **duy nhất** được phép triển khai. Mỗi task có đặc tả đầy đủ trong file của
giai đoạn tương ứng. Agent chỉ làm task được owner giao, theo đúng thứ tự phụ thuộc.

## Quy trình cho agent

1. Đọc `AGENTS.md`, `docs/architecture.md`, rồi mục task được giao.
2. Kiểm tra cột **Phụ thuộc**: mọi task phụ thuộc phải ở trạng thái `done`. Chưa xong → dừng, báo owner.
3. Kiểm tra **Đầu vào cần owner** (nếu có). Chưa có → đánh dấu `blocked`, báo owner, dừng.
4. Tạo nhánh `task/<mã>-<mô-tả>` từ `main` mới nhất.
5. Làm **đúng phạm vi**. Gặp điểm đặc tả không nói tới → hỏi, không đoán (xem AGENTS.md mục 1).
6. Đạt Definition of done (AGENTS.md mục 9) + mọi tiêu chí nghiệm thu của task.
7. Sửa cột **Trạng thái** của task trong bảng dưới thành `review`, mở PR theo mẫu trong AGENTS.md mục 8.
   Owner merge xong sẽ đổi thành `done`.

Trạng thái: `todo` · `in-progress` · `blocked` · `review` · `done`

Mỗi đặc tả task có các mục:

- **Mục tiêu** — kết quả cần đạt.
- **Phạm vi** — những việc PHẢI làm. Chỉ làm những việc này.
- **Ngoài phạm vi** — những việc KHÔNG được làm trong task này (thường vì thuộc task khác).
- **Thiết kế bắt buộc** — tên class/API/hành vi đã chốt; phải làm đúng như vậy.
- **File được sửa** — chỉ được tạo/sửa các file/thư mục này (cộng với `docs/tasks/README.md`).
- **Package được phép** — package được thêm, đúng version. Không ghi = không được thêm package.
- **Đầu vào cần owner** — thứ owner phải cung cấp trước.
- **Tiêu chí nghiệm thu** — checklist để review; tất cả phải đạt.

## Danh sách

### Giai đoạn 1 — Chuẩn bị phát hành ([phase-1.md](phase-1.md))

| Mã | Task | Phụ thuộc | Đầu vào owner | Trạng thái |
|---|---|---|---|---|
| T1.1 | Cấu hình build release (R8, AAB trong CI) | — | — | todo |
| T1.2 | Icon app và splash screen | — | Ảnh icon | todo |
| T1.3 | Thay bộ âm thanh có giấy phép | — | File âm thanh | todo |
| T1.4 | Ký app trong CI bằng GitHub Secrets | T1.1 | Keystore + secrets | todo |

### Giai đoạn 2 — Hoàn thiện lõi game ([phase-2.md](phase-2.md))

| Mã | Task | Phụ thuộc | Đầu vào owner | Trạng thái |
|---|---|---|---|---|
| T2.1 | FEN đầy đủ (parse/format) | — | — | review |
| T2.2 | Luật hòa: 50 nước, lặp 3 lần, thiếu quân | T2.1 | — | review |
| T2.3 | Chọn quân khi phong cấp | — | — | review |
| T2.4 | Ký hiệu SAN, danh sách nước đi, quân bị ăn | T2.2, T2.3 | — | review |
| T2.5 | Đi lại (undo) | T2.4 | — | review |

### Giai đoạn 3 — PvE ([phase-3.md](phase-3.md))

| Mã | Task | Phụ thuộc | Đầu vào owner | Trạng thái |
|---|---|---|---|---|
| T3.1 | Bàn cờ nội bộ tốc độ cao cho AI | T2.2 | — | review |
| T3.2 | Thuật toán tìm nước đi | T3.1 | — | review |
| T3.3 | Mức độ khó + service `ChessAi` chạy Isolate | T3.2 | — | todo |
| T3.4 | Tích hợp AI vào game bloc | T3.3, T2.5 | — | todo |
| T3.5 | Màn hình chính chọn chế độ | T3.4 | — | todo |
| T3.6 | Đầu hàng | T3.4 | — | todo |
| T3.7 | Lưu và tiếp tục ván đang chơi | T3.5, T3.6 | — | todo |

### Giai đoạn 4 — Tùy biến giao diện ([phase-4.md](phase-4.md))

| Mã | Task | Phụ thuộc | Đầu vào owner | Trạng thái |
|---|---|---|---|---|
| T4.1 | Hạ tầng cài đặt + màn Cài đặt + chế độ sáng/tối | T3.5 | — | todo |
| T4.2 | Theme màu bàn cờ | T4.1 | — | todo |
| T4.3 | Tùy chọn hiển thị bàn cờ | T4.1 | — | todo |
| T4.4 | Bộ quân cờ | T4.1 | File SVG + giấy phép | todo |

### Giai đoạn 5 — Âm thanh & hiệu ứng ([phase-5.md](phase-5.md))

| Mã | Task | Phụ thuộc | Đầu vào owner | Trạng thái |
|---|---|---|---|---|
| T5.1 | Cài đặt âm thanh và rung | T4.1, T1.3 | — | todo |
| T5.2 | Bộ âm thanh có thể chọn | T5.1 | File âm thanh | todo |
| T5.3 | Animation di chuyển quân | T4.3 | — | todo |
| T5.4 | Kéo-thả quân | T5.3 | — | todo |
| T5.5 | Hiệu ứng chiếu và kết thúc ván | T5.3 | — | todo |

### Giai đoạn 6 — PvP ([phase-6.md](phase-6.md))

| Mã | Task | Phụ thuộc | Đầu vào owner | Trạng thái |
|---|---|---|---|---|
| T6.1 | Đồng hồ đánh cờ (chơi 2 người cùng máy) | T3.5 | — | todo |
| T6.x | PvP online | — | — | **chưa lên kế hoạch — không được làm** |

## Việc chỉ owner làm (agent không làm)

- Đăng ký tài khoản Google Play Console, điền Data safety, content rating, privacy policy, ảnh store.
- Tạo upload keystore, lưu trữ an toàn, đặt GitHub Secrets.
- Chọn và kiểm tra giấy phép asset (icon, âm thanh, bộ quân cờ).
- Tìm 12 tester và chạy closed testing 14 ngày.
- Tạo task mới, sửa đặc tả task, nâng Flutter/package.
