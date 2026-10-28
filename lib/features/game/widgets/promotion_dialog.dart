import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:flutter/material.dart';

class PromotionDialog extends StatelessWidget {
  const PromotionDialog({super.key, required this.white});

  final bool white;

  @override
  Widget build(BuildContext context) {
    const pieces = [('q', 'Hậu'), ('r', 'Xe'), ('b', 'Tượng'), ('n', 'Mã')];
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Phong cấp', textAlign: TextAlign.center),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (piece, label) in pieces)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: colorScheme.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(piece),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PieceView(
                            piece: white ? piece.toUpperCase() : piece,
                            size: 40,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
