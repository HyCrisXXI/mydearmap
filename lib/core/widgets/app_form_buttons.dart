import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';

extension _ColorHelpers on ColorScheme {
  Color get subduedPrimary => primary.withValues(alpha: .5);
  Color get subduedOnPrimary => onPrimary.withValues(alpha: .7);
}

class AppFormButtons extends StatelessWidget {
  const AppFormButtons({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.isProcessing = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool isProcessing;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool disablePrimary = isProcessing || onPrimaryPressed == null;

    return Column(
      children: [
        SizedBox(
          height: 50,
          width: double.infinity,
          child: FilledButton(
            onPressed: disablePrimary ? null : onPrimaryPressed,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              disabledBackgroundColor: scheme.subduedPrimary,
              disabledForegroundColor: scheme.subduedOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
            ),
            child: isProcessing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    primaryLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: AppSizes.paddingMedium),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (isProcessing || onSecondaryPressed == null)
                  ? null
                  : onSecondaryPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.primary,
                disabledForegroundColor: scheme.subduedPrimary,
                side: BorderSide(color: scheme.primary, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              ),
              child: Text(
                secondaryLabel!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
