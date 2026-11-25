// lib/views/splash/splash_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roadside_assistant/views/off_screen.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_pages.dart';
import '../../feature_toggle_service.dart'; // <- ensure import path correct
// <- ensure import path correct

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final AuthController auth = Get.find<AuthController>();
  final FeatureToggleService ft = Get.find<FeatureToggleService>();

  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer starting the checks until after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startChecks();
    });
  }

  Future<void> _startChecks() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    // 1) Perform feature toggle check (with internal timeout)
    bool fetchOk = false;
    try {
      // fetchAndApply already has its own timeout; call it but guard overall wait as well
      fetchOk = await ft.fetchAndApply().timeout(const Duration(seconds: 8),
          onTimeout: () {
        return false;
      });
    } catch (e) {
      fetchOk = false;
      _error = e.toString();
    }

    debugPrint(
        'Splash: feature fetchOk=$fetchOk isActive=${ft.isActive.value}');

    // If the toggle explicitly turned app off -> show OffScreen and stop.
    if (!ft.isActive.value) {
      // short delay to allow splash to be visible briefly
      await Future.delayed(const Duration(milliseconds: 300));
      // use offAll to clear any backstack
      Get.offAll(() => OffScreen());
      return;
    }

    // 2) If active: wait a bit for AuthController to populate appUser from firestore
    //    but don't wait forever — timeout after ~4 seconds.
    final timeout = Duration(seconds: 4);
    final stopwatch = Stopwatch()..start();
    while (auth.firebaseUser.value != null &&
        auth.appUser.value == null &&
        stopwatch.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Small minimum splash time so users see the splash for a moment
    await Future.delayed(const Duration(milliseconds: 400));

    // 3) Navigate according to auth state
    final user = auth.firebaseUser.value;
    final appUser = auth.appUser.value;
    debugPrint('Splash: user=${user?.uid}, appUser=${appUser?.role}');

    if (user == null) {
      Get.offAllNamed(Routes.LOGIN);
      return;
    }

    if (appUser != null) {
      if (appUser.role == 'admin') {
        Get.offAllNamed(Routes.ADMIN_DASHBOARD);
      } else if (appUser.role == 'mechanic') {
        if (appUser.isApproved) {
          Get.offAllNamed(Routes.MECHANIC_DASHBOARD);
        } else {
          Get.offAllNamed(Routes.WAITING_APPROVAL);
        }
      } else {
        Get.offAllNamed(Routes.USER_HOME);
      }
      return;
    }

    // fallback if appUser is null but firebase user exists
    Get.offAllNamed(Routes.USER_HOME);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.car_repair, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Road Side Assistant',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            if (_checking) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Starting...'),
            ] else if (_error != null) ...[
              Text('Error: $_error',
                  style: TextStyle(color: Colors.red.shade700)),
            ],
          ]),
        ),
      ),
    );
  }
}
