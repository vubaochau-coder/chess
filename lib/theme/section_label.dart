import 'package:flutter/material.dart';

/// Nhãn nhóm viết hoa, giãn chữ, màu nhấn (`CHẾ ĐỘ`, `GIAO DIỆN`…).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}
