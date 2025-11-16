import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';

class AppNavBar extends StatefulWidget {
  final int currentIndex;

  const AppNavBar({
    super.key,
    this.currentIndex = 2, // Por defecto el mapa
  });

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends State<AppNavBar> {
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    // Navegación interna según el índice
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/chatbot');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/memories');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/map');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/notifications');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primaryColor,
      selectedItemColor: AppColors.textColor,
      unselectedItemColor: AppColors.textColor.withValues(alpha: 0.54),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage(AppIcons.ai), size: AppSizes.iconSize),
          label: 'Chatbot',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(
            AssetImage(AppIcons.sticker),
            size: AppSizes.iconSize,
          ),
          label: 'Recuerdos',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage(AppIcons.earth), size: AppSizes.iconSize),
          label: 'Mapa',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage(AppIcons.bell), size: AppSizes.iconSize),
          label: 'Notificaciones',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(
            AssetImage(AppIcons.userRound),
            size: AppSizes.iconSize,
          ),
          label: 'Perfil',
        ),
      ],
    );
  }
}
