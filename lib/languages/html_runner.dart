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
    const style = '<style>body { font-size: 24px; padding: 16px; }</style>';
    if (body.toLowerCase().contains('<html')) {
      final head = RegExp(r'<head\s*>', caseSensitive: false);
      final headMatch = head.firstMatch(body);
      if (headMatch != null) {
        return body.replaceRange(headMatch.end, headMatch.end, style);
      }
      final htmlMatch =
          RegExp(r'<html\s*>', caseSensitive: false).firstMatch(body);
      if (htmlMatch != null) {
        return body.replaceRange(
            htmlMatch.end, htmlMatch.end, '<head>$style</head>');
      }
    }
    return '<html><head>$style</head><body>$body</body></html>';
  }
}
