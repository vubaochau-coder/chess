import 'package:chess/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Co nhẹ [child] khi ngón tay đang nhấn. Chỉ nghe sự kiện con trỏ nên không
/// chặn chạm của nút bên trong; không co khi [enabled] tắt hoặc khi tắt hiệu ứng
/// chuyển động trong cài đặt ([AppMotion]).
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// Tắt khi nút bị vô hiệu để nút không phản hồi như bấm được.
  final bool enabled;

  static const pressedScale = 0.96;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && AppMotion.enabledOf(context);

    return Listener(
      onPointerDown: active ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: active && _pressed ? PressScale.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
