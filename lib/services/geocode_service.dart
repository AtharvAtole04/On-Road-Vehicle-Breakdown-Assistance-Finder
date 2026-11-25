// lib/services/geocode_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodeService {
  /// Reverse geocode using Nominatim OpenStreetMap
  /// Returns a readable address or null on failure.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1'
      );

      final resp = await http.get(url, headers: {
        'User-Agent': 'RoadsideAssistant/1.0 (you@example.com)', // required by Nominatim policy
      }).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final Map<String, dynamic> map = json.decode(resp.body);
        // prefer display_name if present
        if (map.containsKey('display_name')) {
          return map['display_name'] as String?;
        }
        // fallback: construct from address parts
        final addr = map['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final parts = <String>[];
          ['road','neighbourhood','suburb','city','state','postcode','country'].forEach((k) {
            if (addr.containsKey(k)) parts.add(addr[k]);
          });
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
    } catch (e) {
      // ignore / return null
    }
    return null;
  }
}
