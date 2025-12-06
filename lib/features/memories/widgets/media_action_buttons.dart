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
  });

  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mover arriba',
          icon: SvgPicture.asset(AppIcons.chevronUp),
          onPressed: onMoveUp,
        ),
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
