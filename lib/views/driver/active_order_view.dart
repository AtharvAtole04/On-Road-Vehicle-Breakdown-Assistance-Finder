import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roadside_assistant/controllers/order_controller.dart';
import 'package:roadside_assistant/controllers/wallet_controller.dart';
import 'package:roadside_assistant/models/order_model.dart';
import 'mechanic_profile_dialog.dart';
import '../../services/sos_service.dart';

class ActiveOrderView extends StatelessWidget {
  final String orderId;
  final OrderController orderC = Get.find<OrderController>();
  final WalletController walletC = Get.put(WalletController());

  ActiveOrderView({Key? key, required this.orderId}) : super(key: key);

  Map<String, dynamic> _offerMap(dynamic offer) {
    if (offer is Map<String, dynamic>) {
      return offer;
    }
    if (offer is Map) {
      return Map<String, dynamic>.from(offer);
    }
    return const {};
  }

  bool _isRejectedOffer(dynamic offer) {
    final data = _offerMap(offer);
    final responseStatus =
        (data['responseStatus'] as String? ?? '').toLowerCase();
    return responseStatus == 'rejected' || data['rejected'] == true;
  }

  bool _isVisibleOffer(dynamic offer) {
    final data = _offerMap(offer);
    if (data.isEmpty || _isRejectedOffer(data)) {
      return false;
    }

    return data['charges'] != null ||
        data['timeToReach'] != null ||
        data['mechanicId'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Request'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order =
              OrderModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          if (order.status == 'pending') {
            return _pendingOffersView(context, order);
          } else if (order.status == 'accepted' || order.status == 'reached') {
            return _trackingView(context, order);
          } else if (order.status == 'completed' || order.status == 'paid') {
            return _completedView(context, order);
          }

          return Center(child: Text('Status: ${order.status}'));
        },
      ),
    );
  }

  Widget _pendingOffersView(BuildContext context, OrderModel order) {
    final offersList = order.acceptedMechanics.entries
        .where((entry) => _isVisibleOffer(entry.value))
        .toList();

    // Ranking Logic: Sort by Expertise (Higher) -> Distance (Lower) -> Charges (Lower)
    offersList.sort((a, b) {
      final aData = _offerMap(a.value);
      final bData = _offerMap(b.value);

      final aExpertise = (aData['expertise'] as num? ?? 0);
      final bExpertise = (bData['expertise'] as num? ?? 0);
      if (aExpertise != bExpertise) return bExpertise.compareTo(aExpertise);

      const distance = Distance();
      final aDist = distance.as(
          LengthUnit.Meter,
          LatLng(order.lat ?? 0, order.lng ?? 0),
          LatLng((aData['lat'] as num? ?? 0).toDouble(),
              (aData['lng'] as num? ?? 0).toDouble()));
      final bDist = distance.as(
          LengthUnit.Meter,
          LatLng(order.lat ?? 0, order.lng ?? 0),
          LatLng((bData['lat'] as num? ?? 0).toDouble(),
              (bData['lng'] as num? ?? 0).toDouble()));
      if (aDist != bDist) return aDist.compareTo(bDist);

      final aCharges = (aData['charges'] as num? ?? 0);
      final bCharges = (bData['charges'] as num? ?? 0);
      return aCharges.compareTo(bCharges);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Finding mechanics nearby...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (order.vehicleIssue != null)
                Text('Issue: ${order.vehicleIssue}',
                    style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        if (offersList.isEmpty)
          const Expanded(child: Center(child: Text('Waiting for offers...')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: offersList.length,
              itemBuilder: (context, index) {
                final entry = offersList[index];
                final key = entry.key;
                final offer = _offerMap(entry.value);
                final expertise = offer['expertise'] ?? 0;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal.shade50,
                              radius: 24,
                              child:
                                  const Icon(Icons.person, color: Colors.teal),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(offer['name'] ?? 'Mechanic',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      'Charges: ₹${offer['charges']} • Reach in: ${offer['timeToReach']}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  orderC.selectMechanic(order.id, key),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Select'),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        FutureBuilder<Map<String, int>>(
                            future: _fetchFreshStats(key),
                            builder: (context, stats) {
                              final solved = stats.data?['solved'] ??
                                  (offer['solvedCount'] ?? 0);
                              final unsolved = stats.data?['unsolved'] ??
                                  (offer['unsolvedCount'] ?? 0);

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatChip('Solved', solved.toString(),
                                      Colors.green),
                                  _buildStatChip('Unsolved',
                                      unsolved.toString(), Colors.red),
                                  TextButton.icon(
                                    onPressed: () => Get.dialog(
                                        MechanicProfileDialog(
                                            mechanicId: key,
                                            currentIssue: order.vehicleIssue)),
                                    icon: const Icon(Icons.history, size: 16),
                                    label: const Text('Full History',
                                        style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                    ),
                                  ),
                                ],
                              );
                            }),
                        if (expertise > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('✅ Solved $expertise similar issues',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Future<Map<String, int>> _fetchFreshStats(String mechanicId) async {
    final solved = await orderC.getStatusCount(mechanicId, 'solved');
    final unsolved = await orderC.getStatusCount(mechanicId, 'unsolved');
    return {'solved': solved, 'unsolved': unsolved};
  }

  Widget _trackingView(BuildContext context, OrderModel order) {
    final mechanic = order.acceptedMechanics[order.selectedMechanicId];
    if (mechanic == null) {
      return const Center(child: Text('Mechanic data missing'));
    }
    final driverLat = (mechanic['lat'] as num?)?.toDouble();
    final driverLng = (mechanic['lng'] as num?)?.toDouble();
    final requestLat = order.lat ?? driverLat ?? 0;
    final requestLng = order.lng ?? driverLng ?? 0;

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(requestLat, requestLng),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.road_side_assistent',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(requestLat, requestLng),
                    child: const Icon(Icons.location_on,
                        color: Colors.blue, size: 40),
                  ),
                  if (driverLat != null && driverLng != null)
                    Marker(
                      point: LatLng(driverLat, driverLng),
                      child: const Icon(Icons.drive_eta,
                          color: Colors.red, size: 40),
                    ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(mechanic['name'] ?? 'Mechanic'),
                subtitle: Text(mechanic['phone'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => SosService.dialNumber(mechanic['phone']),
                ),
              ),
              if (order.status == 'reached' && order.serviceBudget != null) ...[
                const Divider(),
                Text('Proposed Budget: ₹${order.serviceBudget}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        walletC.payForService(order.id, order.serviceBudget!),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Pay via Wallet',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ] else if (order.status == 'accepted') ...[
                const Text('Mechanic is on the way...',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
                _delayTracker(order),
              ],
              if (driverLat != null && driverLng != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Live location: ${driverLat.toStringAsFixed(5)}, ${driverLng.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Divider(),
              _alternativeTransportSection(context),
              const Divider(),
              TextButton.icon(
                onPressed: () => _showGrievanceDialog(context, order),
                icon: const Icon(Icons.report_problem, color: Colors.red),
                label: const Text('Report Issue',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _delayTracker(OrderModel order) {
    if (order.acceptedAt == null) return const SizedBox();

    final elapsed = DateTime.now().difference(order.acceptedAt!);
    final promised = order.promisedTimeInMinutes ?? 0;
    const gracePeriod = 30; // mins

    if (elapsed.inMinutes > (promised + gracePeriod)) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            const Text('Mechanic is significantly delayed!',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => orderC.updateOrderStatus(order.id, 'pending'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel & Switch Mechanic',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _alternativeTransportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Need Alternative Transport?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _bookTransport('bike'),
                icon: const Icon(Icons.directions_bike),
                label: const Text('Bike'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _bookTransport('cab'),
                icon: const Icon(Icons.local_taxi),
                label: const Text('Cab'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _bookTransport(String type) {
    orderC.placeOrder(
        serviceType: type, location: 'Current Location (via Active Request)');
    Get.snackbar('Success', 'Requested a $type for your travel.',
        backgroundColor: Colors.green.shade100,
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showGrievanceDialog(BuildContext context, OrderModel order) {
    final issueC = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Report a Grievance'),
        content: TextField(
          controller: issueC,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'What went wrong?'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (issueC.text.isNotEmpty) {
                orderC.submitGrievance(
                    order.id, order.helperId ?? '', issueC.text);
                Get.back();
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _completedView(BuildContext context, OrderModel order) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          const Text('Service Completed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (order.status == 'completed')
            const Text('Please proceed to payment if not done.')
          else
            const Text('Payment successful!'),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Get.offAllNamed('/user_home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }
}
