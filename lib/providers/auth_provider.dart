import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool get isGuest => !isAuthenticated;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get hasProfile => _userProfile != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      _currentUser = user;
      if (user != null) {
        await _loadUserProfile();
      } else {
        _userProfile = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      _userProfile = await _authService.getUserProfile(_currentUser!.uid);

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, {String? phoneNumber}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.registerWithEmailAndPassword(email, password);

      await _authService.createUserProfile(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      _currentUser = null;
      _userProfile = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    required String name,
    String? phoneNumber,
    String? profileImageUrl,
    String? address,
    GeoPoint? location,
    String? bio,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = {
      'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      if (bio != null) 'bio': bio,
    };
    await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
  }

  Future<String> uploadProfileImage(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<bool> updateLocation() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.updateUserLocation();
      await _loadUserProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.deleteAccount();

      _currentUser = null;
      _userProfile = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refreshProfile() {
    if (_currentUser != null) {
      _loadUserProfile();
    }
  }
}
