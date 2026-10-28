import 'package:chess/core/storage/tutorial_progress_repository.dart';
import 'package:chess/core/tutorial/lesson.dart';
import 'package:chess/core/tutorial/lesson_catalog.dart';
import 'package:chess/features/tutorial/cubit/tutorial_cubit.dart';
import 'package:chess/features/tutorial/view/lesson_page.dart';
import 'package:chess/theme/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tạo [TutorialCubit] cho màn `Học chơi cờ`; cubit được chia sẻ xuống các
/// màn bài học để cập nhật tiến độ.
class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TutorialCubit(
        repository: context.read<TutorialProgressRepository>(),
      ),
      child: const TutorialView(),
    );
  }
}

class TutorialView extends StatelessWidget {
  const TutorialView({super.key});

  @override
  Widget build(BuildContext context) {
    const lessons = LessonCatalog.lessons;

    return Scaffold(
      appBar: AppBar(title: const Text('Học chơi cờ')),
      body: BlocSelector<TutorialCubit, TutorialState, Set<String>>(
        selector: (state) => state.completed,
        builder: (context, completed) {
          final done = lessons.where((l) => completed.contains(l.id)).length;
          final nextIndex = lessons.indexWhere(
            (l) => !completed.contains(l.id),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _ProgressCard(
                done: done,
                total: lessons.length,
                next: nextIndex < 0 ? null : lessons[nextIndex],
              ),
              for (var c = 0; c < LessonCatalog.chapters.length; c++) ...[
                const SizedBox(height: 24),
                _ChapterHeader(chapter: c, completed: completed),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < lessons.length; i++)
                        if (lessons[i].chapter == c)
                          _LessonTile(
                            index: i,
                            number: i + 1,
                            done: completed.contains(lessons[i].id),
                            isNext: i == nextIndex,
                          ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.done,
    required this.total,
    required this.next,
  });

  final int done;
  final int total;
  final Lesson? next;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextLesson = next;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.tertiary),
              ),
              child: Icon(Icons.school_outlined, color: colorScheme.tertiary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tiến độ của bạn',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '$done/$total bài',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0.0 : done / total,
                      minHeight: 6,
                      color: colorScheme.tertiary,
                      backgroundColor: colorScheme.outlineVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextLesson == null
                        ? 'Bạn đã học xong tất cả các bài!'
                        : 'Tiếp theo: ${nextLesson.title}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.chapter, required this.completed});

  final int chapter;
  final Set<String> completed;

  @override
  Widget build(BuildContext context) {
    const all = LessonCatalog.lessons;
    final lessons = all.where((l) => l.chapter == chapter).toList();
    final done = lessons.where((l) => completed.contains(l.id)).length;

    return Row(
      children: [
        Expanded(
          child: SectionLabel(
            'Chương ${chapter + 1} · ${LessonCatalog.chapters[chapter]}',
          ),
        ),
        Text(
          '$done/${lessons.length}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.index,
    required this.number,
    required this.done,
    required this.isNext,
  });

  final int index;
  final int number;
  final bool done;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lesson = LessonCatalog.lessons[index];

    return Material(
      color: isNext ? colorScheme.surfaceContainerHigh : Colors.transparent,
      child: InkWell(
        onTap: () => openLesson(context, index),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? colorScheme.tertiary : null,
                  border: done
                      ? null
                      : Border.all(
                          color: isNext
                              ? colorScheme.tertiary
                              : colorScheme.outlineVariant,
                          width: isNext ? 1.5 : 1,
                        ),
                ),
                child: done
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: colorScheme.onTertiary,
                      )
                    : Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isNext
                              ? colorScheme.tertiary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
