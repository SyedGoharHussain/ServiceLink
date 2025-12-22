import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../utils/constants.dart';

/// Firestore service for database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== USER OPERATIONS ==========

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Search workers by city and service type
  Stream<List<UserModel>> searchWorkers({String? city, String? serviceType}) {
    try {
      Query query = _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleWorker);

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (serviceType != null && serviceType.isNotEmpty) {
        query = query.where('serviceType', isEqualTo: serviceType);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to search workers: $e');
    }
  }

  /// Get all workers (for browsing)
  Stream<List<UserModel>> getAllWorkers() {
    try {
      return _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleWorker)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => UserModel.fromMap(doc.data()))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to get workers: $e');
    }
  }

  // ========== REQUEST OPERATIONS ==========

  /// Create a new request
  Future<String> createRequest(RequestModel request) async {
    try {
      print('FirestoreService: Starting createRequest');
      print('Request data: ${request.toMap()}');

      final docRef = await _firestore
          .collection(AppConstants.requestsCollection)
          .add(request.toMap());

      print('FirestoreService: Document created with ID: ${docRef.id}');

      // Update the request with its ID
      await docRef.update({'requestId': docRef.id});

      print('FirestoreService: Document updated with requestId field');

      return docRef.id;
    } catch (e, stackTrace) {
      print('FirestoreService: Error creating request: $e');
      print('FirestoreService: Stack trace: $stackTrace');
      throw Exception('Failed to create request: $e');
    }
  }

  /// Update request status
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? workerPhone,
  }) async {
    try {
      final updateData = <String, dynamic>{'status': status};

      if (acceptedAt != null) {
        updateData['acceptedAt'] = Timestamp.fromDate(acceptedAt);
      }

      if (completedAt != null) {
        updateData['completedAt'] = Timestamp.fromDate(completedAt);
      }
      
      if (workerPhone != null) {
        updateData['workerPhone'] = workerPhone;
      }

      await _firestore
          .collection(AppConstants.requestsCollection)
          .doc(requestId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Get requests for a worker (received requests)
  Stream<List<RequestModel>> getWorkerRequests(String workerId) {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .handleError((error) {
          print('Error loading worker requests: $error');
          return Stream.value([]);
        })
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => RequestModel.fromMap(doc.data()))
              .toList();
          // Sort in memory by createdAt descending
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Get requests for a customer (sent requests)
  Stream<List<RequestModel>> getCustomerRequests(String customerId) {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .handleError((error) {
          print('Error loading customer requests: $error');
          return Stream.value([]);
        })
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => RequestModel.fromMap(doc.data()))
              .toList();
          // Sort in memory by createdAt descending
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Add review and rating to a request
  Future<void> addReviewToRequest({
    required String requestId,
    required String review,
    required double rating,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.requestsCollection)
          .doc(requestId)
          .update({'customerReview': review, 'customerRating': rating});
    } catch (e) {
      print('FirestoreService ERROR: Failed to add review: $e');
      throw Exception('Failed to add review: $e');
    }
  }

  /// Update worker rating (called after review is added)
  Future<void> updateWorkerRating(String workerId) async {
    try {
      // Get all completed requests for this worker with ratings
      final requestsSnapshot = await _firestore
          .collection(AppConstants.requestsCollection)
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: AppConstants.statusCompleted)
          .get();

      // Calculate average rating
      double totalRating = 0;
      int count = 0;

      for (var doc in requestsSnapshot.docs) {
        final rating = doc.data()['customerRating'];
        if (rating != null) {
          totalRating += rating.toDouble();
          count++;
          print('FirestoreService: Request ${doc.id} has rating: $rating');
        }
      }

      final averageRating = count > 0 ? totalRating / count : 0.0;
      print(
        'FirestoreService: Calculated average rating: $averageRating from $count reviews',
      );

      // Update worker's rating
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(workerId)
          .update({'rating': averageRating, 'reviewCount': count});

      print('FirestoreService: Worker rating updated successfully');
    } catch (e) {
      print('FirestoreService ERROR: Failed to update worker rating: $e');
      throw Exception('Failed to update worker rating: $e');
    }
  }

  /// Get request by ID
  Future<RequestModel?> getRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.requestsCollection)
          .doc(requestId)
          .get();

      if (doc.exists) {
        final request = RequestModel.fromMap(doc.data()!);
        return request;
      }
      return null;
    } catch (e) {
      print('FirestoreService ERROR: Failed to get request: $e');
      throw Exception('Failed to get request: $e');
    }
  }
}
