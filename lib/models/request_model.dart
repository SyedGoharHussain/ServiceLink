import 'package:cloud_firestore/cloud_firestore.dart';

/// Request model for job requests from customers to workers
class RequestModel {
  final String requestId;
  final String customerId;
  final String customerName;
  final String? customerPhone; // Customer phone for calling
  final String workerId;
  final String workerName;
  final String? workerPhone; // Worker phone for calling
  final String serviceType;
  final String city;
  final double price; // Proposed price by customer
  final String description;
  final String status; // 'pending', 'accepted', 'rejected', 'completed'
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? customerReview;
  final double? customerRating;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;

  RequestModel({
    required this.requestId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.workerId,
    required this.workerName,
    this.workerPhone,
    required this.serviceType,
    required this.city,
    required this.price,
    required this.description,
    this.status = 'pending',
    DateTime? createdAt,
    this.acceptedAt,
    this.completedAt,
    this.customerReview,
    this.customerRating,
    this.latitude,
    this.longitude,
    this.locationAddress,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert RequestModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'workerId': workerId,
      'workerName': workerName,
      'workerPhone': workerPhone,
      'serviceType': serviceType,
      'city': city,
      'price': price,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'customerReview': customerReview,
      'customerRating': customerRating,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
    };
  }

  /// Create RequestModel from Firestore document
  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      requestId: map['requestId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'],
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      workerPhone: map['workerPhone'],
      serviceType: map['serviceType'] ?? '',
      city: map['city'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      customerReview: map['customerReview'],
      customerRating: map['customerRating']?.toDouble(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationAddress: map['locationAddress'],
    );
  }

  /// Create a copy of RequestModel with updated fields
  RequestModel copyWith({
    String? requestId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? workerId,
    String? workerName,
    String? workerPhone,
    String? serviceType,
    String? city,
    double? price,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? customerReview,
    double? customerRating,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) {
    return RequestModel(
      requestId: requestId ?? this.requestId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerPhone: workerPhone ?? this.workerPhone,
      serviceType: serviceType ?? this.serviceType,
      city: city ?? this.city,
      price: price ?? this.price,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      customerReview: customerReview ?? this.customerReview,
      customerRating: customerRating ?? this.customerRating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
    );
  }
}
