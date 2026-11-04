import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Một quân vẽ trong lúc animation, trượt từ ô [from] tới ô [to]
/// (quân bị ăn có `from == to`, đứng yên tới khi animation kết thúc).
typedef _Sprite = ({String piece, int from, int to});

/// Cho quân vừa đi trượt từ ô đi tới ô đến.
///
/// Chỉ chạy khi `moves` dài thêm đúng một nước trong cùng ván; undo, ván mới
/// và khôi phục ván thì không. Trong lúc chạy, các ô đích được đưa vào
/// [hiddenSquares] để lớp quân thật ẩn quân ở đó, tránh vẽ trùng.
class MoveAnimationLayer extends StatefulWidget {
  const MoveAnimationLayer({
    super.key,
    required this.cellSize,
    required this.flipped,
    required this.hiddenSquares,
  });

  static const duration = Duration(milliseconds: 150);

  final double cellSize;
  final bool flipped;
  final ValueNotifier<Set<int>> hiddenSquares;

  @override
  State<MoveAnimationLayer> createState() => _MoveAnimationLayerState();
}

class _MoveAnimationLayerState extends State<MoveAnimationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  late int _gameId;
  late int _moveCount;
  List<_Sprite> _sprites = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MoveAnimationLayer.duration,
    );
    _controller.addStatusListener(_onStatus);
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final state = context.read<ChessGameBloc>().state;
    _gameId = state.gameId;
    _moveCount = state.moves.length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _clear();
  }

  void _clear() {
    widget.hiddenSquares.value = const {};
    if (_sprites.isNotEmpty) setState(() => _sprites = const []);
  }

  void _onMovesChanged(BuildContext context, ChessGameState state) {
    final isNextMove =
        state.gameId == _gameId && state.moves.length == _moveCount + 1;
    _gameId = state.gameId;
    _moveCount = state.moves.length;

    final enabled = context.read<SettingsCubit>().state.animationsEnabled;
    if (!isNextMove || !enabled) {
      _controller.stop();
      _clear();
      return;
    }
    final before = state.history[state.history.length - 2];
    _start(before, state.moves.last.move);
  }

  void _start(GamePosition before, Move move) {
    final board = before.board;
    final piece = board[move.from];
    final sprites = <_Sprite>[];
    final hidden = <int>{move.to};

    // Quân bị ăn vẽ dưới quân đang trượt và biến mất khi animation kết thúc.
    final captured = board[move.to];
    if (captured.isNotEmpty) {
      sprites.add((piece: captured, from: move.to, to: move.to));
    }
    final type = piece.toLowerCase();
    if (type == 'p' && move.to == before.enPassant) {
      final square = (move.from ~/ 8) * 8 + move.to % 8;
      sprites.add((piece: board[square], from: square, to: square));
    }

    sprites.add((piece: piece, from: move.from, to: move.to));

    if (type == 'k' && (move.to - move.from).abs() == 2) {
      final row = move.from ~/ 8;
      final kingSide = move.to > move.from;
      final rookFrom = row * 8 + (kingSide ? 7 : 0);
      final rookTo = row * 8 + (kingSide ? 5 : 3);
      sprites.add((piece: board[rookFrom], from: rookFrom, to: rookTo));
      hidden.add(rookTo);
    }

    setState(() => _sprites = sprites);
    widget.hiddenSquares.value = hidden;
    _controller.forward(from: 0);
  }

  Offset _offsetOf(int index) {
    final display = widget.flipped ? 63 - index : index;
    final cell = widget.cellSize;
    return Offset((display % 8) * cell, (display ~/ 8) * cell);
  }

  Offset _positionOf(_Sprite sprite) {
    final from = _offsetOf(sprite.from);
    return from + (_offsetOf(sprite.to) - from) * _progress.value;
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.cellSize;

    return BlocListener<ChessGameBloc, ChessGameState>(
      listenWhen: (previous, current) =>
          !identical(previous.moves, current.moves) ||
          previous.gameId != current.gameId,
      listener: _onMovesChanged,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final sprite in _sprites)
              AnimatedBuilder(
                animation: _progress,
                child: Center(
                  child: PieceView(piece: sprite.piece, size: cell * 0.68),
                ),
                builder: (context, child) {
                  final offset = _positionOf(sprite);
                  return Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    width: cell,
                    height: cell,
                    child: child!,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
