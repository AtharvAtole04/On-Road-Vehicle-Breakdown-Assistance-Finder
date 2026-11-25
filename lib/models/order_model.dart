import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String serviceType;
  final String location;
  final String status; // pending / accepted / completed / reached
  final DateTime createdAt;
  final double? lat;
  final double? lng;
  final String? vehicleIssue;
  final DateTime? acceptedAt;
  final int? promisedTimeInMinutes;
  final String? helperId;

  // New fields for multi-mechanic selection
  final Map<String, dynamic>
      acceptedMechanics; // mechanicId -> {charges, time, name, phone, lat, lng}
  final String? selectedMechanicId;

  // New fields for fuel/towing
  final String? fuelType;
  final double? fuelCapacity;
  final bool isTowing;

  // New fields for budgeting and completion
  final double? serviceBudget;
  final String? rejectionReason;

  OrderModel({
    required this.lng,
    required this.lat,
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.location,
    required this.status,
    required this.createdAt,
    this.vehicleIssue,
    this.acceptedAt,
    this.promisedTimeInMinutes,
    this.helperId,
    this.acceptedMechanics = const {},
    this.selectedMechanicId,
    this.fuelType,
    this.fuelCapacity,
    this.isTowing = false,
    this.serviceBudget,
    this.rejectionReason,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      serviceType: map['serviceType'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lat: (map['lat'] is num) ? (map['lat'] as num).toDouble() : null,
      lng: (map['lng'] is num) ? (map['lng'] as num).toDouble() : null,
      vehicleIssue: map['vehicleIssue'] as String?,
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      promisedTimeInMinutes: map['promisedTimeInMinutes'] as int?,
      helperId: map['helperId'] as String?,
      acceptedMechanics:
          Map<String, dynamic>.from(map['acceptedMechanics'] ?? {}),
      selectedMechanicId: map['selectedMechanicId'] as String?,
      fuelType: map['fuelType'] as String?,
      fuelCapacity: (map['fuelCapacity'] is num)
          ? (map['fuelCapacity'] as num).toDouble()
          : null,
      isTowing: map['isTowing'] ?? false,
      serviceBudget: (map['serviceBudget'] is num)
          ? (map['serviceBudget'] as num).toDouble()
          : null,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceType': serviceType,
      'location': location,
      'status': status,
      'createdAt': createdAt,
      'vehicleIssue': vehicleIssue,
      'acceptedAt': acceptedAt,
      'promisedTimeInMinutes': promisedTimeInMinutes,
      'helperId': helperId,
      'acceptedMechanics': acceptedMechanics,
      'selectedMechanicId': selectedMechanicId,
      'fuelType': fuelType,
      'fuelCapacity': fuelCapacity,
      'isTowing': isTowing,
      'serviceBudget': serviceBudget,
      'rejectionReason': rejectionReason,
    };
  }

  void operator [](String other) {}
}
