import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import 'CreatePage/Create_page.dart';
import 'HomePage/Home_page.dart';
import 'LeaderBoardPage/Leaderboard_page.dart';
import 'MorePage/More_page.dart';
import 'ReedemPage/Reedem_page.dart';

class Mainpage extends StatefulWidget {
  final int currentIndex;
  final bool navigation;

  const Mainpage(this.currentIndex, this.navigation, {Key? key}) : super(key: key);

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: widget.currentIndex);
  }

  // ✅ Must have 5 screens to match 5 items (for style15)
  List<Widget> _buildScreens() {
    return [
      Home_page(),
      Leaderboard_Page(),
      Create_Page(),
      Reedem_Page(),
      more_page(),
    ];
  }

  // ✅ 5 items, middle one for Create_Page
  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_outlined),
        title: "Home",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.leaderboard_outlined),
        title: "Leaderboard",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      // 🟦 Center button (+ icon)
      PersistentBottomNavBarItem(
        icon: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent,
          ),
          padding: const EdgeInsets.all(10),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: "",
        activeColorPrimary: Colors.transparent,
        inactiveColorPrimary: Colors.transparent,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.card_giftcard_outlined),
        title: "Redeem",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.menu),
        title: "More",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(),

        confineToSafeArea: true,
        backgroundColor: Colors.white,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        navBarHeight: 60,

        decoration: const NavBarDecoration(
          borderRadius: BorderRadius.zero,
          colorBehindNavBar: Colors.white,
        ),

        onItemSelected: (index) {
          setState(() {}); // refresh if you want visual state updates
        },

        navBarStyle: NavBarStyle.style15,
      ),
    );
  }
}
