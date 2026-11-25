import 'package:get/get.dart';

import 'package:roadside_assistant/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/driver/user_home_view.dart';
import '../views/driver/order_form_view.dart';
import '../views/admin/admin_dashboard_view.dart';
import '../views/mechanic/mechanic_dashboard_view.dart';
import '../views/auth/waiting_approval_view.dart';
import '../views/driver/mechanic_list_view.dart';
import '../views/driver/active_order_view.dart';
import '../views/wallet/wallet_view.dart';
import '../controllers/admin_controller.dart';
import '../controllers/mechanic_list_controller.dart';

part 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.SPLASH, page: () => const SplashView()),
    GetPage(name: Routes.LOGIN, page: () => LoginView()),
    GetPage(name: Routes.SIGNUP, page: () => SignupView()),
    GetPage(name: Routes.USER_HOME, page: () => UserHomeView()),
    GetPage(name: Routes.ORDER_FORM, page: () => OrderFormView()),
    GetPage(
      name: Routes.ADMIN_DASHBOARD,
      page: () => AdminDashboardView(),
      binding: BindingsBuilder(() {
        Get.put(AdminController());
      }),
    ),
    GetPage(
        name: Routes.MECHANIC_DASHBOARD, page: () => MechanicDashboardView()),
    GetPage(
        name: Routes.WAITING_APPROVAL, page: () => const WaitingApprovalView()),
    GetPage(
      name: Routes.MECHANIC_LIST,
      page: () => MechanicListView(),
      binding: BindingsBuilder(() {
        Get.put(MechanicListController());
      }),
    ),
    GetPage(
      name: Routes.ACTIVE_ORDER,
      page: () => ActiveOrderView(orderId: Get.arguments ?? ''),
    ),
    GetPage(
      name: Routes.WALLET,
      page: () => WalletView(),
    ),
  ];
}
