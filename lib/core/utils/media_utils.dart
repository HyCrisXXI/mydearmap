import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mydearmap/core/constants/constants.dart';

class MediaUtils {
  static Future<CroppedFile?> pickAndCropImage({
    required BuildContext context,
    CropStyle cropStyle = CropStyle.circle,
    String title = 'Recortar',
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return null;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: AppColors.primaryColor,
          toolbarWidgetColor: AppColors.textColor,
          activeControlsWidgetColor: AppColors.accentColor,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: cropStyle,
        ),
        IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: cropStyle,
        ),
      ],
    );

    return croppedFile;
  }
}
