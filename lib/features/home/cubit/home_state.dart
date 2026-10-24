part of 'home_cubit.dart';

enum ColorChoice { white, black, random }

final class HomeState extends Equatable {
  const HomeState({
    this.mode = GameMode.pve,
    this.level = AiLevel.medium,
    this.colorChoice = ColorChoice.white,
    this.hasSavedGame = false,
  });

  final GameMode mode;
  final AiLevel level;
  final ColorChoice colorChoice;
  final bool hasSavedGame;

  HomeState copyWith({
    GameMode? mode,
    AiLevel? level,
    ColorChoice? colorChoice,
    bool? hasSavedGame,
  }) {
    return HomeState(
      mode: mode ?? this.mode,
      level: level ?? this.level,
      colorChoice: colorChoice ?? this.colorChoice,
      hasSavedGame: hasSavedGame ?? this.hasSavedGame,
    );
  }

  @override
  List<Object?> get props => [mode, level, colorChoice, hasSavedGame];
}
