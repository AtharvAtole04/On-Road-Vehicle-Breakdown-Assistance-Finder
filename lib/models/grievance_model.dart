import 'package:cloud_firestore/cloud_firestore.dart';

class GrievanceModel {
  final String id;
  final String reporterId;
  final String targetId;
  final String? orderId;
  final String issue;
  final String status; // 'pending', 'resolved'
  final DateTime timestamp;

  GrievanceModel({
    required this.id,
    required this.reporterId,
    required this.targetId,
    this.orderId,
    required this.issue,
    this.status = 'pending',
    required this.timestamp,
  });

  factory GrievanceModel.fromMap(Map<String, dynamic> map) {
    return GrievanceModel(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      targetId: map['targetId'] ?? '',
      orderId: map['orderId'],
      issue: map['issue'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'targetId': targetId,
      'orderId': orderId,
      'issue': issue,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
