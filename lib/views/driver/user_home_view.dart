import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:roadside_assistant/services/sos_service.dart';
import 'package:roadside_assistant/utils/map_launcher.dart';
import 'package:roadside_assistant/views/feedback_view.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../routes/app_pages.dart';
import 'order_form_view.dart';

class UserHomeView extends StatelessWidget {
  final AuthController auth = Get.find<AuthController>();
  final OrderController orderC = Get.find<OrderController>();

  UserHomeView({Key? key}) : super(key: key);

  // helper to format date
  String _formatDate(DateTime dt) {
    try {
      return DateFormat('dd MMM yyyy • hh:mm a').format(dt.toLocal());
    } catch (e) {
      return dt.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _serviceIcon(String service) {
    switch (service.toLowerCase()) {
      case 'mechanic':
        return Icons.build_circle;
      case 'petrol':
        return Icons.local_gas_station;
      case 'towing':
        return Icons.anchor; // towing-like icon
      default:
        return Icons.miscellaneous_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    // initial load (safe to call here; it will refresh when view is built)
    orderC.fetchUserOrders();

    final theme = Theme.of(context);

    return Scaffold(
      // Gradient AppBar-like header using a Container
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F9D58), Color(0xFF00BFA6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      (auth.appUser.value?.name?.isNotEmpty ?? false)
                          ? auth.appUser.value!.name![0].toUpperCase()
                          : 'U',
                      style: TextStyle(fontSize: 28, color: Color(0xFF00BFA6)),
                    ),
                  ),

                  const SizedBox(width: 12),
                  // Welcome + role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          auth.appUser.value?.name ?? 'User',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (auth.appUser.value?.role ?? 'user').toUpperCase(),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                letterSpacing: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Wallet + Logout buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                        onPressed: () => Get.toNamed(Routes.WALLET),
                        tooltip: 'Wallet',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => auth.logout(),
                        tooltip: 'Logout',
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Padding and quick actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ServiceCard(
                      title: 'Mechanic',
                      subtitle: 'Engine, flat tyre',
                      icon: Icons.build,
                      color: Colors.indigo,
                      onTap: () {
                        Get.to(() => OrderFormView(),
                            arguments: {'service': 'mechanic'});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      title: 'Petrol',
                      subtitle: 'Fuel delivery',
                      icon: Icons.local_gas_station,
                      color: Colors.deepOrange,
                      onTap: () {
                        Get.to(() => OrderFormView(),
                            arguments: {'service': 'petrol'});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      title: 'Towing',
                      subtitle: 'Tow to garage',
                      icon: Icons.local_shipping,
                      color: Colors.teal,
                      onTap: () {
                        Get.to(() => OrderFormView(),
                            arguments: {'service': 'towing'});
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Orders list title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Your Requests',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Get.toNamed(Routes.MECHANIC_LIST),
                    child: const Text('View Mechanics'),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => orderC.fetchUserOrders(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Orders list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await orderC.fetchUserOrders();
                },
                child: Obx(() {
                  final orders = orderC.orders;
                  if (orders.isEmpty) {
                    // empty state
                    return ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 40),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.car_crash,
                                size: 84, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No requests yet',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey.shade700)),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Tap "Place Request" to ask for help. We’ll notify nearby helpers right away.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        )
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final o = orders[index];
                      final created = o.createdAt;
                      final status = o.status;
                      final service = o.serviceType;
                      final helperId = o.helperId;
                      final isActive = ['pending', 'accepted', 'reached', 'paid'].contains(status.toLowerCase());

                      return GestureDetector(
                        onTap: isActive ? () => Get.toNamed(Routes.ACTIVE_ORDER, arguments: o.id) : null,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon block
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_serviceIcon(service),
                                      size: 28, color: _statusColor(status)),
                                ),

                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${service[0].toUpperCase()}${service.substring(1)} • ${o.location}',
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Status chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status[0].toUpperCase() +
                                                  status.substring(1),
                                              style: TextStyle(
                                                  color: _statusColor(status),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Requested on ${_formatDate(created)}',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      // Small actions
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Open in Google Maps',
                                            onPressed: () {
                                              if (o.lat != null &&
                                                  o.lng != null) {
                                                openMap(o.lat!, o.lng!,
                                                    label: o.location);
                                              } else {
                                                Get.snackbar('Location missing',
                                                    'Coordinates not available for this order');
                                              }
                                            },
                                            icon: Icon(Icons.map_outlined,
                                                color: Colors.grey.shade700),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              o.location,
                                              style: TextStyle(
                                                  color: Colors.grey.shade700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Feedback button shown only for completed orders
                                          if ((o.status ?? '').toLowerCase() ==
                                              'completed') ...[
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                if (helperId == null ||
                                                    helperId.isEmpty) {
                                                  Get.snackbar('Incomplete Data',
                                                      'Detailed helper info is unavailable for this specific order (historical order). Please try with a new request.',
                                                      backgroundColor:
                                                          Colors.orange.shade100);
                                                  return;
                                                }
                                                // navigate to FeedbackView and pass orderId + recipientId
                                                Get.to(() => FeedbackView(
                                                    orderId: o.id,
                                                    recipientId: helperId));
                                              },
                                              icon: const Icon(
                                                  Icons.rate_review_outlined,
                                                  size: 18),
                                              label: const Text('Give Feedback'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],

                                          if (isActive)
                                            IconButton(
                                              icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                              onPressed: () => Get.toNamed(Routes.ACTIVE_ORDER, arguments: o.id),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),

      // Place Request FAB
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('SOS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
            onPressed: () async {
              await SosService.sendSos(
                  userName: auth.firebaseUser.string); // Pass actual user name
            },
          ),
          const SizedBox(
            height: 7,
          ),
          FloatingActionButton.extended(
            onPressed: () => Get.to(() => OrderFormView()),
            label: const Text('Request'),
            icon: const Icon(Icons.add),
            elevation: 6,
            backgroundColor: Color(0xFF0F9D58),
          ),
        ],
      ),
    );
  }
}

/// Small service card used in the header
class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use constraints instead of a hard fixed height so the card can shrink if needed
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 72, maxHeight: 110),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 4))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon block
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withOpacity(0.95),
                    color.withOpacity(0.7)
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),

              const SizedBox(width: 12),

              // Make this column shrink to its contents (MainAxisSize.min)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title - allow wrapping but limit lines
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtitle - smaller and can wrap into 2 lines if needed
                    Text(
                      subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
