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
    final colorScheme = Theme.of(context).colorScheme;
    final colors = theme.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ColoredBox(color: colors.lightSquare),
                          ),
                          Expanded(child: ColoredBox(color: colors.darkSquare)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: ColoredBox(color: colors.darkSquare)),
                          Expanded(
                            child: ColoredBox(color: colors.lightSquare),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(theme.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
