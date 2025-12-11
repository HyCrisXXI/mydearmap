import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/features/ai_chat/views/ai_chat_view.dart';
import 'package:mydearmap/features/memories/views/memories_view.dart';
import 'package:mydearmap/features/map/views/map_view.dart';
import 'package:mydearmap/features/notifications/views/notifications_view.dart';
import 'package:mydearmap/features/profile/views/profile_view.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({
    super.key,
    this.initialIndex = 2, // Map by default
  });

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  int? _previousIndex;
  late AnimationController _animationController;
  DateTime? _lastBackPressed;
  final Duration _exitWarningDuration = const Duration(seconds: 1);

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) {
      // If tapping the same tab, pop to root of that tab's navigation stack
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Check nested navigation
        final currentNavigator = _navigatorKeys[_currentIndex].currentState;
        if (currentNavigator != null) {
          final popped = await currentNavigator.maybePop();
          if (popped) return;
        }

        await _handleShellBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _buildOffstageNavigator(0, const AiChatView()),
            _buildOffstageNavigator(1, const MemoriesView()),
            _buildOffstageNavigator(2, const MapView()),
            _buildOffstageNavigator(3, const NotificationsView()),
            _buildOffstageNavigator(4, const ProfileView()),
          ],
        ),
        bottomNavigationBar: AppNavBar(
          currentIndex: _currentIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index, Widget child) {
    // If it's the current page, we animate it IN
    if (index == _currentIndex) {
      // Enter animation configuration

      // Default (first build): no animation
      if (_previousIndex == null) {
        return _buildNavigator(index, child);
      }

      final isMovingRight = index > _previousIndex!;
      final beginOffset = isMovingRight
          ? const Offset(1.0, 0.0)
          : const Offset(-1.0, 0.0);

      return SlideTransition(
        position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        ),
        child: _buildNavigator(index, child),
      );
    }

    // If it's the outgoing page, we animate it OUT
    if (index == _previousIndex && _previousIndex != null) {
      // Exit animation configuration
      final isMovingRight = _currentIndex > index;
      final endOffset = isMovingRight
          ? const Offset(-1.0, 0.0)
          : const Offset(1.0, 0.0);

      return SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: endOffset).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        ),
        child: _buildNavigator(index, child),
      );
    }

    // Otherwise, keep it offstage to preserve state but hidden
    return Offstage(offstage: true, child: _buildNavigator(index, child));
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => child);
      },
    );
  }

  Future<void> _handleShellBack() async {
    if (_currentIndex != 2) {
      _navigateToMapTab();
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > _exitWarningDuration) {
      _lastBackPressed = now;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Vuelve a tocar para salir'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      SystemNavigator.pop();
    }
  }

  void _navigateToMapTab() {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = 2;
    });
    _animationController.reset();
    _animationController.forward();
  }
}
