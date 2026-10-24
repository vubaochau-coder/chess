import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/engine/san.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:equatable/equatable.dart';

part 'chess_game_event.dart';
part 'chess_game_state.dart';

class ChessGameBloc extends Bloc<ChessGameEvent, ChessGameState> {
  ChessGameBloc({
    required SoundPlayer soundPlayer,
    required ChessAi ai,
    GameRepository? gameRepository,
    required GameConfig config,
    GamePosition? startPosition,
    SavedGame? restore,
  }) : this._(
         soundPlayer,
         ai,
         gameRepository ?? const NoopGameRepository(),
         restore?.config ?? config,
         restore != null
             ? Fen.parse(restore.startFen)
             : (startPosition ?? GamePosition.initial()),
         restore,
       );

  ChessGameBloc._(
    this._sound,
    this._ai,
    this._repository,
    this._config,
    this._start,
    SavedGame? restore,
  ) : super(
        restore != null
            ? ChessGameState.restore(restore)
            : ChessGameState.initial(_start, config: _config),
      ) {
    on<NewGameRequested>(_onNewGameRequested);
    on<SquareTapped>(_onSquareTapped);
    on<PromotionPieceSelected>(_onPromotionPieceSelected);
    on<PromotionCancelled>(_onPromotionCancelled);
    on<UndoRequested>(_onUndoRequested);
    on<ResignRequested>(_onResignRequested);
    on<_AiMoveRequested>(_onAiMoveRequested, transformer: restartable());

    if (restore == null) {
      _saveGame();
    }
    _checkRequestAiMove();
  }

  final SoundPlayer _sound;
  final ChessAi _ai;
  final GameRepository _repository;
  final GameConfig _config;
  final GamePosition _start;
  int _gameId = 0;

  void _onNewGameRequested(
    NewGameRequested event,
    Emitter<ChessGameState> emit,
  ) {
    _gameId++;
    emit(ChessGameState.initial(_start, config: _config, gameId: _gameId));
    _saveGame();
    _checkRequestAiMove();
  }

  void _onSquareTapped(SquareTapped event, Emitter<ChessGameState> emit) {
    if (state.isGameOver ||
        state.pendingPromotion != null ||
        state.isAiThinking ||
        !state.isHumanTurn) {
      return;
    }

    final square = event.index;
    final piece = state.position.board[square];
    final isOwnPiece =
        piece.isNotEmpty &&
        ChessRules.isWhite(piece) == state.position.whiteToMove;

    if (isOwnPiece) {
      _sound.play(SoundEffect.select);
      if (state.selected == square) {
        emit(state.withoutSelection());
      } else {
        emit(
          state.withSelection(
            square,
            ChessRules.legalMoves(state.position, square),
          ),
        );
      }
      return;
    }

    final from = state.selected;
    if (from == null) return;

    if (!state.legalTargets.contains(square)) {
      _sound.play(SoundEffect.illegal);
      return;
    }

    if (ChessRules.isPromotionMove(state.position, from, square)) {
      emit(state.withPendingPromotion((from: from, to: square)));
      return;
    }

    final record = _createRecord(from, square);
    final result = ChessRules.applyMove(state.position, from, square);
    final next = state.afterMove(result.position, record);
    _sound.play(_moveSound(result, next.status));
    emit(next);
    if (next.isGameOver) {
      _clearGame();
    } else {
      _saveGame();
    }
    _checkRequestAiMove();
  }

  void _onPromotionPieceSelected(
    PromotionPieceSelected event,
    Emitter<ChessGameState> emit,
  ) {
    final pending = state.pendingPromotion;
    if (pending == null) return;

    final record = _createRecord(
      pending.from,
      pending.to,
      promotion: event.piece,
    );
    final result = ChessRules.applyMove(
      state.position,
      pending.from,
      pending.to,
      promotion: event.piece,
    );
    final next = state.afterMove(result.position, record);
    _sound.play(_moveSound(result, next.status));
    emit(next);
    if (next.isGameOver) {
      _clearGame();
    } else {
      _saveGame();
    }
    _checkRequestAiMove();
  }

