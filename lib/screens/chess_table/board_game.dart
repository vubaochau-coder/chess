import 'package:chess/screens/chess_table/painter/game_board_painter.dart';
import 'package:chess/screens/chess_table/views/game_state.dart';
import 'package:chess/utils/chess_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/chess_game_bloc.dart';
import 'painter/game_hint_painter.dart';

class BoardGame extends StatelessWidget {
  final double size;

  const BoardGame({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: AlignmentDirectional.center,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                size: Size(size * 8, size * 8),
                painter: GameBoardPainter(cellSize: size),
                // foregroundPainter: GameBoardPainter(cellSize: size),
              ),
            ),
            BlocBuilder<ChessGameBloc, ChessGameState>(
              builder: (context, state) {
                final position = state.isLoading ? null : state.position;
                final inCheck = state.status == GameStatus.check ||
                    state.status == GameStatus.checkmate;

                return CustomPaint(
                  size: Size(size * 8, size * 8),
                  painter: GameHintPainter(
                    cellSize: size,
                    hints: state.hintMoves,
                    hightLight: state.hightLights,
                    check: inCheck
                        ? position!.board
                            .indexOf(position.whiteToMove ? 'K' : 'k')
                        : null,
                  ),
                );
              },
            ),
            GameState(size: size),
          ],
        ),
      ],
    );
  }
}
