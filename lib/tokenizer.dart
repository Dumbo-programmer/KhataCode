import 'models.dart';
import 'tokens.dart';

Program tokenize(List<List<String?>> grid) {
  final cells = <Cell>[];
  final vars = <String, int>{'a': 0, 'b': 0, 'c': 0};
  for (var row = 0; row < grid.length; row++) {
    for (var col = 0; col < grid[row].length; col++) {
      final raw = grid[row][col] ?? '';
      if (row == 16 && col < 3) {
        vars[String.fromCharCode(97 + col)] = int.tryParse(raw) ?? 0;
        continue;
      }
      final type = tokenLookup[raw] ?? TokenType.blank;
      cells.add(Cell(
          row: row,
          col: col,
          type: type,
          raw: raw,
          digit: type == TokenType.digit
              ? (raw == 'O' ? 0 : int.tryParse(raw))
              : null,
          varName: type == TokenType.variable ? raw.toLowerCase() : null));
    }
  }
  return Program(cells: cells, vars: vars);
}
