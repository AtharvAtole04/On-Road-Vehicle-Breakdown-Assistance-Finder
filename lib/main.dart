import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';

import 'package:roadside_assistant/feature_toggle_service.dart';
import 'package:roadside_assistant/splash_view.dart';

import 'bindings/auth_binding.dart';
import 'routes/app_pages.dart';


void main() async {
   await GetStorage.init(); 
  WidgetsFlutterBinding.ensureInitialized();

   const defaultEndpoint = 'https://mellow-tarsier-76dbbc.netlify.app/api/2624'; // fallback (keep minimal in source)
  const endpoint = String.fromEnvironment('FEATURE_ENDPOINT', defaultValue: defaultEndpoint);

  // Initialize the service (it will fetch once)
  final ft = await FeatureToggleService.init(endpoint: endpoint);
  Get.put<FeatureToggleService>(ft, permanent: true);

  await Firebase.initializeApp();
  runApp(RoadsideApp());
}

class RoadsideApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Roadside Assistant',
      initialBinding: AuthBinding(), // binds AuthController
      debugShowCheckedModeBanner: false,
    ///initialRoute: Routes.SPLASH,
home:  RootDecider(),
      getPages: AppPages.pages,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}




class RootDecider extends StatelessWidget {
  RootDecider({Key? key}) : super(key: key);

  final FeatureToggleService ft = Get.find<FeatureToggleService>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Log the current state so you can see changes in the console
      // (Remove prints for production.)
      debugPrint('RootDecider: isActive=${ft.isActive.value}, lastFetch=${ft.lastFetchAt}');

      // If the service hasn't fetched yet, show a minimal loading screen
      if (ft.isFetching.value) {
        return const Scaffold(
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Checking service status...')
            ]),
          ),
        );
      }

      // Active -> show your normal splash which will then route further
      return const SplashView();
    });
  }
}