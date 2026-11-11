import 'package:flutter_test/flutter_test.dart';
import 'package:khatacode/gemini_recognizer.dart';

void main() {
  test('strips markdown fences without changing the text', () {
    expect(cleanGeminiReply('```html\n<h1>Hello</h1>\n```'), '<h1>Hello</h1>');
  });

  test('maps NOTHING to an empty result', () {
    expect(normalizeGeminiResult(' NOTHING '), isEmpty);
    expect(normalizeGeminiResult('nothing'), isEmpty);
  });
}
