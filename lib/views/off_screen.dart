// lib/views/off_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roadside_assistant/feature_toggle_service.dart';


class OffScreen extends StatelessWidget {
  final FeatureToggleService ft = Get.find<FeatureToggleService>();

  OffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.power_off, size: 92, color: Colors.redAccent),
                const SizedBox(height: 18),
                Text('Service Unavailable',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'The app is temporarily turned off by the provider. Please try again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 28),
                // ElevatedButton.icon(
                //   onPressed: () async {
                //     // Try to refetch remotely
                //     final ok = await ft.fetchAndApply();
                //     if (!ok) {
                //       Get.snackbar('Retry failed', 'Could not reach server');
                //     }
                //   },
                //   icon: Icon(Icons.refresh),
                //   label: Text('Retry'),
                //   style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
