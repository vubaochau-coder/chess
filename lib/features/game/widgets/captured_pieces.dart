import 'package:chess/core/game/game_config.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CapturedPieces extends StatelessWidget {
  const CapturedPieces({super.key, required this.color});

  final PieceColor color;

  static int _pieceValue(String piece) => switch (piece.toLowerCase()) {
    'q' => 9,
    'r' => 5,
    'b' => 3,
    'n' => 3,
    'p' => 1,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChessGameBloc, ChessGameState, List<MoveRecord>>(
      selector: (state) => state.moves,
      builder: (context, moves) {
        final allCaptured = moves
            .map((m) => m.captured)
            .whereType<String>()
            .toList();

        final whiteCaptured = allCaptured
            .where((p) => p == p.toUpperCase())
            .toList();
        final blackCaptured = allCaptured
            .where((p) => p == p.toLowerCase())
            .toList();

        final whiteScore = whiteCaptured.fold<int>(
          0,
          (sum, p) => sum + _pieceValue(p),
        );
        final blackScore = blackCaptured.fold<int>(
          0,
          (sum, p) => sum + _pieceValue(p),
        );

        const order = ['q', 'r', 'b', 'n', 'p'];
        final displayedPieces = color == PieceColor.white
            ? whiteCaptured
            : blackCaptured;
        displayedPieces.sort(
          (a, b) => order
              .indexOf(a.toLowerCase())
              .compareTo(order.indexOf(b.toLowerCase())),
        );

        // Bên ăn quân trắng là Đen; bên ăn quân đen là Trắng.
        final diff = color == PieceColor.white
            ? whiteScore - blackScore
            : blackScore - whiteScore;

        return SizedBox(
          height: 24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final piece in displayedPieces)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: PieceView(piece: piece, size: 20),
                  ),
                if (diff > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '+$diff',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
