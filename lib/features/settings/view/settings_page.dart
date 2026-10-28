import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:chess/theme/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemTitleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const SectionLabel('Giao diện'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Chế độ màu', style: itemTitleStyle),
                  const SizedBox(height: 10),
                  BlocSelector<SettingsCubit, AppSettings, AppThemeMode>(
                    selector: (settings) => settings.themeMode,
                    builder: (context, themeMode) {
                      return SegmentedButton<AppThemeMode>(
                        showSelectedIcon: false,
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  Text('Màu bàn cờ', style: itemTitleStyle),
                  const SizedBox(height: 12),
                  BlocSelector<SettingsCubit, AppSettings, BoardTheme>(
                    selector: (settings) => settings.boardTheme,
                    builder: (context, currentTheme) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final boardTheme in BoardTheme.values)
                            Expanded(
                              child: _BoardThemePreview(
                                theme: boardTheme,
                                isSelected: boardTheme == currentTheme,
                                onTap: () {
                                  context.read<SettingsCubit>().setBoardTheme(
                                    boardTheme,
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.tertiary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox.square(
                    dimension: 44,
                    child: CustomPaint(
                      painter: _MiniBoardPainter(theme.colors),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                theme.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
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
