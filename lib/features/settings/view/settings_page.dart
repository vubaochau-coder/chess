import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Giao diện',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Chế độ màu'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: BlocSelector<SettingsCubit, AppSettings, AppThemeMode>(
                selector: (settings) => settings.themeMode,
                builder: (context, themeMode) {
                  return SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: AppThemeMode.system,
                        label: Text('Theo hệ thống'),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.light,
                        label: Text('Sáng'),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.dark,
                        label: Text('Tối'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selected) {
                      context.read<SettingsCubit>().setThemeMode(
                        selected.first,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Màu bàn cờ'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: BlocSelector<SettingsCubit, AppSettings, BoardTheme>(
                selector: (settings) => settings.boardTheme,
                builder: (context, currentTheme) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final boardTheme in BoardTheme.values) ...[
                          _BoardThemePreview(
                            theme: boardTheme,
                            isSelected: boardTheme == currentTheme,
                            onTap: () {
                              context.read<SettingsCubit>().setBoardTheme(
                                boardTheme,
                              );
                            },
                          ),
                          if (boardTheme != BoardTheme.values.last)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardThemePreview extends StatelessWidget {
  const _BoardThemePreview({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final BoardTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final colors = theme.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.5 : 1,
          ),
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.25)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox.square(
                  dimension: 48,
                  child: CustomPaint(painter: _MiniBoardPainter(colors)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              theme.label,
              style: themeData.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  const _MiniBoardPainter(this.colors);

  final BoardColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / 2;
    final cellH = size.height / 2;
    final light = Paint()..color = colors.lightSquare;
    final dark = Paint()..color = colors.darkSquare;

    canvas.drawRect(Rect.fromLTWH(0, 0, cellW, cellH), light);
    canvas.drawRect(Rect.fromLTWH(cellW, 0, cellW, cellH), dark);
    canvas.drawRect(Rect.fromLTWH(0, cellH, cellW, cellH), dark);
    canvas.drawRect(Rect.fromLTWH(cellW, cellH, cellW, cellH), light);
  }

  @override
  bool shouldRepaint(_MiniBoardPainter oldDelegate) =>
      colors != oldDelegate.colors;
}
