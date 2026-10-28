# Giai đoạn 4 — Tùy biến giao diện

Mục tiêu giai đoạn: màn Cài đặt; đổi chế độ sáng/tối, màu bàn cờ, tùy chọn hiển thị, bộ quân cờ.
Mọi cài đặt được lưu và áp dụng ngay, không cần khởi động lại app.

Quy ước chung:
- Cài đặt nằm trong **một** class `AppSettings` (thuần Dart) và **một** `SettingsCubit` cấp app.
  Task sau chỉ thêm field vào đây, không tạo cubit/repository cài đặt thứ hai.
- Widget đọc cài đặt bằng `BlocSelector<SettingsCubit, AppSettings, T>` chọn đúng field cần
  (không `BlocBuilder` cả settings).

---

## T4.1 — Hạ tầng cài đặt + màn Cài đặt + chế độ sáng/tối

**Thiết kế bắt buộc**
- `lib/core/settings/app_settings.dart`: `final class AppSettings extends Equatable` (bất biến, `copyWith`,
  `toJson`/`fromJson` viết tay). Field đầu tiên: `themeMode` kiểu `AppThemeMode { system, light, dark }`
  (enum riêng, thuần Dart; mặc định `system`). `fromJson`: field thiếu/sai kiểu → giá trị mặc định của field đó
  (không ném lỗi).
- `lib/core/storage/settings_repository.dart`:
  ```dart
  abstract interface class SettingsRepository { AppSettings load(); Future<void> save(AppSettings settings); }
  final class SharedPrefsSettingsRepository implements SettingsRepository { ... } // key 'settings_v1'
  ```
  Dùng chung `SharedPreferencesWithCache` đã tạo trong `main()` (thêm key vào allowList).
- `lib/features/settings/cubit/settings_cubit.dart`: `SettingsCubit extends Cubit<AppSettings>`; mỗi cài đặt một
  method `setXxx(value)` → emit + `save` (không await).
- `SettingsCubit` cung cấp **trên** `MaterialApp` (trong `ChessApp`). `MaterialApp` có `theme` (sáng) và
  `darkTheme` (`ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark)`),
  `themeMode` lấy bằng `BlocSelector`.
- `lib/features/settings/view/settings_page.dart`: `SettingsPage` — `AppBar` tiêu đề `Cài đặt`, danh sách theo nhóm.
  Nhóm `Giao diện` → mục `Chế độ màu` với 3 lựa chọn `Theo hệ thống` / `Sáng` / `Tối` (`SegmentedButton`).
- Lối vào: `IconButton(Icons.settings, tooltip: 'Cài đặt')` trên `AppBar` của `HomeView` và `GameView`.

**Ngoài phạm vi:** các cài đặt khác (T4.2+), đa ngôn ngữ, đặt lại cài đặt mặc định.

**File được sửa:** `lib/core/settings/**`, `lib/core/storage/**`, `lib/features/settings/**`, `lib/features/home/view/**`,
`lib/features/game/view/**`, `lib/app.dart`, `lib/main.dart`, `test/**`, `docs/architecture.md`.

**Package được phép:** không (đã có `shared_preferences` từ T3.7).

**Tiêu chí nghiệm thu**
- [ ] Test `AppSettings` JSON: round-trip; JSON rỗng/hỏng/sai kiểu → mặc định.
- [ ] Test cubit: đổi chế độ màu → emit + gọi `save`.
- [ ] Widget test: đổi sang `Tối` → `MaterialApp.themeMode == ThemeMode.dark`.
- [ ] Thử trên Android: đổi chế độ màu, tắt app, mở lại vẫn giữ.

---

## T4.2 — Theme màu bàn cờ

**Thiết kế bắt buộc**
- `lib/theme/board_theme.dart`:
  ```dart
  final class BoardColors { lightSquare, darkSquare, lightSelected, darkSelected, hint, check } // đều là Color, const
  enum BoardTheme { wood, green, blue, gray, purple; BoardColors get colors; String get label; }
  ```
  | Theme | label | light | dark | lightSelected | darkSelected | hint | check |
  |---|---|---|---|---|---|---|---|
  | wood | Gỗ | F2E1C3 | C3A082 | F9F07B | E2CF57 | 80361B | CCE53935 |
  | green | Xanh lá | EEEED2 | 769656 | F6F669 | BACA2B | 59000000 | CCE53935 |
  | blue | Xanh dương | DEE3E6 | 8CA2AD | E5EB9B | B8C46A | 59000000 | CCE53935 |
  | gray | Xám | E8E8E8 | A0A0A0 | F5F682 | B9CA43 | 59000000 | CCE53935 |
  | purple | Tím | EDE4F7 | 9F86C0 | F5F682 | C8B95A | 59000000 | CCE53935 |

  (Màu ghi dạng hex RRGGBB = alpha FF; 8 ký tự là AARRGGBB.)
