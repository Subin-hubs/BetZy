import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdmineMore extends StatefulWidget {
  const AdmineMore({super.key});

  @override
  State<AdmineMore> createState() => _AdmineMoreState();
}

class _AdmineMoreState extends State<AdmineMore> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color accentColor = const Color(0xFFFF6584);
  final Color successColor = const Color(0xFF00D9A3);
  final Color warningColor = const Color(0xFFFFA726);

  User? currentUser;
  Map<String, dynamic>? adminData;
  bool isLoading = true;
  int totalUsers = 0;
  int totalMatches = 0;
  int activeMatches = 0;
  int totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _loadDashboardStats();
  }

  Future<void> _loadAdminData() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore
            .collection('admins')
            .doc(currentUser!.uid)
            .get();

        if (adminDoc.exists) {
          setState(() {
            adminData = adminDoc.data() as Map<String, dynamic>?;
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

  Future<void> _loadDashboardStats() async {
    try {
      // Get total users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      // Get total matches
      QuerySnapshot matchesSnapshot = await _firestore.collection('matches').get();

      // Get active matches
      QuerySnapshot activeMatchesSnapshot = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'active')
          .get();

      setState(() {
        totalUsers = usersSnapshot.docs.length;
        totalMatches = matchesSnapshot.docs.length;
        activeMatches = activeMatchesSnapshot.docs.length;
        // Calculate total revenue from matches
        totalRevenue = matchesSnapshot.docs.fold(0, (sum, doc) {
          var data = doc.data() as Map<String, dynamic>;
          return sum + (data['points'] ?? 0) as int;
        });
      });
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: adminData?['name'] ?? currentUser?.displayName ?? '',
    );
    final roleController = TextEditingController(
      text: adminData?['role'] ?? 'Admin',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.admin_panel_settings, color: primaryColor),
            ),
            const SizedBox(width: 10),
            const Text("Edit Admin Profile"),
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
            const SizedBox(height: 16),
            TextField(
              controller: roleController,
              decoration: InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.badge),
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
                await _firestore
                    .collection('admins')
                    .doc(currentUser!.uid)
                    .set({
                  'name': nameController.text.trim(),
                  'role': roleController.text.trim(),
                  'email': currentUser!.email,
                }, SetOptions(merge: true));

                await currentUser!.updateDisplayName(nameController.text.trim());
                await _loadAdminData();

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserManagementPage(),
      ),
    );
  }

  void _navigateToMatchManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchManagementPage(),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.rocket_launch, color: warningColor),
            const SizedBox(width: 10),
            const Text("Coming Soon"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction,
              size: 70,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              "$feature feature is under development",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "We're working hard to bring you this feature!",
              textAlign: TextAlign.center,
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
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: accentColor),
            const SizedBox(width: 10),
            const Text("Logout"),
          ],
        ),
        content: const Text("Are you sure you want to logout from admin panel?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Logout"),
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
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showComingSoonDialog("Notifications"),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
        onRefresh: () async {
          await _loadAdminData();
          await _loadDashboardStats();
        },
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Admin Profile Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar with badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: 55,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: successColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Admin Name
                    Text(
                      adminData?['name'] ??
                          currentUser?.displayName ??
                          'Admin',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Admin Role
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        adminData?['role'] ?? 'Super Admin',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Admin Email
                    Text(
                      currentUser?.email ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dashboard Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildSectionTitle("Dashboard Overview", Icons.dashboard),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Total Users",
                            value: totalUsers.toString(),
                            icon: Icons.people,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: "Active Matches",
                            value: activeMatches.toString(),
                            icon: Icons.sports_esports,
                            color: successColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Total Matches",
                            value: totalMatches.toString(),
                            icon: Icons.history,
                            color: warningColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: "Total Points",
                            value: totalRevenue.toString(),
                            icon: Icons.stars,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Management Section
                    _buildSectionTitle("Management", Icons.settings),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.people_outline,
                        title: "User Management",
                        subtitle: "Manage users and permissions",
                        onTap: _navigateToUserManagement,
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.sports_esports_outlined,
                        title: "Match Management",
                        subtitle: "Monitor and control matches",
                        onTap: _navigateToMatchManagement,
                        color: successColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.receipt_long,
                        title: "Transaction History",
                        subtitle: "View all transactions",
                        onTap: () => _showComingSoonDialog("Transaction History"),
                        color: warningColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.flag_outlined,
                        title: "Reports & Flags",
                        subtitle: "Handle user reports",
                        onTap: () => _showComingSoonDialog("Reports & Flags"),
                        color: accentColor,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Analytics Section
                    _buildSectionTitle("Analytics", Icons.analytics),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.bar_chart,
                        title: "Platform Statistics",
                        subtitle: "Detailed analytics and insights",
                        onTap: () => _showComingSoonDialog("Platform Statistics"),
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.trending_up,
                        title: "Growth Metrics",
                        subtitle: "User and revenue growth",
                        onTap: () => _showComingSoonDialog("Growth Metrics"),
                        color: successColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.insights,
                        title: "User Insights",
                        subtitle: "Behavior and engagement data",
                        onTap: () => _showComingSoonDialog("User Insights"),
                        color: warningColor,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Settings Section
                    _buildSectionTitle("Settings", Icons.settings_outlined),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: "Edit Profile",
                        subtitle: "Update admin information",
                        onTap: _showEditProfileDialog,
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.security,
                        title: "Security Settings",
                        subtitle: "Password and authentication",
                        onTap: () => _showComingSoonDialog("Security Settings"),
                        color: accentColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.tune,
                        title: "Platform Settings",
                        subtitle: "Configure app settings",
                        onTap: () => _showComingSoonDialog("Platform Settings"),
                        color: successColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.backup,
                        title: "Backup & Restore",
                        subtitle: "Data management",
                        onTap: () => _showComingSoonDialog("Backup & Restore"),
                        color: warningColor,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // System Section
                    _buildSectionTitle("System", Icons.computer),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.bug_report_outlined,
                        title: "System Logs",
                        subtitle: "View system activity",
                        onTap: () => _showComingSoonDialog("System Logs"),
                        color: Colors.grey.shade700,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: "App Information",
                        subtitle: "Version and details",
                        onTap: _showAboutDialog,
                        color: Colors.grey.shade700,
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // Logout Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.1),
                            accentColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        icon: const Icon(Icons.logout, size: 22),
                        label: const Text(
                          "Logout from Admin Panel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // App Version
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Admin Panel v1.0.0",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    required Color color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0,
      indent: 76,
      endIndent: 20,
      color: Colors.grey.shade200,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.info_outline, color: primaryColor),
            ),
            const SizedBox(width: 10),
            const Text("About Admin Panel"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Betzy - Admin Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Version:", "1.0.0"),
                  const SizedBox(height: 8),
                  _buildInfoRow("Platform:", "Gaming Match Management"),
                  const SizedBox(height: 8),
                  _buildInfoRow("Access Level:", "Super Admin"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Complete control panel for managing users, matches, and platform operations.",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// User Management Page Placeholder
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text("User Management Page - To be implemented"),
      ),
    );
  }
}

// Match Management Page Placeholder
class MatchManagementPage extends StatelessWidget {
  const MatchManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Management"),
        backgroundColor: const Color(0xFF00D9A3),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text("Match Management Page - To be implemented"),
      ),
    );
  }
}