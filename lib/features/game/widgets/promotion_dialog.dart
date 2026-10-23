import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:flutter/material.dart';

class PromotionDialog extends StatelessWidget {
  const PromotionDialog({super.key, required this.white});

  final bool white;

  @override
  Widget build(BuildContext context) {
    const pieces = ['q', 'r', 'b', 'n'];

    return AlertDialog(
      title: const Text('Phong cấp'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final piece in pieces)
            InkWell(
              onTap: () => Navigator.of(context).pop(piece),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: PieceView(
                  piece: white ? piece.toUpperCase() : piece,
                  size: 48,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
