import 'package:betting_app/Page/Auth/SignupPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Admine/admin_navbar.dart';
import '../Navbar_page.dart';

// ─── Custom Exception ────────────────────────────────────────────────────────

class DeactivatedAccountException implements Exception {
  final String message;
  const DeactivatedAccountException(this.message);

  @override
  String toString() => message;
}

// ─── Helpers (top-level) ─────────────────────────────────────────────────────

Future<bool> checkDeactivatedAccount(User user) async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  try {
    final doc = await firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) return true; // no data — let them in

    final data = doc.data() as Map<String, dynamic>;
    final isDeactivated = data['isDeactivated'] ?? false;

    if (!isDeactivated) return true; // normal account — let them in

    // Account is deactivated — check if 10-day window has passed
    final Timestamp? scheduledDeletionAt = data['scheduledDeletionAt'];
    final now = DateTime.now();

    if (scheduledDeletionAt != null &&
        now.isAfter(scheduledDeletionAt.toDate())) {
      // 10 days passed: permanently delete everything
      await _permanentlyDeleteAccount(user, firestore, auth);
      return false; // block login (account no longer exists)
    } else {
      // Still within recovery window: block login
      await auth.signOut();

      final deletionDate = scheduledDeletionAt?.toDate();
      final formattedDate = deletionDate != null
          ? "${deletionDate.day}/${deletionDate.month}/${deletionDate.year}"
          : "soon";

      throw DeactivatedAccountException(
        "Your account is deactivated. Data will be deleted on $formattedDate. "
            "Contact support@yourapp.com to recover it.",
      );
    }
  } catch (e) {
    if (e is DeactivatedAccountException) rethrow;
    return true; // On unexpected error, let them through
  }
}

Future<void> _permanentlyDeleteAccount(
    User user,
    FirebaseFirestore firestore,
    FirebaseAuth auth,
    ) async {
  final uid = user.uid;

  try {
    // 1. Delete settings sub-collection
    final settingsSnap = await firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .get();
    for (final doc in settingsSnap.docs) {
      await doc.reference.delete();
    }

    // 2. Delete main user document
    await firestore.collection('users').doc(uid).delete();

    // 3. Delete Firebase Auth account
    await user.delete();
  } catch (e) {
    debugPrint('Error during permanent deletion: $e');
  }
}

// ─── LoginPage ───────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final Color primaryColor = const Color(0xFF2962FF);

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Save login time to SharedPreferences
  Future<void> _saveLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('login_time', currentTime);
  }

  // Check if email is admin
  bool _isAdminEmail(String email) {
    return email.trim().toLowerCase().endsWith('@admin.com');
  }

  // Check if user is banned
  Future<bool> _isUserBanned(String uid) async {
    try {
      final userDoc =
      await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.get('isBanned') ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _showBannedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            const Text(
              'Account Banned',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your account has been banned by the administrator.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Please contact the admin of this app for more information.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _auth.signOut();
            },
            child: Text(
              'OK',
              style: TextStyle(
                  color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.pending_actions,
                color: Colors.orange, size: 30),
            const SizedBox(width: 10),
            const Text(
              'Approval Pending',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your admin access request is still pending approval.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait for an existing admin to approve your request. '
                  'You will be notified once approved.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _auth.signOut();
            },
            child: Text(
              'OK',
              style: TextStyle(
                  color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminRejectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            const Text(
              'Request Rejected',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your admin access request has been rejected.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Please contact the administrator for more information.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _auth.signOut();
            },
            child: Text(
              'OK',
              style: TextStyle(
                  color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeactivatedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.pause_circle_outline,
                color: Colors.orange, size: 30),
            const SizedBox(width: 10),
            const Text(
              'Account Deactivated',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                  color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Core Login Logic ──────────────────────────────────────────────────────

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // 1. Authenticate with Firebase
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = userCredential.user!;
      final String userId = user.uid;
      final String userName = user.displayName ?? 'User';

      if (!mounted) return;

      // 2. Admin path
      if (_isAdminEmail(email)) {
        final adminUserDoc =
        await _firestore.collection('admin_users').doc(userId).get();
        final adminDoc =
        await _firestore.collection('admins').doc(userId).get();

        if (adminUserDoc.exists || adminDoc.exists) {
          // Approved admin
          await _firestore.collection('admin_users').doc(userId).set({
            'name': userName,
            'email': email,
            'loginTime': FieldValue.serverTimestamp(),
            'lastLogin': DateTime.now().toString(),
          }, SetOptions(merge: true));

          if (!adminDoc.exists) {
            await _firestore.collection('admins').doc(userId).set({
              'name': userName,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
              'uid': userId,
            });
          }

          await _saveLoginTime();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin Login Successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdmineMain(0, true),
            ),
          );
        } else {
          // Not yet approved — check request
          final requestDoc = await _firestore
              .collection('admin_requests')
              .doc(userId)
              .get();

          await _auth.signOut();

          if (requestDoc.exists) {
            final status = requestDoc.get('status') ?? 'pending';
            if (status == 'rejected') {
              _showAdminRejectedDialog();
            } else {
              _showAdminPendingDialog();
            }
          } else {
            _showAdminPendingDialog();
          }

          setState(() => _isLoading = false);
          return;
        }

        // ── Regular user path ──────────────────────────────────────────
      } else {
        // 3. Check deactivated / scheduled for deletion
        bool allowed;
        try {
          allowed = await checkDeactivatedAccount(user);
        } on DeactivatedAccountException catch (e) {
          if (mounted) _showDeactivatedDialog(e.message);
          setState(() => _isLoading = false);
          return;
        }

        if (!allowed) {
          // Account was past 10-day window and has been permanently deleted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This account no longer exists.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // 4. Check if banned
        final bool isBanned = await _isUserBanned(userId);
        if (isBanned) {
          await _auth.signOut();
          if (mounted) _showBannedDialog();
          setState(() => _isLoading = false);
          return;
        }

        // 5. All clear — update last login and proceed
        await _firestore.collection('users').doc(userId).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        await _saveLoginTime();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('Login Successful! Session valid for 24 hours.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Mainpage(0, true),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reset Password
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(
          email: _emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Failed to send reset email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo
                  Hero(
                    tag: 'logo',
                    child: SizedBox(
                      height: size.height * 0.18,
                      child: Image.asset(
                        "assests/betzy.png",
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.sports_esports,
                          size: 80,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.02),

                  // Welcome Text
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: size.height * 0.01),

                  Text(
                    "Login to continue",
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 15),
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Email Field
                  buildInput(
                    "Email Address",
                    Icons.email_outlined,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: size.height * 0.02),

                  // Password Field
                  buildInput(
                    "Password",
                    Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.015),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loginWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                          : const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.03),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupPage(),
                          ),
                        ),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Text Input Field
  Widget buildInput(
      String hint,
      IconData icon, {
        bool isPassword = false,
        required TextEditingController controller,
        String? Function(String?)? validator,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Colors.grey.shade600,
            ),
            onPressed: () => setState(
                    () => _isPasswordVisible = !_isPasswordVisible),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 10,
          ),
        ),
      ),
    );
  }
}