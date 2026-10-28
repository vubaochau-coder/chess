import 'package:chess/core/ai/ai_level.dart';

/// Tên mức độ khó hiển thị cho người dùng.
String aiLevelLabel(AiLevel level) => switch (level) {
  AiLevel.easy => 'Dễ',
  AiLevel.medium => 'Trung bình',
  AiLevel.hard => 'Khó',
};
