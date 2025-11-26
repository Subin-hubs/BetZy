import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Admine/admin_navbar.dart';
import 'Page/Auth/LoginPage.dart';
import 'Page/Auth/SignupPage.dart';
import 'Page/Navbar_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  AdmineMain(0, true),
    );
  }
}


