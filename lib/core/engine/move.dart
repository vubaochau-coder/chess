import 'package:chess/core/engine/square.dart';
import 'package:equatable/equatable.dart';

final class Move extends Equatable {
  const Move(this.from, this.to, {this.promotion});

  final int from;
  final int to;
  final String? promotion; // 'q'|'r'|'b'|'n' hoặc null

  String toUci() => '${squareName(from)}${squareName(to)}${promotion ?? ''}';

  static Move fromUci(String uci) {
    if (uci.length != 4 && uci.length != 5) {
      throw FormatException('Invalid UCI move length: $uci');
    }
    final from = squareFromName(uci.substring(0, 2));
    final to = squareFromName(uci.substring(2, 4));
    String? promotion;
    if (uci.length == 5) {
      promotion = uci[4].toLowerCase();
      if (!const {'q', 'r', 'b', 'n'}.contains(promotion)) {
        throw FormatException('Invalid UCI promotion piece: $promotion');
      }
    }
    return Move(from, to, promotion: promotion);
  }

  @override
  List<Object?> get props => [from, to, promotion];
}
