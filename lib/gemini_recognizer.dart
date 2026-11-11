import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'secrets.dart';

const geminiPrompt =
    'This is a photo of handwritten HTML code on paper. Transcribe it exactly '
    'as written into plain text, one line per written line. Do not add '
    'explanations, markdown, or code fences. Do not fix mistakes or add '
    'missing tags. If nothing legible is written, reply with exactly NOTHING.';

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
  @override
  String toString() => message;
}

bool hasGeminiKey() =>
    geminiApiKey != 'PASTE_KEY_HERE' &&
    geminiApiKey.trim().isNotEmpty &&
    geminiModel != 'PASTE_CURRENT_FLASH_MODEL_NAME' &&
    geminiModel.trim().isNotEmpty;

String cleanGeminiReply(String reply) {
  var cleaned = reply.trim();
  if (cleaned.startsWith('```') && cleaned.endsWith('```')) {
    final lines = cleaned.split('\n');
    if (lines.isNotEmpty && lines.first.trim().startsWith('```')) {
      lines.removeAt(0);
    }
    if (lines.isNotEmpty && lines.last.trim() == '```') {
      lines.removeLast();
    }
    cleaned = lines.join('\n').trim();
  }
  return cleaned;
}

String normalizeGeminiResult(String reply) {
  final cleaned = cleanGeminiReply(reply);
  return cleaned.toUpperCase() == 'NOTHING' ? '' : cleaned;
}

Future<String> transcribeHtml(Uint8List sourceBytes) async {
  if (!hasGeminiKey()) {
    throw const GeminiException('Gemini is not configured');
  }
  final image = img.decodeImage(sourceBytes);
  if (image == null) {
    throw const GeminiException('The image could not be prepared for Gemini.');
  }
  final longEdge = image.width > image.height ? image.width : image.height;
  final scale = 1600 / longEdge;
  final resized = scale < 1
      ? img.copyResize(image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round())
      : image;
  final jpeg = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiApiKey');
  final client = HttpClient();
  try {
    final request =
        await client.postUrl(uri).timeout(const Duration(seconds: 10));
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': geminiPrompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(jpeg)
              }
            }
          ]
        }
      ],
      'generationConfig': {'temperature': 0}
    })));
    final response = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) {
        throw const GeminiException('Gemini is temporarily busy');
      }
      throw GeminiException(
          'Gemini could not recognize the image (HTTP ${response.statusCode})');
    }
    final decoded = jsonDecode(responseBody);
    final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text is! String) {
      throw const GeminiException('Gemini returned no readable text');
    }
    return normalizeGeminiResult(text);
  } on GeminiException {
    rethrow;
  } on TimeoutException {
    throw const GeminiException('Gemini timed out');
  } on SocketException {
    throw const GeminiException('Gemini could not be reached');
  } on FormatException {
    throw const GeminiException('Gemini returned an invalid response');
  } catch (_) {
    throw const GeminiException('Online recognition failed');
  } finally {
    client.close(force: true);
  }
}
