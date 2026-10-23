import 'dart:async';

import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/features/game/view/game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Service dùng chung cả app được tạo và dispose ở đây, rồi truyền vào bloc.
    return RepositoryProvider<SoundPlayer>(
      create: (_) => AudioPoolSoundPlayer(),
      dispose: (player) => unawaited(player.dispose()),
      child: MaterialApp(
        title: 'Chess',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const GamePage(),
      ),
    );
  }
}
