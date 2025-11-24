import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:betting_app/services/match_result_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _animationController;
  String _selectedGame = 'All';

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

  Future<void> _joinMatch(String matchId, Map<String, dynamic> matchData) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      _showCustomToast("Please login to join a match", const Color(0xFFEF4444));
      return;
    }

    if (matchData['createdBy']['userId'] == currentUser.uid) {
      _showCustomToast("You cannot join your own match", const Color(0xFFF59E0B));
      return;
    }

    // Check if user has enough points
    final handler = MatchResultHandler();
    int requiredPoints = matchData['points'] ?? 0;

    bool canJoin = await handler.canJoinMatch(currentUser.uid, requiredPoints);

    if (!canJoin) {
      _showCustomToast("Insufficient points! You need $requiredPoints points", const Color(0xFFEF4444));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFF3B82F6),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                "Joining match...",
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Hold points in escrow
      await handler.holdPointsForMatch(
        userId: currentUser.uid,
        points: requiredPoints,
        matchId: matchId,
      );

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

      Navigator.pop(context);
      _showCustomToast("🎮 Joined! $requiredPoints points deducted", const Color(0xFF10B981));
    } catch (e) {
      Navigator.pop(context);
      _showCustomToast("Error: ${e.toString()}", const Color(0xFFEF4444));
    }
  }

  void _showCustomToast(String message, Color color) {
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "Active Matches",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xFF1F2937),
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -60,
                      top: -60,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      bottom: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: 40,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Game Filter chips
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Select Game",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildGameChip('All', '🎮', Colors.blue),
                        _buildGameChip('Free Fire', '🔥', const Color(0xFFEF4444)),
                        _buildGameChip('PUBG', '🎯', const Color(0xFFF59E0B)),
                        _buildGameChip('eFootball', '⚽', const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Matches list
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('matches')
                .where('status', isEqualTo: 'active')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: const Color(0xFF3B82F6),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Loading matches...",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _buildEmptyState(
                    Icons.error_outline_rounded,
                    "Error loading matches",
                    "Please try again later",
                    const Color(0xFFEF4444),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(
                    Icons.sports_esports_rounded,
                    "No active matches",
                    "Be the first to create a match!",
                    const Color(0xFF3B82F6),
                  ),
                );
              }

              var filteredDocs = snapshot.data!.docs.where((doc) {
                if (_selectedGame == 'All') return true;
                var data = doc.data() as Map<String, dynamic>;
                return data['game'] == _selectedGame;
              }).toList();

              if (filteredDocs.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(
                    Icons.filter_alt_off_rounded,
                    "No matches found",
                    "Try selecting a different game",
                    const Color(0xFF3B82F6),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var doc = filteredDocs[index];
                      var matchData = doc.data() as Map<String, dynamic>;
                      String matchId = doc.id;

                      return FadeTransition(
                        opacity: _animationController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: _buildMatchCard(matchId, matchData),
                        ),
                      );
                    },
                    childCount: filteredDocs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameChip(String label, String emoji, Color color) {
    bool isSelected = _selectedGame == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedGame = label;
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE2E8F0),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(icon, size: 70, color: color),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
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
    int points = matchData['points'] ?? 0;
    String creatorName = matchData['createdBy']?['userName'] ?? 'Unknown';
    String gunAttributes = matchData['gunAttributes'] ?? 'No';
    String unlimitedItems = matchData['unlimitedItems'] ?? 'No';
    String characterSkills = matchData['characterSkills'] ?? 'No';
    List participants = matchData['participants'] ?? [];

    // Game specific colors and emojis
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gameColor,
                  gameColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        gameEmoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  mode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (map != 'N/A')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.map_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        map,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: gameColor,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$points",
                            style: TextStyle(
                              color: gameColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (participants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.group_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${participants.length} ${participants.length == 1 ? 'player' : 'players'} joined",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Host info
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [gameColor, gameColor.withOpacity(0.7)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Match Host",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              creatorName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
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
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "ACTIVE",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Match Settings
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Match Settings",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSettingRow(
                        "Gun Attributes",
                        gunAttributes,
                        Icons.gps_fixed_rounded,
                        gunAttributes == "Yes",
                      ),
                      Divider(
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                        indent: 16,
                        endIndent: 16,
                      ),
                      _buildSettingRow(
                        "Unlimited Items",
                        unlimitedItems,
                        Icons.inventory_2_rounded,
                        unlimitedItems == "Yes",
                      ),
                      Divider(
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                        indent: 16,
                        endIndent: 16,
                      ),
                      _buildSettingRow(
                        "Character Skills",
                        characterSkills,
                        Icons.auto_awesome_rounded,
                        characterSkills == "Yes",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Join button
                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gameColor, gameColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: gameColor.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _joinMatch(matchId, matchData),
                      borderRadius: BorderRadius.circular(18),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.sports_esports_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Join Match",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSettingRow(String label, String value, IconData icon, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isEnabled ? const Color(0xFF10B981) : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : const Color(0xFFEF4444).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEnabled
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : const Color(0xFFEF4444).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}