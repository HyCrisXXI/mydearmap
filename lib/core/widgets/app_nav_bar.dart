import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onItemTapped;

  const AppNavBar({
    super.key,
    this.currentIndex = 2, // Por defecto el mapa
    this.onItemTapped,
  });

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
        currentIndex: currentIndex,
        onTap: onItemTapped,
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
