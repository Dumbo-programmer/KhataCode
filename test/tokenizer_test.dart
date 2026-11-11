import 'package:flutter_test/flutter_test.dart';
import 'package:khatacode/models.dart';
import 'package:khatacode/tokenizer.dart';

void main() {
  test('tokenizes glyphs and aliases', () {
    final p = tokenize([
      ['V', 'r', 'l', 'p', '(', ')', 'O', 'A', null]
    ]);
    expect(p.cells.map((c) => c.type), [
      TokenType.moveDown,
      TokenType.repeat,
      TokenType.ifThen,
      TokenType.print,
      TokenType.blockOpen,
      TokenType.blockClose,
      TokenType.digit,
      TokenType.variable,
      TokenType.blank
    ]);
    expect(p.cells[6].digit, 0);
  });
  test('reads variable strip and blank as zero', () {
    final p = tokenize(List.generate(
        17, (r) => List<String?>.filled(12, null)..[0] = r == 16 ? '3' : null));
    expect(p.vars['a'], 3);
    expect(p.vars['b'], 0);
  });
}
