String maskEmail(String? email) {
  if (email == null || !email.contains('@')) return '';
  final parts = email.split('@');
  final local = parts.first;
  final shown = local.length <= 2 ? local : local.substring(0, 2);
  return '$shown****@${parts.sublist(1).join('@')}';
}

/// "201012345678" -> "+20 10******78" (country code kept, middle hidden).
String maskPhone(String? phone) {
  if (phone == null) return '';
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length < 8) return d.isEmpty ? '' : '+$d';
  final ccLen = d.startsWith('20') ? 2 : (d.startsWith('249') || d.startsWith('966') ? 3 : 2);
  final rest = d.substring(ccLen);
  if (rest.length < 5) return '+$d';
  final masked = rest.substring(0, 2) + '*' * (rest.length - 4) + rest.substring(rest.length - 2);
  return '+${d.substring(0, ccLen)} $masked';
}

String formatNumber(num v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
