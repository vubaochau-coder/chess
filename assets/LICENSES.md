# Giấy phép tài nguyên (Asset Licenses)

Bảng kê khai nguồn gốc và giấy phép của toàn bộ tài nguyên (âm thanh, hình ảnh, quân cờ) trong ứng dụng.

## 1. Quân cờ (Chess Pieces)

| Bộ quân | Tên thư mục | Nguồn / Tác giả | Giấy phép | Ghi chú |
|---|---|---|---|---|
| Cổ điển | `classic` (mặc định) | Hình quân: Colin M.L. Burnett (Cburnett), [Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:SVG_chess_pieces); package: Laurent Bernabe | Hình quân: tác giả cho chọn GFDL/BSD/GPL, app dùng theo **BSD** ([trang tác giả](https://en.wikipedia.org/wiki/User:Cburnett/GFDL_images/Chess)); package: [MIT](https://pub.dev/packages/chess_vectors_flutter/license) | Tích hợp qua package `chess_vectors_flutter: 1.1.0` |
| Gỗ | `assets/pieces/wood/` | RhosGFX, [Vector Chess Pieces Pack](https://rhosgfx.itch.io/vector-chess-pieces) | [Creative Commons CC0 1.0 Universal (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/) | 12 file SVG (Outline) |
| Phẳng | `assets/pieces/flat/` | RhosGFX, [Vector Chess Pieces Pack](https://rhosgfx.itch.io/vector-chess-pieces) | [Creative Commons CC0 1.0 Universal (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/) | 12 file SVG (Flat) |
| Hiện đại | `assets/pieces/modern/` | RhosGFX, [Vector Chess Pieces Pack](https://rhosgfx.itch.io/vector-chess-pieces) | [Creative Commons CC0 1.0 Universal (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/) | 12 file SVG (Outline) |

Ghi chú bộ RhosGFX (Gỗ, Phẳng, Hiện đại):

- Văn bản giấy phép gốc trong file zip của tác giả được lưu nguyên tại `assets/pieces/RHOSGFX_LICENSE.txt`.
- Các file SVG đã được chỉnh sửa (CC0 cho phép): chuyển class CSS trong thẻ `<style>` thành thuộc tính
  trên từng phần tử, vì `flutter_svg` không hỗ trợ thẻ `<style>`. Hình hiển thị không đổi.

## 2. Nhận diện thương hiệu (Branding)

| File | Nguồn | Giấy phép | Ghi chú |
|---|---|---|---|
| `assets/branding/icon.png`, `icon_foreground.png`, `icon_background.png` (và file `.svg` nguồn cùng tên) | Ghép từ `assets/pieces/wood/bK.svg` và `wK.svg` (RhosGFX, [Vector Chess Pieces Pack](https://rhosgfx.itch.io/vector-chess-pieces)) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | Logo app: quân Vua chia đôi, nửa trái quân đen trên nền `#F2E1C3`, nửa phải quân trắng trên nền `#9A6B45`. PNG 1024×1024 xuất từ SVG nguồn |
