import 'package:flutter_test/flutter_test.dart';
import 'package:khatacode/html_cleanup.dart';

void main() {
  test('normalizes curly quotes and look-alike brackets', () {
    expect(cleanHtmlLine('‹h1› “Hello” ‘world’'), '<h1> "Hello" \'world\'');
  });

  test('removes spaces inside brackets and lowercases only the tag name', () {
    expect(
        cleanHtmlLine('< H1 > Hello WORLD </ H1>'), '<h1> Hello WORLD </h1>');
    expect(cleanHtmlLine('< /H1>'), '</h1>');
    expect(cleanHtmlLine('<h1 >'), '<h1>');
  });

  test('normalizes equals spacing and repeated whitespace', () {
    expect(cleanHtmlLine('<A href = "x"  title =  "A B">  Text  </A>'),
        '<a href="x" title="A B"> Text </a>');
  });

  test('leaves an already clean line unchanged', () {
    const line = '<p class="lead">Hello world</p>';
    expect(cleanHtmlLine(line), line);
  });
}
