import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/request_model.dart';

/// Provider for managing job requests
class RequestProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  List<RequestModel> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get requests by status
  List<RequestModel> getRequestsByStatus(String status) {
    return _requests.where((req) => req.status == status).toList();
  }

  /// Create a new request
  Future<bool> createRequest({
    required String customerId,
    required String customerName,
    required String workerId,
    required String workerName,
    required String serviceType,
    required String city,
    required double price,
    required String description,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final request = RequestModel(
        requestId: '', // Will be set by Firestore
        customerId: customerId,
        customerName: customerName,
        workerId: workerId,
        workerName: workerName,
        serviceType: serviceType,
        city: city,
        price: price,
        description: description,
        latitude: latitude,
        longitude: longitude,
        locationAddress: locationAddress,
      );

      final requestId = await _firestoreService.createRequest(request);

      // Send notification to worker only
      await _notificationService.sendRequestNotification(
        recipientId: workerId,
        title: 'New Service Request',
        body: '$customerName requested $serviceType service',
        requestId: requestId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating request: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load worker's requests
  void loadWorkerRequests(String workerId) {
    _firestoreService.getWorkerRequests(workerId).listen((requests) {
      _requests = requests;
      notifyListeners();
    });
  }

  /// Load customer's requests
  void loadCustomerRequests(String customerId) {
    _firestoreService.getCustomerRequests(customerId).listen((requests) {
      _requests = requests;
      notifyListeners();
    });
  }

  /// Accept request
  Future<bool> acceptRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateRequestStatus(
        requestId: requestId,
        status: 'accepted',
        acceptedAt: DateTime.now(),
      );

      // Find the request to get customer details
      final request = _requests.firstWhere((r) => r.requestId == requestId);

      // Send notification to customer
      await _notificationService.sendRequestNotification(
        recipientId: request.customerId,
        title: 'Request Accepted',
        body:
            '${request.workerName} accepted your ${request.serviceType} request',
        requestId: requestId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject request
  Future<bool> rejectRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateRequestStatus(
        requestId: requestId,
        status: 'rejected',
      );

      // Find the request to get customer details
      final request = _requests.firstWhere((r) => r.requestId == requestId);

      // Send notification to customer
      await _notificationService.sendRequestNotification(
        recipientId: request.customerId,
        title: 'Request Rejected',
        body:
            '${request.workerName} declined your ${request.serviceType} request',
        requestId: requestId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Complete request
  Future<bool> completeRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateRequestStatus(
        requestId: requestId,
        status: 'completed',
        completedAt: DateTime.now(),
      );

      // Find the request to get customer details
      final request = _requests.firstWhere((r) => r.requestId == requestId);

      // Send notification to customer
      await _notificationService.sendRequestNotification(
        recipientId: request.customerId,
        title: 'Task Completed',
        body:
            '${request.workerName} completed your ${request.serviceType} request',
        requestId: requestId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add review to completed request
  Future<bool> addReview({
    required String requestId,
    required double rating,
    String? review,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get the request to find worker ID
      final request = await _firestoreService.getRequest(requestId);
      if (request == null) {
        print('RequestProvider ERROR: Request not found');
        throw Exception('Request not found');
      }

      // Add review to request
      await _firestoreService.addReviewToRequest(
        requestId: requestId,
        review: review ?? '',
        rating: rating,
      );

      // Update worker's average rating
      await _firestoreService.updateWorkerRating(request.workerId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      print('RequestProvider ERROR in addReview: $e');
      print('RequestProvider STACK TRACE: $stackTrace');
      return false;
    }
  }

  /// Load requests based on role
  void loadRequests(String userId, String role) {
    if (role == 'worker') {
      loadWorkerRequests(userId);
    } else {
      loadCustomerRequests(userId);
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
