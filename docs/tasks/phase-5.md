# Giai đoạn 5 — Âm thanh & hiệu ứng

Mục tiêu giai đoạn: tùy chỉnh âm thanh/rung, chọn bộ âm thanh, animation di chuyển, kéo-thả, hiệu ứng kết thúc ván.

Quy ước chung:
- Cài đặt mới thêm vào `AppSettings` / `SettingsCubit` có sẵn (T4.1).
- Animation không được emit state bloc theo frame; dùng animation cục bộ trong widget
  (xem `docs/architecture.md` mục 5). Không thêm package animation/hiệu ứng.

---

## T5.1 — Cài đặt âm thanh và rung

**Thiết kế bắt buộc**
- `AppSettings` thêm: `soundEnabled` (true), `soundVolume` (double 0..1, mặc định 0.8), `hapticsEnabled` (true).
- Interface đổi thành `void play(SoundEffect effect, {double volume = 1.0})`; `AudioPoolSoundPlayer` truyền
  `volume` vào `pool.start(volume:)`.
- `lib/core/audio/feedback_sound_player.dart`: `final class FeedbackSoundPlayer implements SoundPlayer` bọc một
  `SoundPlayer` khác và một hàm `AppSettings Function() readSettings`:
  - `soundEnabled = false` → không phát; ngược lại phát với `volume: soundVolume`.
  - `hapticsEnabled = true` → `HapticFeedback.selectionClick()` cho `select`; `lightImpact()` cho `move`, `castle`,
    `promote`; `mediumImpact()` cho `capture`, `check`, `gameEnd`; `illegal` không rung.
- `ChessApp` đăng ký `SoundPlayer` là `FeedbackSoundPlayer(AudioPoolSoundPlayer(), readSettings: () => settingsCubit.state)`.
  Bloc **không** đổi gì (vẫn chỉ biết `SoundPlayer`).
- Màn Cài đặt, nhóm `Âm thanh`: `SwitchListTile` `Âm thanh`; `Slider` `Âm lượng` (disable khi tắt âm thanh,
  thả tay thì phát thử `SoundEffect.move`); `SwitchListTile` `Rung`.

**Ngoài phạm vi:** bộ âm thanh (T5.2), nhạc nền.

**File được sửa:** `lib/core/audio/**`, `lib/core/settings/**`, `lib/features/settings/**`, `lib/app.dart`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Test `FeedbackSoundPlayer` (mock inner player): tắt âm thanh → không gọi `play`; volume truyền đúng;
      rung đúng loại theo bảng (mock `SystemChannels.platform` hoặc tách hàm haptic để inject).
- [ ] Test bloc hiện có vẫn xanh, không phải sửa.

---

## T5.2 — Bộ âm thanh có thể chọn

**Đầu vào cần owner:** mỗi bộ âm thanh mới gồm đủ 8 file (`select, illegal, move, capture, castle, check, promote,
game_end`), tên hiển thị, nguồn và giấy phép.

**Thiết kế bắt buộc**
- File đặt tại `assets/audio/<tên-bộ>/` (giống `standard/` của T1.3); ghi nguồn vào `assets/LICENSES.md`.
- `lib/core/audio/sound_pack.dart`: `enum SoundPack { standard, ...; String get label; }` (`standard` label `Mặc định`).
- `SoundEffect` có `String assetFor(SoundPack pack)` thay cho field `asset` cố định.
- `AppSettings.soundPack` (mặc định `standard`). `FeedbackSoundPlayer` truyền pack hiện tại xuống
  (interface: `play(effect, {volume, pack})`, mặc định `standard`). `AudioPoolSoundPlayer` giữ pool theo cặp (pack, effect).
- Màn Cài đặt, nhóm `Âm thanh`: mục `Bộ âm thanh`; chọn bộ nào thì phát thử `move` của bộ đó.

**Ngoài phạm vi:** tải âm thanh từ mạng, âm thanh tùy chỉnh của người dùng.

