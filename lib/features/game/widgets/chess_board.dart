import 'dart:math' as math;

import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/painter/board_painter.dart';
import 'package:chess/features/game/painter/highlight_painter.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bàn cờ vuông, lớn nhất có thể trong không gian được cấp.
///
/// Chia thành các lớp độc lập, mỗi lớp nằm trong [RepaintBoundary] riêng và
/// chỉ lắng nghe phần state nó cần:
/// - ô bàn cờ: tĩnh, không bao giờ vẽ lại;
/// - lớp tô màu: rebuild khi chọn quân / đi quân / chiếu;
/// - 64 ô quân cờ: mỗi ô chỉ rebuild khi quân trên chính ô đó đổi.
/// Chạm được xử lý một lần ở cấp bàn cờ (tính ô từ tọa độ) thay vì 64 widget.
class ChessBoard extends StatelessWidget {
  const ChessBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final cell = boardSize / 8;

        return SizedBox.square(
          dimension: boardSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final col = (details.localPosition.dx ~/ cell).clamp(0, 7);
              final row = (details.localPosition.dy ~/ cell).clamp(0, 7);
              context.read<ChessGameBloc>().add(SquareTapped(row * 8 + col));
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                const RepaintBoundary(
                  child: CustomPaint(painter: BoardPainter()),
                ),
                const RepaintBoundary(child: _HighlightLayer()),
                RepaintBoundary(child: _PiecesLayer(cellSize: cell)),
              ],
            ),
          ),
        );
      },
    );
  }
}

typedef _Highlights = ({
  int? selected,
  LastMove? lastMove,
  List<int> targets,
  int? checkSquare,
});

class _HighlightLayer extends StatelessWidget {
  const _HighlightLayer();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChessGameBloc, ChessGameState, _Highlights>(
      selector: (state) => (
        selected: state.selected,
        lastMove: state.lastMove,
        targets: state.legalTargets,
        checkSquare: state.checkSquare,
      ),
      builder: (context, h) {
        return CustomPaint(
          painter: HighlightPainter(
            highlighted: [
              if (h.lastMove case final move?) ...[move.from, move.to],
              ?h.selected,
            ],
            targets: h.targets,
            checkSquare: h.checkSquare,
          ),
        );
      },
    );
  }
}

class _PiecesLayer extends StatelessWidget {
  const _PiecesLayer({required this.cellSize});

  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 8; row++)
          Row(
            children: [
              for (var col = 0; col < 8; col++)
                _SquarePiece(index: row * 8 + col, cellSize: cellSize),
            ],
          ),
      ],
    );
  }
}

class _SquarePiece extends StatelessWidget {
  const _SquarePiece({required this.index, required this.cellSize});

  final int index;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: cellSize,
      child: BlocSelector<ChessGameBloc, ChessGameState, (String, bool)>(
        selector: (state) =>
            (state.position.board[index], state.selected == index),
        builder: (context, square) {
          final (piece, isSelected) = square;
          if (piece.isEmpty) return const SizedBox.shrink();
          return Center(
            child: PieceView(
              piece: piece,
              size: cellSize * (isSelected ? 0.8 : 0.68),
            ),
          );
        },
      ),
    );
  }
}
