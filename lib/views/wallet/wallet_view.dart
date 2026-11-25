import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roadside_assistant/controllers/wallet_controller.dart';

class WalletView extends StatelessWidget {
  final WalletController walletC = Get.put(WalletController());

  WalletView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imaginary Wallet'),
        backgroundColor: Colors.indigo,
      ),
      body: Obx(() {
        return Column(
          children: [
            _balanceCard(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: walletC.transactions.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : ListView.builder(
                      itemCount: walletC.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = walletC.transactions[index];
                        final isDebit = tx.type == 'debit';
                        return ListTile(
                          leading: Icon(
                            isDebit ? Icons.arrow_outward : Icons.arrow_downward,
                            color: isDebit ? Colors.red : Colors.green,
                          ),
                          title: Text(isDebit ? 'Service Payment' : 'Funds Added'),
                          subtitle: Text(tx.timestamp.toString()),
                          trailing: Text(
                            '${isDebit ? "-" : "+"} ₹${tx.amount}',
                            style: TextStyle(
                              color: isDebit ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFundsDialog(context),
        label: const Text('Add Funds'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            '₹ ${walletC.balance.value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context) {
    final amountC = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Add Funds'),
        content: TextField(
          controller: amountC,
          decoration: const InputDecoration(labelText: 'Amount (₹)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountC.text);
              if (amount != null && amount > 0) {
                walletC.addFunds(amount);
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
