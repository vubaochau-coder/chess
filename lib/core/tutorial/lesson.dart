/// Loại thử thách cuối bài học.
enum ChallengeKind {
  /// Đưa một quân Trắng tới [LessonChallenge.target] trong tối đa
  /// [LessonChallenge.maxMoves] nước.
  reach,

  /// Đi một nước chiếu Vua đen.
  giveCheck,

  /// Đi một nước chiếu hết.
  checkmate,

  /// Đi đúng một trong các nước [LessonChallenge.acceptedMoves] (UCI).
  playMove,
}

final class LessonChallenge {
  const LessonChallenge.reach({
    required this.prompt,
    required String this.target,
    required this.maxMoves,
  }) : kind = ChallengeKind.reach,
       acceptedMoves = const [];

  const LessonChallenge.giveCheck({required this.prompt})
    : kind = ChallengeKind.giveCheck,
      target = null,
      maxMoves = 1,
      acceptedMoves = const [];

  const LessonChallenge.checkmate({required this.prompt})
    : kind = ChallengeKind.checkmate,
      target = null,
      maxMoves = 1,
      acceptedMoves = const [];

  const LessonChallenge.playMove({
    required this.prompt,
    required this.acceptedMoves,
  }) : kind = ChallengeKind.playMove,
       target = null,
       maxMoves = 1;

  final ChallengeKind kind;

  /// Câu yêu cầu hiển thị cho người chơi.
  final String prompt;

  /// Tên ô đích (vd. `g5`), chỉ dùng cho [ChallengeKind.reach].
  final String? target;

  final int maxMoves;

  /// Nước đi UCI được chấp nhận, chỉ dùng cho [ChallengeKind.playMove].
  final List<String> acceptedMoves;
}

final class Lesson {
  const Lesson({
    required this.id,
    required this.chapter,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.fen,
    this.highlights = const [],
    this.challenge,
  });

  /// Khóa ổn định để lưu tiến độ; không đổi sau khi phát hành.
  final String id;

  /// Chỉ số chương trong `LessonCatalog.chapters`.
  final int chapter;
  final String title;
  final String subtitle;

  /// Nội dung bài, chia thành nhiều đoạn ngắn; hiển thị nối liền bằng dấu cách.
  final List<String> body;

  /// Thế cờ ban đầu; luôn có đủ hai Vua và tới lượt Trắng.
  final String fen;

  /// Tên các ô được tô sáng để minh họa (vd. trung tâm).
  final List<String> highlights;
  final LessonChallenge? challenge;
}
