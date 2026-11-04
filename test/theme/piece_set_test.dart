import 'dart:io';

import 'package:chess/theme/piece_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieceSet', () {
    test('labels match the owner-provided names', () {
      expect(PieceSet.values.map((s) => s.label), [
        'Cổ điển',
        'Gỗ',
        'Phẳng',
        'Hiện đại',
      ]);
    });

    test('classic has no asset', () {
      expect(PieceSet.classic.assetFor('K'), isNull);
      expect(PieceSet.classic.assetFor('n'), isNull);
    });

    test('assetFor maps FEN symbols to color-prefixed file names', () {
      expect(PieceSet.flat.assetFor('K'), 'assets/pieces/flat/wK.svg');
      expect(PieceSet.wood.assetFor('n'), 'assets/pieces/wood/bN.svg');
      expect(PieceSet.modern.assetFor('p'), 'assets/pieces/modern/bP.svg');
    });

    test('every SVG set has all 12 files without <style> elements', () {
      for (final set in PieceSet.values.where((s) => s != PieceSet.classic)) {
        for (final piece in 'KQRBNPkqrbnp'.split('')) {
          final file = File(set.assetFor(piece)!);
          expect(file.existsSync(), isTrue, reason: file.path);
          // flutter_svg bỏ qua thẻ <style>, quân sẽ bị vẽ sai màu.
          expect(file.readAsStringSync(), isNot(contains('<style')));
        }
      }
    });

    test('fromName falls back to classic', () {
      expect(PieceSet.fromName('modern'), PieceSet.modern);
      expect(PieceSet.fromName('unknown'), PieceSet.classic);
      expect(PieceSet.fromName(null), PieceSet.classic);
    });
  });
}
