import 'dart:math' as math;

import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/painter/board_painter.dart';
import 'package:chess/features/game/painter/coordinates_painter.dart';
import 'package:chess/features/game/painter/highlight_painter.dart';
import 'package:chess/features/game/widgets/move_animation_layer.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bàn cờ vuông, lớn nhất có thể trong không gian được cấp.
///
/// Chia thành các lớp độc lập, mỗi lớp nằm trong [RepaintBoundary] riêng và
/// chỉ lắng nghe phần state nó cần:
/// - ô bàn cờ: vẽ theo [BoardColors] từ [BoardTheme];
/// - lớp tô màu: rebuild khi chọn quân / đi quân / chiếu / đổi theme;
/// - 64 ô quân cờ: mỗi ô chỉ rebuild khi quân trên chính ô đó đổi;
/// - lớp animation nước đi ([MoveAnimationLayer]).
/// Chạm được xử lý một lần ở cấp bàn cờ (tính ô từ tọa độ) thay vì 64 widget.
class ChessBoard extends StatefulWidget {
  const ChessBoard({super.key, this.flipped = false});

  final bool flipped;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  /// Ô đang có quân trượt tới: lớp quân thật ẩn quân ở đó tới khi trượt xong.
  final _hiddenSquares = ValueNotifier<Set<int>>(const {});

  @override
  void dispose() {
    _hiddenSquares.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flipped = widget.flipped;

    return BlocSelector<SettingsCubit, AppSettings, _BoardOptions>(
      selector: (settings) => (
        theme: settings.boardTheme,
        coordinates: settings.showCoordinates,
        legalMoves: settings.showLegalMoves,
        lastMove: settings.highlightLastMove,
      ),
      builder: (context, options) {
        final colors = options.theme.colors;

        return LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final cell = boardSize / 8;

            return SizedBox.square(
              dimension: boardSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final col = (details.localPosition.dx ~/ cell).clamp(0, 7);
                  final row = (details.localPosition.dy ~/ cell).clamp(0, 7);
                  final displayIndex = row * 8 + col;
                  final actualIndex = flipped
                      ? (63 - displayIndex)
                      : displayIndex;
                  context.read<ChessGameBloc>().add(SquareTapped(actualIndex));
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(painter: BoardPainter(colors)),
                    ),
                    if (options.coordinates)
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: CoordinatesPainter(
                            colors: colors,
                            flipped: flipped,
                          ),
                        ),
                      ),
                    RepaintBoundary(
                      child: _HighlightLayer(
                        flipped: flipped,
                        colors: colors,
                        showTargets: options.legalMoves,
                        showLastMove: options.lastMove,
                      ),
                    ),
                    RepaintBoundary(
                      child: _PiecesLayer(
                        cellSize: cell,
                        flipped: flipped,
                        hiddenSquares: _hiddenSquares,
                      ),
                    ),
                    RepaintBoundary(
                      child: MoveAnimationLayer(
                        cellSize: cell,
                        flipped: flipped,
                        hiddenSquares: _hiddenSquares,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

typedef _BoardOptions = ({
  BoardTheme theme,
  bool coordinates,
  bool legalMoves,
  bool lastMove,
});

typedef _Highlights = ({
  int? selected,
  LastMove? lastMove,
  List<int> targets,
  int? checkSquare,
});

class _HighlightLayer extends StatelessWidget {
  const _HighlightLayer({
    required this.flipped,
    required this.colors,
    required this.showTargets,
    required this.showLastMove,
  });

  final bool flipped;
  final BoardColors colors;
  final bool showTargets;
  final bool showLastMove;

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
        final lastMove = showLastMove ? h.lastMove : null;
        return CustomPaint(
          painter: HighlightPainter(
            colors: colors,
            highlighted: [
              if (lastMove case final move?) ...[move.from, move.to],
              ?h.selected,
            ],
            targets: showTargets ? h.targets : const [],
            checkSquare: h.checkSquare,
            flipped: flipped,
          ),
        );
      },
    );
  }
}

class _PiecesLayer extends StatelessWidget {
  const _PiecesLayer({
    required this.cellSize,
    required this.flipped,
    required this.hiddenSquares,
  });

  final double cellSize;
  final bool flipped;
  final ValueNotifier<Set<int>> hiddenSquares;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 8; row++)
          Row(
            children: [
              for (var col = 0; col < 8; col++)
                _SquarePiece(
                  index: flipped ? (63 - (row * 8 + col)) : (row * 8 + col),
                  cellSize: cellSize,
                  hiddenSquares: hiddenSquares,
                ),
            ],
          ),
      ],
    );
  }
}

class _SquarePiece extends StatelessWidget {
  const _SquarePiece({
    required this.index,
    required this.cellSize,
    required this.hiddenSquares,
  });

  final int index;
  final double cellSize;
  final ValueNotifier<Set<int>> hiddenSquares;

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
          return ValueListenableBuilder<Set<int>>(
            valueListenable: hiddenSquares,
            builder: (context, hidden, child) =>
                hidden.contains(index) ? const SizedBox.shrink() : child!,
            child: Center(
              child: PieceView(
                piece: piece,
                size: cellSize * (isSelected ? 0.8 : 0.68),
              ),
            ),
          );
        },
      ),
    );
  }
}
