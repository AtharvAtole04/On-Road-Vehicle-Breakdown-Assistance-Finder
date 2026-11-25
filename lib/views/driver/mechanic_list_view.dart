import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mechanic_list_controller.dart';

class MechanicListView extends StatelessWidget {
  final MechanicListController controller = Get.find<MechanicListController>();

  MechanicListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Top Rated Mechanics',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F9D58), Color(0xFF00BFA6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.mechanics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_rounded,
                    size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No approved mechanics found',
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchMechanics,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.mechanics.length,
            itemBuilder: (context, index) {
              final mechanic = controller.mechanics[index];
              final String name = mechanic['name'] ?? 'Unknown';
              final String garage =
                  mechanic['garageName'] ?? 'General Mechanic';
              final double rating = mechanic['avgRating'] ?? 0.0;
              final int count = mechanic['ratingCount'] ?? 0;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F9D58).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.build_circle_rounded,
                            color: Color(0xFF0F9D58), size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              garage,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($count reviews)',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
