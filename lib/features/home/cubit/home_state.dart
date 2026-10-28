part of 'home_cubit.dart';

enum ColorChoice { white, black, random }

final class HomeState extends Equatable {
  const HomeState({
    this.mode = GameMode.pve,
    this.level = AiLevel.medium,
    this.colorChoice = ColorChoice.white,
    this.savedGame,
  });

  final GameMode mode;
  final AiLevel level;
  final ColorChoice colorChoice;

  /// Ván đang chơi dở (để tiếp tục), `null` nếu không có.
  final SavedGame? savedGame;

  bool get hasSavedGame => savedGame != null;

  HomeState copyWith({
    GameMode? mode,
    AiLevel? level,
    ColorChoice? colorChoice,
  }) {
    return HomeState(
      mode: mode ?? this.mode,
      level: level ?? this.level,
      colorChoice: colorChoice ?? this.colorChoice,
      savedGame: savedGame,
    );
  }

  @override
  List<Object?> get props => [mode, level, colorChoice, savedGame];
}
