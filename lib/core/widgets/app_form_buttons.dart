// lib/core/widgets/app_form_buttons.dart
import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';

class AppFormButtons extends StatelessWidget {
  const AppFormButtons({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.isProcessing = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.primaryIsCompact = false,
    this.secondaryIsCompact = false,
    this.secondaryOutlined =
        true, // new: render secondary as outlined by default
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool isProcessing;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool primaryIsCompact;
  final bool secondaryIsCompact;
  final bool secondaryOutlined;

  double _buttonWidth(bool isCompact) =>
      isCompact ? AppSizes.buttonWidthSmall : AppSizes.buttonWidthLarge;

  ButtonStyle _buttonStyle() => FilledButton.styleFrom(
    backgroundColor: AppColors.buttonBackground,
    foregroundColor: AppColors.buttonForeground,
    disabledBackgroundColor: AppColors.buttonBackground.withValues(alpha: .4),
    disabledForegroundColor: AppColors.buttonForeground.withValues(alpha: .7),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.buttonPaddingHorizontal,
      vertical: AppSizes.buttonPaddingVertical,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
    ),
  );

  // new: outlined style for secondary
  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
    foregroundColor: AppColors.buttonForeground,
    backgroundColor: Colors.transparent,
    disabledForegroundColor: AppColors.buttonForeground.withValues(alpha: .4),
    side: const BorderSide(color: AppColors.buttonBackground, width: 1.0),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.buttonPaddingHorizontal,
      vertical: AppSizes.buttonPaddingVertical,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final baseLabel =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    final primaryLabelStyle = baseLabel.copyWith(
      fontWeight: FontWeight.bold,
      color: AppColors.buttonForeground,
    );
    final secondaryLabelStyle = baseLabel.copyWith(
      fontWeight: FontWeight.bold,
      color: AppColors.buttonBackground,
    );
    final bool disablePrimary = isProcessing || onPrimaryPressed == null;
    final bool disableSecondary = isProcessing || onSecondaryPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: _buttonWidth(primaryIsCompact),
              child: FilledButton(
                onPressed: disablePrimary ? null : onPrimaryPressed,
                style: _buttonStyle(),
                child: isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.buttonForeground,
                        ),
                      )
                    : Text(primaryLabel, style: primaryLabelStyle),
              ),
            ),
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: AppSizes.buttonSpacing),
          Align(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: _buttonWidth(secondaryIsCompact),
                child: secondaryOutlined
                    ? OutlinedButton(
                        onPressed: disableSecondary ? null : onSecondaryPressed,
                        style: _outlinedStyle(),
                        child: Text(
                          secondaryLabel!,
                          style: secondaryLabelStyle,
                        ),
                      )
                    : FilledButton(
                        onPressed: disableSecondary ? null : onSecondaryPressed,
                        style: _buttonStyle(),
                        child: Text(secondaryLabel!, style: primaryLabelStyle),
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
