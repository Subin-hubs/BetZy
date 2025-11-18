import 'package:betting_app/Page/CreatePage/FreeFireCreatePage.dart';
import 'package:flutter/material.dart';

class Create_Page extends StatefulWidget {
  const Create_Page({super.key});

  @override
  State<Create_Page> createState() => _Create_PageState();
}

class _Create_PageState extends State<Create_Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create a Game",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ---------------- Free Fire Card ----------------
            buildGameCard(
              title: "Free Fire",
              subtitle: "Tap to create a Free Fire custom match",
              imagePath: "assests/freefire.png",
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FFCreatePage()));
              },
            ),

            const SizedBox(height: 20),

            // ---------------- PUBG Card ----------------
            buildGameCard(
              title: "PUBG Mobile",
              subtitle: "Create PUBG custom room matches",
              imagePath: "assests/pubg.png",
              onTap: () {
                // TODO: Add PUBG create page navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("PUBG Create Page Coming Soon!")),
                );
              },
            ),

            const SizedBox(height: 20),

            // ---------------- eFootball Card ----------------
            buildGameCard(
              title: "eFootball",
              subtitle: "Create eFootball 1v1 matches",
              imagePath: "assests/efootball.png",
              onTap: () {
                // TODO: Add Efootball create page navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("eFootball Create Page Coming Soon!")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------------ Reusable Game Card Widget ------------
  Widget buildGameCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
