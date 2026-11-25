import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'credit' or 'debit'
  final String? orderId;
  final DateTime timestamp;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.orderId,
    required this.timestamp,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      type: map['type'] ?? 'credit',
      orderId: map['orderId'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'orderId': orderId,
      'timestamp': timestamp,
    };
  }
}
