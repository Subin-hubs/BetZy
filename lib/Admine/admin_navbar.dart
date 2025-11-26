import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import 'Admin_Pages/Admin_home.dart';
import 'Admin_Pages/Admine_Dashboard.dart';
import 'Admin_Pages/Admine_Results.dart';
import 'Admin_Pages/Admine_more.dart';
import 'Admin_Pages/admine_mageManagement.dart';

class AdmineMain extends StatefulWidget {
  final int currentIndex;
  final bool navigation;

  const AdmineMain(this.currentIndex, this.navigation, {Key? key})
      : super(key: key);

  @override
  State<AdmineMain> createState() => _AdmineMainState();
}

class _AdmineMainState extends State<AdmineMain> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: widget.currentIndex);
  }

  // Screens
  List<Widget> _buildScreens() {
    return [
      AdminUserManagementScreen(),
      AdmineDashboard(),
      AdmineMagemanagement(),
      AdmineResults(),
      AdmineMore(),
    ];
  }

  // Nav items
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
        title: "Dashboard",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.image_outlined),
        title: "Media",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
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

  // Custom NavBar UI (flat, no shadow)
  Widget _buildCustomNavBar(BuildContext context) {
    final items = _navBarsItems();
    final selectedIndex = _controller.index;

    return Container(
      color: Colors.white, // flat bar background
      height: 60,
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _controller.jumpToTab(index)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.icon is Icon)
                    Icon(
                      (item.icon as Icon).icon,
                      size: 26,
                      color: isSelected ? Colors.blueAccent : Colors.grey,
                    ),
                  if ((item.title ?? "").isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.title!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.blueAccent : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(),
        navBarHeight: 0, // hide default
        stateManagement: true,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        confineToSafeArea: true,
      ),
      bottomNavigationBar: _buildCustomNavBar(context),
    );
  }
}
