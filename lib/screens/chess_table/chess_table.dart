import 'package:chess/screens/chess_table/board_game.dart';
import 'package:chess/utils/chess_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/chess_game_bloc.dart';

class ChessTable extends StatelessWidget {
  const ChessTable({super.key});
  static const commonSize = 50.0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChessGameBloc()
        ..add(ChessGameInit(gameState: {0: ChessUtils.initGame})),
      child: _PageContent(),
    );
  }
}

class _PageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double cellSize = width / 8;

    return Scaffold(
      body: BoardGame(size: cellSize),
    );
  }
}
