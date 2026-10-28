import 'dart:math' as math;

import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/tutorial/lesson_board.dart';
import 'package:chess/features/game/painter/board_painter.dart';
import 'package:chess/features/game/painter/coordinates_painter.dart';
import 'package:chess/features/game/painter/highlight_painter.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/features/tutorial/cubit/lesson_cubit.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bàn cờ của bài học: vẽ ô theo theme bàn cờ trong Cài đặt, chạm để đi.
class LessonBoardView extends StatelessWidget {
  const LessonBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsCubit, AppSettings, (BoardTheme, bool)>(
      selector: (settings) => (settings.boardTheme, settings.showCoordinates),
      builder: (context, options) {
        final (boardTheme, showCoordinates) = options;
        final colors = boardTheme.colors;

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
                  context.read<LessonCubit>().tap(row * 8 + col);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(painter: BoardPainter(colors)),
                    ),
                    if (showCoordinates)
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: CoordinatesPainter(colors: colors),
                        ),
                      ),
                    BlocBuilder<LessonCubit, LessonBoard>(
                      builder: (context, board) =>
                          _Layers(board: board, colors: colors, cell: cell),
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

class _Layers extends StatelessWidget {
  const _Layers({
    required this.board,
    required this.colors,
    required this.cell,
  });

  final LessonBoard board;
  final BoardColors colors;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final squares = board.position.board;
    final target = board.targetSquare;
    final move = board.lastMove;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: HighlightPainter(
              colors: colors,
              highlighted: [
                ...board.highlightSquares,
                if (move != null) ...[move.from, move.to],
                ?board.selected,
              ],
              targets: board.targets,
              checkSquare: null,
            ),
          ),
        ),
        if (target != null && squares[target].isEmpty)
          _at(
            target,
            Icon(
              Icons.star_rounded,
              size: cell * 0.62,
              color: const Color(0xCC5E3B12),
            ),
          ),
        for (var i = 0; i < 64; i++)
          if (squares[i].isNotEmpty)
            _at(
              i,
              PieceView(
                piece: squares[i],
                size: cell * (board.selected == i ? 0.8 : 0.68),
              ),
            ),
      ],
    );
  }

  Widget _at(int square, Widget child) {
    return Positioned(
      left: square % 8 * cell,
      top: square ~/ 8 * cell,
      width: cell,
      height: cell,
      child: Center(child: child),
    );
  }
}
