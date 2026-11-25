import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';

class AdminController extends GetxController {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  RxList<UserModel> mechanics = <UserModel>[].obs;
  RxList<OrderModel> orders = <OrderModel>[].obs;
  RxList<Map<String, dynamic>> grievances = <Map<String, dynamic>>[].obs;

  // Dashboard Stats
  RxInt dailyRequests = 0.obs;
  RxInt monthlyRequests = 0.obs;
  RxInt yearlyRequests = 0.obs;
  RxInt completedOrders = 0.obs;
  RxInt notCompletedOrders = 0.obs;
  RxInt totalMechanics = 0.obs;

  @override
  void onInit() {
    super.onInit();
    listenToData();
  }

  void listenToData() {
    // Listen to all users with role 'mechanic'
    _fire
        .collection('users')
        .where('role', isEqualTo: 'mechanic')
        .snapshots()
        .listen((snap) {
      mechanics.value = snap.docs
          .map((d) => UserModel.fromMap({...d.data(), 'uid': d.id}))
          .toList();
      totalMechanics.value = mechanics.length;
    });

    // Listen to all orders for stats
    _fire.collection('orders').snapshots().listen((snap) {
      orders.value = snap.docs.map((d) {
        final map = d.data();
        map['createdAt'] = map['createdAt'] ?? Timestamp.now();
        return OrderModel.fromMap(map);
      }).toList();
      _calculateStats();
    });

    // Listen to grievances
    _fire.collection('grievances').orderBy('timestamp', descending: true).snapshots().listen((snap) {
      grievances.value = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
    });
  }

  Future<void> resolveGrievance(String grievanceId) async {
    await _fire.collection('grievances').doc(grievanceId).update({'status': 'resolved'});
  }

  Future<Map<String, int>> getMechanicOrderStats(String mechanicId) async {
    final completed = orders.where((o) {
      final status = o.status.toLowerCase();
      return o.helperId == mechanicId &&
          (status == 'completed' || status == 'paid');
    }).length;

    final offers = orders.where((o) {
      final acceptedMechanics = o.acceptedMechanics;

      if (acceptedMechanics.containsKey(mechanicId)) {
        return true;
      }

      return acceptedMechanics.values.any((offer) {
        if (offer is Map<String, dynamic>) {
          return offer['mechanicId'] == mechanicId;
        }
        if (offer is Map) {
          return offer['mechanicId'] == mechanicId;
        }
        return false;
      });
    }).length;

    return {'completed': completed, 'offers': offers};
  }

  void _calculateStats() {
    final now = DateTime.now();
    int daily = 0;
    int monthly = 0;
    int yearly = 0;
    int completed = 0;
    int notCompleted = 0;

    for (var o in orders) {
      final date = o.createdAt;

      // Request counts
      if (date.year == now.year) {
        yearly++;
        if (date.month == now.month) {
          monthly++;
          if (date.day == now.day) {
            daily++;
          }
        }
      }

      // Status counts
      if (o.status.toLowerCase() == 'completed') {
        completed++;
      } else {
        notCompleted++;
      }
    }

    dailyRequests.value = daily;
    monthlyRequests.value = monthly;
    yearlyRequests.value = yearly;
    completedOrders.value = completed;
    notCompletedOrders.value = notCompleted;
  }

  Future<void> updateMechanicApproval(String uid, bool isApproved) async {
    try {
      await _fire
          .collection('users')
          .doc(uid)
          .update({'isApproved': isApproved});
    } catch (e) {
      Get.snackbar('Error', 'Failed to update approval: $e');
    }
  }

  // Fetch mechanics sorted by rating (for new users)
  Future<List<Map<String, dynamic>>> getMechanicsSortedByRating() async {
    final querySnap = await _fire
        .collection('users')
        .where('role', isEqualTo: 'mechanic')
        .where('isApproved', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in querySnap.docs) {
      final data = doc.data();
      final ratingData = await fetchMechanicRating(doc.id);
      results.add({
        ...data,
        'uid': doc.id,
        'avgRating': ratingData['avg'],
        'ratingCount': ratingData['count'],
      });
    }

    // Sort by rating descending
    results.sort(
        (a, b) => (b['avgRating'] as num).compareTo(a['avgRating'] as num));
    return results;
  }

  // Alias for cleanliness in view
  Future<List<Map<String, dynamic>>> getMechanicsWithRatings() =>
      getMechanicsSortedByRating();

  Future<Map<String, dynamic>> fetchMechanicRating(String recipientId) async {
    try {
      final q = await _fire
          .collection('feedbacks')
          .where('recipientId', isEqualTo: recipientId)
          .get();
      final docs = q.docs;
      if (docs.isEmpty) return {'avg': 0.0, 'count': 0};

      double sum = 0;
      int count = 0;
      for (final d in docs) {
        final r = d.data()['rating'];
        if (r is num) {
          sum += r;
          count++;
        }
      }
      final avg = count == 0 ? 0.0 : (sum / count);
      return {'avg': avg, 'count': count};
    } catch (e) {
      return {'avg': 0.0, 'count': 0};
    }
  }

  // Fetch reviews (feedbacks) for a specific mechanic
  Future<List<Map<String, dynamic>>> getMechanicReviews(
      String mechanicId) async {
    final snap = await _fire
        .collection('feedbacks')
        .where('recipientId', isEqualTo: mechanicId)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
