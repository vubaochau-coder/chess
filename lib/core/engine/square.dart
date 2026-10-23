int squareFromName(String name) {
  if (name.length != 2) {
    throw FormatException('Invalid square name: $name');
  }
  final col = name.codeUnitAt(0) - 97; // 'a' = 97
  final rank = int.tryParse(name[1]);
  if (col < 0 || col > 7 || rank == null || rank < 1 || rank > 8) {
    throw FormatException('Invalid square name: $name');
  }
  final row = 8 - rank;
  return row * 8 + col;
}

String squareName(int square) {
  if (square < 0 || square > 63) {
    throw RangeError.range(square, 0, 63, 'square');
  }
  final row = square ~/ 8;
  final col = square % 8;
  final colChar = String.fromCharCode(97 + col);
  final rankChar = '${8 - row}';
  return '$colChar$rankChar';
}
