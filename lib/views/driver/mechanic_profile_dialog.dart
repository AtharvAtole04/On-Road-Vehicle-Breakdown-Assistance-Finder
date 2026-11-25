import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class MechanicProfileDialog extends StatelessWidget {
  final String mechanicId;
  final String? currentIssue;

  const MechanicProfileDialog({
    Key? key,
    required this.mechanicId,
    this.currentIssue,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchStats() async {
    final fire = FirebaseFirestore.instance;
    
    final completed = await fire
        .collection('orders')
        .where('helperId', isEqualTo: mechanicId)
        .where('status', whereIn: ['completed', 'paid'])
        .get();

    final cancelled = await fire
        .collection('orders')
        .where('helperId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'cancelled')
        .get();

    int expertiseCount = 0;
    if (currentIssue != null && currentIssue!.isNotEmpty) {
      expertiseCount = completed.docs.where((doc) => doc.data()['vehicleIssue'] == currentIssue).length;
    }

    return {
      'completed': completed.docs.length,
      'cancelled': cancelled.docs.length,
      'expertise': expertiseCount,
      'history': completed.docs.map((d) => d.data()).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Fetching mechanic history...'),
                ],
              ),
            );
          }

          final stats = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mechanic Performance', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statusCard('Solved', stats['completed'].toString(), Colors.green),
                    _statusCard('Unsolved', stats['cancelled'].toString(), Colors.red),
                  ],
                ),
                
                const SizedBox(height: 20),
                if (currentIssue != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expertise Rank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 4),
                        Text('Solved ${stats['expertise']} orders with similar "$currentIssue" problems.',
                          style: TextStyle(color: Colors.blue.shade900)),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                const Text('Past History', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: stats['history'].isEmpty 
                    ? const Center(child: Text('No past history available'))
                    : ListView.builder(
                        itemCount: stats['history'].length,
                        itemBuilder: (context, index) {
                          final h = stats['history'][index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            title: Text(h['vehicleIssue'] ?? 'General Repair', maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(h['createdAt'] != null ? (h['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : ''),
                          );
                        },
                      ),
                ),
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
