import 'package:cloud_firestore/cloud_firestore.dart';

class MatchResultHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate points earned from a match win
  /// Formula: winner gets 95% of total pot
  int calculateWinnerPoints(int winnerBet, int loserBet) {
    final totalPot = winnerBet + loserBet;
    final winnings = (totalPot * 0.95).round();
    return winnings;
  }

  /// Update user stats after a match
  Future<void> updateMatchResult({
    required String winnerId,
    required String loserId,
    required int winnerBet,
    required int loserBet,
    required String matchId,
  }) async {
    try {
      final batch = _firestore.batch();

      final pointsWon = calculateWinnerPoints(winnerBet, loserBet);

      // Update winner
      final winnerRef = _firestore.collection('users').doc(winnerId);
      batch.update(winnerRef, {
        'totalPoints': FieldValue.increment(pointsWon),
        'wins': FieldValue.increment(1),
        'gamesPlayed': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update loser
      final loserRef = _firestore.collection('users').doc(loserId);
      batch.update(loserRef, {
        'totalPoints': FieldValue.increment(-loserBet),
        'losses': FieldValue.increment(1),
        'gamesPlayed': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update match status
      final matchRef = _firestore.collection('matches').doc(matchId);
      batch.update(matchRef, {
        'status': 'completed',
        'winnerId': winnerId,
        'loserId': loserId,
        'pointsDistributed': pointsWon,
        'completedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

    } catch (e) {
      print('Error updating match result: $e');
      rethrow;
    }
  }

  /// Declare match winner by matchId
  Future<void> declareMatchWinner({
    required String matchId,
    required String winnerId,
  }) async {
    try {
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();

      if (!matchDoc.exists) {
        throw Exception('Match not found');
      }

      final matchData = matchDoc.data()!;
      final participants = matchData['participants'] as List;
      final matchPoints = matchData['points'] as int;

      if (participants.length < 2) {
        throw Exception('Not enough participants');
      }

      final winner = participants.firstWhere((p) => p['userId'] == winnerId);
      final loser = participants.firstWhere((p) => p['userId'] != winnerId);

      await updateMatchResult(
        winnerId: winnerId,
        loserId: loser['userId'],
        winnerBet: matchPoints,
        loserBet: matchPoints,
        matchId: matchId,
      );

    } catch (e) {
      print('Error declaring winner: $e');
      rethrow;
    }
  }

  /// Get user's current points
  Future<int> getUserPoints(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return 0;
      }

      return userDoc.data()?['totalPoints'] ?? 0;
    } catch (e) {
      print('Error getting user points: $e');
      return 0;
    }
  }

  /// Check if user has enough points
  Future<bool> canJoinMatch(String userId, int requiredPoints) async {
    final currentPoints = await getUserPoints(userId);
    return currentPoints >= requiredPoints;
  }

  /// Hold points when joining match
  Future<void> holdPointsForMatch({
    required String userId,
    required int points,
    required String matchId,
  }) async {
    try {
      final hasEnoughPoints = await canJoinMatch(userId, points);

      if (!hasEnoughPoints) {
        throw Exception('Insufficient points');
      }

      await _firestore.collection('users').doc(userId).update({
        'totalPoints': FieldValue.increment(-points),
      });

    } catch (e) {
      print('Error holding points: $e');
      rethrow;
    }
  }
}