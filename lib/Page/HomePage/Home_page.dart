import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedGame = 'All';
  String _searchQuery = '';
  bool _isJoining = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getMaxPlayers(String teamSize) {
    if (teamSize.contains('v')) {
      List<String> parts = teamSize.split('v');
      if (parts.length == 2) {
        int teamsCount = int.tryParse(parts[0]) ?? 0;
        return teamsCount * 2;
      }
    }
    switch (teamSize.toLowerCase()) {
      case 'solo': return 1;
      case 'duo': return 2;
      case 'squad': return 4;
      default: return 0;
    }
  }

  Future<void> _joinMatch(String matchId, Map<String, dynamic> matchData) async {
    if (_isJoining) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showToast("❌ Please login first", Colors.red);
      return;
    }

    // Quick pre-checks
    List participants = matchData['participants'] ?? [];
    if (participants.any((p) => p['userId'] == currentUser.uid)) {
      _showToast("⚠️ You already joined this match", Colors.orange);
      return;
    }

    String teamSize = matchData['teamSize'] ?? '';
    int maxPlayers = _getMaxPlayers(teamSize);
    if (maxPlayers > 0 && participants.length >= maxPlayers) {
      _showToast("⚠️ Match is full", Colors.orange);
      return;
    }

    // Check for 2v2
    if (teamSize == '2v2') {
      _show2v2Dialog(matchId, matchData);
    } else {
      await _processJoinMatch(matchId, matchData, null, null);
    }
  }

  Future<void> _processJoinMatch(String matchId, Map<String, dynamic> matchData,
      String? yourGameId, String? friendGameId) async {

    if (_isJoining) return;
    setState(() => _isJoining = true);

    final currentUser = _auth.currentUser!;
    int requiredPoints = matchData['points'] ?? 0;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Joining match...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Step 1: Check user balance first
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception("User account not found");
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final double currentBalance = (userData['points'] ?? 0).toDouble();

      if (currentBalance < requiredPoints) {
        throw Exception("Insufficient points. You need $requiredPoints points");
      }

      // Step 2: Get fresh match data
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();

      if (!matchDoc.exists) {
        throw Exception("Match not found");
      }

      final freshMatchData = matchDoc.data() as Map<String, dynamic>;

      // Validate match status
      if (freshMatchData['status'] != 'active') {
        throw Exception("Match is no longer active");
      }

      List currentParticipants = List.from(freshMatchData['participants'] ?? []);

      // Check if already joined
      if (currentParticipants.any((p) => p['userId'] == currentUser.uid)) {
        throw Exception("You already joined");
      }

      // Check if full
      String teamSize = freshMatchData['teamSize'] ?? '';
      int maxPlayers = _getMaxPlayers(teamSize);
      if (maxPlayers > 0 && currentParticipants.length >= maxPlayers) {
        throw Exception("Match is full");
      }

      // Step 3: Create participant entry
      Map<String, dynamic> participant = {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'email': currentUser.email ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
        'pointsPaid': requiredPoints,
      };

      if (yourGameId != null) participant['yourGameId'] = yourGameId;
      if (friendGameId != null) participant['friendGameId'] = friendGameId;

      currentParticipants.add(participant);

      // Step 4: Update match with WriteBatch for atomicity
      final batch = _firestore.batch();

      // Update match
      Map<String, dynamic> matchUpdate = {
        'participants': currentParticipants,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (maxPlayers > 0 && currentParticipants.length >= maxPlayers) {
        matchUpdate['status'] = 'full';
      }

      batch.update(_firestore.collection('matches').doc(matchId), matchUpdate);

      // Deduct points from user
      batch.update(
        _firestore.collection('users').doc(currentUser.uid),
        {
          'points': FieldValue.increment(-requiredPoints),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Commit batch
      await batch.commit();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showToast("✅ Successfully joined the match!", Colors.green);
        setState(() {});
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      String errorMessage = e.toString();
      print("❌ Join match error: $errorMessage");

      if (errorMessage.contains("Insufficient")) {
        _showToast("❌ Insufficient points", Colors.red);
      } else if (errorMessage.contains("already joined")) {
        _showToast("⚠️ You already joined this match", Colors.orange);
      } else if (errorMessage.contains("full")) {
        _showToast("⚠️ Match is full", Colors.orange);
      } else if (errorMessage.contains("not found")) {
        _showToast("❌ Match or user not found", Colors.red);
      } else if (errorMessage.contains("no longer active")) {
        _showToast("⚠️ Match is no longer active", Colors.orange);
      } else {
        _showToast("❌ Failed to join match. Please try again.", Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _show2v2Dialog(String matchId, Map<String, dynamic> matchData) {
    final yourGameIdController = TextEditingController();
    final friendGameIdController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, color: Color(0xFF3B82F6), size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('2v2 Team Setup',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter both team members\' game IDs to continue',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: yourGameIdController,
                  decoration: InputDecoration(
                    labelText: 'Your Game ID',
                    hintText: 'Enter your in-game ID',
                    prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF3B82F6)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (val) => val?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: friendGameIdController,
                  decoration: InputDecoration(
                    labelText: "Friend's Game ID",
                    hintText: "Your teammate's in-game ID",
                    prefixIcon: const Icon(Icons.group_rounded, color: Color(0xFF3B82F6)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (val) => val?.trim().isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                _processJoinMatch(
                  matchId,
                  matchData,
                  yourGameIdController.text.trim(),
                  friendGameIdController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Join Match', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 14,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSearchBar(),
          _buildGameFilter(),
          _buildMatchList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1E293B),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          "🎮 Live Matches",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -100,
              top: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by host username...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 24),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameFilter() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 22, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  "Filter Games",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildGameChip('All', '🎮', const Color(0xFF6366F1)),
                _buildGameChip('Free Fire', '🔥', const Color(0xFFEF4444)),
                _buildGameChip('PUBG', '🎯', const Color(0xFFF59E0B)),
                _buildGameChip('eFootball', '⚽', const Color(0xFF10B981)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGameChip(String label, String emoji, Color color) {
    bool isSelected = _selectedGame == label;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedGame = label),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('matches')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: const Color(0xFF6366F1),
                    strokeWidth: 4,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading matches...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                  const SizedBox(height: 20),
                  const Text(
                    'Error loading matches',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      size: 80,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Active Matches',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to create one!',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          bool gameMatch = _selectedGame == 'All' || data['game'] == _selectedGame;
          bool searchMatch = _searchQuery.isEmpty ||
              (data['createdBy']?['userName'] ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
          return gameMatch && searchMatch;
        }).toList();

        if (filteredDocs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text(
                    'No Matches Found',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different filter or search',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                var doc = filteredDocs[index];
                var matchData = doc.data() as Map<String, dynamic>;
                return _buildMatchCard(doc.id, matchData);
              },
              childCount: filteredDocs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(String matchId, Map<String, dynamic> matchData) {
    String game = matchData['game'] ?? 'Unknown';
    String mode = matchData['mode'] ?? 'Unknown';
    String map = matchData['map'] ?? 'N/A';
    String teamSize = matchData['teamSize'] ?? '';
    int points = matchData['points'] ?? 0;
    String creatorName = matchData['createdBy']?['userName'] ?? 'Unknown';
    List participants = matchData['participants'] ?? [];

    int maxPlayers = _getMaxPlayers(teamSize);
    bool isFull = maxPlayers > 0 && participants.length >= maxPlayers;

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
        gameColor = const Color(0xFF6366F1);
        gameEmoji = '🎮';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gameColor, gameColor.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(gameEmoji, style: const TextStyle(fontSize: 32)),
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(Icons.gamepad_rounded, mode),
                              if (map != 'N/A') _buildInfoChip(Icons.map_rounded, map),
                              if (teamSize.isNotEmpty) _buildInfoChip(Icons.people_rounded, teamSize),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.stars_rounded, color: gameColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "$points",
                            style: TextStyle(
                              color: gameColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "pts",
                            style: TextStyle(
                              color: gameColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (participants.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.group_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              maxPlayers > 0
                                  ? "${participants.length}/$maxPlayers"
                                  : "${participants.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Host info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match Host',
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Join button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isFull || _isJoining ? null : () => _joinMatch(matchId, matchData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull ? Colors.grey.shade300 : gameColor,
                      foregroundColor: isFull ? Colors.grey.shade600 : Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: isFull ? 0 : 8,
                      shadowColor: gameColor.withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFull ? Icons.block : Icons.sports_esports_rounded,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isFull ? 'Match Full' : (_isJoining ? 'Joining...' : 'Join Match'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}