// lib/services/nearby_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NearbyPlace {
  final String id;
  final String? name;
  final double lat;
  final double lon;
  final Map<String, dynamic> tags;

  NearbyPlace({required this.id, this.name, required this.lat, required this.lon, required this.tags});

  double distanceTo(LatLng from) {
    final d = Distance();
    return d(LatLng(lat, lon), from);
  }
}

class NearbyService {
  /// Query Overpass API for nearby mechanics (amenity=car_repair or shop=car_repair).
  /// radiusMeters default 1500 (1.5 km). Returns up to `limit` results.
  static Future<List<NearbyPlace>> findMechanics({
    required double lat,
    required double lon,
    int radiusMeters = 1500,
    int limit = 8,
  }) async {
    final endpoint = Uri.parse('https://overpass-api.de/api/interpreter');

    final query = '''
[out:json][timeout:25];
(
  node["amenity"="car_repair"](around:$radiusMeters,$lat,$lon);
  node["shop"="car_repair"](around:$radiusMeters,$lat,$lon);
  way["amenity"="car_repair"](around:$radiusMeters,$lat,$lon);
  way["shop"="car_repair"](around:$radiusMeters,$lat,$lon);
  relation["amenity"="car_repair"](around:$radiusMeters,$lat,$lon);
  relation["shop"="car_repair"](around:$radiusMeters,$lat,$lon);
);
out center ${limit};
''';

    try {
      final resp = await http.post(endpoint, body: query).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(resp.body);
        final elements = (jsonBody['elements'] as List<dynamic>? ?? []);
        final List<NearbyPlace> results = [];
        for (final el in elements) {
          final id = el['id'].toString();
          double eLat, eLon;
          if (el['type'] == 'way' || el['type'] == 'relation') {
            final center = el['center'] as Map<String, dynamic>?;
            if (center == null) continue;
            eLat = (center['lat'] as num).toDouble();
            eLon = (center['lon'] as num).toDouble();
          } else {
            eLat = (el['lat'] as num).toDouble();
            eLon = (el['lon'] as num).toDouble();
          }
          final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
          final name = tags['name'] as String?;
          results.add(NearbyPlace(id: id, name: name, lat: eLat, lon: eLon, tags: tags));
        }
        return results;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
