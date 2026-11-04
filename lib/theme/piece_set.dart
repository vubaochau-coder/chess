/// Bộ hình quân cờ. [classic] vẽ bằng `chess_vectors_flutter`; các bộ còn lại
/// dùng SVG trong `assets/pieces/<name>/`.
enum PieceSet {
  classic('Cổ điển'),
  wood('Gỗ'),
  flat('Phẳng'),
  modern('Hiện đại');

  const PieceSet(this.label);

  final String label;

  /// Đường dẫn SVG của [piece] (ký hiệu FEN), `null` với [classic].
  String? assetFor(String piece) {
    if (this == PieceSet.classic) return null;
    final color = piece == piece.toUpperCase() ? 'w' : 'b';
    return 'assets/pieces/$name/$color${piece.toUpperCase()}.svg';
  }

  static PieceSet fromName(String? name) {
    for (final set in values) {
      if (set.name == name) return set;
    }
    return PieceSet.classic;
  }
}
