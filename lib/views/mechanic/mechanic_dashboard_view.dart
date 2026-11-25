// lib/views/mechanic/mechanic_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:roadside_assistant/utils/map_launcher.dart';
import '../../models/order_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/wallet_controller.dart';

class MechanicDashboardView extends StatelessWidget {
  final AuthController auth = Get.find<AuthController>();
  final OrderController orderC = Get.find<OrderController>();
  final WalletController walletC = Get.put(WalletController());

  MechanicDashboardView({super.key}) {
    orderC.listenOrdersForAdmin();
    orderC.startMechanicLiveLocationTracking();
  }

  Map<String, dynamic> _mechanicResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return const {};
  }

  bool _isRejectedResponse(Map<String, dynamic> response) {
    final responseStatus =
        (response['responseStatus'] as String? ?? '').toLowerCase();
    return responseStatus == 'rejected' || response['rejected'] == true;
  }

  bool _hasResponded(OrderModel order, String mechanicId) {
    final response = _mechanicResponse(order.acceptedMechanics[mechanicId]);
    final responseStatus =
        (response['responseStatus'] as String? ?? '').toLowerCase();
    return responseStatus.isNotEmpty ||
        response['rejected'] == true ||
        response['charges'] != null ||
        response['timeToReach'] != null ||
        response['mechanicId'] != null;
  }

  bool _hasPendingOffer(OrderModel order, String mechanicId) {
    final response = _mechanicResponse(order.acceptedMechanics[mechanicId]);
    if (response.isEmpty || _isRejectedResponse(response)) {
      return false;
    }

    return response['charges'] != null ||
        response['timeToReach'] != null ||
        response['mechanicId'] != null;
  }

  List<OrderModel> _visibleOrders(String? mechanicId) {
    if (mechanicId == null || mechanicId.isEmpty) {
      return const [];
    }

    return orderC.orders.where((order) {
      if (order.status.toLowerCase() == 'pending') {
        final response = _mechanicResponse(order.acceptedMechanics[mechanicId]);
        return !_isRejectedResponse(response);
      }

      return order.helperId == mechanicId ||
          order.selectedMechanicId == mechanicId;
    }).toList();
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _serviceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'mechanic':
        return Icons.build_circle;
      case 'petrol':
        return Icons.local_gas_station;
      case 'towing':
        return Icons.local_shipping;
      default:
        return Icons.miscellaneous_services;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        elevation: 4,
        title: const Text('Mechanic Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Obx(() {
        final mechanicId = auth.appUser.value?.uid;
        final orders = _visibleOrders(mechanicId);

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.task_alt_rounded,
                    size: 90, color: Colors.grey),
                const SizedBox(height: 10),
                Text(
                  'No orders yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => orderC.listenOrdersForAdmin(),
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: orders.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                final creditTransactions = walletC.transactions
                    .where((tx) => tx.type == 'credit')
                    .toList();
                final totalEarned = creditTransactions.fold<double>(
                  0,
                  (sum, tx) => sum + tx.amount,
                );

                return _earningsCard(totalEarned, creditTransactions);
              }

              final o = orders[i - 1];
              final status = o.status.toLowerCase();
              final displayStatus = status == 'paid' ? 'completed' : status;
              final color = _statusColor(status);
              final isCancelled = status == 'cancelled';
              final isCompleted = status == 'completed';
              final isPaid = status == 'paid';
              final isAssignedToMe = mechanicId != null &&
                  (o.helperId == mechanicId ||
                      o.selectedMechanicId == mechanicId);
              final isAccepted = status == 'accepted' && isAssignedToMe;
              final isPending = status == 'pending';
              final canRespond = isPending &&
                  mechanicId != null &&
                  !_hasResponded(o, mechanicId);
              final hasPendingOffer = isPending &&
                  mechanicId != null &&
                  _hasPendingOffer(o, mechanicId);

              return Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isCancelled ? 0.6 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _serviceIcon(o.serviceType),
                            color: color,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      o.serviceType.toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      displayStatus[0].toUpperCase() +
                                          displayStatus.substring(1),
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Location: ${o.location}',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (o.lat != null && o.lng != null) ...[
                                IconButton(
                                  tooltip: 'Open in Google Maps',
                                  onPressed: () => openMap(o.lat!, o.lng!,
                                      label: o.location),
                                  icon: Icon(Icons.map_outlined,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${_formatDate(o.createdAt)}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                              if (o.serviceBudget != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      status == 'paid'
                                          ? 'Earned Amount:'
                                          : 'Service Amount:',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '₹${o.serviceBudget!.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: status == 'paid'
                                            ? Colors.green.shade700
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              if (!isCancelled && !isCompleted && !isPaid)
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    if (canRespond) ...[
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showOfferDialog(context, o.id),
                                        icon: const Icon(
                                            Icons.check_circle_outline,
                                            size: 18),
                                        label: const Text('Send Offer'),
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.blue.shade700),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final error =
                                              await orderC.rejectOrder(o.id);
                                          if (error == null) {
                                            Get.snackbar(
                                              'Rejected',
                                              'This request was removed only for you.',
                                              backgroundColor:
                                                  Colors.red.shade100,
                                            );
                                          } else {
                                            Get.snackbar(
                                              'Unable to reject',
                                              error,
                                              backgroundColor:
                                                  Colors.red.shade100,
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.cancel_outlined,
                                            size: 18),
                                        label: const Text('Reject'),
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.red.shade700),
                                      ),
                                    ],
                                    if (hasPendingOffer)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        child: Text(
                                          'Offer Sent',
                                          style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                    if (isAccepted) ...[
                                      TextButton.icon(
                                        onPressed: () {
                                          orderC.updateOrderStatus(
                                              o.id, 'reached');
                                          _showBudgetDialog(context, o.id);
                                        },
                                        icon: const Icon(Icons.location_on,
                                            size: 18),
                                        label: const Text('Reached Location'),
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.orange.shade700),
                                      ),
                                    ],
                                    if (status == 'reached')
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showBudgetDialog(context, o.id),
                                        icon: const Icon(Icons.attach_money,
                                            size: 18),
                                        label: const Text('Update Budget'),
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.green.shade700),
                                      ),
                                    if (isAssignedToMe)
                                      TextButton.icon(
                                        onPressed: () => _showGrievanceDialog(
                                            context, o.id, o.userId),
                                        icon: const Icon(
                                            Icons.report_problem_outlined,
                                            size: 18),
                                        label: const Text('Issue'),
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.orange.shade900),
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
          ),
        );
      }),
    );
  }

  Widget _earningsCard(double totalEarned, List<dynamic> creditTransactions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B8E5A), Color(0xFF39B36E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${totalEarned.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (creditTransactions.isEmpty)
            const Text(
              'No earning transactions yet',
              style: TextStyle(color: Colors.white),
            )
          else
            ...creditTransactions.take(3).map((tx) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order ${tx.orderId ?? '-'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '+ ₹${tx.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showGrievanceDialog(
      BuildContext context, String orderId, String targetId) {
    final issueC = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Report a Grievance'),
        content: TextField(
          controller: issueC,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Describe your issue details...'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (issueC.text.isNotEmpty) {
                orderC.submitGrievance(orderId, targetId, issueC.text);
                Get.back();
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showOfferDialog(BuildContext context, String orderId) {
    final chargesC = TextEditingController();
    final timeC = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Send Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: chargesC,
                decoration:
                    const InputDecoration(labelText: 'Visiting Charges (₹)'),
                keyboardType: TextInputType.number),
            TextField(
                controller: timeC,
                decoration: const InputDecoration(
                    labelText: 'Estimated Time to Reach (mins)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final charges = double.tryParse(chargesC.text.trim());
              final eta = timeC.text.trim();
              if (charges == null || eta.isEmpty) {
                Get.snackbar(
                  'Missing details',
                  'Enter valid charges and estimated time to reach.',
                );
                return;
              }

              final error = await orderC.offerService(orderId, charges, eta);
              if (error == null) {
                Get.back();
                Get.snackbar(
                  'Offer sent',
                  'The user can now review your offer.',
                  backgroundColor: Colors.green.shade100,
                );
              } else {
                Get.snackbar(
                  'Unable to send offer',
                  error,
                  backgroundColor: Colors.red.shade100,
                );
              }
            },
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, String orderId) {
    final budgetC = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Service Budget'),
        content: TextField(
            controller: budgetC,
            decoration: const InputDecoration(labelText: 'Total Budget (₹)'),
            keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              orderC.submitBudget(orderId, double.parse(budgetC.text));
              Get.back();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
