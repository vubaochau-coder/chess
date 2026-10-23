import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/widgets.dart';

/// Vẽ một quân cờ theo ký hiệu FEN (`K Q R B N P` trắng, chữ thường là đen).
///
/// Đây là điểm mở rộng duy nhất cho kiểu quân cờ: khi thêm bộ quân mới
/// (Giai đoạn 4) chỉ sửa widget này, không sửa nơi gọi.
class PieceView extends StatelessWidget {
  const PieceView({super.key, required this.piece, required this.size});

  final String piece;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (piece) {
      'K' => vector.WhiteKing(size: size),
      'Q' => vector.WhiteQueen(size: size),
      'R' => vector.WhiteRook(size: size),
      'B' => vector.WhiteBishop(size: size),
      'N' => vector.WhiteKnight(size: size),
      'P' => vector.WhitePawn(size: size),
      'k' => vector.BlackKing(size: size),
      'q' => vector.BlackQueen(size: size),
      'r' => vector.BlackRook(size: size),
      'b' => vector.BlackBishop(size: size),
      'n' => vector.BlackKnight(size: size),
      'p' => vector.BlackPawn(size: size),
      _ => const SizedBox.shrink(),
    };
  }
}
