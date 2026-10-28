# Giai đoạn 7 — Hướng dẫn người mới

Mục tiêu giai đoạn: người chưa biết chơi cờ học được luật và vài mẹo cơ bản ngay trong app, có bàn cờ để thử đi.

---

## T7.1 — Màn hướng dẫn người mới

**Mục tiêu:** màn `Học chơi cờ` gồm 17 bài trong 4 chương, mỗi bài có giải thích, bàn cờ minh họa chạm để đi
thử, và (nếu có) thử thách được chấm đúng/sai. Theo mockup owner đã duyệt (artboard "Học chơi cờ").

**Quyết định owner:** mọi bài mở tự do (không khóa theo thứ tự); tiến độ lưu bằng `shared_preferences`;
bài không có thử thách vẫn chạm đi thử được và hoàn thành khi bấm `Tiếp`/`Hoàn thành`.

**Thiết kế bắt buộc**
- `lib/core/tutorial/lesson.dart` (thuần Dart): `Lesson` (id, chương, tiêu đề, mô tả ngắn, nội dung, FEN, ô tô sáng,
  thử thách tùy chọn) và `LessonChallenge` với 4 loại: `reach` (đưa quân tới ô trong tối đa N nước),
  `giveCheck`, `checkmate`, `playMove` (một trong các nước UCI cho trước).
- `lib/core/tutorial/lesson_catalog.dart`: `LessonCatalog.chapters` + `LessonCatalog.lessons` — nội dung 17 bài:
  1. Các quân cờ: Bàn cờ và cách xếp quân, Vua, Hậu, Xe, Tượng, Mã, Tốt.
  2. Luật đặc biệt: Nhập thành, Bắt tốt qua đường, Phong cấp.
  3. Kết thúc ván: Chiếu, Chiếu hết, Các trường hợp hòa.
  4. Mẹo cơ bản: Giá trị các quân, Kiểm soát trung tâm, Phát triển quân, Bảo vệ Vua.
- `lib/core/tutorial/lesson_board.dart`: `LessonBoard` bất biến — `start(lesson)`, `tap(square)` dùng `ChessRules`
  (chỉ quân Trắng được đi; với bài `reach`/không thử thách, sau mỗi nước vẫn tới lượt Trắng; phong cấp tự chọn Hậu).
  Kết quả `LessonResult { playing, success, failed }`.
- `lib/core/storage/tutorial_progress_repository.dart`: `TutorialProgressRepository { Set<String> load(); Future<void> save(Set<String>); }`,
  `SharedPrefsTutorialProgressRepository` (key `tutorial_progress_v1`, dữ liệu hỏng → rỗng), `InMemoryTutorialProgressRepository`.
  Đăng ký trong `ChessApp`; thêm key vào `allowList` trong `main()`.
- `lib/features/tutorial/`: `TutorialCubit` (tập bài đã xong, `markCompleted`), `LessonCubit` (bọc `LessonBoard`),
  `TutorialPage` (danh sách chương/bài + thẻ tiến độ), `LessonPage` (nội dung, thử thách, bàn cờ, `Làm lại`, `Bài tiếp`).
  Bàn cờ bài học dùng lại `BoardPainter`, `HighlightPainter`, `PieceView` và theme bàn cờ trong Cài đặt.
- Lối vào: nút `Học chơi cờ` trên `AppBar` màn chính.

**Ngoài phạm vi:** bài học tải từ mạng, câu đố nhiều nước có máy đáp trả, âm thanh riêng cho bài học, khóa bài.

**File được sửa:** `lib/core/tutorial/**`, `lib/core/storage/**`, `lib/features/tutorial/**`, `lib/features/home/view/**`,
`lib/app.dart`, `lib/main.dart`, `test/**`, `docs/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test catalog: mọi FEN hợp lệ, có đủ 2 Vua; mọi thử thách giải được (reach: tới được trong N nước;
      giveCheck/checkmate: tồn tại nước thỏa mãn; playMove: mọi nước UCI hợp lệ).
- [ ] Test `LessonBoard` cho từng loại thử thách (thành công và thất bại).
- [ ] Test repository: lưu/đọc, dữ liệu hỏng → rỗng.
- [ ] Widget test: mở danh sách từ màn chính; hoàn thành bài Mã bằng cách chạm → báo thành công và tiến độ tăng.
- [ ] Thử trên Android.
