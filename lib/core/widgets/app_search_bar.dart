import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/constants/constants.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSuffixPressed,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSuffixPressed;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.searchBarText,
      // Removed textAlignVertical to ensure default (usually centered/baseline balanced)
      // or to respect contentPadding explicitly.
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.searchBarText,
        // Enforce 1px border. UnderlineInputBorder default is 1.0 for enabledBorder.
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textColor, width: 1.0),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.textColor,
            width: 2.0,
          ), // Standard focus
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textColor, width: 1.0),
        ),
        // Custom padding to align text and icon
        contentPadding: const EdgeInsets.only(
          left: 0,
          right: 38.0,
          top: 12,
          bottom: 12, // Adjust bottom to control baseline relative to line
        ),
        prefixIcon: null,
        suffixIcon: IconButton(
          icon: SvgPicture.asset(AppIcons.search, width: 22, height: 22),
          onPressed: onSuffixPressed,
        ),
      ),
    );
  }
}
