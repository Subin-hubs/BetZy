import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'Match History page.dart';

const String _emailjsServiceId  = 'service_sl0195o';
const String _emailjsTemplateId = 'template_lqvbopl';
const String _emailjsPublicKey  = 'aUzKKmeS0RI4RymZF';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color primaryColor = const Color(0xFF2962FF);
  final Color accentColor  = const Color(0xFFFF6B35);

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
        final doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        setState(() {
          userData  = doc.exists ? doc.data() as Map<String, dynamic>? : null;
          isLoading = false;
        });
      } catch (_) {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  // ── Edit Profile ─────────────────────────────────────────────────────────

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: userData?['name'] ?? currentUser?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.person, color: primaryColor),
            ),
            const SizedBox(width: 10),
            const Text("Edit Profile"),
          ],
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
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
                    .update({'name': nameController.text.trim()});
                await currentUser!
                    .updateDisplayName(nameController.text.trim());
                await _loadUserData();
                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: "Profile updated successfully!",
                    backgroundColor: Colors.green.shade600,
                  );
                }
              } catch (_) {
                Fluttertoast.showToast(
                  msg: "Error updating profile",
                  backgroundColor: Colors.red.shade600,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Save",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Change Password ───────────────────────────────────────────────────────

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController     = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
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
              controller: currentPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
              if (newPassController.text != confirmPassController.text) {
                Fluttertoast.showToast(
                  msg: "Passwords don't match",
                  backgroundColor: Colors.red.shade600,
                );
                return;
              }
              if (newPassController.text.length < 6) {
                Fluttertoast.showToast(
                  msg: "Password must be at least 6 characters",
                  backgroundColor: Colors.red.shade600,
                );
                return;
              }
              try {
                final credential = EmailAuthProvider.credential(
                  email: currentUser!.email!,
                  password: currentPassController.text,
                );
                await currentUser!
                    .reauthenticateWithCredential(credential);
                await currentUser!
                    .updatePassword(newPassController.text);
                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: "Password changed successfully!",
                    backgroundColor: Colors.green.shade600,
                  );
                }
              } catch (_) {
                Fluttertoast.showToast(
                  msg: "Incorrect current password.",
                  backgroundColor: Colors.red.shade600,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Update",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Match History ─────────────────────────────────────────────────────────

  void _showMatchHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchHistoryPage(userId: currentUser!.uid),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red.shade600),
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
              Navigator.pop(context);
              try {
                await _auth.signOut();
                if (mounted) {
                  Fluttertoast.showToast(
                    msg: "Logged out successfully",
                    backgroundColor: Colors.green.shade600,
                    textColor: Colors.white,
                  );
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (route) => false,
                  );
                }
              } catch (_) {
                Fluttertoast.showToast(
                  msg: "Error logging out. Please try again.",
                  backgroundColor: Colors.red.shade600,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Logout",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Delete Account ────────────────────────────────────────────────────────

  Future<void> _sendDeactivationEmail({
    required String toEmail,
    required String userName,
    required String deletionDate,
    required String userId,
  }) async {
    try {
      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':  _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id':     _emailjsPublicKey,
          'template_params': {
            'to_email':      toEmail,
            'user_name':     userName,
            'deletion_date': deletionDate,
            'user_id':       userId,
          },
        }),
      );
    } catch (e) {
      debugPrint('Email send failed: $e');
    }
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade600),
              const SizedBox(width: 10),
              const Text("Delete Account"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever,
                  size: 70, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text(
                "Are you sure you want to delete your account?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                "Your data will be kept for 10 days. Contact support "
                    "within that time to recover your account.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Enter your password to confirm",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                if (passwordController.text.isEmpty) {
                  Fluttertoast.showToast(
                    msg: "Please enter your password",
                    backgroundColor: Colors.red.shade600,
                  );
                  return;
                }
                setDialogState(() => isProcessing = true);
                try {
                  final credential =
                  EmailAuthProvider.credential(
                    email: currentUser!.email!,
                    password: passwordController.text,
                  );
                  await currentUser!
                      .reauthenticateWithCredential(credential);

                  final deletionDate = DateTime.now()
                      .add(const Duration(days: 10));
                  final formattedDate =
                      "${deletionDate.day}/${deletionDate.month}/${deletionDate.year}";

                  await _firestore
                      .collection('users')
                      .doc(currentUser!.uid)
                      .set({
                    'isDeactivated': true,
                    'deactivatedAt': FieldValue.serverTimestamp(),
                    'scheduledDeletionAt':
                    Timestamp.fromDate(deletionDate),
                    'email': currentUser!.email,
                    'name': userData?['name'] ??
                        currentUser!.displayName ??
                        '',
                  }, SetOptions(merge: true));

                  await _sendDeactivationEmail(
                    toEmail: currentUser!.email!,
                    userName: userData?['name'] ??
                        currentUser!.displayName ??
                        'User',
                    deletionDate: formattedDate,
                    userId: currentUser!.uid,
                  );

                  await _auth.signOut();

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    Fluttertoast.showToast(
                      msg:
                      "Account deactivated. Check your email.",
                      backgroundColor: Colors.orange.shade700,
                      textColor: Colors.white,
                      toastLength: Toast.LENGTH_LONG,
                    );
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                      '/login', (route) => false,
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  setDialogState(() => isProcessing = false);
                  String msg = "Something went wrong.";
                  if (e.code == 'wrong-password' ||
                      e.code == 'invalid-credential') {
                    msg = "Incorrect password. Please try again.";
                  } else if (e.code == 'too-many-requests') {
                    msg = "Too many attempts. Try again later.";
                  }
                  Fluttertoast.showToast(
                    msg: msg,
                    backgroundColor: Colors.red.shade600,
                  );
                } catch (_) {
                  setDialogState(() => isProcessing = false);
                  Fluttertoast.showToast(
                    msg: "Error deactivating account. Try again.",
                    backgroundColor: Colors.red.shade600,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isProcessing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text("Delete Account",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── About Dialog ──────────────────────────────────────────────────────────

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
              "Betzy — Gaming Match Platform",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Version: 1.0.0\n\nCreate and join gaming matches with ease. "
                  "Connect with players and compete!",
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
          child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ──────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color:
                            Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 50, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData?['name'] ??
                        currentUser?.displayName ??
                        'User',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentUser?.email ?? 'No email',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit,
                        size: 16, color: Colors.white),
                    label: const Text("Edit Profile",
                        style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(
                      backgroundColor:
                      Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ── Account ─────────────────────────────────
                  _buildSectionTitle("Account"),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: "Edit Profile",
                      subtitle: "Update your display name",
                      onTap: _showEditProfileDialog,
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      subtitle: "Update your password",
                      onTap: _showChangePasswordDialog,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Activity ─────────────────────────────────
                  _buildSectionTitle("My Activity"),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.history,
                      title: "Match History",
                      subtitle: "View your past matches",
                      onTap: _showMatchHistory,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── About ─────────────────────────────────────
                  _buildSectionTitle("About"),
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: "About Betzy",
                      subtitle: "Version 1.0.0",
                      onTap: _showAboutDialog,
                    ),
                  ]),

                  const SizedBox(height: 30),

                  // ── Logout button ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                          side: BorderSide(
                              color: Colors.red.shade200),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Delete account ────────────────────────────
                  TextButton.icon(
                    onPressed: _showDeleteAccountDialog,
                    icon: Icon(Icons.delete_forever,
                        color: Colors.red.shade600),
                    label: Text(
                      "Delete Account",
                      style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

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
            letterSpacing: 0.5,
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
              offset: const Offset(0, 3)),
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
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
              fontSize: 12, color: Colors.grey.shade500),
        ),
      )
          : null,
      trailing: onTap != null
          ? Icon(Icons.arrow_forward_ios,
          size: 15, color: Colors.grey.shade400)
          : null,
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 0,
        indent: 64,
        endIndent: 16,
        color: Colors.grey.shade200);
  }
}