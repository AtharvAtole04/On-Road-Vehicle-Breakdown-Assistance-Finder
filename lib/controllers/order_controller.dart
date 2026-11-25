import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/order_model.dart';
import 'auth_controller.dart';

class _OrderActionException implements Exception {
  const _OrderActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderController extends GetxController {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final AuthController _auth = Get.find<AuthController>();

  RxList<OrderModel> orders = <OrderModel>[].obs;
  Timer? _mechanicLocationTimer;
  bool _isUpdatingMechanicLocation = false;

  Map<String, dynamic> _responseMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return const {};
  }

  bool _isRejectedResponse(dynamic response) {
    final data = _responseMap(response);
    final responseStatus =
        (data['responseStatus'] as String? ?? '').toLowerCase();
    return responseStatus == 'rejected' || data['rejected'] == true;
  }

  Future<int> _getApprovedMechanicCount() async {
    final mechanics = await _fire
        .collection('users')
        .where('role', isEqualTo: 'mechanic')
        .where('isApproved', isEqualTo: true)
        .get();
    return mechanics.docs.length;
  }

  // Mechanic rejects a request without affecting other mechanics.
  Future<String?> rejectOrder(String orderId) async {
    final user = _auth.appUser.value;
    if (user == null) return 'Unable to identify the current mechanic.';

    final orderRef = _fire.collection('orders').doc(orderId);

    try {
      final approvedMechanicCount = await _getApprovedMechanicCount();
      await _fire.runTransaction((transaction) async {
        final snapshot = await transaction.get(orderRef);
        if (!snapshot.exists) {
          throw const _OrderActionException('This request no longer exists.');
        }

        final data = snapshot.data() ?? <String, dynamic>{};
        final status = (data['status'] as String? ?? 'pending').toLowerCase();
        final helperId = data['helperId'] as String?;
        if (status != 'pending' || (helperId != null && helperId.isNotEmpty)) {
          throw const _OrderActionException(
            'This request has already been assigned.',
          );
        }

        final acceptedMechanics =
            Map<String, dynamic>.from(data['acceptedMechanics'] ?? {});
        final currentResponse = _responseMap(acceptedMechanics[user.uid]);
        final nextResponses = Map<String, dynamic>.from(acceptedMechanics)
          ..[user.uid] = {
            ...currentResponse,
            'mechanicId': user.uid,
            'name': user.name,
            'phone': user.phone ?? currentResponse['phone'] ?? '',
            'responseStatus': 'rejected',
            'rejected': true,
          };

        final rejectedCount =
            nextResponses.values.where(_isRejectedResponse).length;
        final eligibleMechanicCount =
            (data['eligibleMechanicCount'] as num?)?.toInt() ??
                approvedMechanicCount;

        final updateData = <String, dynamic>{
          'acceptedMechanics.${user.uid}.mechanicId': user.uid,
          'acceptedMechanics.${user.uid}.name': user.name,
          'acceptedMechanics.${user.uid}.phone':
              user.phone ?? currentResponse['phone'] ?? '',
          'acceptedMechanics.${user.uid}.responseStatus': 'rejected',
          'acceptedMechanics.${user.uid}.rejected': true,
          'acceptedMechanics.${user.uid}.rejectedAt':
              FieldValue.serverTimestamp(),
        };

        if (eligibleMechanicCount > 0 &&
            rejectedCount >= eligibleMechanicCount) {
          updateData.addAll({
            'status': 'cancelled',
            'rejectionReason': 'All mechanics rejected',
          });
        }

        transaction.update(orderRef, updateData);
      });

      return null;
    } on _OrderActionException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> placeOrder(
      {required String serviceType, required String location}) async {
    try {
      final uid = _auth.appUser.value!.uid;
      final eligibleMechanicCount = await _getApprovedMechanicCount();
      final docRef = _fire.collection('orders').doc();
      final order = {
        'id': docRef.id,
        'userId': uid,
        'serviceType': serviceType,
        'location': location,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedMechanics': {},
        'eligibleMechanicCount': eligibleMechanicCount,
      };
      await docRef.set(order);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Admin: listen to orders collection
  void listenOrdersForAdmin() {
    _fire
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      orders.value = snap.docs.map((d) {
        final map = d.data();
        map['createdAt'] = map['createdAt'] ?? Timestamp.now();
        return OrderModel.fromMap(map);
      }).toList();
    });
  }

  // in lib/controllers/order_controller.dart - add these methods
  Future<String?> placeOrderWithLocation({
    required String serviceType,
    required String location,
    required double lat,
    required double lng,
    String? notes,
    String? fuelType,
    double? fuelCapacity,
    bool isTowing = false,
    String? vehicleIssue,
  }) async {
    try {
      final uid = _auth.appUser.value!.uid;
      final eligibleMechanicCount = await _getApprovedMechanicCount();
      final docRef = _fire.collection('orders').doc();
      final order = {
        'id': docRef.id,
        'userId': uid,
        'serviceType': serviceType,
        'location': location,
        'lat': lat,
        'lng': lng,
        'notes': notes ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'fuelType': fuelType,
        'fuelCapacity': fuelCapacity,
        'isTowing': isTowing,
        'vehicleIssue': vehicleIssue,
        'acceptedMechanics': {},
        'eligibleMechanicCount': eligibleMechanicCount,
      };
      await docRef.set(order);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Mechanic sends an offer. The user chooses one offer later.
  Future<String?> offerService(
    String orderId,
    double charges,
    String timeToReach,
  ) async {
    final user = _auth.appUser.value;
    if (user == null) return 'Unable to identify the current mechanic.';

    int minutes = 0;
    try {
      final numericPart = RegExp(r'\d+').firstMatch(timeToReach)?.group(0);
      if (numericPart != null) {
        minutes = int.parse(numericPart);
      }
    } catch (_) {
      minutes = 0;
    }

    final expertise = await calculateExpertise(user.uid, orderId);
    final solvedCount = await getStatusCount(user.uid, 'solved');
    final unsolvedCount = await getStatusCount(user.uid, 'unsolved');
    final orderRef = _fire.collection('orders').doc(orderId);

    try {
      await _fire.runTransaction((transaction) async {
        final snapshot = await transaction.get(orderRef);
        if (!snapshot.exists) {
          throw const _OrderActionException('This request no longer exists.');
        }

        final data = snapshot.data() ?? <String, dynamic>{};
        final status = (data['status'] as String? ?? 'pending').toLowerCase();
        final helperId = data['helperId'] as String?;
        if (status != 'pending' || (helperId != null && helperId.isNotEmpty)) {
          throw const _OrderActionException(
            'This request has already been assigned.',
          );
        }

        transaction.update(orderRef, {
          'acceptedMechanics.${user.uid}': {
            'mechanicId': user.uid,
            'name': user.name,
            'phone': user.phone ?? '',
            'charges': charges,
            'timeToReach': timeToReach,
            'promisedTimeInMinutes': minutes,
            'lat': user.liveLat,
            'lng': user.liveLng,
            'expertise': expertise,
            'solvedCount': solvedCount,
            'unsolvedCount': unsolvedCount,
            'responseStatus': 'offered',
            'rejected': false,
            'offeredAt': FieldValue.serverTimestamp(),
          },
        });
      });

      return null;
    } on _OrderActionException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<int> getStatusCount(String mechanicId, String statusType) async {
    try {
      if (statusType == 'solved') {
        final snap = await _fire
            .collection('orders')
            .where('helperId', isEqualTo: mechanicId)
            .where('status', whereIn: ['completed', 'paid']).get();
        return snap.docs.length;
      } else {
        final snap = await _fire
            .collection('orders')
            .where('helperId', isEqualTo: mechanicId)
            .where('status', isEqualTo: 'cancelled')
            .get();
        return snap.docs.length;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<int> calculateExpertise(
      String mechanicId, String currentOrderId) async {
    try {
      final orderDoc =
          await _fire.collection('orders').doc(currentOrderId).get();
      final currentIssue = orderDoc.data()?['vehicleIssue'] as String?;
      if (currentIssue == null || currentIssue.isEmpty) return 0;

      final count = await _fire
          .collection('orders')
          .where('helperId', isEqualTo: mechanicId)
          .where('status', isEqualTo: 'completed')
          .where('vehicleIssue', isEqualTo: currentIssue)
          .get();
      return count.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // User selects a mechanic
  Future<void> selectMechanic(String orderId, String mechanicId) async {
    final doc = await _fire.collection('orders').doc(orderId).get();
    final data = doc.data() ?? <String, dynamic>{};
    final acceptedMechanics =
        Map<String, dynamic>.from(data['acceptedMechanics'] ?? {});
    final mechanicData = _responseMap(acceptedMechanics[mechanicId]);
    if (mechanicData.isEmpty || _isRejectedResponse(mechanicData)) {
      Get.snackbar('Unavailable', 'That offer is no longer available.');
      return;
    }

    await _fire.collection('orders').doc(orderId).update({
      'selectedMechanicId': mechanicId,
      'helperId': mechanicId,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'acceptedMechanics.$mechanicId.responseStatus': 'selected',
      'acceptedMechanics.$mechanicId.selectedAt': FieldValue.serverTimestamp(),
      'promisedTimeInMinutes': mechanicData['promisedTimeInMinutes'],
      'rejectionReason': FieldValue.delete(),
    });
  }

  // Mechanic updates live location
  Future<void> updateMechanicLiveLocation(double lat, double lng) async {
    final uid = _auth.appUser.value?.uid;
    if (uid != null) {
      await _fire.collection('users').doc(uid).update({
        'liveLat': lat,
        'liveLng': lng,
      });

      final assignedOrders = await _fire
          .collection('orders')
          .where('helperId', isEqualTo: uid)
          .get();

      final batch = _fire.batch();
      for (final doc in assignedOrders.docs) {
        final data = doc.data();
        final status = (data['status'] as String? ?? '').toLowerCase();
        if (status != 'accepted' && status != 'reached') {
          continue;
        }

        batch.update(doc.reference, {
          'acceptedMechanics.$uid.lat': lat,
          'acceptedMechanics.$uid.lng': lng,
        });
      }

      await batch.commit();
    }
  }

  Future<Position?> _getCurrentLivePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<void> startMechanicLiveLocationTracking() async {
    if (_mechanicLocationTimer != null ||
        _auth.appUser.value?.role != 'mechanic') {
      return;
    }

    await _syncMechanicLiveLocation();
    _mechanicLocationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _syncMechanicLiveLocation(),
    );
  }

  Future<void> _syncMechanicLiveLocation() async {
    if (_isUpdatingMechanicLocation) {
      return;
    }

    _isUpdatingMechanicLocation = true;
    try {
      final position = await _getCurrentLivePosition();
      if (position != null) {
        await updateMechanicLiveLocation(
          position.latitude,
          position.longitude,
        );
      }
    } finally {
      _isUpdatingMechanicLocation = false;
    }
  }

  void stopMechanicLiveLocationTracking() {
    _mechanicLocationTimer?.cancel();
    _mechanicLocationTimer = null;
  }

  // Mechanic reached and gives budget
  Future<void> submitBudget(String orderId, double budget) async {
    await _fire.collection('orders').doc(orderId).update({
      'serviceBudget': budget,
      'status': 'reached',
    });
  }

  // User confirms completion
  Future<void> confirmCompletion(String orderId, bool confirmed,
      {String? reason}) async {
    final updateData = {
      'status': confirmed ? 'completed' : 'rejected_completion',
    };
    if (reason != null) updateData['rejectionReason'] = reason;
    await _fire.collection('orders').doc(orderId).update(updateData);
  }

  // User: fetch user's orders
  Future<void> fetchUserOrders() async {
    final uid = _auth.appUser.value!.uid;
    final snap =
        await _fire.collection('orders').where('userId', isEqualTo: uid).get();
    final list = snap.docs.map((d) {
      final map = d.data();
      map['createdAt'] = map['createdAt'] ?? Timestamp.now();
      return OrderModel.fromMap(map);
    }).toList();

    // Latest requests first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    orders.assignAll(list);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (status == 'cancelled') {
      final doc = await _fire.collection('orders').doc(orderId).get();
      final data = doc.data();
      if (data != null &&
          data['status'] == 'accepted' &&
          data['helperId'] != null) {
        final mechDoc =
            await _fire.collection('users').doc(data['helperId']).get();
        final mechData = mechDoc.data();
        if (mechData != null &&
            mechData['liveLat'] != null &&
            data['lat'] != null) {
          const distance = Distance();
          final dist = distance.as(
            LengthUnit.Meter,
            LatLng(data['lat'], data['lng']),
            LatLng(mechData['liveLat'], mechData['liveLng']),
          );
          if (dist < 500) {
            Get.snackbar(
                'Cannot Cancel', 'Mechanic is already near your location.');
            return;
          }
        }
      }
    }

    final Map<String, dynamic> updateData = {'status': status};
    if (status == 'accepted' || status == 'completed') {
      final uid = _auth.appUser.value?.uid;
      if (uid != null) {
        updateData['helperId'] = uid;
      }
    }
    await _fire.collection('orders').doc(orderId).update(updateData);
  }

  Future<void> submitGrievance(
      String orderId, String targetId, String issue) async {
    await _fire.collection('grievances').add({
      'orderId': orderId,
      'reporterId': _auth.appUser.value?.uid,
      'targetId': targetId,
      'issue': issue,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    Get.snackbar('Submitted', 'Your grievance has been recorded.');
  }

  @override
  void onClose() {
    stopMechanicLiveLocationTracking();
    super.onClose();
  }
}
