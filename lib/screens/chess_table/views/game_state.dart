import 'package:chess/models/factories.dart/chess_factory.dart';
import 'package:chess/models/position_model.dart';
import 'package:chess/screens/chess_table/bloc/chess_game_bloc.dart';
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
            ChessModel? chess = Chess().fromString(chessList[index]);

            if (chess == null) {
              return InkWell(
                onTap: () {
                  if (state.selectedChess != null) {
                    BlocProvider.of<ChessGameBloc>(context).add(
                      MoveChessToEvent(index: index),
                    );
                  }
                },
                child: SizedBox.fromSize(
                  size: Size(size, size),
                ),
              );
            }

            return InkWell(
              onTap: () {
                BlocProvider.of<ChessGameBloc>(context).add(
                  ChessSelectedEvent(
                    index: index,
                    hintMoves: chess.getPossibleMove(
                      Position.fromIndex(index),
                      chessList,
                    ),
                  ),
                );
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
