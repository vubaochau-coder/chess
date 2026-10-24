part of 'home_cubit.dart';

enum ColorChoice { white, black, random }

final class HomeState extends Equatable {
  const HomeState({
    this.mode = GameMode.pve,
    this.level = AiLevel.medium,
    this.colorChoice = ColorChoice.white,
  });

  final GameMode mode;
  final AiLevel level;
  final ColorChoice colorChoice;

  HomeState copyWith({
    GameMode? mode,
    AiLevel? level,
    ColorChoice? colorChoice,
  }) {
    return HomeState(
      mode: mode ?? this.mode,
      level: level ?? this.level,
      colorChoice: colorChoice ?? this.colorChoice,
    );
  }

  @override
  List<Object?> get props => [mode, level, colorChoice];
}
