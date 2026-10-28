import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// GeoJSON outline + lat/lon -> normalised (0..1) projection.
/// Outline and markers share this projection, so they stay aligned
/// at any zoom or pan.
class IndiaOutline {
  final List<List<Offset>> rings; // normalised 0..1
  final double minLon, maxLon, minLat, maxLat;
  final double aspect; // height / width

  IndiaOutline._(
    this.rings,
    this.minLon,
    this.maxLon,
    this.minLat,
    this.maxLat,
    this.aspect,
  );

  static Future<IndiaOutline> load([
    String asset = 'assets/maps/india.geojson',
  ]) async {
    final raw = <List<Offset>>[];
    _collect(json.decode(await rootBundle.loadString(asset)), raw);
    if (raw.isEmpty) throw FormatException('No polygons in $asset');

    var minLon = double.infinity, maxLon = -double.infinity;
    var minLat = double.infinity, maxLat = -double.infinity;
    for (final r in raw) {
      for (final p in r) {
        minLon = math.min(minLon, p.dx);
        maxLon = math.max(maxLon, p.dx);
        minLat = math.min(minLat, p.dy);
        maxLat = math.max(maxLat, p.dy);
      }
    }
    final padLon = (maxLon - minLon) * 0.03;
    final padLat = (maxLat - minLat) * 0.03;
    minLon -= padLon;
    maxLon += padLon;
    minLat -= padLat;
    maxLat += padLat;

    final cosMid = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final aspect = (maxLat - minLat) / ((maxLon - minLon) * cosMid);
    final rings = [
      for (final r in raw)
        [
          for (final p in r)
            Offset(
              (p.dx - minLon) / (maxLon - minLon),
              (maxLat - p.dy) / (maxLat - minLat),
            ),
        ],
    ];
    return IndiaOutline._(rings, minLon, maxLon, minLat, maxLat, aspect);
  }

  Offset project(double lat, double lon) => Offset(
    (lon - minLon) / (maxLon - minLon),
    (maxLat - lat) / (maxLat - minLat),
  );

  static void _collect(dynamic n, List<List<Offset>> out) {
    if (n is! Map) return;
    switch (n['type']) {
      case 'FeatureCollection':
        for (final f in n['features'] as List) {
          _collect(f, out);
        }
      case 'Feature':
        _collect(n['geometry'], out);
      case 'GeometryCollection':
        for (final g in n['geometries'] as List) {
          _collect(g, out);
        }
      case 'Polygon':
        _polygon(n['coordinates'] as List, out);
      case 'MultiPolygon':
        for (final p in n['coordinates'] as List) {
          _polygon(p as List, out);
        }
    }
  }

  static void _polygon(List rings, List<List<Offset>> out) {
    for (final ring in rings) {
      out.add([
        for (final c in ring as List)
          Offset((c[0] as num).toDouble(), (c[1] as num).toDouble()),
      ]);
    }
  }
}
