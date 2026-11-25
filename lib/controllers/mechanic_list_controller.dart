import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MechanicListController extends GetxController {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  var mechanics = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMechanics();
  }

  Future<void> fetchMechanics() async {
    isLoading.value = true;
    try {
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
      mechanics.value = results;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch mechanics: $e');
    } finally {
      isLoading.value = false;
    }
  }

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
}
