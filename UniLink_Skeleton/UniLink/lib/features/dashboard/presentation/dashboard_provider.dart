import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _newsSubscription;

  bool _isLoading = false;
  bool get isLoading => _isLoading;



  List<Map<String, dynamic>> _news = [];
  List<Map<String, dynamic>> get news => _news;

  DashboardProvider() {
    _listenToDashboardData();
  }

  void _listenToDashboardData() {
    _newsSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    // Listen to News
    _newsSubscription = _firestore
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final nextNews = snapshot.docs.map((doc) => doc.data()).toList();
          if (_areMapListsEqual(_news, nextNews) && !_isLoading) return;
          _news = nextNews;
          _isLoading = false;
          notifyListeners();
        });


  }

  bool _areMapListsEqual(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!mapEquals(a[i], b[i])) return false;
    }
    return true;
  }

  // Legacy method signature maintained for compatibility
  Future<void> fetchDashboardData() async {
    // Real-time listeners are already active
  }

  @override
  void dispose() {
    _newsSubscription?.cancel();
    super.dispose();
  }
}
