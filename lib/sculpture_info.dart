class SculptureInfo {
  final String name;
  final String? period, significance, description, mythology;
  final Map<String, String> extras;

  const SculptureInfo({
    required this.name,
    this.period,
    this.significance,
    this.description,
    this.mythology,
    this.extras = const {},
  });

  static const _known = {
    'name',
    'period',
    'significance',
    'description',
    'mythology',
  };

  static String? _s(dynamic v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  factory SculptureInfo.fromJson(
    Map<String, dynamic> j, {
    String? fallbackName,
  }) {
    final extras = <String, String>{};
    j.forEach((k, v) {
      final s = _s(v);
      if (!_known.contains(k) && s != null) extras[k] = s;
    });
    return SculptureInfo(
      name: _s(j['name']) ?? fallbackName ?? 'Unknown sculpture',
      period: _s(j['period']),
      significance: _s(j['significance']),
      description: _s(j['description']),
      mythology: _s(j['mythology']),
      extras: extras,
    );
  }
}
