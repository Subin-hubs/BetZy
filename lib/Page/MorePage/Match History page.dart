import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MatchHistoryPage extends StatefulWidget {
  final String userId;

  const MatchHistoryPage({super.key, required this.userId});

  @override
  State<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends State<MatchHistoryPage> {
  final Color primaryColor = const Color(0xFF2962FF);
  final Color accentColor = const Color(0xFFFF6B35);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteMatch(String matchId, Map<String, dynamic> matchData) async {
    final TextEditingController reasonController = TextEditingController();

    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade600),
            const SizedBox(width: 10),
            const Text("Delete Match"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please provide a reason for deleting this match:",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter reason...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "All participants will be refunded",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Fluttertoast.showToast(
                  msg: "Please provide a reason",
                  backgroundColor: Colors.red.shade600,
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true && reasonController.text.trim().isNotEmpty) {
      _performMatchDeletion(matchId, matchData, reasonController.text.trim());
    }
  }

  Future<void> _performMatchDeletion(
      String matchId,
      Map<String, dynamic> matchData,
      String reason,
      ) async {
    // Show loading with proper context handling
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      List participants = matchData['participants'] ?? [];

      // Refund all participants
      await _firestore.runTransaction((transaction) async {
        for (var participant in participants) {
          String userId = participant['userId'];
          int pointsPaid = participant['pointsPaid'] ?? 0;

          if (pointsPaid > 0) {
            DocumentReference userRef = _firestore.collection('users').doc(userId);
            DocumentSnapshot userSnapshot = await transaction.get(userRef);

            if (userSnapshot.exists) {
              var userData = userSnapshot.data() as Map<String, dynamic>;
              double currentPoints = (userData['points'] ?? 0).toDouble();
              transaction.update(userRef, {
                'points': currentPoints + pointsPaid,
              });
            }
          }
        }

        // Update match status to deleted
        DocumentReference matchRef = _firestore.collection('matches').doc(matchId);
        transaction.update(matchRef, {
          'status': 'deleted',
          'deletionReason': reason,
          'deletedAt': DateTime.now().toIso8601String(),
        });
      });

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show success message
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Match deleted and refunds processed",
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error message
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error deleting match: ${e.toString()}",
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Match History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('matches')
            .where('status', whereIn: ['active', 'completed', 'deleted'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text("Error loading matches"),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No matches yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create or join your first match!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter matches where user is creator or participant
          var userMatches = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String creatorId = data['createdBy']?['userId'] ?? '';
            List participants = data['participants'] ?? [];

            bool isCreator = creatorId == widget.userId;
            bool isParticipant = participants.any((p) => p['userId'] == widget.userId);

            return isCreator || isParticipant;
          }).toList();

          if (userMatches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No matches yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userMatches.length,
            itemBuilder: (context, index) {
              var doc = userMatches[index];
              var matchData = doc.data() as Map<String, dynamic>;
              String matchId = doc.id;

              // Check if current user is the creator
              bool isCreator = matchData['createdBy']?['userId'] == widget.userId;

              return _buildMatchHistoryCard(matchId, matchData, isCreator);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchHistoryCard(
      String matchId,
      Map<String, dynamic> matchData,
      bool isCreator,
      ) {
    String game = matchData['game'] ?? 'Unknown';
    String mode = matchData['mode'] ?? 'Unknown';
    String teamSize = matchData['teamSize'] ?? 'N/A';
    int points = matchData['points'] ?? 0;
    String status = matchData['status'] ?? 'active';
    List participants = matchData['participants'] ?? [];

    Color statusColor = status == 'active'
        ? Colors.green
        : status == 'completed'
        ? Colors.blue
        : Colors.red;

    String statusText = status == 'active'
        ? 'ACTIVE'
        : status == 'completed'
        ? 'COMPLETED'
        : 'DELETED';

    IconData gameIcon;
    Color gameColor;

    switch (game) {
      case 'Free Fire':
        gameIcon = Icons.whatshot;
        gameColor = const Color(0xFFEF4444);
        break;
      case 'PUBG':
        gameIcon = Icons.military_tech;
        gameColor = const Color(0xFFF59E0B);
        break;
      case 'eFootball':
        gameIcon = Icons.sports_soccer;
        gameColor = const Color(0xFF10B981);
        break;
      default:
        gameIcon = Icons.sports_esports;
        gameColor = primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'deleted' ? Colors.red.shade200 : Colors.grey.shade200,
          width: status == 'deleted' ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gameColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: gameColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(gameIcon, color: gameColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: gameColor,
                        ),
                      ),
                      Text(
                        "$mode ${teamSize != 'N/A' ? '• $teamSize' : ''}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "$points Points",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.people, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "${participants.length} Joined",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                if (isCreator) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings, color: primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "You are the host",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Show deletion reason if deleted
                if (status == 'deleted' && matchData['deletionReason'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Deletion Reason:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                matchData['deletionReason'],
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Delete button (only for creator and non-deleted matches)
                if (isCreator && status != 'deleted') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteMatch(matchId, matchData),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text(
                        "Delete Match",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}