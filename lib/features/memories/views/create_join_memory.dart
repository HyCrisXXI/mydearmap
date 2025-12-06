import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/memories/views/memory_form_view.dart';

class CreateJoinMemoryView extends StatelessWidget {
  const CreateJoinMemoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false, // Handle padding manually
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.upperPadding,
                    left: 16.0,
                  ),
                  child: IconButton(
                    icon: SvgPicture.asset(
                      AppIcons.chevronLeft,
                      width: AppSizes.iconSize,
                      height: AppSizes.iconSize,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48), // Space between back button and title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '¿Qué te gustaría hacer?',
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48), // Space between title and buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    _SelectionButton(
                      title: 'Crear nuevo recuerdo',
                      subtitle: 'Cumpleaños, viajes, citas...',
                      iconPath: AppIcons.sticker,
                      iconColor: AppColors.blue,
                      onPressed: () {
                        // Navigate to create memory
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MemoryUpsertView.create(
                              initialLocation: const LatLng(39.4699, -0.3763),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _SelectionButton(
                      title: 'Unirte a un recuerdo',
                      subtitle: 'A través de un QR o link',
                      iconPath: AppIcons.qrCode,
                      iconColor: AppColors.orange,
                      onPressed: () {
                        // Navigate to join memory logic
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.iconColor,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String iconPath;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(45),
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400, // Assuming bold/semibold
                      color: AppColors.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
