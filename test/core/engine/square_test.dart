import 'package:chess/core/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('squareFromName and squareName', () {
    test('standard square mappings', () {
      expect(squareFromName('a8'), 0);
      expect(squareName(0), 'a8');

      expect(squareFromName('h8'), 7);
      expect(squareName(7), 'h8');

      expect(squareFromName('a1'), 56);
      expect(squareName(56), 'a1');

      expect(squareFromName('h1'), 63);
      expect(squareName(63), 'h1');

      expect(squareFromName('e4'), 36);
      expect(squareName(36), 'e4');
    });

    test('all 64 squares round-trip', () {
      for (var i = 0; i < 64; i++) {
        final name = squareName(i);
        expect(squareFromName(name), i);
      }
    });

    test('squareFromName throws FormatException on invalid inputs', () {
      expect(() => squareFromName(''), throwsFormatException);
      expect(() => squareFromName('e'), throwsFormatException);
      expect(() => squareFromName('e44'), throwsFormatException);
      expect(() => squareFromName('e9'), throwsFormatException);
      expect(() => squareFromName('e0'), throwsFormatException);
      expect(() => squareFromName('i4'), throwsFormatException);
      expect(() => squareFromName('14'), throwsFormatException);
      expect(() => squareFromName('ea'), throwsFormatException);
    });

    test('squareName throws RangeError on out of bounds', () {
      expect(() => squareName(-1), throwsRangeError);
      expect(() => squareName(64), throwsRangeError);
      expect(() => squareName(100), throwsRangeError);
    });
  });
}
