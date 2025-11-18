import 'package:flutter/material.dart';

class Leaderboard_Page extends StatefulWidget {
  const Leaderboard_Page({super.key});

  @override
  State<Leaderboard_Page> createState() => _Leaderboard_PageState();
}

class _Leaderboard_PageState extends State<Leaderboard_Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      title: Text("Leader Board"),
    ),);
  }
}
