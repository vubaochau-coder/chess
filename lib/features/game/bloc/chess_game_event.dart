part of 'chess_game_bloc.dart';

sealed class ChessGameEvent extends Equatable {
  const ChessGameEvent();

  @override
  List<Object?> get props => [];
}

/// Bắt đầu ván mới từ thế cờ ban đầu.
final class NewGameRequested extends ChessGameEvent {
  const NewGameRequested();
}

/// Người chơi chạm vào ô [index] (0..63, xem quy ước index trong AGENTS.md).
final class SquareTapped extends ChessGameEvent {
  const SquareTapped(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Người chơi chọn quân phong cấp ('q', 'r', 'b', 'n').
final class PromotionPieceSelected extends ChessGameEvent {
  PromotionPieceSelected(this.piece) {
    if (!const {'q', 'r', 'b', 'n'}.contains(piece)) {
      throw ArgumentError.value(
        piece,
        'piece',
        'Promotion piece must be one of q, r, b, n',
      );
    }
  }

  final String piece;

  @override
  List<Object?> get props => [piece];
}

/// Hủy chọn phong cấp (đóng dialog mà không chọn).
final class PromotionCancelled extends ChessGameEvent {
  const PromotionCancelled();
}
