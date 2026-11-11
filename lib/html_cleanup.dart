String cleanHtmlLine(String line) {
  var cleaned = line
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('‘', "'")
      .replaceAll('’', "'")
      .replaceAll('‹', '<')
      .replaceAll('«', '<')
      .replaceAll('〈', '<')
      .replaceAll('›', '>')
      .replaceAll('»', '>')
      .replaceAll('〉', '>');

  cleaned = cleaned.replaceAllMapped(RegExp(r'<\s*/\s*([^<>]*?)\s*>'), (match) {
    return '</${match.group(1)!.trim()}>';
  });
  cleaned =
      cleaned.replaceAllMapped(RegExp(r'<(?!/)\s*([^<>]*?)\s*>'), (match) {
    return '<${match.group(1)!.trim()}>';
  });
  cleaned = cleaned.replaceAllMapped(
      RegExp(r'</\s*([A-Za-z][\w:-]*)|<\s*([A-Za-z][\w:-]*)'), (match) {
    final closing = match.group(1);
    final tag = closing ?? match.group(2)!;
    return '<${closing == null ? '' : '/'}${tag.toLowerCase()}';
  });
  cleaned = cleaned.replaceAll(RegExp(r'\s*=\s*'), '=');
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}
