import 'package:bloc/bloc.dart';
import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:equatable/equatable.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void setMode(GameMode mode) => emit(state.copyWith(mode: mode));
  void setLevel(AiLevel level) => emit(state.copyWith(level: level));
  void setColorChoice(ColorChoice choice) =>
      emit(state.copyWith(colorChoice: choice));
}
