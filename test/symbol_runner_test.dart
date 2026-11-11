import 'package:flutter_test/flutter_test.dart';
import 'package:khatacode/languages/symbol_runner.dart';
import 'package:khatacode/models.dart';

Cell c(int row, TokenType type, {int? digit, String? varName}) =>
    Cell(row: row, col: 0, type: type, digit: digit, varName: varName);
void main() {
  test('builds output and path', () {
    final html = SymbolRunner().build([
      c(0, TokenType.print),
      c(0, TokenType.digit, digit: 3),
      c(0, TokenType.moveRight)
    ]);
    expect(html, contains('<div>3</div>'));
    expect(html, contains('<polyline'));
  });
  test('reports braces and missing arguments', () {
    expect(() => SymbolRunner().build([c(4, TokenType.blockOpen)]),
        throwsA(isA<ProgramError>()));
    expect(() => SymbolRunner().build([c(2, TokenType.blockClose)]),
        throwsA(predicate((e) => e.toString().contains('Stray'))));
    expect(() => SymbolRunner().build([c(5, TokenType.print)]),
        throwsA(predicate((e) => e.toString().contains('Expected'))));
  });
  test('empty and loop cap errors', () {
    expect(() => SymbolRunner().build([]), throwsA(isA<ProgramError>()));
    expect(
        () => SymbolRunner().build([
              c(0, TokenType.repeat),
              c(0, TokenType.digit, digit: 9),
              c(0, TokenType.blockOpen),
              c(0, TokenType.repeat),
              c(0, TokenType.digit, digit: 9),
              c(0, TokenType.blockOpen),
              c(0, TokenType.repeat),
              c(0, TokenType.digit, digit: 9),
              c(0, TokenType.blockOpen),
              c(0, TokenType.repeat),
              c(0, TokenType.digit, digit: 9),
              c(0, TokenType.blockOpen),
              c(0, TokenType.moveRight),
              c(0, TokenType.blockClose),
              c(0, TokenType.blockClose),
              c(0, TokenType.blockClose),
              c(0, TokenType.blockClose)
            ]),
        throwsA(predicate((e) => e.toString().contains('loop limit'))));
  });
}
