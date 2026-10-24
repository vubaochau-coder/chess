import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
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
        ],
      ),
    );
  }
}
