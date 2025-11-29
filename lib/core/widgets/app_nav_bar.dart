import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    return SizedBox(
      height: 94, // Altura deseada para la barra de navegación
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryColor,
        selectedItemColor: AppColors.accentColor,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        iconSize: 36,
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.ai,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.ai,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.accentColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.sticker,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.sticker,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.accentColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Recuerdos',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.earth,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.earth,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.accentColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.bell,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.bell,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.accentColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.userRound,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SvgPicture.asset(
                AppIcons.userRound,
                width: AppSizes.iconSize,
                height: AppSizes.iconSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.accentColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
