import 'dart:io';

import 'package:file_picker/file_picker.dart';

class OfficeFilePickerService {
  Future<File?> pickOfficeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx', 'ppt', 'pptx'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return File(result.files.single.path!);
  }
}
