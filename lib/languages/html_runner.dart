import '../models.dart';
import 'symbol_runner.dart';

class HtmlRunner implements LanguageRunner {
  @override
  String build(List<Cell> cells) {
    final body = cells
        .where((cell) => cell.type == TokenType.text)
        .map((cell) => cell.raw)
        .join('\n')
        .trim();
    if (body.isEmpty) {
      throw const ProgramError(
          'Nothing detected, try again with the sheet flat and well lit.');
    }
    final document = body.toLowerCase().contains('<html')
        ? body
        : '<html><head></head><body>$body</body></html>';
    return document.replaceFirst('<head>',
        '<head><style>body { font-size: 24px; padding: 16px; }</style>');
  }
}
