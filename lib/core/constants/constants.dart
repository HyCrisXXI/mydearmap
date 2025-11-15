// lib/core/constants/constants.dart
import 'package:flutter/material.dart';
export 'app_icons.dart';

// Definiciones de colores, tamaños y estilos de texto utilizados en la aplicaciónç
class AppColors {
  static const primaryColor = Color(0xFFFFFCF6);
  static const accentColor = Color(0xFFFF9312);
  static const backgroundColor = Color(0xFFFFF5E5);
  static const textColor = Color(0xFF000000);
  static const blue = Color(0xFF5E67F2);
  static const yellow = Color(0xFFFFE833);
  static const orange = Color(0xFFFF9312);
  static const pink = Color(0xFFFFCCF1);
  static const green = Color(0xFFADE4A6);
  static const buttonBackground = Color(0xFF000000);
  static const buttonForeground = Color(0xFFFFFFFF);
}

class AppSizes {
  // Esto no es la version final de las constantes paddings
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double title = 24.0;
  static const double subtitle = 18.0;
  static const double text = 16.0;
  static const double textButton = 14.0;
  static const double iconSize = 24.0;
  static const double borderRadius = 30.0;
  static const double buttonWidthSmall = 128.0;
  static const double buttonWidthLarge = 230.0;
  static const double buttonHeight = 36.0;
  static const double buttonSpacing = 21.0;
  static const double buttonPaddingHorizontal = 15.0;
  static const double buttonPaddingVertical = 12.0;
}

class AppTextStyles {
  static const String _fontFamily = 'TikTokSans';

  // Estilo para Título
  static const TextStyle title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w600, // w600 es Semibold
    color: AppColors.textColor,
  );

  // Estilo para Subtítulo
  static const TextStyle subtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w500, // w500 es Medium
    color: AppColors.textColor,
  );

  // Estilo para Texto
  static const TextStyle text = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400, // w400 es Regular
    color: AppColors.textColor,
  );

  // Estilo para Texto de Botón
  static const TextStyle textButton = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400, // w400 es Regular
    color: AppColors.textColor,
  );
}

// Definición del esquema de colores claro
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.accentColor,
  onPrimary: AppColors.buttonForeground,
  secondary: AppColors.blue,
  onSecondary: Colors.white,
  tertiary: AppColors.pink,
  onTertiary: AppColors.textColor,
  surface: AppColors.primaryColor,
  onSurface: AppColors.textColor,
  surfaceContainerHighest: AppColors.backgroundColor,
  onSurfaceVariant: AppColors.textColor,
  // Todos los colores derivados de Colors son placeholders, por ahora
  outline: Colors.grey,
  error: Colors.red,
  onError: Colors.white,
);
