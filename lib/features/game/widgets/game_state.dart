import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/models/chess_factory.dart';
import 'package:chess/features/game/models/chess_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

        final List<String> chessList = state.position.board;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 8 * 8,
          itemBuilder: (context, index) {
            final bool isSelect = index == state.selectedChess;
            final ChessModel? chess = Chess().fromString(chessList[index]);

            return InkWell(
              onTap: () {
                BlocProvider.of<ChessGameBloc>(context)
                    .add(SquareTappedEvent(index: index));
              },
              child: chess == null
                  ? SizedBox.fromSize(size: Size(size, size))
                  : Center(child: chess.draw(context, isSelect ? 40 : null)),
            );
          },
        );
      },
    );
  }
}
