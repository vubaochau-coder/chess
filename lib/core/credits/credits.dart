/// Ghi công một tài nguyên bên thứ ba dùng trong app.
///
/// Danh sách [credits] là nguồn duy nhất cho mục Giới thiệu và cho các giấy phép
/// đăng ký vào trang giấy phép; giữ khớp với `assets/LICENSES.md`.
final class Credit {
  const Credit({
    required this.title,
    required this.author,
    required this.license,
    this.licenseAsset,
  });

  final String title;
  final String author;
  final String license;

  /// File văn bản giấy phép đầy đủ phải kèm theo app; null nếu giấy phép không
  /// yêu cầu (vd. CC0).
  final String? licenseAsset;
}

const List<Credit> credits = [
  Credit(
    title: 'Bộ quân Cổ điển',
    author: 'Colin M.L. Burnett (Cburnett)',
    license: 'BSD',
    licenseAsset: 'assets/licenses/CBURNETT_LICENSE.txt',
  ),
  Credit(
    title: 'Bộ quân Gỗ, Phẳng, Hiện đại',
    author: 'RhosGFX',
    license: 'CC0 1.0',
  ),
  Credit(
    title: 'Logo app',
    author: 'Ghép từ bộ quân Gỗ của RhosGFX',
    license: 'CC0 1.0',
  ),
];
