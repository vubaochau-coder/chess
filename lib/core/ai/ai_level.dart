import 'package:chess/core/ai/search.dart';

enum AiLevel {
  easy,
  medium,
  hard;

  SearchConfig get config => switch (this) {
    AiLevel.easy => const SearchConfig(
      maxDepth: 2,
      timeLimit: Duration(milliseconds: 300),
      useQuiescence: false,
      useTranspositionTable: false,
      randomMarginCp: 150,
      blunderChance: 0.15,
    ),
    AiLevel.medium => const SearchConfig(
      maxDepth: 4,
      timeLimit: Duration(milliseconds: 1000),
      useQuiescence: true,
      useTranspositionTable: true,
      randomMarginCp: 30,
      blunderChance: 0,
    ),
    AiLevel.hard => const SearchConfig(
      maxDepth: 64,
      timeLimit: Duration(milliseconds: 2500),
      useQuiescence: true,
      useTranspositionTable: true,
      randomMarginCp: 0,
      blunderChance: 0,
    ),
  };
}
