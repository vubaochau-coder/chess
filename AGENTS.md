# AGENTS.md

Quy tắc bắt buộc cho mọi AI agent (Claude Code, Codex, Copilot, Cursor…) và người làm việc trên repo này.
**Đọc hết file này trước khi làm bất cứ việc gì.** Khi file này mâu thuẫn với thói quen hoặc "best practice"
chung của bạn, file này thắng.

Thứ tự đọc khi nhận việc:

1. `AGENTS.md` (file này) — luật chung.
2. [`docs/architecture.md`](docs/architecture.md) — kiến trúc, chuẩn bloc, quy tắc hiệu năng.
3. [`docs/tasks/README.md`](docs/tasks/README.md) — quy trình làm task và danh sách task.
4. File đặc tả của **đúng task** bạn được giao (`docs/tasks/phase-N.md`, mục `TN.M`).

---

## 1. Luật vàng (đọc kỹ)

1. **Chỉ làm đúng một task được giao**, theo đặc tả trong `docs/tasks/`. Không có task → không code.
2. **Không làm gì nằm ngoài mục "Phạm vi"** của task, kể cả khi thấy "tiện tay": không refactor code khác,
   không đổi tên, không "cải thiện" UI, không nâng package, không sửa lint rule.
   Thấy vấn đề ngoài phạm vi → ghi vào mục *Ghi chú cho owner* trong mô tả PR, không sửa.
3. **Không tự suy luận quyết định sản phẩm.** Đặc tả thiếu, mơ hồ hoặc mâu thuẫn với code hiện tại →
   dừng phần đó và hỏi owner (hoặc ghi câu hỏi trong PR, đánh dấu task `blocked`). Không đoán.
4. **Các quyết định ở mục 2 là cố định.** Không đề xuất thay thế trong code, không "thử phương án khác".
5. **Task có mục "Đầu vào cần owner"** (ảnh icon, file âm thanh, secrets…) mà chưa có → không tự tạo
   asset giả để thay thế, đánh dấu `blocked`.
6. Một task = một nhánh = một PR. Không gộp nhiều task.
7. Chỉ coi là xong khi đạt toàn bộ *Definition of done* (mục 9) **và** toàn bộ *Tiêu chí nghiệm thu* của task.

## 2. Quyết định đã chốt (không được thay đổi)

| Chủ đề | Quyết định |
|---|---|
| App id | `com.chauvb.chess` — không bao giờ đổi `applicationId` / `namespace` |
| Nền tảng | Chỉ **Android**. Không sửa thư mục `ios/ web/ linux/ macos/ windows/` |
| Flutter | Phiên bản ghi trong `.fvmrc` (hiện 3.47.7), luôn chạy qua **FVM** |
| Version package | Ghim **chính xác** (không `^`, không range) — xem mục 6 |
| State management | `bloc` / `flutter_bloc` (Bloc cho màn hình, Cubit cho cài đặt đơn giản). Không Provider/Riverpod/GetX |
| Điều hướng | `Navigator` + `MaterialPageRoute`. Không go_router hay thư viện routing khác |
| Lưu trữ cục bộ | `shared_preferences` (khi task cho phép). Không Hive/Isar/sqflite |
| AI (PvE) | **Tự viết bằng Dart**, chạy trong Isolate. **Không** dùng Stockfish hay engine native/GPL |
| Biểu diễn bàn cờ công khai | `List<String>` 64 ô, index `x * 8 + y` (xem `docs/architecture.md`) |
| Ngôn ngữ UI | Tiếng Việt, hard-code trong widget (chưa làm đa ngôn ngữ) |
| Luật hòa | Lặp lại 3 lần và luật 50 nước **tự động** xử hòa (không cần "claim") |
| Phong cấp | Người chơi chọn Hậu/Xe/Tượng/Mã qua hộp thoại |

## 3. Môi trường

| Công cụ | Phiên bản |
|---|---|
| FVM | 3.x |
| Flutter | theo `.fvmrc` (3.47.7 stable, Dart 3.13) |
| Java | 17+ |
| Android Gradle Plugin / Gradle | 9.1 / 9.3 (Kotlin DSL) |

```bash
fvm install          # cài đúng Flutter theo .fvmrc
fvm use              # tạo .fvm/ (đã gitignore), IDE tự trỏ SDK vào .fvm/
```

**Luôn gọi lệnh qua `fvm`** (`fvm flutter …`, `fvm dart …`). Không dùng Flutter global.
Không sửa `.fvmrc` (nâng Flutter là một task riêng, chỉ owner tạo).

## 4. Lệnh thường dùng

```bash
fvm flutter pub get --enforce-lockfile   # cài package đúng như pubspec.lock
fvm dart format lib test                 # format
fvm flutter analyze                      # phải "No issues found!" (kể cả info)
fvm flutter test                         # toàn bộ test
fvm flutter run                          # chạy trên thiết bị / emulator Android
fvm flutter build apk --release
fvm flutter build appbundle              # AAB để upload Google Play
```

## 5. Quy tắc code

