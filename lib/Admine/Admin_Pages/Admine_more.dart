import 'dart:convert';
import 'package:betting_app/Page/Auth/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

const String _emailjsServiceId  = 'service_sl0195o';
const String _emailjsTemplateId = 'template_lqvbopl';
const String _emailjsPublicKey  = 'aUzKKmeS0RI4RymZF';

class SettingsMore extends StatefulWidget {
  const SettingsMore({super.key});

  @override
  State<SettingsMore> createState() => _SettingsMoreState();
}

class _SettingsMoreState extends State<SettingsMore> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color primaryColor   = const Color(0xFF6C63FF);
  final Color accentColor    = const Color(0xFFFF6584);
  final Color successColor   = const Color(0xFF00D9A3);
  final Color warningColor   = const Color(0xFFFFA726);

  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  bool notificationsEnabled = true;
  bool soundEnabled         = true;
  bool vibrationEnabled     = true;

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

  Future<void> _loadSettings() async {
    if (currentUser == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('settings')
          .doc('preferences')
          .get();
      if (doc.exists) {
        final s = doc.data() as Map<String, dynamic>;
        setState(() {
          notificationsEnabled = s['notifications'] ?? true;
          soundEnabled         = s['sound']         ?? true;
          vibrationEnabled     = s['vibration']     ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('settings')
          .doc('preferences')
          .set({
        'notifications': notificationsEnabled,
        'sound':         soundEnabled,
        'vibration':     vibrationEnabled,
        'updatedAt':     FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

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
            'to_email':     toEmail,
            'user_name':    userName,
            'deletion_date': deletionDate,
            'user_id':      userId,
          },
        }),
      );
    } catch (e) {
      debugPrint('Email send failed: $e');
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              Navigator.pop(context);
              try {
                await _auth.signOut();
                if (mounted) {
                  Fluttertoast.showToast(
                    msg: "Logged out successfully",
                    backgroundColor: Colors.green.shade600,
                    textColor: Colors.white,
                  );
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                }
              } catch (_) {
                Fluttertoast.showToast(
                  msg: "Error logging out. Please try again.",
                  backgroundColor: Colors.red.shade600,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
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

  // ── Delete / Deactivate account ──────────────────────────────────────────

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

                  final deletionDate =
                  DateTime.now().add(const Duration(days: 10));
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
                      msg: "Account deactivated. Check your email.",
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

  // ── Edit Profile ─────────────────────────────────────────────────────────

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
        text: userData?['name'] ?? currentUser?.displayName ?? '');
    final phoneController =
    TextEditingController(text: userData?['phone'] ?? '');

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                Fluttertoast.showToast(
                    msg: "Name cannot be empty",
                    backgroundColor: Colors.red.shade600);
                return;
              }
              try {
                await _firestore
                    .collection('users')
                    .doc(currentUser!.uid)
                    .set({
                  'name':      nameController.text.trim(),
                  'phone':     phoneController.text.trim(),
                  'email':     currentUser!.email,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
                await currentUser!
                    .updateDisplayName(nameController.text.trim());
                await _loadUserData();
                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                      msg: "Profile updated successfully!",
                      backgroundColor: Colors.green.shade600);
                }
              } catch (_) {
                Fluttertoast.showToast(
                    msg: "Error updating profile",
                    backgroundColor: Colors.red.shade600);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text("Save",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Change Password ───────────────────────────────────────────────────────

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController     = TextEditingController();
    final confirmPasswordController = TextEditingController();

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
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                    borderRadius: BorderRadius.circular(12)),
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
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                Fluttertoast.showToast(
                    msg: "Passwords don't match",
                    backgroundColor: Colors.red.shade600);
                return;
              }
              if (newPasswordController.text.length < 6) {
                Fluttertoast.showToast(
                    msg: "Password must be at least 6 characters",
                    backgroundColor: Colors.red.shade600);
                return;
              }
              try {
                final credential = EmailAuthProvider.credential(
                    email: currentUser!.email!,
                    password: currentPasswordController.text);
                await currentUser!
                    .reauthenticateWithCredential(credential);
                await currentUser!
                    .updatePassword(newPasswordController.text);
                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                      msg: "Password changed successfully!",
                      backgroundColor: Colors.green.shade600);
                }
              } catch (_) {
                Fluttertoast.showToast(
                    msg: "Incorrect current password.",
                    backgroundColor: Colors.red.shade600);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text("Change Password",
                style: TextStyle(color: Colors.white)),
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
        title: const Text("Settings",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
          child: CircularProgressIndicator(color: primaryColor))
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
              // ── Profile Header ──────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
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
                          size: 18, color: Colors.white),
                      label: const Text("Edit Profile",
                          style:
                          TextStyle(color: Colors.white)),
                      style: TextButton.styleFrom(
                        backgroundColor:
                        Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // ── Preferences ──────────────────────────────
                    _buildSectionTitle(
                        "Preferences", Icons.tune),
                    _buildMenuCard([
                      _buildSwitchTile(
                        icon: Icons.notifications_outlined,
                        title: "Notifications",
                        subtitle: "Receive push notifications",
                        value: notificationsEnabled,
                        onChanged: (v) {
                          setState(
                                  () => notificationsEnabled = v);
                          _saveSettings();
                        },
                        color: primaryColor,
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.volume_up_outlined,
                        title: "Sound Effects",
                        subtitle: "Enable in-app sounds",
                        value: soundEnabled,
                        onChanged: (v) {
                          setState(() => soundEnabled = v);
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
                        onChanged: (v) {
                          setState(() => vibrationEnabled = v);
                          _saveSettings();
                        },
                        color: warningColor,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Account ───────────────────────────────────
                    _buildSectionTitle(
                        "Account", Icons.account_circle_outlined),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: "Edit Profile",
                        subtitle: "Update your name and phone",
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
                    ]),

                    const SizedBox(height: 20),

                    // ── About ─────────────────────────────────────
                    _buildSectionTitle(
                        "About", Icons.info_outline),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.info,
                        title: "App Version",
                        subtitle: "v1.0.0",
                        onTap: null,
                        color: Colors.grey.shade600,
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // ── Logout button ─────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          accentColor.withOpacity(0.1),
                          accentColor.withOpacity(0.05),
                        ]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: accentColor.withOpacity(0.3)),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        icon: const Icon(Icons.logout, size: 22),
                        label: const Text("Logout",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Delete account ────────────────────────────
                    TextButton.icon(
                      onPressed: _showDeleteAccountDialog,
                      icon: Icon(Icons.delete_forever,
                          color: Colors.red.shade600),
                      label: Text("Delete Account",
                          style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600)),
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

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800)),
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
              offset: const Offset(0, 4))
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
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600)),
      )
          : null,
      trailing: onTap != null
          ? Icon(Icons.arrow_forward_ios,
          size: 16, color: Colors.grey.shade400)
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
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600)),
      )
          : null,
      trailing:
      Switch(value: value, onChanged: onChanged, activeColor: color),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 0,
        indent: 76,
        endIndent: 20,
        color: Colors.grey.shade200);
  }
}