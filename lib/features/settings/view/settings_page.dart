import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:chess/theme/piece_set.dart';
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
              // Dòng công tắc cuối đã có đệm dọc riêng; lề dưới nhỏ hơn để
              // khoảng trống trên/dưới dòng đó cân nhau.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  Text('Bộ quân cờ', style: itemTitleStyle),
                  const SizedBox(height: 12),
                  BlocSelector<SettingsCubit, AppSettings, _PieceSetOptions>(
                    selector: (settings) => (
                      pieceSet: settings.pieceSet,
                      boardTheme: settings.boardTheme,
                    ),
                    builder: (context, options) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final pieceSet in PieceSet.values)
                            Expanded(
                              child: _PieceSetPreview(
                                pieceSet: pieceSet,
                                colors: options.boardTheme.colors,
                                isSelected: pieceSet == options.pieceSet,
                                onTap: () {
                                  context.read<SettingsCubit>().setPieceSet(
                                    pieceSet,
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Divider(),
                  ),
                  _SettingSwitch(
                    title: 'Hiệu ứng chuyển động',
                    contentPadding: EdgeInsets.zero,
                    select: (s) => s.animationsEnabled,
                    onChanged: (cubit, v) => cubit.setAnimationsEnabled(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Bàn cờ'),
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingSwitch(
                  title: 'Hiện tọa độ',
                  select: (s) => s.showCoordinates,
                  onChanged: (cubit, v) => cubit.setShowCoordinates(v),
                ),
                const Divider(),
                _SettingSwitch(
                  title: 'Hiện nước đi hợp lệ',
                  select: (s) => s.showLegalMoves,
                  onChanged: (cubit, v) => cubit.setShowLegalMoves(v),
                ),
                const Divider(),
                _SettingSwitch(
                  title: 'Tô nước vừa đi',
                  select: (s) => s.highlightLastMove,
                  onChanged: (cubit, v) => cubit.setHighlightLastMove(v),
                ),
                const Divider(),
                _SettingSwitch(
                  title: 'Tự lật bàn khi chơi 2 người',
                  select: (s) => s.autoFlipInPvp,
                  onChanged: (cubit, v) => cubit.setAutoFlipInPvp(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Âm thanh'),
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingSwitch(
                  title: 'Âm thanh',
                  select: (s) => s.soundEnabled,
                  onChanged: (cubit, v) => cubit.setSoundEnabled(v),
                ),
                const Divider(),
                const _VolumeTile(),
                const Divider(),
                _SettingSwitch(
                  title: 'Rung',
                  select: (s) => s.hapticsEnabled,
                  onChanged: (cubit, v) => cubit.setHapticsEnabled(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Một công tắc cài đặt; chỉ rebuild khi đúng field nó hiển thị thay đổi.
///
/// Công tắc thu nhỏ còn [_switchScale] cho gọn; cả dòng vẫn bấm được nên vùng
/// chạm không nhỏ đi. `Transform.scale` không thu khung bố cục, nên đặt công tắc
/// trong khung đúng bằng rãnh đã thu nhỏ: mép phải rãnh cách mép thẻ đúng bằng lề
/// trái của chữ.
class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.select,
    required this.onChanged,
    this.contentPadding,
  });

  final String title;
  final bool Function(AppSettings settings) select;
  final void Function(SettingsCubit cubit, bool value) onChanged;
  final EdgeInsetsGeometry? contentPadding;

  static const _switchScale = 0.65;

  /// Kích thước rãnh công tắc Material 3; công tắc vẽ rãnh ở giữa khung của nó.
  static const _trackSize = Size(52, 32);

  /// Lề ngang của dòng, bằng lề trong của thẻ có [contentPadding] = 0.
  static const _horizontalPadding = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsCubit, AppSettings, bool>(
      selector: select,
      builder: (context, value) {
        void toggle(bool v) => onChanged(context.read<SettingsCubit>(), v);
        return MergeSemantics(
          child: ListTile(
            title: Text(title, style: const TextStyle(fontSize: 14)),
            contentPadding: contentPadding ?? _horizontalPadding,
            onTap: () => toggle(!value),
            trailing: SizedBox.fromSize(
              size: _trackSize * _switchScale,
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.scale(
                  scale: _switchScale,
                  child: Switch(
                    value: value,
                    onChanged: toggle,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thanh âm lượng (tắt theo công tắc Âm thanh); thả tay thì phát thử.
class _VolumeTile extends StatelessWidget {
  const _VolumeTile();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsCubit, AppSettings, (bool, double)>(
      selector: (s) => (s.soundEnabled, s.soundVolume),
      builder: (context, value) {
        final (enabled, volume) = value;
        final cubit = context.read<SettingsCubit>();
        void preview(double _) =>
            context.read<SoundPlayer>().play(SoundEffect.move);

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              const Text('Âm lượng', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Slider(
                  value: volume,
                  onChanged: enabled ? cubit.setSoundVolume : null,
                  onChangeEnd: enabled ? preview : null,
                ),
              ),
            ],
          ),
        );
      },
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

typedef _PieceSetOptions = ({PieceSet pieceSet, BoardTheme boardTheme});

/// Vua trắng trên ô sáng và mã đen trên ô tối theo màu bàn cờ đang chọn,
/// để thấy trước bộ quân có dễ nhìn trên bàn cờ hay không.
class _PieceSetPreview extends StatelessWidget {
  const _PieceSetPreview({
    required this.pieceSet,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  static const _squareSize = 30.0;

  final PieceSet pieceSet;
  final BoardColors colors;
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _square(colors.lightSquare, 'K'),
                      _square(colors.darkSquare, 'n'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pieceSet.label,
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

  Widget _square(Color color, String piece) {
    return ColoredBox(
      color: color,
      child: SizedBox.square(
        dimension: _squareSize,
        child: Center(
          child: PieceView(
            piece: piece,
            size: _squareSize * 0.85,
            pieceSet: pieceSet,
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
