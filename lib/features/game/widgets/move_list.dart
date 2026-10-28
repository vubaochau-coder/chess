import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MoveList extends StatelessWidget {
  const MoveList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocSelector<ChessGameBloc, ChessGameState, List<MoveRecord>>(
      selector: (state) => state.moves,
      builder: (context, moves) {
        return Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: moves.isEmpty
              ? Center(
                  child: Text(
                    'Chưa có nước đi',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : _MoveListView(moves: moves),
        );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      itemCount: widget.moves.length,
      itemBuilder: (context, index) {
        final isLatest = index == widget.moves.length - 1;
        final moveNumber = (index ~/ 2) + 1;
        final text = index.isEven
            ? '$moveNumber. ${widget.moves[index].san}'
            : widget.moves[index].san;

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLatest ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isLatest ? FontWeight.w700 : FontWeight.w500,
                color: isLatest ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}
