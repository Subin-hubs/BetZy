import 'package:cloud_firestore/cloud_firestore.dart';

class TopupRequest {
  final String requestId;
  final String userId;
  final double amount;
  final String method;
  final String screenshotBase64; // Changed from screenshotUrl
  final String status;
  final DateTime timestamp;

  TopupRequest({
    required this.requestId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.screenshotBase64,
    required this.status,
    required this.timestamp,
  });

  factory TopupRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return TopupRequest(
      requestId: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'] ?? '',
      screenshotBase64: data['screenshotBase64'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'method': method,
      'screenshotBase64': screenshotBase64,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}