import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/constants/app_icons.dart';

class MediaActionButtons extends StatelessWidget {
  const MediaActionButtons({
    super.key,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    this.isDeleting = false,
    this.showMoveUp = true,
    this.showMoveDown = true,
  });

  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;
  final bool isDeleting;
  final bool showMoveUp;
  final bool showMoveDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMoveUp)
          IconButton(
            tooltip: 'Mover arriba',
            icon: SvgPicture.asset(AppIcons.chevronUp),
            onPressed: onMoveUp,
          ),
        if (showMoveDown)
          IconButton(
            tooltip: 'Mover abajo',
            icon: SvgPicture.asset(AppIcons.chevronDown),
            onPressed: onMoveDown,
          ),
        isDeleting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              )
            : IconButton(
                tooltip: 'Eliminar archivo',
                icon: SvgPicture.asset(AppIcons.trash),
                onPressed: onDelete,
              ),
      ],
    );
  }
}
