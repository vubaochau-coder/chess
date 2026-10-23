import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:chess/core/audio/sound_effect.dart';

/// Phát hiệu ứng âm thanh. Bloc chỉ phụ thuộc interface này để test được
/// (dùng mock) và để đổi cách phát (bộ âm thanh, tắt tiếng…) mà không sửa bloc.
abstract interface class SoundPlayer {
  /// Không chờ âm thanh phát xong; lỗi phát âm thanh không được làm hỏng game.
  void play(SoundEffect effect);

  Future<void> dispose();
}

/// Mỗi hiệu ứng có một [AudioPool] riêng, tạo khi phát lần đầu, để các âm
/// phát liên tiếp không cắt nhau và có độ trễ thấp.
class AudioPoolSoundPlayer implements SoundPlayer {
  final Map<SoundEffect, Future<AudioPool>> _pools = {};

  @override
  void play(SoundEffect effect) {
    unawaited(_play(effect));
  }

  Future<void> _play(SoundEffect effect) async {
    // Lỗi âm thanh (thiếu file, thiết bị không phát được) chỉ bỏ qua,
    // game vẫn chạy bình thường.
    final AudioPool pool;
    try {
      pool = await _pools.putIfAbsent(
        effect,
        () => AudioPool.createFromAsset(path: effect.asset, maxPlayers: 2),
      );
    } on Object {
      // Tạo pool lỗi: bỏ đi để lần sau thử tạo lại.
      _pools.remove(effect)?.ignore();
      return;
    }
    try {
      await pool.start();
    } on Object {
      return;
    }
  }

  @override
  Future<void> dispose() async {
    final pools = List.of(_pools.values);
    _pools.clear();
    for (final pool in pools) {
      try {
        await (await pool).dispose();
      } on Object {
        // Pool tạo lỗi thì không có gì để giải phóng.
      }
    }
  }
}
