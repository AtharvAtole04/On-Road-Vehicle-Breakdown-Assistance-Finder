// lib/views/admin/admin_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView>
    with SingleTickerProviderStateMixin {
  final AuthController auth = Get.find<AuthController>();
  final AdminController adminC = Get.find<AdminController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Admin Control Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Data'),
            Tab(icon: Icon(Icons.engineering), text: 'Mechanics'),
            Tab(icon: Icon(Icons.history), text: 'Orders'),
            Tab(icon: Icon(Icons.star), text: 'Reviews'),
            Tab(icon: Icon(Icons.report_problem), text: 'Grievance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildMechanicsTab(),
          _buildOrdersTab(),
          _buildReviewsTab(),
          _buildGrievanceTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Obx(() => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard('Daily',
                        adminC.dailyRequests.value.toString(), Colors.blue),
                  ),
                  Expanded(
                    child: _statCard('Monthly',
                        adminC.monthlyRequests.value.toString(), Colors.green),
                  ),
                  Expanded(
                    child: _statCard('Yearly',
                        adminC.yearlyRequests.value.toString(), Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Service Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard('Completed',
                        adminC.completedOrders.value.toString(), Colors.teal),
                  ),
                  Expanded(
                    child: _statCard(
                        'In Progress',
                        adminC.notCompletedOrders.value.toString(),
                        Colors.redAccent),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('User Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _statCard('Total Mechanics',
                    adminC.totalMechanics.value.toString(), Colors.indigo),
              ),
            ],
          ),
        ));
  }

  Widget _statCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanicsTab() {
    return Obx(() {
      final mechanics = adminC.mechanics;
      if (mechanics.isEmpty) {
        return const Center(child: Text('No mechanics registered yet'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: mechanics.length,
        itemBuilder: (context, index) {
          final m = mechanics[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: m.isApproved ? Colors.green : Colors.grey,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(m.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(m.email),
              children: [
                FutureBuilder<Map<String, int>>(
                  future: adminC.getMechanicOrderStats(m.uid),
                  builder: (context, snap) {
                    final stats = snap.data ?? {'completed': 0, 'offers': 0};
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Offers Sent:'),
                              Text('${stats['offers']}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Orders Completed:'),
                              Text('${stats['completed']}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Account Status:'),
                              const Spacer(),
                              Switch(
                                value: m.isApproved,
                                onChanged: (val) => adminC.updateMechanicApproval(m.uid, val),
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildOrdersTab() {
    return Obx(() {
      final orders = adminC.orders;
      if (orders.isEmpty) {
        return const Center(child: Text('No orders found'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final o = orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(o.serviceType.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${o.location}\n${DateFormat('dd MMM yyyy').format(o.createdAt)}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(o.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  o.status.toUpperCase(),
                  style: TextStyle(
                      color: _statusColor(o.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildReviewsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future:
          adminC.getMechanicsWithRatings(), // I'll add this to admin controller
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('No reviews found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final m = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(m['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Avg Rating: ${m['avgRating'].toStringAsFixed(1)} (${m['ratingCount']} reviews)'),
                trailing: Icon(Icons.star, color: Colors.amber.shade700),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrievanceTab() {
    return Obx(() {
      final grievances = adminC.grievances;
      if (grievances.isEmpty) {
        return const Center(child: Text('No grievances reported'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: grievances.length,
        itemBuilder: (context, index) {
          final g = grievances[index];
          final isPending = g['status'] == 'pending';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('Order ID: ${g['orderId']}'),
              subtitle: Text('Issue: ${g['issue']}\nStatus: ${g['status']}'),
              trailing: isPending
                  ? ElevatedButton(
                      onPressed: () => adminC.resolveGrievance(g['id'] ?? ''), // Assuming id is in map
                      child: const Text('Resolve'),
                    )
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      );
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
