import 'package:flutter/material.dart';

final class BoardColors {
  const BoardColors({
    required this.lightSquare,
    required this.darkSquare,
    required this.lightSelected,
    required this.darkSelected,
    required this.hint,
    required this.check,
  });

  final Color lightSquare;
  final Color darkSquare;
  final Color lightSelected;
  final Color darkSelected;
  final Color hint;
  final Color check;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardColors &&
          runtimeType == other.runtimeType &&
          lightSquare == other.lightSquare &&
          darkSquare == other.darkSquare &&
          lightSelected == other.lightSelected &&
          darkSelected == other.darkSelected &&
          hint == other.hint &&
          check == other.check;

  @override
  int get hashCode => Object.hash(
    lightSquare,
    darkSquare,
    lightSelected,
    darkSelected,
    hint,
    check,
  );
}

enum BoardTheme {
  wood(
    label: 'Gỗ',
    colors: BoardColors(
      lightSquare: Color(0xFFF2E1C3),
      darkSquare: Color(0xFFC3A082),
      lightSelected: Color(0xFFF9F07B),
      darkSelected: Color(0xFFE2CF57),
      hint: Color(0xFF80361B),
      check: Color(0xCCE53935),
    ),
  ),
  green(
    label: 'Xanh lá',
    colors: BoardColors(
      lightSquare: Color(0xFFEEEED2),
      darkSquare: Color(0xFF769656),
      lightSelected: Color(0xFFF6F669),
      darkSelected: Color(0xFFBACA2B),
      hint: Color(0x59000000),
      check: Color(0xCCE53935),
    ),
  ),
  blue(
    label: 'Xanh dương',
    colors: BoardColors(
      lightSquare: Color(0xFFDEE3E6),
      darkSquare: Color(0xFF8CA2AD),
      lightSelected: Color(0xFFE5EB9B),
      darkSelected: Color(0xFFB8C46A),
      hint: Color(0x59000000),
      check: Color(0xCCE53935),
    ),
  ),
  gray(
    label: 'Xám',
    colors: BoardColors(
      lightSquare: Color(0xFFE8E8E8),
      darkSquare: Color(0xFFA0A0A0),
      lightSelected: Color(0xFFF5F682),
      darkSelected: Color(0xFFB9CA43),
      hint: Color(0x59000000),
      check: Color(0xCCE53935),
    ),
  ),
  purple(
    label: 'Tím',
    colors: BoardColors(
      lightSquare: Color(0xFFEDE4F7),
      darkSquare: Color(0xFF9F86C0),
      lightSelected: Color(0xFFF5F682),
      darkSelected: Color(0xFFC8B95A),
      hint: Color(0x59000000),
      check: Color(0xCCE53935),
    ),
  );

  const BoardTheme({required this.label, required this.colors});

  final String label;
  final BoardColors colors;

  static BoardTheme fromName(String? name) {
    return switch (name) {
      'green' => BoardTheme.green,
      'blue' => BoardTheme.blue,
      'gray' => BoardTheme.gray,
      'purple' => BoardTheme.purple,
      _ => BoardTheme.wood,
    };
  }
}
