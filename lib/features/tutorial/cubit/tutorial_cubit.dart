import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chess/core/storage/tutorial_progress_repository.dart';
import 'package:equatable/equatable.dart';

final class TutorialState extends Equatable {
  const TutorialState({this.completed = const {}});

  /// Id các bài đã hoàn thành.
  final Set<String> completed;

  @override
  List<Object?> get props => [completed];
}

/// Tiến độ học, dùng chung cho màn danh sách bài và màn bài học.
class TutorialCubit extends Cubit<TutorialState> {
  TutorialCubit({required TutorialProgressRepository repository})
    : _repository = repository,
      super(TutorialState(completed: repository.load()));

  final TutorialProgressRepository _repository;

  void markCompleted(String lessonId) {
    if (state.completed.contains(lessonId)) return;
    final next = {...state.completed, lessonId};
    emit(TutorialState(completed: next));
    unawaited(_repository.save(next));
  }
}
