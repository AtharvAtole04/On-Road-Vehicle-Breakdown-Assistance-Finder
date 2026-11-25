// lib/services/sos_service.dart
// lib/services/sos_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/geocode_service.dart';

class SosService {
  static final _storage = GetStorage();
  static const _key = 'sos_phone';

  /// Get stored SOS number
  static String? getSavedPhone() => _storage.read<String>(_key);

  /// Save new SOS number
  static void savePhone(String phone) => _storage.write(_key, phone);

  /// Ask user to enter SOS phone number via dialog
  static Future<String?> promptForPhone() async {
    final controller = TextEditingController();
    return await Get.dialog<String>(
      AlertDialog(
        title: const Text('Set Emergency Contact'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Enter SOS Phone Number',
            prefixIcon: Icon(Icons.phone, color: Colors.teal),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              final number = controller.text.trim();
              if (number.isNotEmpty) {
                savePhone(number);
                Get.back(result: number);
              } else {
                Get.snackbar('Error', 'Please enter a phone number',
                    backgroundColor: Colors.red.shade100,
                    colorText: Colors.black);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Get current GPS position (with permission handling)
  static Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('Error fetching location: $e');
      return null;
    }
  }

  /// Compose SMS body including coordinates and optional address
  static String composeSmsBody({
    required double lat,
    required double lng,
    String? address,
    String? userName,
  }) {
    final locUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final sb = StringBuffer();

    sb.writeln('🚨 SOS Emergency Alert 🚨');
    if (userName != null && userName.isNotEmpty) {
      sb.writeln('From: $userName');
    }
    sb.writeln('');
    sb.writeln('📍 Location: ${address ?? 'Unknown location'}');
    sb.writeln('🌐 Coordinates: $lat, $lng');
    sb.writeln('🗺️ Google Maps: $locUrl');
    sb.writeln('');
    sb.writeln('Please send help immediately!');

    return sb.toString();
  }

  /// Send SOS message - requires user to have entered phone number
  static Future<void> sendSos({String? userName}) async {
    try {
      String? phone = getSavedPhone();
      if (phone == null || phone.isEmpty) {
        phone = await promptForPhone();
        if (phone == null || phone.isEmpty) {
          Get.snackbar('SOS Cancelled', 'You must enter a phone number first.',
              backgroundColor: Colors.orange.shade100, colorText: Colors.black);
          return;
        }
      }

      final pos = await _getCurrentPosition();
      if (pos == null) {
        Get.snackbar('Location Error', 'Unable to get current location.',
            backgroundColor: Colors.red.shade100, colorText: Colors.black);
        return;
      }

      final addr =
          await GeocodeService.reverseGeocode(pos.latitude, pos.longitude);
      final body = composeSmsBody(
        lat: pos.latitude,
        lng: pos.longitude,
        address: addr,
        userName: userName,
      );

      final smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(body)}');
      if (!await launchUrl(smsUri)) {
        Get.snackbar('Error', 'Could not open SMS app',
            backgroundColor: Colors.red.shade100, colorText: Colors.black);
      } else {
        Get.snackbar('SOS Ready', 'Message prepared in your SMS app',
            backgroundColor: Colors.green.shade100, colorText: Colors.black);
      }
    } catch (e) {
      debugPrint('sendSos error: $e');
      Get.snackbar('Error', 'Something went wrong while preparing SOS',
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
    }
  }

  /// Optional helper to call SOS number directly
  static Future<void> callSos() async {
    final phone = getSavedPhone();
    if (phone == null || phone.isEmpty) {
      await promptForPhone();
      return;
    }
    final telUri = Uri.parse('tel:$phone');
    if (!await launchUrl(telUri)) {
      Get.snackbar('Error', 'Could not open dialer',
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
    }
  }

  static Future<bool> dialNumber(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (true) {
        await launchUrl(uri);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('dialNumber error: $e');
      return false;
    }
  }
}
