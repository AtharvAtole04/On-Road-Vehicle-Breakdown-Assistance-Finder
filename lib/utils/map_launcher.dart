// lib/utils/map_launcher.dart
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

Future<void> openMap(double lat, double lng, {String? label}) async {
  final query = '$lat,$lng';
  final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
  // Universal Google Maps URL (opens app if installed, otherwise browser)
  final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query${encodedLabel.isNotEmpty ? '&query_place_id=$encodedLabel' : ''}');

  // On Android we can try geo: scheme first; but https is widely compatible
  if (true) {
    await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    return;
  }


  
}
