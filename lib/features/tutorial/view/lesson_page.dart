import 'package:chess/core/tutorial/lesson.dart';
import 'package:chess/core/tutorial/lesson_board.dart';
import 'package:chess/core/tutorial/lesson_catalog.dart';
import 'package:chess/features/tutorial/cubit/lesson_cubit.dart';
import 'package:chess/features/tutorial/cubit/tutorial_cubit.dart';
import 'package:chess/features/tutorial/widgets/lesson_board_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mở bài học thứ [index], dùng chung [TutorialCubit] của màn gọi.
Future<void> openLesson(
  BuildContext context,
  int index, {
  bool replace = false,
}) {
  final route = MaterialPageRoute<void>(
    builder: (_) => BlocProvider.value(
      value: context.read<TutorialCubit>(),
      child: LessonPage(index: index),
    ),
  );
  return replace
      ? Navigator.pushReplacement<void, void>(context, route)
      : Navigator.push<void>(context, route);
}

class LessonPage extends StatelessWidget {
  const LessonPage({super.key, required this.index});

  /// Chỉ số bài trong `LessonCatalog.lessons`.
  final int index;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LessonCubit(LessonCatalog.lessons[index]),
      child: LessonView(index: index),
    );
  }
}

class LessonView extends StatelessWidget {
  const LessonView({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lesson = LessonCatalog.lessons[index];
    final chapterLessons = [
      for (var i = 0; i < LessonCatalog.lessons.length; i++)
        if (LessonCatalog.lessons[i].chapter == lesson.chapter) i,
    ];
    final position = chapterLessons.indexOf(index) + 1;
    final challenge = lesson.challenge;

    return BlocListener<LessonCubit, LessonBoard>(
      listenWhen: (previous, current) =>
          previous.result != LessonResult.success &&
          current.result == LessonResult.success,
      listener: (context, state) {
        context.read<TutorialCubit>().markCompleted(lesson.id);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lesson.title),
              Text(
                'Chương ${lesson.chapter + 1} · '
                'Bài $position/${chapterLessons.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    _ChapterProgress(
                      lessonIndices: chapterLessons,
                      current: index,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lesson.body.join(' '),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (challenge != null) ...[
                      const SizedBox(height: 12),
                      _ChallengeCard(challenge: challenge),
                    ],
                    const SizedBox(height: 14),
                    const Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 420),
                        child: _Frame(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: LessonBoardView(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Feedback(hasChallenge: challenge != null),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.read<LessonCubit>().reset(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(64, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Làm lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _NextButton(index: index)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(2), child: child),
    );
  }
}

/// Thanh tiến độ trong chương: mỗi bài một vạch.
class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.lessonIndices, required this.current});

  final List<int> lessonIndices;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocSelector<TutorialCubit, TutorialState, Set<String>>(
      selector: (state) => state.completed,
      builder: (context, completed) {
        return Row(
          children: [
            for (final i in lessonIndices)
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: completed.contains(LessonCatalog.lessons[i].id)
                        ? colorScheme.tertiary
                        : i == current
                        ? colorScheme.tertiary.withValues(alpha: 0.5)
                        : colorScheme.outlineVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final LessonChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, size: 20, color: colorScheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thử thách: ${challenge.prompt}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (challenge.kind == ChallengeKind.reach)
            BlocSelector<LessonCubit, LessonBoard, int>(
              selector: (board) => board.movesMade,
              builder: (context, moves) => Text(
                'Nước $moves/${challenge.maxMoves}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.tertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.hasChallenge});

  final bool hasChallenge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocSelector<LessonCubit, LessonBoard, LessonResult>(
      selector: (board) => board.result,
      builder: (context, result) {
        switch (result) {
          case LessonResult.success:
            return _Banner(
              icon: Icons.check_rounded,
              text: 'Tuyệt vời! Bạn đã hoàn thành thử thách.',
              background: colorScheme.primaryContainer,
              border: colorScheme.tertiary,
              foreground: colorScheme.onPrimaryContainer,
            );
          case LessonResult.failed:
            return _Banner(
              icon: Icons.refresh_rounded,
              text: 'Chưa đúng rồi. Bấm Làm lại để thử lần nữa nhé.',
              background: colorScheme.surfaceContainerHigh,
              border: colorScheme.outlineVariant,
              foreground: colorScheme.onSurface,
            );
          case LessonResult.playing:
            return Text(
              hasChallenge
                  ? 'Chạm vào một quân Trắng, rồi chạm ô có chấm để đi.'
                  : 'Chạm vào các quân Trắng để thử đi, rồi bấm Bài tiếp.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            );
        }
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `Bài tiếp` (hoặc `Hoàn thành` ở bài cuối). Bài có thử thách chỉ đi tiếp
/// được khi đã làm đúng; bài không có thử thách được tính xong khi bấm nút.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final lesson = LessonCatalog.lessons[index];
    final isLast = index == LessonCatalog.lessons.length - 1;

    return BlocSelector<LessonCubit, LessonBoard, bool>(
      selector: (board) =>
          lesson.challenge == null || board.result == LessonResult.success,
      builder: (context, enabled) {
        return FilledButton(
          onPressed: enabled
              ? () {
                  context.read<TutorialCubit>().markCompleted(lesson.id);
                  if (isLast) {
                    Navigator.pop(context);
                  } else {
                    openLesson(context, index + 1, replace: true);
                  }
                }
              : null,
          child: Text(isLast ? 'Hoàn thành' : 'Bài tiếp'),
        );
      },
    );
  }
}
