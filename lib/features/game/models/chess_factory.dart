import 'package:chess/features/game/models/chess_model.dart';
import 'package:chess/features/game/models/pieces/black_bishop_model.dart';
import 'package:chess/features/game/models/pieces/black_king_model.dart';
import 'package:chess/features/game/models/pieces/black_knight_model.dart';
import 'package:chess/features/game/models/pieces/black_pawn_model.dart';
import 'package:chess/features/game/models/pieces/black_queen_model.dart';
import 'package:chess/features/game/models/pieces/black_rook_model.dart';
import 'package:chess/features/game/models/pieces/white_bishop_model.dart';
import 'package:chess/features/game/models/pieces/white_king_model.dart';
import 'package:chess/features/game/models/pieces/white_knight_model.dart';
import 'package:chess/features/game/models/pieces/white_pawn_model.dart';
import 'package:chess/features/game/models/pieces/white_queen_model.dart';
import 'package:chess/features/game/models/pieces/white_rook_model.dart';

class Chess {
  static final Chess _instance = Chess._internal();

  Chess._internal();

  factory Chess() {
    return _instance;
  }

  late BlackBishopModel _blackBishopModel;
  late WhiteBishopModel _whiteBishopModel;
  late BlackKingModel _blackKingModel;
  late WhiteKingModel _whiteKingModel;
  late BlackQueenModel _blackQueenModel;
  late WhiteQueenModel _whiteQueenModel;
  late BlackRookModel _blackRookModel;
  late WhiteRookModel _whiteRookModel;
  late BlackKnightModel _blackKnightModel;
  late WhiteKnightModel _whiteKnightModel;
  late BlackPawnModel _blackPawnModel;
  late WhitePawnModel _whitePawnModel;

  void initChess() {
    _blackBishopModel = BlackBishopModel();
    _whiteBishopModel = WhiteBishopModel();
    _blackKingModel = BlackKingModel();
    _whiteKingModel = WhiteKingModel();
    _blackQueenModel = BlackQueenModel();
    _whiteQueenModel = WhiteQueenModel();
    _blackRookModel = BlackRookModel();
    _whiteRookModel = WhiteRookModel();
    _blackKnightModel = BlackKnightModel();
    _whiteKnightModel = WhiteKnightModel();
    _blackPawnModel = BlackPawnModel();
    _whitePawnModel = WhitePawnModel();
  }

  BlackBishopModel get bBishop => _blackBishopModel;
  WhiteBishopModel get wBishop => _whiteBishopModel;

  BlackKingModel get bKing => _blackKingModel;
  WhiteKingModel get wKing => _whiteKingModel;

  BlackQueenModel get bQueen => _blackQueenModel;
  WhiteQueenModel get wQueen => _whiteQueenModel;

  BlackRookModel get bRook => _blackRookModel;
  WhiteRookModel get wRook => _whiteRookModel;

  BlackKnightModel get bKnight => _blackKnightModel;
  WhiteKnightModel get wKnight => _whiteKnightModel;

  BlackPawnModel get bPawn => _blackPawnModel;
  WhitePawnModel get wPawn => _whitePawnModel;

  ChessModel? fromString(String chess) {
    switch (chess) {
      case 'K':
        return _whiteKingModel;
      case 'Q':
        return _whiteQueenModel;
      case 'R':
        return _whiteRookModel;
      case 'B':
        return _whiteBishopModel;
      case 'N':
        return _whiteKnightModel;
      case 'P':
        return _whitePawnModel;
      case 'k':
        return _blackKingModel;
      case 'q':
        return _blackQueenModel;
      case 'r':
        return _blackRookModel;
      case 'b':
        return _blackBishopModel;
      case 'n':
        return _blackKnightModel;
      case 'p':
        return _blackPawnModel;
      default:
        return null;
    }
  }
}
