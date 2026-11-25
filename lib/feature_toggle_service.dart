// lib/services/feature_toggle_service.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class FeatureToggleService extends GetxService {
  final RxBool isActive = true.obs;        // default true (fail-open)
  final RxBool isFetching = false.obs;     // NEW: whether a fetch is in progress
  final Rxn<DateTime> lastFetchAt = Rxn<DateTime>(); // NEW: last successful fetch

  final String endpoint;
  FeatureToggleService._(this.endpoint);

  static Future<FeatureToggleService> init({required String endpoint}) async {
    final s = FeatureToggleService._(endpoint);
    await s.fetchAndApply();
    return s;
  }

  Future<bool> fetchAndApply() async {
    try {
      isFetching.value = true;
      final resp = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(resp.body);
        final dynamic raw = jsonBody['isActive'];
        final bool flag = _parseBool(raw);
        isActive.value = flag;
        lastFetchAt.value = DateTime.now(); // update timestamp
        isFetching.value = false;
        return true;
      } else {
        isFetching.value = false;
        return false;
      }
    } catch (e) {
      isFetching.value = false;
      return false;
    }
  }

  bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final lower = v.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    if (v is num) return v != 0;
    return true; // safe default: keep app active if unknown. Change to false to fail-closed.
  }
}
