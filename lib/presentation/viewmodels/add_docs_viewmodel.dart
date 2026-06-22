import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf_converter/core/constants/app_constants.dart';
import 'package:pdf_converter/core/services/office_file_picker_service.dart';
import 'package:pdf_converter/core/services/permission_service.dart';
import 'package:pdf_converter/data/repositories/office_pdf_repository.dart';

class AddDocsViewModel extends ChangeNotifier {
  AddDocsViewModel({
    PermissionService? permissionService,
    OfficeFilePickerService? officeFilePickerService,
    OfficePdfRepository? officePdfRepository,
  })  : _permissionService = permissionService ?? PermissionService(),
        _officeFilePickerService =
            officeFilePickerService ?? OfficeFilePickerService(),
        _officePdfRepository = officePdfRepository ?? OfficePdfRepository();

  final PermissionService _permissionService;
  final OfficeFilePickerService _officeFilePickerService;
  final OfficePdfRepository _officePdfRepository;

  String pdfFileName = AppConstants.defaultPdfFileName;
  File? selectedFile;
  bool isLoading = false;

  Future<bool> pickOfficeFile(BuildContext context) async {
    final permission = await _permissionService.checkStoragePermission(context);
    if (!permission) return false;

    final pickedFile = await _officeFilePickerService.pickOfficeFile();
    if (pickedFile == null) {
      return false;
    }

    selectedFile = pickedFile;
    isLoading = true;
    notifyListeners();
    return true;
  }

  Future<File> convertSelectedFile(String pdfName) async {
    pdfFileName = pdfName;
    final pdfFile =
        await _officePdfRepository.convertOfficeToPdf(selectedFile!, pdfName);
    isLoading = false;
    notifyListeners();
    return pdfFile;
  }

  void stopLoading() {
    isLoading = false;
    notifyListeners();
  }
}
