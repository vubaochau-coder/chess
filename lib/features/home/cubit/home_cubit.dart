import 'package:bloc/bloc.dart';
import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:equatable/equatable.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit([GameRepository? repository])
    : _repository = repository ?? const NoopGameRepository(),
      super(
        HomeState(savedGame: (repository ?? const NoopGameRepository()).load()),
      );

  final GameRepository _repository;

  void setMode(GameMode mode) => emit(state.copyWith(mode: mode));
  void setLevel(AiLevel level) => emit(state.copyWith(level: level));
  void setColorChoice(ColorChoice choice) =>
      emit(state.copyWith(colorChoice: choice));

  void refresh() {
    emit(
      HomeState(
        mode: state.mode,
        level: state.level,
        colorChoice: state.colorChoice,
        savedGame: _repository.load(),
      ),
    );
  }
}
