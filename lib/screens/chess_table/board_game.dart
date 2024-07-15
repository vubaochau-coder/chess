import 'package:chess/screens/chess_table/painter/game_board_painter.dart';
import 'package:chess/screens/chess_table/painter/game_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/chess_game_bloc.dart';

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
            BlocBuilder<ChessGameBloc, ChessGameState>(
              builder: (context, state) {
                return CustomPaint(
                  size: Size(size * 8, size * 8),
                  painter: GameBoardPainter(
                    cellSize: size,
                    hints: state.hintMoves,
                    hightLight: state.hightLights,
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
