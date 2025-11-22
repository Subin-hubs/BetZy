import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Home_page extends StatefulWidget {
  const Home_page({super.key});

  @override
  State<Home_page> createState() => _Home_pageState();
}

class _Home_pageState extends State<Home_page> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Color primaryColor = const Color(0xFF2962FF);
  final Color accentColor = const Color(0xFFFF6B35);

  Future<void> _joinMatch(String matchId, Map<String, dynamic> matchData) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      Fluttertoast.showToast(
        msg: "Please login to join a match",
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
      return;
    }

    // Check if user is trying to join their own match
    if (matchData['createdBy']['userId'] == currentUser.uid) {
      Fluttertoast.showToast(
        msg: "You cannot join your own match",
        backgroundColor: Colors.orange.shade600,
        textColor: Colors.white,
      );
      return;
    }

    try {
      // Add user to match participants
      await _firestore.collection('matches').doc(matchId).update({
        'participants': FieldValue.arrayUnion([
          {
            'userId': currentUser.uid,
            'userName': currentUser.displayName ?? 'Unknown',
            'joinedAt': FieldValue.serverTimestamp(),
          }
        ])
      });

      Fluttertoast.showToast(
        msg: "🎮 Successfully joined the match!",
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error joining match: ${e.toString()}",
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Active Matches",
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
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
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
                  Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading matches",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_esports_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No active matches yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create a match to get started!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var matchData = doc.data() as Map<String, dynamic>;
              String matchId = doc.id;

              return _buildMatchCard(matchId, matchData);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(String matchId, Map<String, dynamic> matchData) {
    String mode = matchData['mode'] ?? 'Unknown';
    String teamSize = matchData['teamSize'] ?? 'N/A';
    int points = matchData['points'] ?? 0;
    String creatorName = matchData['createdBy']?['userName'] ?? 'Unknown';
    String gunAttributes = matchData['gunAttributes'] ?? 'No';
    String unlimitedItems = matchData['unlimitedItems'] ?? 'No';
    String characterSkills = matchData['characterSkills'] ?? 'No';

    // Get mode icon
    IconData modeIcon = mode == "Clash Squad"
        ? Icons.groups
        : mode == "Lone Wolf"
        ? Icons.person
        : Icons.map;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with mode and points
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(modeIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (teamSize != 'N/A')
                        Text(
                          teamSize,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$points",
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

          // Match details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Creator info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Created by",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            creatorName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Match settings
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingRow(
                        "Gun Attributes",
                        gunAttributes,
                        Icons.gps_fixed,
                        gunAttributes == "Yes" ? Colors.green : Colors.red,
                      ),
                      const Divider(height: 16),
                      _buildSettingRow(
                        "Unlimited Items",
                        unlimitedItems,
                        Icons.inventory_2_outlined,
                        unlimitedItems == "Yes" ? Colors.green : Colors.red,
                      ),
                      const Divider(height: 16),
                      _buildSettingRow(
                        "Character Skills",
                        characterSkills,
                        Icons.auto_awesome,
                        characterSkills == "Yes" ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Join button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _joinMatch(matchId, matchData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Join Match",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}