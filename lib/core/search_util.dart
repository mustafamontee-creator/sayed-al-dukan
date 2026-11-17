/// Arabic-aware normalisation + tolerant matching for product search.
String normalizeArabic(String s) {
  var t = s.toLowerCase().trim();
  t = t.replaceAll(RegExp('[\u064B-\u065F\u0670\u0640]'), ''); // tashkeel, tatweel
  t = t.replaceAll(RegExp('[\u0622\u0623\u0625]'), '\u0627'); // آأإ -> ا
  t = t.replaceAll('\u0649', '\u064A'); // ى -> ي
  t = t.replaceAll('\u0629', '\u0647'); // ة -> ه
  t = t.replaceAll('\u0624', '\u0648').replaceAll('\u0626', '\u064A'); // ؤ ئ
  t = t.replaceAll(RegExp(r'\s+'), ' ');
  return t;
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final del = prev[j] + 1, ins = cur[j - 1] + 1, sub = prev[j - 1] + cost;
      cur[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    prev = cur;
  }
  return prev[b.length];
}

bool _tokenClose(String q, String n) {
  if (n.contains(q)) return true;
  final maxErr = q.length <= 3 ? 0 : (q.length <= 5 ? 1 : 2);
  if (maxErr == 0) return false;
  if (levenshtein(q, n) <= maxErr) return true;
  // partially typed word with one typo
  if (n.length > q.length && levenshtein(q, n.substring(0, q.length)) <= 1) {
    return true;
  }
  return false;
}

/// True when every word of [query] is (nearly) found in [name].
bool fuzzyMatches(String query, String name) {
  final q = normalizeArabic(query);
  final n = normalizeArabic(name);
  if (q.isEmpty) return false;
  if (n.contains(q)) return true;
  final qt = q.split(' ').where((e) => e.isNotEmpty);
  final nt = n.split(' ').where((e) => e.isNotEmpty).toList();
  return qt.every((w) => nt.any((x) => _tokenClose(w, x)));
}
