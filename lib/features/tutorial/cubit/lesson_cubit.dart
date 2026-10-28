import 'package:bloc/bloc.dart';
import 'package:chess/core/tutorial/lesson.dart';
import 'package:chess/core/tutorial/lesson_board.dart';

class LessonCubit extends Cubit<LessonBoard> {
  LessonCubit(Lesson lesson) : super(LessonBoard.start(lesson));

  void tap(int square) => emit(state.tap(square));

  void reset() => emit(LessonBoard.start(state.lesson));
}
