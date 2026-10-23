import 'package:chess/core/engine/move.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Move UCI serialization', () {
    test('round-trip normal moves', () {
      const moves = ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'e1g1', 'a7a8'];
      for (final uci in moves) {
        expect(Move.fromUci(uci).toUci(), uci);
      }
    });

    test('round-trip promotion moves', () {
      const promotions = ['e7e8q', 'e7e8r', 'e7e8b', 'e7e8n', 'a2a1q'];
      for (final uci in promotions) {
        expect(Move.fromUci(uci).toUci(), uci);
      }
    });

    test('invalid length throws FormatException', () {
      expect(() => Move.fromUci(''), throwsFormatException);
      expect(() => Move.fromUci('e2'), throwsFormatException);
      expect(() => Move.fromUci('e2e4q+'), throwsFormatException);
    });

    test('invalid square name throws FormatException', () {
      expect(() => Move.fromUci('z9e4'), throwsFormatException);
      expect(() => Move.fromUci('e2k9'), throwsFormatException);
    });

    test('invalid promotion character throws FormatException', () {
      expect(() => Move.fromUci('e7e8x'), throwsFormatException);
      expect(() => Move.fromUci('e7e8k'), throwsFormatException);
    });

    test('equality and props', () {
      const m1 = Move(52, 36);
      const m2 = Move(52, 36);
      const m3 = Move(52, 36, promotion: 'q');
      expect(m1, equals(m2));
      expect(m1, isNot(equals(m3)));
    });
  });
}
