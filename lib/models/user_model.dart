import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing both Customer and Worker accounts
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'customer' or 'worker'
  final String? city;
  final String?
  serviceType; // For workers: 'carpenter', 'plumber', 'electrician', 'mechanic', etc.
  final double? rate; // Hourly rate for workers
  final String? description; // Worker description/bio
  final String? profileImage; // Firebase Storage URL
  final double rating; // Average rating
  final int reviewCount; // Number of reviews
  final String? fcmToken; // For push notifications
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.city,
    this.serviceType,
    this.rate,
    this.description,
    this.profileImage,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'city': city,
      'serviceType': serviceType,
      'rate': rate,
      'description': description,
      'profileImage': profileImage,
      'rating': rating,
      'reviewCount': reviewCount,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'customer',
      city: map['city'],
      serviceType: map['serviceType'],
      rate: map['rate']?.toDouble(),
      description: map['description'],
      profileImage: map['profileImage'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? city,
    String? serviceType,
    double? rate,
    String? description,
    String? profileImage,
    double? rating,
    int? reviewCount,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      city: city ?? this.city,
      serviceType: serviceType ?? this.serviceType,
      rate: rate ?? this.rate,
      description: description ?? this.description,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
