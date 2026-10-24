import 'package:chess/core/ai/ai_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiLevel SearchConfig parameters', () {
    test('easy level config matches specification', () {
      final config = AiLevel.easy.config;
      expect(config.maxDepth, equals(2));
      expect(config.timeLimit, equals(const Duration(milliseconds: 300)));
      expect(config.useQuiescence, isFalse);
      expect(config.useTranspositionTable, isFalse);
      expect(config.randomMarginCp, equals(150));
      expect(config.blunderChance, equals(0.15));
    });

    test('medium level config matches specification', () {
      final config = AiLevel.medium.config;
      expect(config.maxDepth, equals(4));
      expect(config.timeLimit, equals(const Duration(milliseconds: 1000)));
      expect(config.useQuiescence, isTrue);
      expect(config.useTranspositionTable, isTrue);
      expect(config.randomMarginCp, equals(30));
      expect(config.blunderChance, equals(0));
    });

    test('hard level config matches specification', () {
      final config = AiLevel.hard.config;
      expect(config.maxDepth, equals(64));
      expect(config.timeLimit, equals(const Duration(milliseconds: 2500)));
      expect(config.useQuiescence, isTrue);
      expect(config.useTranspositionTable, isTrue);
      expect(config.randomMarginCp, equals(0));
      expect(config.blunderChance, equals(0));
    });
  });
}
