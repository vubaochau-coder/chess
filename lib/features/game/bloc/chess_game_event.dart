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

/// Quay lại 1 nước đi.
final class UndoRequested extends ChessGameEvent {
  const UndoRequested();
}

/// Người chơi yêu cầu đầu hàng.
final class ResignRequested extends ChessGameEvent {
  const ResignRequested();
}

/// Đảo chiều hiển thị bàn cờ.
final class BoardFlipToggled extends ChessGameEvent {
  const BoardFlipToggled();
}

/// Yêu cầu AI tính nước đi cho ván [gameId] ở độ sâu [ply].
final class _AiMoveRequested extends ChessGameEvent {
  const _AiMoveRequested({required this.gameId, required this.ply});

  final int gameId;
  final int ply;

  @override
  List<Object?> get props => [gameId, ply];
}