  void _onPromotionCancelled(
    PromotionCancelled event,
    Emitter<ChessGameState> emit,
  ) {
    if (state.pendingPromotion == null) return;
    emit(state.withoutPendingPromotion());
  }

  void _onUndoRequested(UndoRequested event, Emitter<ChessGameState> emit) {
    if (!state.canUndo) return;
    emit(state.undo());
    if (state.isGameOver) {
      _clearGame();
    } else {
      _saveGame();
    }
    _checkRequestAiMove();
  }

  void _onResignRequested(ResignRequested event, Emitter<ChessGameState> emit) {
    if (state.isGameOver) return;

    final GameStatus resignStatus;
    if (state.config.mode == GameMode.pvp) {
      resignStatus = state.position.whiteToMove
          ? GameStatus.whiteResigned
          : GameStatus.blackResigned;
    } else {
      resignStatus = state.config.humanColor == PieceColor.white
          ? GameStatus.whiteResigned
          : GameStatus.blackResigned;
    }

    _sound.play(SoundEffect.gameEnd);
    emit(state.resigned(resignStatus));
    _clearGame();
  }

  Future<void> _onAiMoveRequested(
    _AiMoveRequested event,
    Emitter<ChessGameState> emit,
  ) async {
    if (state.gameId != event.gameId ||
        state.moves.length != event.ply ||
        state.isGameOver) {
      return;
    }
    emit(state.copyWith(isAiThinking: true));
    final move = await _ai.chooseMove(state.history, state.config.level);
    if (state.gameId != event.gameId ||
        state.moves.length != event.ply ||
        state.isGameOver) {
      return;
    }
    final record = _createRecord(move.from, move.to, promotion: move.promotion);
    final result = ChessRules.applyMove(
      state.position,
      move.from,
      move.to,
      promotion: move.promotion ?? 'q',
    );
    final next = state.afterMove(result.position, record);
    _sound.play(_moveSound(result, next.status));
    emit(next);
    if (next.isGameOver) {
      _clearGame();
    } else {
      _saveGame();
    }
  }

  void _clearGame() => unawaited(_repository.clear());

  void _saveGame() {
    if (state.isGameOver) {
      _clearGame();
      return;
    }
    final uciMoves = state.moves.map((r) => r.move.toUci()).toList();
    final saved = SavedGame(
      startFen: Fen.format(_start),
      moves: uciMoves,
      config: state.config,
    );
    unawaited(_repository.save(saved));
  }

  void _checkRequestAiMove() {
    if (state.config.mode == GameMode.pve &&
        !state.isGameOver &&
        !state.isHumanTurn &&
        !state.isAiThinking) {
      add(_AiMoveRequested(gameId: state.gameId, ply: state.moves.length));
    }
  }

  MoveRecord _createRecord(int from, int to, {String? promotion}) {
    final before = state.position;
    final move = Move(from, to, promotion: promotion);
    final san = San.format(before, move);
    final type = before.board[from].toLowerCase();
    final isEnPassant = type == 'p' && to == before.enPassant;
    final captured = isEnPassant
        ? before.board[(from ~/ 8) * 8 + (to % 8)]
        : (before.board[to].isNotEmpty ? before.board[to] : null);
    return MoveRecord(move: move, san: san, captured: captured);
  }

  SoundEffect _moveSound(MoveResult result, GameStatus status) {
    if (status.isGameOver) {
      return SoundEffect.gameEnd;
    }
    return switch (status) {
      GameStatus.check => SoundEffect.check,
      GameStatus.playing when result.isPromotion => SoundEffect.promote,
      GameStatus.playing when result.isCastle => SoundEffect.castle,
      GameStatus.playing when result.isCapture => SoundEffect.capture,
      _ => SoundEffect.move,
    };
  }
}
