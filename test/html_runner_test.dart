import 'package:flutter_test/flutter_test.dart';
import 'package:khatacode/languages/html_runner.dart';
import 'package:khatacode/models.dart';

Cell text(int row, String raw) =>
    Cell(row: row, col: 0, type: TokenType.text, raw: raw);

void main() {
  test('wraps a single line', () {
    final html = HtmlRunner().build([text(0, '<h1>Hello</h1>')]);
    expect(html, contains('<html>'));
    expect(html, contains('<style>'));
    expect(html, contains('<h1>Hello</h1>'));
  });

  test('does not double wrap an HTML document', () {
    final html = HtmlRunner().build([text(0, '<html><body>Hi</body></html>')]);
    expect('<html>'.allMatches(html).length, 1);
  });

  test('joins multiple lines', () {
    expect(HtmlRunner().build([text(0, '<p>One</p>'), text(1, '<p>Two</p>')]),
        contains('<p>One</p>\n<p>Two</p>'));
  });

  test('rejects empty input', () {
    expect(
        () => HtmlRunner().build([]),
        throwsA(predicate(
            (error) => error.toString().contains('Nothing detected'))));
  });

  test('allows unclosed tags', () {
    expect(HtmlRunner().build([text(0, '<p>Unclosed')]), contains('Unclosed'));
  });
}
