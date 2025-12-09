import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'MatchDetailsScreen.dart';

class AdminMatchManagement extends StatefulWidget {
  const AdminMatchManagement({super.key});

  @override
  State<AdminMatchManagement> createState() => _AdminMatchManagementState();
}

class _AdminMatchManagementState extends State<AdminMatchManagement> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _approveMatch(String matchId, Map<String, dynamic> matchData) async {
    try {
      // Get match participants
      List<dynamic> participants = matchData['participants'] ?? [];
      int pointsPerPlayer = matchData['points'] ?? 0;

      // Update match status to active and hold the points
      await _firestore.collection('matches').doc(matchId).update({
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
        'pointsStatus': 'held', // Points are held until match completion
      });

      // Update each participant's held points
      WriteBatch batch = _firestore.batch();
      for (var participant in participants) {
        String userId = participant['userId'];
        DocumentReference userRef = _firestore.collection('users').doc(userId);

        batch.update(userRef, {
          'heldPoints': FieldValue.increment(pointsPerPlayer),
        });
      }
      await batch.commit();

      _showToast("✅ Match approved! Points held successfully", const Color(0xFF10B981));
    } catch (e) {
      _showToast("Error approving match: ${e.toString()}", const Color(0xFFEF4444));
    }
  }

  Future<void> _rejectMatch(String matchId, Map<String, dynamic> matchData) async {
    // Show rejection reason dialog
    TextEditingController reasonController = TextEditingController();

    bool? shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            const Text("Reject Match"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please provide a reason for rejection:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g., Invalid match details, suspicious activity...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
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
                _showToast("Please provide a reason", const Color(0xFFEF4444));
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text("Reject & Refund"),
          ),
        ],
      ),
    );

    if (shouldReject == true && reasonController.text.trim().isNotEmpty) {
      try {
        String rejectionReason = reasonController.text.trim();
        List<dynamic> participants = matchData['participants'] ?? [];
        int pointsPerPlayer = matchData['points'] ?? 0;

        // Update match status
        await _firestore.collection('matches').doc(matchId).update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectionReason': rejectionReason,
          'pointsStatus': 'refunded',
        });

        // Refund points to all participants
        WriteBatch batch = _firestore.batch();
        for (var participant in participants) {
          String userId = participant['userId'];
          String userName = participant['userName'] ?? 'Unknown';

          DocumentReference userRef = _firestore.collection('users').doc(userId);

          // Refund points
          batch.update(userRef, {
            'points': FieldValue.increment(pointsPerPlayer),
          });

          // Create notification for user
          DocumentReference notifRef = _firestore.collection('notifications').doc();
          batch.set(notifRef, {
            'userId': userId,
            'title': 'Match Rejected',
            'message': 'Your match has been rejected. Reason: $rejectionReason. $pointsPerPlayer points have been refunded.',
            'type': 'match_rejected',
            'matchId': matchId,
            'pointsRefunded': pointsPerPlayer,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();

        _showToast("❌ Match rejected & points refunded", const Color(0xFFEF4444));
      } catch (e) {
        _showToast("Error rejecting match: ${e.toString()}", const Color(0xFFEF4444));
      }
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Match?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('matches').doc(matchId).delete();
        _showToast("🗑️ Match deleted", const Color(0xFF64748B));
      } catch (e) {
        _showToast("Error deleting match: ${e.toString()}", const Color(0xFFEF4444));
      }
    }
  }

  void _showMatchDetails(String matchId, Map<String, dynamic> matchData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailsScreen(
          matchId: matchId,
          matchData: matchData,
        ),
      ),
    );
  }

  void _showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 14,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Match Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab(
                    'Pending',
                    'pending',
                    Icons.pending_actions_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterTab(
                    'Active',
                    'active',
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterTab(
                    'Rejected',
                    'rejected',
                    Icons.cancel_rounded,
                    const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),

          // Matches List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('matches')
                  .where('status', isEqualTo: _selectedFilter)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var matchData = doc.data() as Map<String, dynamic>;
                    String matchId = doc.id;

                    return FadeTransition(
                      opacity: _animationController,
                      child: _buildMatchCard(matchId, matchData),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFilterTab(String label, String value, IconData icon, Color color) {
    bool isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF64748B),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    Color color;

    switch (_selectedFilter) {
      case 'pending':
        message = "No pending matches";
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'active':
        message = "No active matches";
        icon = Icons.sports_esports_outlined;
        color = const Color(0xFF10B981);
        break;
      case 'rejected':
        message = "No rejected matches";
        icon = Icons.cancel_outlined;
        color = const Color(0xFFEF4444);
        break;
      default:
        message = "No matches found";
        icon = Icons.inbox_rounded;
        color = const Color(0xFF64748B);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(String matchId, Map<String, dynamic> matchData) {
    String game = matchData['game'] ?? 'Unknown';
    String mode = matchData['mode'] ?? 'Unknown';
    String map = matchData['map'] ?? 'N/A';
    int amount = matchData['amount'] ?? 0;
    String creatorName = matchData['createdBy']?['userName'] ?? 'Unknown';
    String status = matchData['status'] ?? 'pending';
    List<dynamic> participants = matchData['participants'] ?? [];

    Color gameColor;
    String gameEmoji;
    switch (game) {
      case 'Free Fire':
        gameColor = const Color(0xFFEF4444);
        gameEmoji = '🔥';
        break;
      case 'PUBG':
        gameColor = const Color(0xFFF59E0B);
        gameEmoji = '🎯';
        break;
      case 'eFootball':
        gameColor = const Color(0xFF10B981);
        gameEmoji = '⚽';
        break;
      default:
        gameColor = const Color(0xFF3B82F6);
        gameEmoji = '🎮';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gameColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(gameEmoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game,
                        style: TextStyle(
                          color: gameColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$mode • $map",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: gameColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "$amount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
                    Icon(Icons.person_rounded, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "Created by: ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      creatorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.group_rounded, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "Participants: ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "${participants.length}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),

                // View Details Button
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showMatchDetails(matchId, matchData),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          color: Color(0xFF3B82F6),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "View Full Details",
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveMatch(matchId, matchData),
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text("Approve"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectMatch(matchId, matchData),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: const Text("Reject"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (status != 'pending') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteMatch(matchId),
                      icon: const Icon(Icons.delete_rounded, size: 20),
                      label: const Text("Delete Match"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64748B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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