**File được sửa:** `assets/audio/**`, `assets/LICENSES.md`, `pubspec.yaml`, `lib/core/audio/**`, `lib/core/settings/**`,
`lib/features/settings/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Mỗi bộ đủ 8 file, có giấy phép.
- [ ] Test: đổi bộ → `AudioPoolSoundPlayer` tạo pool với đúng asset.

---

## T5.3 — Animation di chuyển quân

**Thiết kế bắt buộc**
- `AppSettings.animationsEnabled` (true). Nhóm `Giao diện` thêm `SwitchListTile` `Hiệu ứng chuyển động`.
- Khi `moves` dài thêm đúng 1 (nước đi của người hoặc máy, **không** áp dụng cho undo/ván mới/khôi phục):
  quân trượt từ ô đi tới ô đến trong **150 ms**, `Curves.easeOut`; nhập thành thì xe trượt đồng thời;
  phong cấp: tốt trượt rồi hiện quân mới; quân bị ăn biến mất khi animation kết thúc.
- Kiến trúc: lớp mới `MoveAnimationLayer` (StatefulWidget có `AnimationController`) nằm trên `_PiecesLayer` trong
  `Stack` của `ChessBoard`, nghe bằng `BlocListener` (`listenWhen` theo độ dài `moves`). Trong lúc chạy, ô đích
  (và ô xe đích khi nhập thành) ẩn quân thật bằng một `ValueNotifier<Set<int>>` cục bộ của `ChessBoard`
  mà `_SquarePiece` lắng nghe — **không** đưa trạng thái animation vào bloc.
- `animationsEnabled = false` → không animation.

**Ngoài phạm vi:** kéo-thả (T5.4), animation lật bàn, hiệu ứng ăn quân.

**File được sửa:** `lib/core/settings/**`, `lib/features/game/widgets/**`, `lib/features/settings/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Widget test: giữa animation (pump 75 ms) quân nằm giữa 2 ô; sau 150 ms ở ô đích; undo không animation.
- [ ] Nhập thành: xe và vua cùng trượt.
- [ ] Đo bằng DevTools/`flutter run --profile` trên Android: không có frame > 16 ms khi đi quân (ghi kết quả trong PR).

---

## T5.4 — Kéo-thả quân

**Thiết kế bắt buộc**
- Xử lý ở cấp bàn cờ (`onPanStart/Update/End` trên `GestureDetector` hiện có), **không** dùng `Draggable` cho từng ô.
- Bắt đầu kéo trên quân được phép đi → nếu chưa chọn thì gửi `SquareTapped(from)` (hiện nước hợp lệ);
  quân kéo hiển thị phóng to ×1.2 theo ngón tay ở lớp overlay, ô gốc ẩn quân trong lúc kéo.
- Thả trên ô đích hợp lệ → `SquareTapped(to)` (không chạy animation T5.3 cho nước kéo-thả).
  Thả ở ô gốc hoặc ngoài bàn cờ → hủy, quân về chỗ cũ, không âm thanh. Thả ở ô không hợp lệ khác → âm thanh `illegal`
  như chạm hiện tại, quân về chỗ cũ.
- Phong cấp bằng kéo-thả đi qua dialog của T2.3 như bình thường. Chạm (tap) giữ nguyên hành vi.

**Ngoài phạm vi:** premove, kéo quân của đối phương.

**File được sửa:** `lib/features/game/widgets/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Widget test: kéo e2→e4 đi được; kéo e2→e5 bị từ chối, quân ở lại e2; kéo khi máy đang nghĩ không có tác dụng.
- [ ] Bàn cờ lật vẫn kéo-thả đúng ô.

---

## T5.5 — Hiệu ứng chiếu và kết thúc ván

**Thiết kế bắt buộc**
- Khi `checkSquare` chuyển từ `null` sang có giá trị: ô vua bị chiếu nhấp nháy (opacity lớp đỏ 1 → 0.4 → 1, 2 lần,
  tổng 400 ms) — animation cục bộ trong lớp tô màu.
- Khi ván kết thúc (`status.isGameOver` chuyển false → true): sau 500 ms mở `GameOverDialog`
  (`lib/features/game/widgets/game_over_dialog.dart`) hiển thị text kết quả như status bar, nút `Ván mới`
  (gửi `NewGameRequested`) và `Về màn chính` (`Navigator.pop` về `HomePage`). Mở bằng `BlocListener` trong `GameView`.
- Pháo giấy (custom painter, tối đa 80 hạt, 2 giây, không package) phía sau dialog khi: pve và người thắng; hoặc pvp
  và có chiếu hết.
- Mọi hiệu ứng tắt khi `animationsEnabled = false` (dialog vẫn hiện).

**Ngoài phạm vi:** âm thanh mới, rung mới, chia sẻ kết quả.

**File được sửa:** `lib/features/game/**`, `test/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Widget test: chiếu hết → sau 500 ms có dialog; `Ván mới` reset ván; `Về màn chính` quay về `HomePage`.
- [ ] Pháo giấy chỉ xuất hiện đúng điều kiện (test cả trường hợp máy thắng: không có pháo giấy).
