/// Converts a display name into a URL-friendly slug, mirroring the web app's
/// `slugify()` in Invee-Vue/src/utils.ts.
String slugify(String input) {
  const translitMap = <String, String>{
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y', 'ñ': 'n', 'ç': 'c', 'ß': 'ss',
  };
  var s = input.toLowerCase().trim();
  for (final e in translitMap.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return s
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
}
