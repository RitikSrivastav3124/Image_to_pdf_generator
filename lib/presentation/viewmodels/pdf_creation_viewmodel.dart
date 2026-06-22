// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf_converter/core/constants/app_constants.dart';
import 'package:pdf_converter/core/services/permission_service.dart';
import 'package:pdf_converter/data/repositories/image_pdf_repository.dart';

class PdfCreationViewModel extends ChangeNotifier {
  PdfCreationViewModel({
    PermissionService? permissionService,
    ImagePdfRepository? imagePdfRepository,
    ImagePicker? imagePicker,
  })  : _permissionService = permissionService ?? PermissionService(),
        _imagePdfRepository = imagePdfRepository ?? ImagePdfRepository(),
        _imagePicker = imagePicker ?? ImagePicker();

  final PermissionService _permissionService;
  final ImagePdfRepository _imagePdfRepository;
  final ImagePicker _imagePicker;

  final List<File> _images = [];
  String pdfFileName = AppConstants.defaultPdfFileName;

  List<File> get images => _images;

  Future<bool> pickImages(
    BuildContext context,
    ImageSource source, {
    required Future<bool> Function() askTakeAnotherPicture,
  }) async {
    final permission = await _permissionService.checkStoragePermission(context);
    if (!permission) return false;

    if (source == ImageSource.gallery) {
      final pickedImages = await _imagePicker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        _images.addAll(pickedImages.map((x) => File(x.path)));
        notifyListeners();
        return true;
      }
    } else {
      final cameraPermission = await _permissionService.checkCameraPermission(context);
      if (!cameraPermission) return false;
      bool pickAnother = true;
      while (pickAnother) {
        final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
        if (pickedFile != null) {
          _images.add(File(pickedFile.path));
          notifyListeners();
          pickAnother = await askTakeAnotherPicture();
        } else {
          pickAnother = false;
        }
      }
      if (_images.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  Future<File> createPdf(String fileName) {
    pdfFileName = fileName;
    return _imagePdfRepository.createPdf(
      images: _images,
      pdfFileName: pdfFileName,
    );
  }
}
