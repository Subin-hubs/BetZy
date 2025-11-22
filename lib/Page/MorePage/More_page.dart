import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color primaryColor = const Color(0xFF2962FF);
  final Color accentColor = const Color(0xFFFF6B35);

  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>?;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  // Edit Profile Dialog
  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: userData?['name'] ?? currentUser?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: primaryColor),
            const SizedBox(width: 10),
            const Text("Edit Profile"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                Fluttertoast.showToast(
                  msg: "Name cannot be empty",
                  backgroundColor: Colors.red.shade600,
                );
                return;
              }

              try {
                // Update Firestore
                await _firestore
                    .collection('users')
                    .doc(currentUser!.uid)
                    .update({'name': nameController.text.trim()});

                // Update Firebase Auth displayName
                await currentUser!.updateDisplayName(nameController.text.trim());

                // Reload user data
                await _loadUserData();

                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: "Profile updated successfully!",
                    backgroundColor: Colors.green.shade600,
                  );
                }
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Error updating profile",
                  backgroundColor: Colors.red.shade600,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Show Match History
  void _showMatchHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchHistoryPage(
          userId: currentUser!.uid,
        ),
      ),
    );
  }

  // Show Coming Soon Dialog
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.upcoming, color: accentColor),
            const SizedBox(width: 10),
            const Text("Coming Soon"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "$feature feature is under development",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Stay tuned for updates!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _auth.signOut();
                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: "Logged out successfully",
                    backgroundColor: Colors.green.shade600,
                    textColor: Colors.white,
                  );
                }
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Error logging out",
                  backgroundColor: Colors.red.shade600,
                  textColor: Colors.white,
                );
              }
            },
            child: Text(
              "Logout",
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User Name
                  Text(
                    userData?['name'] ??
                        currentUser?.displayName ??
                        'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // User Email
                  Text(
                    currentUser?.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Account Section
                  _buildSectionTitle("Account"),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: "Edit Profile",
                      onTap: _showEditProfileDialog,
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      onTap: () =>
                          _showComingSoonDialog("Change Password"),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: "Notifications",
                      trailing: Switch(
                        value: true,
                        onChanged: (val) {
                          _showComingSoonDialog("Notifications");
                        },
                        activeColor: primaryColor,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // My Matches Section
                  _buildSectionTitle("My Activity"),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.history,
                      title: "Match History",
                      onTap: _showMatchHistory,
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.emoji_events_outlined,
                      title: "My Achievements",
                      onTap: () =>
                          _showComingSoonDialog("My Achievements"),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.leaderboard_outlined,
                      title: "Leaderboard",
                      onTap: () => _showComingSoonDialog("Leaderboard"),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Settings Section
                  _buildSectionTitle("Support"),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: () =>
                          _showComingSoonDialog("Help & Support"),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: "About",
                      onTap: _showAboutDialog,
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: () =>
                          _showComingSoonDialog("Privacy Policy"),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // App Version
                  Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0,
      indent: 72,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: primaryColor),
            const SizedBox(width: 10),
            const Text("About"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Betzy - Gaming Match Platform",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Version: 1.0.0\n\nCreate and join gaming matches with ease. Connect with players and compete!",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

// Match History Page
class MatchHistoryPage extends StatelessWidget {
  final String userId;
  final Color primaryColor = const Color(0xFF2962FF);
  final Color accentColor = const Color(0xFFFF6B35);

  const MatchHistoryPage({super.key, required this.userId});

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
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('createdBy.userId', isEqualTo: userId)
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
                  Icon(Icons.history,
                      size: 80, color: Colors.grey.shade300),
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
                    "Create your first match to get started!",
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

              return _buildMatchHistoryCard(matchData);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchHistoryCard(Map<String, dynamic> matchData) {
    String mode = matchData['mode'] ?? 'Unknown';
    String teamSize = matchData['teamSize'] ?? 'N/A';
    int points = matchData['points'] ?? 0;
    String status = matchData['status'] ?? 'active';

    Color statusColor = status == 'active'
        ? Colors.green
        : status == 'completed'
        ? Colors.blue
        : Colors.red;

    IconData modeIcon = mode == "Clash Squad"
        ? Icons.groups
        : mode == "Lone Wolf"
        ? Icons.person
        : Icons.map;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(modeIcon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (teamSize != 'N/A')
                      Text(
                        teamSize,
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
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
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
                "${matchData['participants']?.length ?? 0} Joined",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}