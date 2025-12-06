import 'package:flutter/material.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/features/ai_chat/views/ai_chat_view.dart';
import 'package:mydearmap/features/memories/views/memories_view.dart';
import 'package:mydearmap/features/map/views/map_view.dart';
import 'package:mydearmap/features/notifications/views/notifications_view.dart';
import 'package:mydearmap/features/profile/views/profile_view.dart';

/// A shell widget that manages the main navigation structure with a persistent bottom navigation bar.
///
/// This widget provides:
/// - Persistent navigation bar across all main screens
/// - Smooth animated transitions between tabs
/// - Nested navigation for each section to allow deep linking while keeping the nav bar visible
class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({
    super.key,
    this.initialIndex = 2, // Map by default
  });

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _currentIndex;
  late PageController _pageController;

  // GlobalKeys for each tab's navigator to maintain their navigation stacks
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // AI Chat
    GlobalKey<NavigatorState>(), // Memories
    GlobalKey<NavigatorState>(), // Map
    GlobalKey<NavigatorState>(), // Notifications
    GlobalKey<NavigatorState>(), // Profile
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) {
      // If tapping the same tab, pop to root of that tab's navigation stack
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final currentNavigator = _navigatorKeys[_currentIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe navigation
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildNavigator(0, const AiChatView()),
            _buildNavigator(1, const MemoriesView()),
            _buildNavigator(2, const MapView()),
            _buildNavigator(3, const NotificationsView()),
            _buildNavigator(4, const ProfileView()),
          ],
        ),
        bottomNavigationBar: AppNavBar(
          currentIndex: _currentIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => child);
      },
    );
  }
}
