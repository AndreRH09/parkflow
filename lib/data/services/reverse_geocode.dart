import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

/// Convierte lat/lng en ciudad + dirección legible.
///
/// El paquete `geocoding` solo tiene implementación Android/iOS; en web lanza
/// MissingPluginException. Ahí caemos a Nominatim (OSM), que permite CORS.
Future<({String city, String address})?> reverseGeocode(
  double lat,
  double lng,
) async {
  if (!kIsWeb) {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;
    return (
      city: p.locality?.isNotEmpty == true
          ? p.locality!
          : p.subAdministrativeArea ?? p.administrativeArea ?? '',
      address: [p.street, p.locality ?? p.subAdministrativeArea]
          .where((s) => s != null && s.isNotEmpty)
          .join(', '),
    );
  }

  // ponytail: sin API key ni rate limiter. Nominatim pide max 1 req/s — basta
  // para un botón manual; si se automatiza, mover a un provider con throttle.
  final res = await http.get(
    Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '$lat',
      'lon': '$lng',
      'format': 'jsonv2',
      'zoom': '18',
    }),
  );
  if (res.statusCode != 200) return null;

  final a = (jsonDecode(res.body)['address'] as Map?) ?? {};
  final city = (a['city'] ?? a['town'] ?? a['village'] ?? a['county'] ?? '') as String;
  final street = [a['road'], a['house_number']]
      .where((s) => s != null && (s as String).isNotEmpty)
      .join(' ');

  return (
    city: city,
    address: [street, city].where((s) => s.isNotEmpty).join(', '),
  );
}