- `AppSettings.boardTheme` (mặc định `wood`).
- `BoardPainter` và `HighlightPainter` nhận `BoardColors` qua constructor; `shouldRepaint` so sánh colors.
- `ChessBoard` lấy theme bằng `BlocSelector<SettingsCubit, AppSettings, BoardTheme>`.
- Xóa `lib/theme/colors.dart` sau khi chuyển hết sang `BoardTheme`.
- Màn Cài đặt, nhóm `Giao diện`: mục `Màu bàn cờ` — hàng các ô xem trước (2×2 ô vuông của theme + label),
  theme đang chọn có viền `colorScheme.primary`.

**Ngoài phạm vi:** tự chọn màu tùy ý, ảnh nền bàn cờ.

**File được sửa:** `lib/theme/**`, `lib/core/settings/**`, `lib/features/game/painter/**`, `lib/features/game/widgets/chess_board.dart`,
`lib/features/settings/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Đúng 5 theme với đúng mã màu trong bảng (test so sánh giá trị).
- [ ] Widget test: chọn theme khác → painter nhận màu mới.
- [ ] Không còn tham chiếu `ChessColors`.

---

## T4.3 — Tùy chọn hiển thị bàn cờ

**Thiết kế bắt buộc**
- `AppSettings` thêm: `showCoordinates` (true), `showLegalMoves` (true), `highlightLastMove` (true),
  `autoFlipInPvp` (false).
- Tọa độ: `CoordinatesPainter` (lớp tĩnh riêng trong `RepaintBoundary`) vẽ chữ cột `a–h` ở góc dưới-phải các ô hàng
  dưới cùng và số hàng `1–8` ở góc trên-trái các ô cột trái cùng, cỡ chữ `cell * 0.18`, màu chữ là màu ô
  tương phản (ô sáng dùng màu ô tối và ngược lại); đổi đúng khi bàn cờ lật.
- `showLegalMoves = false` → không vẽ chấm gợi ý (vẫn chọn/đi được). `highlightLastMove = false` → không tô nước vừa đi.
- Lật bàn cờ:
  - State bloc có `flipped` (khởi tạo `true` khi pve + người cầm Đen, ngược lại `false`); event `BoardFlipToggled`
    đảo giá trị. `IconButton(Icons.swap_vert, tooltip: 'Lật bàn cờ')` trên `AppBar` của `GameView`.
  - `autoFlipInPvp = true` và chế độ pvp → sau mỗi nước `flipped = !whiteToMove` (bên tới lượt ở phía dưới).
- Màn Cài đặt, nhóm `Bàn cờ`: 4 `SwitchListTile`: `Hiện tọa độ`, `Hiện nước đi hợp lệ`, `Tô nước vừa đi`,
  `Tự lật bàn khi chơi 2 người`.

**Ngoài phạm vi:** animation lật bàn, tọa độ bên ngoài viền bàn cờ.

**File được sửa:** `lib/core/settings/**`, `lib/features/game/**`, `lib/features/settings/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Widget test cho từng tùy chọn (bật/tắt thấy khác biệt).
- [ ] Test bloc: `BoardFlipToggled`; auto-flip trong pvp; không auto-flip trong pve.
- [ ] Lật bàn rồi chạm vẫn chọn đúng ô (widget test).

---

## T4.4 — Bộ quân cờ

**Đầu vào cần owner:** mỗi bộ quân gồm 12 file SVG tên `wK wQ wR wB wN wP bK bQ bR bB bN bP` (`.svg`), tên hiển thị
tiếng Việt của bộ, nguồn và giấy phép (cho phép dùng thương mại).

**Thiết kế bắt buộc**
- SVG đặt tại `assets/pieces/<tên-bộ>/`; khai báo asset trong `pubspec.yaml`; ghi nguồn vào `assets/LICENSES.md`.
- `lib/theme/piece_set.dart`: `enum PieceSet { classic, ...các bộ owner cung cấp; String get label; }`.
  `classic` = bộ hiện tại của `chess_vectors_flutter` (label `Cổ điển`, giữ nguyên làm mặc định).
- `AppSettings.pieceSet` (mặc định `classic`).
- `PieceView` nhận thêm `pieceSet`; `classic` vẽ như hiện tại, bộ khác dùng `SvgPicture.asset`.
- Hiệu năng: `_PiecesLayer` select `PieceSet` **một lần** rồi truyền xuống 64 ô; ô không tự select settings.
- Màn Cài đặt, nhóm `Giao diện`: mục `Bộ quân cờ` — mỗi bộ hiển thị xem trước vua trắng + mã đen + label.

**Ngoài phạm vi:** tải bộ quân từ mạng, quân cờ 3D/ảnh PNG.

**File được sửa:** `assets/pieces/**`, `assets/LICENSES.md`, `pubspec.yaml`, `pubspec.lock`, `lib/theme/**`,
`lib/core/settings/**`, `lib/features/game/widgets/**`, `lib/features/settings/**`, `test/**`.

**Package được phép:** `flutter_svg: 2.3.0`.

**Tiêu chí nghiệm thu**
- [ ] Mỗi bộ đủ 12 file, có dòng giấy phép trong `assets/LICENSES.md`.
- [ ] Widget test: đổi bộ quân → `PieceView` vẽ bằng `SvgPicture` với đúng asset.
- [ ] Đổi bộ quân trong lúc chơi không mất thế cờ.

---

## T4.5 — Giao diện cổ điển (đợt nâng cấp UI)

**Mục tiêu:** đổi toàn bộ app sang phong cách cổ điển sang trọng theo mockup owner đã duyệt
(tông nâu gỗ đậm / ngà / vàng đồng ở chế độ tối, giấy cũ / nâu đậm ở chế độ sáng; tiêu đề chữ có chân).

**Phạm vi**
- `lib/theme/app_theme.dart`: `abstract final class AppTheme { static ThemeData light(); static ThemeData dark(); }`
  — `ColorScheme` dựng tay theo bảng màu dưới, theme cho `AppBar`, `FilledButton`, `SegmentedButton`, `Card`,
  `Dialog`, `Divider`; tiêu đề (`display*`, `headline*`, `titleLarge`) dùng `fontFamily: 'serif'`.
  `ChessApp` dùng `AppTheme.light()` / `AppTheme.dark()` (bỏ `ColorScheme.fromSeed`).
- Màn chính: emblem viền đôi, tiêu đề chữ có chân, dòng phụ viết hoa giãn chữ, đường kẻ trang trí; nút
  `Tiếp tục ván đang chơi` dạng thẻ đặt ngay dưới tiêu đề; chọn chế độ bằng 2 thẻ (`Chơi với máy` / `2 người`);
  nhãn nhóm viết hoa màu nhấn (`Chế độ`, `Độ khó`, `Quân của bạn`); nút `Bắt đầu` cao, full width.
- Màn chơi: hàng người chơi phía trên và dưới bàn cờ (tên `Bạn`/`Máy` hoặc `Trắng`/`Đen` + màu quân, quân đã
  ăn, viền màu nhấn cho bên tới lượt); khung bàn cờ viền đồng; danh sách nước đi dạng dải ngang có kẻ trên/dưới,
  nước mới nhất tô màu nhấn; 3 nút điều khiển cỡ lớn có nhãn (`Ván mới`, `Đi lại`, `Đầu hàng`).
- Màn Cài đặt: nhãn nhóm viết hoa màu nhấn, nội dung trong thẻ, xem trước theme bàn cờ dạng lưới 5 ô.
- Dialog: phong cấp (4 ô có tên quân + nút `Hủy`), đầu hàng (icon, chữ căn giữa, nút xác nhận màu đỏ).

**Bảng màu**

| Token | Tối | Sáng |
|---|---|---|
| surface (nền) | `#17110D` | `#F6F0E4` |
| surfaceContainerLow (thẻ) | `#1E1712` | `#FFFBF3` |
| outlineVariant (viền) | `#3A2E24` | `#E2D5BE` |
| onSurface (chữ) | `#F2E8D5` | `#2A1E16` |
| onSurfaceVariant (chữ phụ) | `#B7A58A` | `#6F5E48` |
| primary (nút chính) | `#C8A15A` | `#2A1E16` |
| tertiary (nhãn nhóm, viền chọn) | `#C8A15A` | `#8A6A2F` |
| error (đầu hàng) | `#A4483A` | `#A4483A` |

**Ngoài phạm vi:** đổi màu theme bàn cờ (`BoardTheme`, T4.2), font tùy chỉnh (cần file font + giấy phép từ owner),
hộp thoại kết thúc ván (hành vi mới — task riêng), các cài đặt của T4.3/T5.x, đổi chuỗi trạng thái/tiêu đề đang có.

**File được sửa:** `lib/theme/**`, `lib/app.dart`, `lib/features/home/view/**`, `lib/features/game/view/**`,
`lib/features/game/widgets/**` (trừ `chess_board.dart`, `piece_view.dart`, `lib/features/game/painter/**`),
`lib/features/settings/view/**`, `test/**`, `docs/architecture.md`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Toàn bộ test hiện có vẫn xanh (chỉ được sửa finder nếu widget đổi kiểu, không bỏ kiểm tra hành vi).
- [ ] Test `AppTheme`: `light()`/`dark()` đúng `brightness` và đúng màu `primary`/`surface` theo bảng.
- [ ] Widget test màn chơi: hàng người chơi hiện đúng tên theo chế độ (pve: `Bạn`/`Máy`; pvp: `Trắng`/`Đen`).
- [ ] Không thêm `BlocBuilder` thiếu `buildWhen`; dữ liệu mới đọc bằng `BlocSelector` (architecture.md mục 5).
- [ ] Thử trên Android cả chế độ sáng và tối.

---

## T4.6 — Hoàn thiện giao diện theo mockup (gộp T4.3, T5.1, hộp thoại kết thúc ván)

**Quyết định owner (2026-10-28):** làm chung một PR: T4.3, T5.1, phần hộp thoại kết thúc ván của T5.5 và các
chỗ lệch mockup còn lại. Âm thanh vẫn dùng bộ file hiện có (bộ có giấy phép là việc của T1.3).

**Phạm vi**
- T4.3 và T5.1 theo đúng đặc tả của từng task, với một khác biệt: tự lật bàn khi chơi 2 người được tính ở
  `GameView` (kết hợp state `flipped` của bloc với cài đặt) để bloc không phụ thuộc `SettingsCubit`.
- T5.5, chỉ phần `GameOverDialog` (mở sau 500 ms bằng `BlocListener`): lý do kết thúc, kết quả theo góc nhìn
  người chơi (`Bạn đã thắng` / `Bạn đã thua` / `Trắng thắng` / `Đen thắng` / `Hòa`), số nước; nút `Xem bàn cờ`,
  `Ván mới`, `Về màn chính`. Nhấp nháy ô bị chiếu và pháo giấy vẫn thuộc T5.5.
- Màn chính: thẻ `Tiếp tục ván đang chơi` hiện chế độ, số nước, lượt đi; tiêu đề `Cờ Vua`; dòng phụ và nhãn nhóm
  viết hoa giãn chữ; nút `Học chơi cờ` dạng viên có viền.
- Màn chơi: tiêu đề 2 dòng (`Chơi với máy` + mức độ / `2 người`); nhãn lượt đi trong hàng người chơi; avatar
  robot cho máy, Vua theo màu quân cho người; 3 nút điều khiển chia đều, icon và chữ trong cùng nút; nút `Lật bàn cờ`;
  hộp thoại đầu hàng hai nút chia đều.
- Bài học: tọa độ trên bàn cờ bài học (theo cài đặt); nút `Bài tiếp: <tên bài>`.

**Ngoài phạm vi:** font tùy chỉnh, đổi màu theme `Gỗ`, hiệu ứng nhấp nháy/pháo giấy, bộ âm thanh mới.

**Tiêu chí nghiệm thu**
- [ ] Tiêu chí của T4.3 và T5.1.
- [ ] Widget test: chiếu hết → sau 500 ms có `GameOverDialog`; `Ván mới` reset ván.
- [ ] Test cũ chỉ sửa ở chỗ chữ hiển thị đổi theo mockup (tiêu đề, nhãn viết hoa, nút `Bài tiếp`).
