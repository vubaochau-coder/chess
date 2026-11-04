import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/theme/piece_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPiece(WidgetTester tester, PieceSet pieceSet) {
    return tester.pumpWidget(
      Center(
        child: PieceView(piece: 'n', size: 40, pieceSet: pieceSet),
      ),
    );
  }

  testWidgets('classic draws vectors without SvgPicture', (tester) async {
    await pumpPiece(tester, PieceSet.classic);

    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('changing the piece set draws SvgPicture with its asset', (
    tester,
  ) async {
    for (final set in [PieceSet.wood, PieceSet.flat, PieceSet.modern]) {
      await pumpPiece(tester, set);

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svg.bytesLoader as SvgAssetLoader;
      expect(loader.assetName, 'assets/pieces/${set.name}/bN.svg');
    }
  });

  testWidgets('empty square draws nothing for SVG sets', (tester) async {
    await tester.pumpWidget(
      const PieceView(piece: '', size: 40, pieceSet: PieceSet.flat),
    );

    expect(find.byType(SvgPicture), findsNothing);
  });
}
