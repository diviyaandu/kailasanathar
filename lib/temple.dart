import 'dart:convert';

import 'package:flutter/services.dart';

class Temple {
  final String id, name, state, period, description, image;
  final double lat, lon;
  final Map<String, String> extras;

  const Temple({
    required this.id,
    required this.name,
    required this.state,
    required this.period,
    required this.description,
    required this.image,
    required this.lat,
    required this.lon,
    this.extras = const {},
  });

  static const _known = {
    'id',
    'name',
    'state',
    'period',
    'description',
    'image',
    'lat',
    'lon',
  };

  factory Temple.fromJson(Map<String, dynamic> j) {
    final extras = <String, String>{};
    j.forEach((k, v) {
      if (!_known.contains(k) && v is String && v.trim().isNotEmpty) {
        extras[k] = v.trim();
      }
    });
    final name = j['name'] as String;
    return Temple(
      id: (j['id'] as String?) ?? name,
      name: name,
      state: (j['state'] as String?) ?? '',
      period: (j['period'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      image: (j['image'] as String?) ?? '',
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      extras: extras,
    );
  }

  static Future<List<Temple>> loadAll() async {
    final s = await rootBundle.loadString('assets/temples.json');
    return [
      for (final e in json.decode(s) as List)
        Temple.fromJson(e as Map<String, dynamic>),
    ];
  }
}
