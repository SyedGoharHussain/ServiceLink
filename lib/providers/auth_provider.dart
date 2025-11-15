import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/messaging_service.dart';
import '../models/user_model.dart';

/// Provider for authentication and user state management
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final MessagingService _messagingService = MessagingService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  /// Initialize auth state
  void initialize() {
    _authService.authStateChanges.listen((User? user) async {
      print('Auth state changed: ${user?.uid}');
      _firebaseUser = user;

      if (user != null) {
        print('Loading user profile for: ${user.uid}');
        await loadUserProfile(user.uid);
        print('User profile loaded: ${_userModel?.name}');
        await _messagingService.updateUserToken(user.uid);
      } else {
        _userModel = null;
      }

      notifyListeners();
    });
  }

  /// Load user profile from Firestore
  Future<void> loadUserProfile(String uid) async {
    try {
      print('Fetching user from Firestore: $uid');
      _userModel = await _firestoreService.getUser(uid);
      print('User model fetched: ${_userModel?.toMap()}');
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      print('Starting sign in for: $email');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      print('Sign in successful, user: ${userCredential.user?.uid}');

      // Manually set the firebase user and load profile
      _firebaseUser = userCredential.user;
      if (_firebaseUser != null) {
        print('Loading user profile immediately after sign-in');
        await loadUserProfile(_firebaseUser!.uid);
        await _messagingService.updateUserToken(_firebaseUser!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Sign in error: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      await _authService.createUserProfile(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
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

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _authService.signInWithGoogle();

      // Check if user profile exists
      final exists = await _authService.userProfileExists(
        userCredential.user!.uid,
      );

      // If new user, return false to show role selection
      if (!exists) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

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

  /// Complete Google sign-in with role selection
  Future<bool> completeGoogleSignIn(String name, String role) async {
    try {
      if (_firebaseUser == null) return false;

      await _authService.createUserProfile(
        uid: _firebaseUser!.uid,
        email: _firebaseUser!.email!,
        name: name,
        role: role,
      );

      await loadUserProfile(_firebaseUser!.uid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateUserProfile(updatedUser);
      _userModel = updatedUser;

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

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _userModel = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Refresh user profile from Firestore
  Future<void> refreshUserProfile() async {
    if (_firebaseUser != null) {
      try {
        print(
          'AuthProvider: Refreshing user profile for ${_firebaseUser!.uid}',
        );
        final oldRating = _userModel?.rating;
        final oldReviewCount = _userModel?.reviewCount;
        _userModel = await _firestoreService.getUser(_firebaseUser!.uid);
        print(
          'AuthProvider: User profile refreshed - Rating: ${_userModel?.rating} (was $oldRating), Reviews: ${_userModel?.reviewCount} (was $oldReviewCount)',
        );
        notifyListeners();
      } catch (e) {
        print('AuthProvider ERROR: Failed to refresh profile: $e');
      }
    } else {
      print('AuthProvider: Cannot refresh - no firebase user');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.deleteAccount();

      _userModel = null;
      _firebaseUser = null;

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
}
