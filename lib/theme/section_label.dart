import 'package:flutter/material.dart';

/// Nhãn nhóm giãn chữ, màu nhấn (`Chế độ`, `Giao diện`…).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}
