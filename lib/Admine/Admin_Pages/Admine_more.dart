// PART 1 - Class Definition, State Variables, and Init Methods

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsMore extends StatefulWidget {
  const SettingsMore({super.key});

  @override
  State<SettingsMore> createState() => _SettingsMoreState();
}

class _SettingsMoreState extends State<SettingsMore> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color accentColor = const Color(0xFFFF6584);
  final Color successColor = const Color(0xFF00D9A3);
  final Color warningColor = const Color(0xFFFFA726);

  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot settingsDoc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('settings')
            .doc('preferences')
            .get();

        if (settingsDoc.exists) {
          var settings = settingsDoc.data() as Map<String, dynamic>;
          setState(() {
            notificationsEnabled = settings['notifications'] ?? true;
            darkModeEnabled = settings['darkMode'] ?? false;
            soundEnabled = settings['sound'] ?? true;
            vibrationEnabled = settings['vibration'] ?? true;
          });
        }
      } catch (e) {
        print("Error loading settings: $e");
      }
    }
  }

  Future<void> _saveSettings() async {
    if (currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('settings')
            .doc('preferences')
            .set({
          'notifications': notificationsEnabled,
          'darkMode': darkModeEnabled,
          'sound': soundEnabled,
          'vibration': vibrationEnabled,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving settings: $e");
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: userData?['name'] ?? currentUser?.displayName ?? '',
    );
    final phoneController = TextEditingController(
      text: userData?['phone'] ?? '',
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
              child: Icon(Icons.person, color: primaryColor),
            ),
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
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
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
                    .collection('users')
                    .doc(currentUser!.uid)
                    .set({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'email': currentUser!.email,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                await currentUser!.updateDisplayName(nameController.text.trim());
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

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

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
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock, color: accentColor),
            ),
            const SizedBox(width: 10),
            const Text("Change Password"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
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
              if (newPasswordController.text != confirmPasswordController.text) {
                Fluttertoast.showToast(
                  msg: "Passwords don't match",
                  backgroundColor: Colors.red.shade600,
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                Fluttertoast.showToast(
                  msg: "Password must be at least 6 characters",
                  backgroundColor: Colors.red.shade600,
                );
                return;
              }

              try {
                // Re-authenticate user
                AuthCredential credential = EmailAuthProvider.credential(
                  email: currentUser!.email!,
                  password: currentPasswordController.text,
                );
                await currentUser!.reauthenticateWithCredential(credential);

                // Update password
                await currentUser!.updatePassword(newPasswordController.text);

                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: "Password changed successfully!",
                    backgroundColor: Colors.green.shade600,
                  );
                }
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Error changing password. Check current password.",
                  backgroundColor: Colors.red.shade600,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Change Password"),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 10),
            const Text("Delete Account"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_forever,
              size: 70,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 20),
            const Text(
              "Are you sure you want to delete your account?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "This action cannot be undone. All your data will be permanently deleted.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
              try {
                // Delete user data from Firestore
                await _firestore.collection('users').doc(currentUser!.uid).delete();

                // Delete user account
                await currentUser!.delete();

                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: "Account deleted successfully",
                    backgroundColor: Colors.green.shade600,
                  );
                }
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Error deleting account",
                  backgroundColor: Colors.red.shade600,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Delete Account"),
          ),
        ],
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
        content: const Text("Are you sure you want to logout?"),
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

// PART 2 - Build Method and UI Widgets

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _loadSettings();
        },
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
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
                    const SizedBox(height: 30),
                    // Avatar
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
                    const SizedBox(height: 8),
                    // Edit Profile Button
                    TextButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                      label: const Text(
                        "Edit Profile",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Settings Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // App Preferences
                    _buildSectionTitle("App Preferences", Icons.tune),
                    _buildMenuCard([
                      _buildSwitchTile(
                        icon: Icons.notifications_outlined,
                        title: "Notifications",
                        subtitle: "Receive push notifications",
                        value: notificationsEnabled,
                        onChanged: (value) {
                          setState(() => notificationsEnabled = value);
                          _saveSettings();
                        },
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        title: "Dark Mode",
                        subtitle: "Enable dark theme",
                        value: darkModeEnabled,
                        onChanged: (value) {
                          setState(() => darkModeEnabled = value);
                          _saveSettings();
                        },
                        color: Colors.grey.shade700,
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.volume_up_outlined,
                        title: "Sound Effects",
                        subtitle: "Enable sound effects",
                        value: soundEnabled,
                        onChanged: (value) {
                          setState(() => soundEnabled = value);
                          _saveSettings();
                        },
                        color: successColor,
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.vibration,
                        title: "Vibration",
                        subtitle: "Enable vibration feedback",
                        value: vibrationEnabled,
                        onChanged: (value) {
                          setState(() => vibrationEnabled = value);
                          _saveSettings();
                        },
                        color: warningColor,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Account Settings
                    _buildSectionTitle("Account", Icons.account_circle_outlined),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: "Edit Profile",
                        subtitle: "Update your personal information",
                        onTap: _showEditProfileDialog,
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: "Change Password",
                        subtitle: "Update your password",
                        onTap: _showChangePasswordDialog,
                        color: accentColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.email_outlined,
                        title: "Email Preferences",
                        subtitle: "Manage email notifications",
                        onTap: () => _showComingSoonDialog("Email Preferences"),
                        color: successColor,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Privacy & Security
                    _buildSectionTitle("Privacy & Security", Icons.security),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: "Privacy Policy",
                        subtitle: "Read our privacy policy",
                        onTap: () => _showComingSoonDialog("Privacy Policy"),
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.shield_outlined,
                        title: "Security Settings",
                        subtitle: "Two-factor authentication",
                        onTap: () => _showComingSoonDialog("Security Settings"),
                        color: successColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.block,
                        title: "Blocked Users",
                        subtitle: "Manage blocked accounts",
                        onTap: () => _showComingSoonDialog("Blocked Users"),
                        color: Colors.red.shade600,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Support & Help
                    _buildSectionTitle("Support & Help", Icons.help_outline),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.contact_support_outlined,
                        title: "Help Center",
                        subtitle: "Get help and support",
                        onTap: () => _showComingSoonDialog("Help Center"),
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.feedback_outlined,
                        title: "Send Feedback",
                        subtitle: "Share your thoughts",
                        onTap: () => _showComingSoonDialog("Send Feedback"),
                        color: warningColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.bug_report_outlined,
                        title: "Report a Problem",
                        subtitle: "Report bugs and issues",
                        onTap: () => _showComingSoonDialog("Report a Problem"),
                        color: accentColor,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // About
                    _buildSectionTitle("About", Icons.info_outline),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: "Terms of Service",
                        subtitle: "Read our terms",
                        onTap: () => _showComingSoonDialog("Terms of Service"),
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.star_outline,
                        title: "Rate App",
                        subtitle: "Rate us on the store",
                        onTap: () => _showComingSoonDialog("Rate App"),
                        color: warningColor,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.info,
                        title: "App Version",
                        subtitle: "v1.0.0",
                        onTap: null,
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
                          "Logout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Delete Account Button
                    TextButton.icon(
                      onPressed: _showDeleteAccountDialog,
                      icon: Icon(Icons.delete_forever, color: Colors.red.shade600),
                      label: Text(
                        "Delete Account",
                        style: TextStyle(
                          color: Colors.red.shade600,
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

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
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
      trailing: onTap != null
          ? Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      )
          : null,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return ListTile(
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: color,
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
}