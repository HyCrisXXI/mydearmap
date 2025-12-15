import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
export 'app_icons.dart';

// Definiciones de colores, tamaños y estilos de texto utilizados en la aplicaciónç
class AppColors {
  static const primaryColor = Color(0xFFFFFCF6);
  static const accentColor = Color(0xFF5E67F2); // Azul vibrante placeholder?
  static const backgroundColor = Color(0xFFFFF5E5);
  static const textColor = Color(0xFF000000);
  static const textGray = Color(0xFF686868);
  static const blue = accentColor;
  static const orange = Color(0xFFFF9312);
  static const pink = Color(0xFFFFCCF1);
  static const buttonBackground = Color(0xFF000000);
  static const buttonForeground = Color(0xFFFFFFFF);
  static const buttonDisabledBackground = Color(0xFFD9D9D9);
}

class AppSizes {
  // Esto no es la version final de las constantes paddings
  static const double paddingSmall = 8.0;
  static const double paddingSmallMedium = 12.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double upperPadding = 64.0;

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
  static const double profileAvatarSize = 56.0;
  static const double profileAvatarBorder = 1.5;
  static const double listAvatarSize = 48.0;
  static const double modalMaxWidth = 520.0;

  static const double memoryRadiusTop = 22.0;
  static const double memoryFooterHeight = 46.0;
  static const double appBarHeight = 80.0;
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
    color: AppColors.textGray,
  );

  // Estilo para campos de texto
  static const TextStyle textField = TextStyle(
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

  static const TextStyle searchBarText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textGray,
  );

  static TextStyle get myDearMapTitle => GoogleFonts.archivo(
    fontSize: 24.0,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF000000), // Negro
    fontStyle: FontStyle.normal,
  );
}

class AppButtonStyles {
  static const ButtonStyle circularIconButton = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(AppColors.primaryColor),
    shape: WidgetStatePropertyAll(CircleBorder()),
    padding: WidgetStatePropertyAll(EdgeInsets.all(1)),
    fixedSize: WidgetStatePropertyAll(Size(36, 36)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class AppInputStyles {
  static const InputDecorationTheme defaultInputDecorationTheme =
      InputDecorationTheme(
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textColor),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textColor, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textColor, width: 2.0),
        ),
        labelStyle: TextStyle(color: AppColors.textColor),
        floatingLabelStyle: TextStyle(color: AppColors.textColor),
        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
      );

  static const EdgeInsets searchBarContentPadding = EdgeInsets.symmetric(
    horizontal: 38.0,
    vertical: 12.0,
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

class AppDecorations {
  static const BoxDecoration memoryCardTop = BoxDecoration(
    color: AppColors.primaryColor,
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppSizes.memoryRadiusTop),
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0xADDBD0BE),
        blurRadius: 3.5,
        spreadRadius: 0,
        offset: Offset(0, 2.0),
      ),
    ],
  );

  static const BoxDecoration memoryCardBottom = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(AppCardMemory.borderRadius),
    ),
  );

  static BoxDecoration profileAvatar(ImageProvider imageProvider) {
    return BoxDecoration(
      shape: BoxShape.circle,
      // Borde fino blanco
      border: Border.all(
        color: Colors.white,
        width: AppSizes.profileAvatarBorder,
      ),
      // La imagen dentro del círculo
      image: DecorationImage(
        image: imageProvider,
        fit: BoxFit.cover, // Para que la imagen cubra todo el círculo
      ),
    );
  }
}

class AppCardMemory {
  // Mantenemos las existentes
  static const double width = 171;
  static const double height = 160;
  static const double cardWithTitleHeight = 192; // 160 + espacio para el título
  static const double aspectRatio = width / cardWithTitleHeight;
  static const double borderRadius = 20.0;

  static const double bigWidth = 219.0;
  // Altura total 300 - Footer 46 = Imagen 254
  static const double bigImageHeight = 254.0;
  static const double bigTotalHeight = 300.0;

  static const double previewWidth = 194.0;
  static const double previewHeight = 260.0;
  static const double previewRadius = 20.0;
}
