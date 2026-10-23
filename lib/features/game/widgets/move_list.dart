import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MoveList extends StatelessWidget {
  const MoveList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChessGameBloc, ChessGameState, List<MoveRecord>>(
      selector: (state) => state.moves,
      builder: (context, moves) {
        return SizedBox(height: 40, child: _MoveListView(moves: moves));
      },
    );
  }
}

class _MoveListView extends StatefulWidget {
  const _MoveListView({required this.moves});

  final List<MoveRecord> moves;

  @override
  State<_MoveListView> createState() => _MoveListViewState();
}

class _MoveListViewState extends State<_MoveListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _MoveListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moves.length != oldWidget.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.moves.length,
      itemBuilder: (context, index) {
        final isLatest = index == widget.moves.length - 1;
        final moveNumber = (index ~/ 2) + 1;
        final text = index.isEven
            ? '$moveNumber. ${widget.moves[index].san}'
            : widget.moves[index].san;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
