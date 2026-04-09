import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/topup_request.dart';

class TopupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert image to base64 string
  Future<String> convertImageToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      throw Exception('Failed to encode screenshot: $e');
    }
  }

  // Submit top-up request
  Future<void> submitTopupRequest({
    required double amount,
    required String method,
    required String screenshotBase64,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final request = TopupRequest(
        requestId: '',
        userId: userId,
        amount: amount,
        method: method,
        screenshotBase64: screenshotBase64,
        status: 'pending',
        timestamp: DateTime.now(),
      );

      await _firestore.collection('topup_requests').add(request.toFirestore());
    } catch (e) {
      throw Exception('Failed to submit request: $e');
    }
  }

  // Get all pending requests (for admin)
  Stream<List<TopupRequest>> getPendingRequests() {
    return _firestore
        .collection('topup_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TopupRequest.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Get all requests with failed points addition (for admin)
  Stream<List<TopupRequest>> getFailedPointsRequests() {
    return _firestore
        .collection('topup_requests')
        .where('status', isEqualTo: 'payment_verified_but_points_failed')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TopupRequest.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Approve request and add points (TRANSACTION-SAFE)
  Future<void> approveRequest(String requestId, String userId, double amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get user document
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        // Calculate new points
        final currentPoints = (userDoc.data()?['points'] ?? 0).toDouble();
        final newPoints = currentPoints + amount;

        // Update user points
        transaction.update(userRef, {'points': newPoints});

        // Update request status to success
        final requestRef = _firestore.collection('topup_requests').doc(requestId);
        transaction.update(requestRef, {
          'status': 'success',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // If transaction fails, mark request as failed
      await _firestore.collection('topup_requests').doc(requestId).update({
        'status': 'payment_verified_but_points_failed',
        'error': e.toString(),
      });
      throw Exception('Failed to add points: $e');
    }
  }

  // Retry adding points for failed requests
  Future<void> retryAddPoints(String requestId, String userId, double amount) async {
    await approveRequest(requestId, userId, amount);
  }

  // Reject request
  Future<void> rejectRequest(String requestId) async {
    try {
      await _firestore.collection('topup_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  // Get user's current points
  Stream<double> getUserPoints() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return 0;
      return (doc.data()?['points'] ?? 0).toDouble();
    });
  }

  // Get user's top-up history
  Stream<List<TopupRequest>> getUserTopupHistory() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('topup_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TopupRequest.fromFirestore(doc.data(), doc.id))
        .toList());
  }
}