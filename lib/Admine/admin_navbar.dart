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
      AdminHomePage(),
      AdminUserManagementScreen(),
      AdminMatchManagement(),
      AdminTopupPage(),
      SettingsMore(),
    ];
  }

  // Nav items
  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_rounded),
        title: "Home",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.people_rounded),
        title: "Users",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.sports_soccer_rounded),
        title: "Matches",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.wallet_rounded),
        title: "Topup",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.more_horiz_rounded),
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
        navBarHeight: 0, // hide default
        stateManagement: true,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        confineToSafeArea: true,
      ),
      bottomNavigationBar: _buildCustomNavBar(context),
    );
  }
  // Custom NavBar UI - Modern design with animations
  Widget _buildCustomNavBar(BuildContext context) {
    final items = _navBarsItems();
    final selectedIndex = _controller.index;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _controller.jumpToTab(index)),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blueAccent.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: item.icon is Icon
                              ? Icon(
                            (item.icon as Icon).icon,
                            size: isSelected ? 24 : 26,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          )
                              : item.icon,
                        ),
                        const SizedBox(height: 4),
                        if ((item.title ?? "").isNotEmpty)
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: isSelected ? 11 : 10,
                              fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.grey.shade600,
                            ),
                            child: Text(
                              item.title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}