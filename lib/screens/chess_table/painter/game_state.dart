import 'package:chess/models/position_model.dart';
import 'package:chess/screens/chess_table/bloc/chess_game_bloc.dart';
import 'package:chess/utils/chess_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/abstract/chess_model.dart';

class GameState extends StatelessWidget {
  final double size;

  const GameState({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessGameBloc, ChessGameState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox();
        }

        List<String> chessList = state.gameStates[state.currentState]!;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 8 * 8,
          itemBuilder: (context, index) {
            bool isSelect = index == state.selectedChess;
            Chess? chess = ChessUtils.strToChess(
              chessList[index],
              Position(x: index ~/ 8, y: index % 8),
            );

            if (chess == null) {
              return InkWell(
                onTap: () {
                  if (state.selectedChess != null) {
                    context
                        .read<ChessGameBloc>()
                        .add(MoveChessToEvent(index: index));
                  }
                },
                child: SizedBox.fromSize(
                  size: Size(size, size),
                ),
              );
            }

            return InkWell(
              onTap: () {
                context.read<ChessGameBloc>().add(ChessSelectedEvent(
                      index: index,
                      hintMoves: chess.getPossibleMove(chessList),
                    ));
              },
              child: Center(
                child: chess.draw(context, isSelect ? 40 : null),
              ),
            );
          },
        );
      },
    );
  }
}
