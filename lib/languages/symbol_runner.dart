import '../models.dart';

class ProgramError implements Exception {
  final int? row;
  final String message;
  const ProgramError(this.message, {this.row});
  @override
  String toString() => message;
}

abstract class LanguageRunner {
  String build(List<Cell> cells);
}

class SymbolRunner implements LanguageRunner {
  final Map<String, int> initialVars;
  int statements = 0;
  final vars = <String, int>{};
  final path = <String>['0,0'];
  final output = <String>[];
  SymbolRunner([Map<String, int>? variables])
      : initialVars = variables ?? const {};

  @override
  String build(List<Cell> cells) {
    vars.addAll({'a': 0, 'b': 0, 'c': 0});
    vars.addAll(initialVars);
    final program = cells.where((c) => c.type != TokenType.blank).toList();
    if (program.isEmpty) {
      throw const ProgramError(
          'Nothing detected, try again with the sheet flat and well lit.');
    }
    final openRows = <int>[];
    for (final cell in program) {
      if (cell.type == TokenType.blockOpen) openRows.add(cell.row + 1);
      if (cell.type == TokenType.blockClose) {
        if (openRows.isEmpty) {
          throw ProgramError('Stray closing brace at row ${cell.row + 1}',
              row: cell.row + 1);
        }
        openRows.removeLast();
      }
    }
    if (openRows.isNotEmpty) {
      throw ProgramError('Unclosed block at row ${openRows.last}',
          row: openRows.last);
    }
    _execute(program, 0, program.length);
    final text = output.map((line) => '<div>${_escape(line)}</div>').join();
    final points = path.join(' ');
    return '<html><body><div style="font-size:32px">$text</div><svg xmlns="http://www.w3.org/2000/svg" viewBox="-20 -20 40 40"><polyline points="$points" fill="none" stroke="black" stroke-width="2"/></svg></body></html>';
  }

  int _value(Cell cell) {
    if (cell.type == TokenType.digit) return cell.digit ?? 0;
    if (cell.type == TokenType.variable) return vars[cell.varName] ?? 0;
    throw ProgramError('Expected a number at row ${cell.row + 1}',
        row: cell.row + 1);
  }

  int _findOpen(List<Cell> cells, int start) {
    if (start >= cells.length || cells[start].type != TokenType.blockOpen) {
      throw ProgramError('Expected a block at row ${cells[start - 1].row + 1}',
          row: cells[start - 1].row + 1);
    }
    var depth = 1;
    for (var i = start + 1; i < cells.length; i++) {
      if (cells[i].type == TokenType.blockOpen) depth++;
      if (cells[i].type == TokenType.blockClose && --depth == 0) return i;
    }
    throw ProgramError('Unclosed block at row ${cells[start].row + 1}',
        row: cells[start].row + 1);
  }

  void _execute(List<Cell> cells, int from, int to) {
    var i = from;
    while (i < to) {
      if (++statements > 5000) {
        throw const ProgramError('Program ran too long (loop limit).');
      }
      final c = cells[i];
      switch (c.type) {
        case TokenType.moveRight:
          path.add('${_lastX + 20},$_lastY');
          i++;
          break;
        case TokenType.moveLeft:
          path.add('${_lastX - 20},$_lastY');
          i++;
          break;
        case TokenType.moveUp:
          path.add('$_lastX,${_lastY - 20}');
          i++;
          break;
        case TokenType.moveDown:
          path.add('$_lastX,${_lastY + 20}');
          i++;
          break;
        case TokenType.print:
          if (i + 1 >= to ||
              !{TokenType.digit, TokenType.variable}
                  .contains(cells[i + 1].type)) {
            throw ProgramError('Expected a number after P at row ${c.row + 1}',
                row: c.row + 1);
          }
          output.add('${_value(cells[i + 1])}');
          i += 2;
          break;
        case TokenType.assign:
          if (i + 2 >= to ||
              cells[i + 1].type != TokenType.variable ||
              !{TokenType.digit, TokenType.variable}
                  .contains(cells[i + 2].type)) {
            throw ProgramError(
                'Expected a variable and number after = at row ${c.row + 1}',
                row: c.row + 1);
          }
          vars[cells[i + 1].varName!] = _value(cells[i + 2]);
          i += 3;
          break;
        case TokenType.repeat:
        case TokenType.ifThen:
          if (i + 1 >= to ||
              !{TokenType.digit, TokenType.variable}
                  .contains(cells[i + 1].type)) {
            throw ProgramError(
                'Expected a number after ${c.type == TokenType.repeat ? 'R' : 'I'} at row ${c.row + 1}',
                row: c.row + 1);
          }
          final end = _findOpen(cells, i + 2);
          final count = c.type == TokenType.repeat
              ? _value(cells[i + 1])
              : (_value(cells[i + 1]) == 0 ? 0 : 1);
          for (var n = 0; n < count; n++) {
            _execute(cells, i + 3, end);
          }
          i = end + 1;
          break;
        case TokenType.blockClose:
          throw ProgramError('Stray closing brace at row ${c.row + 1}',
              row: c.row + 1);
        default:
          throw ProgramError('Unexpected symbol at row ${c.row + 1}',
              row: c.row + 1);
      }
    }
  }

  int get _lastX => int.tryParse(path.last.split(',').first) ?? 0;
  int get _lastY => int.tryParse(path.last.split(',').last) ?? 0;
  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
