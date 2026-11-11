enum TokenType {
  blank,
  moveRight,
  moveLeft,
  moveUp,
  moveDown,
  repeat,
  ifThen,
  blockOpen,
  blockClose,
  print,
  assign,
  digit,
  variable,
  text,
}

class Cell {
  final int row;
  final int col;
  final TokenType type;
  final String raw;
  final int? digit;
  final String? varName;
  const Cell(
      {required this.row,
      required this.col,
      required this.type,
      this.raw = '',
      this.digit,
      this.varName});
}

class Program {
  final List<Cell> cells;
  final Map<String, int> vars;
  const Program({required this.cells, required this.vars});
}
