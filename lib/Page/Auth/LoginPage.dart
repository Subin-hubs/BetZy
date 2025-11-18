import 'package:betting_app/Page/Auth/SignupPage.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  final Color primaryColor = const Color(0xFF2962FF);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Responsive

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.07,
            ),
            child: Column(
              children: [
                // LOGO
                SizedBox(
                  height: size.height * 0.18,
                  child: Image.asset(
                    "assests/betzy.png",     // ✔ FIXED: correct path
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported_outlined,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                Text(
                  "Please login to your account",
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                SizedBox(height: size.height * 0.04),

                buildInput("Email Address", Icons.email_outlined),
                SizedBox(height: size.height * 0.02),

                buildInput(
                  "Password",
                  Icons.lock_outline,
                  isPassword: true,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text("Forgot Password?",
                        style: TextStyle(color: primaryColor)),
                  ),
                ),

                SizedBox(height: size.height * 0.015),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Log In",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                // CONTINUE WITH SOCIAL
                Row(
                  children: [
                    Expanded(child: Divider()),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("or"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                SizedBox(height: size.height * 0.02),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    socialButton(Icons.g_mobiledata, Colors.red),
                    const SizedBox(width: 15),
                    socialButton(Icons.apple, Colors.black),
                    const SizedBox(width: 15),
                    socialButton(Icons.facebook, Colors.blue),
                  ],
                ),

                SizedBox(height: size.height * 0.03),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {},
                      child: GestureDetector (onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>SignupPage()));
                      },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold),
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
    );
  }

  // TEXT INPUT FIELD
  Widget buildInput(String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        obscureText: isPassword ? !_isPasswordVisible : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 10),
        ),
      ),
    );
  }

  // SOCIAL BUTTON
  Widget socialButton(IconData icon, Color color) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, color: color),
    );
  }
}
