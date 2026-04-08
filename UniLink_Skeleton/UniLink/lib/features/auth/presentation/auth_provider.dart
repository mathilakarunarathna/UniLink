import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? _user;
  User? get user => _user;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    _checkInitialState();
  }

  void _checkInitialState() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _user = currentUser;
      fetchUserData();
    }
  }

  Future<void> fetchUserData() async {
    if (_user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;
      await fetchUserData();

      if (_userData != null && _userData!['role'] == 'student') {
        _setLoading(false);
        return true;
      }

      await logout();
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint("Login Error: $e");
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _userData = null;
    notifyListeners();
  }
}