Lint được ép bởi `analysis_options.yaml` (strict-casts, strict-inference, strict-raw-types…).
**Không được sửa `analysis_options.yaml`**, không dùng `// ignore:` / `// ignore_for_file:` trừ khi task cho phép.

1. Import tuyệt đối `package:chess/...` (trừ `part` / `part of`). Test được import helper tương đối trong `test/`.
2. `lib/core/` **thuần Dart**: không import `package:flutter/...` (ngoại lệ duy nhất: `lib/core/audio/`
   và `lib/core/storage/` được dùng plugin). Engine/AI phải chạy được trong Isolate và test bằng `test()` thường.
3. Khai báo kiểu trả về cho mọi hàm; ưu tiên `final`, `const`; class dữ liệu bất biến.
4. Không `print`; debug tạm bằng `debugPrint` và xóa trước khi commit.
5. Đặt tên: file `snake_case.dart`, class `PascalCase`, biến/hàm `camelCase`, private bắt đầu bằng `_`.
6. Text cho người dùng: tiếng Việt. Tên biến/hàm: tiếng Anh. Comment: chỉ giải thích *tại sao*.
7. Bloc/state/widget theo đúng chuẩn trong [`docs/architecture.md`](docs/architecture.md) — đặc biệt
   mục "Quy tắc hiệu năng". Vi phạm = PR không đạt.
8. Không để code chết, TODO không có task, file không dùng.

## 6. Package & phiên bản

- Mọi package trong `pubspec.yaml` ghi **version chính xác** (`flutter_bloc: 9.1.1`), không `^`.
- Chỉ được thêm package **có tên trong mục "Package được phép" của task**, đúng version ghi ở đó.
  Task không ghi → không được thêm package nào.
- Không nâng / hạ version package có sẵn (nâng package là task riêng).
- Luôn commit `pubspec.yaml` và `pubspec.lock` cùng nhau. CI chạy `pub get --enforce-lockfile`.
- Asset (âm thanh, ảnh, font, SVG quân cờ) phải có giấy phép cho phép phát hành thương mại; ghi nguồn
  và giấy phép vào `assets/LICENSES.md` khi thêm.

## 7. Test

- Test đặt trong `test/` theo cấu trúc song song với `lib/`.
- `lib/core/engine/`: mọi thay đổi phải giữ **toàn bộ perft test** xanh. **Không được sửa giá trị kỳ vọng
  của perft** — sai perft nghĩa là code sai.
- Bloc: test bằng `bloc_test` + `mocktail` (xem `test/features/game/bloc/chess_game_bloc_test.dart`).
- Widget mới có tương tác: có widget test.
- Bug fix: thêm test tái hiện bug trước khi sửa.
- Mock dùng chung đặt ở `test/helpers/`.

## 8. Git & PR

- Nhánh: `task/<mã-task>-<mô-tả-ngắn>`, ví dụ `task/T2.1-fen`.
- Commit message tiếng Anh, dạng mệnh lệnh: `Add FEN parser and formatter`.
- Tiêu đề PR: `[T2.1] <tên task>`.
- Mô tả PR theo mẫu:

  ```markdown
  ## Task
  T2.1 — <tên task> (link tới mục trong docs/tasks/phase-N.md)

  ## Đã làm
  - ...

  ## Tiêu chí nghiệm thu
  - [x] <copy từng tiêu chí trong task, đánh dấu>

  ## Cách kiểm tra
  - ...

  ## Ghi chú cho owner
  - Câu hỏi / vấn đề ngoài phạm vi phát hiện được (không sửa)
  ```

- Không push trực tiếp lên `main`. Không force-push nhánh người khác.
- Cập nhật trạng thái task trong `docs/tasks/README.md` ngay trong PR.

## 9. Definition of done

- [ ] `fvm dart format --output=none --set-exit-if-changed lib test` không đổi gì
- [ ] `fvm flutter analyze` → No issues found
- [ ] `fvm flutter test` pass toàn bộ
- [ ] `fvm flutter build apk --release` build được
- [ ] Đạt toàn bộ *Tiêu chí nghiệm thu* của task
- [ ] Đã chạy thử trên Android (emulator/máy thật) nếu task có thay đổi UI hoặc native
- [ ] Cập nhật trạng thái task trong `docs/tasks/README.md`; cập nhật `docs/architecture.md`
      nếu task thêm thành phần kiến trúc mới (layer, repository, bloc mới)

## 10. Tuyệt đối không

- Đổi `applicationId` / `namespace`, sửa `.fvmrc`, sửa `analysis_options.yaml`, sửa `.github/workflows/`
  (trừ task yêu cầu).
- Sửa giá trị kỳ vọng của perft test, hoặc xóa/skip test để CI xanh.
- Đặt logic luật cờ / AI trong widget hoặc bloc (thuộc về `lib/core/`).
- Commit keystore (`*.jks`, `*.keystore`), `key.properties`, mật khẩu, API key, `local.properties`, file build.
- Dùng asset không rõ giấy phép, hoặc tạo asset giả thay cho asset owner phải cung cấp.
- Thêm tính năng không có trong task (analytics, quảng cáo, đăng nhập, mạng…).
