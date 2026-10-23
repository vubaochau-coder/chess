/// Âm thanh game dùng. Mỗi giá trị gắn với một file trong `assets/audio/`.
enum SoundEffect {
  select('audio/click.mp3'),
  illegal('audio/illegal.mp3'),
  move('audio/move-self.mp3'),
  capture('audio/capture.mp3'),
  castle('audio/castle.mp3'),
  check('audio/move-check.mp3'),
  promote('audio/promote.mp3'),
  gameEnd('audio/game-end.mp3');

  const SoundEffect(this.asset);

  /// Đường dẫn tương đối với `assets/` (định dạng `AssetSource` của audioplayers).
  final String asset;
}
