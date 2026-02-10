import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pdf_converter/Controllers/permission_controller.dart';

class DocumentPickingController {
  Controllers controllers = Controllers();

  Future<void> pickOfficeFile(BuildContext context) async {
    try {
      final permission = await controllers.checkStoragePermission(context);
      if (!permission) return;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx', 'ppt', 'pptx'],
      );

      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected")),
        );
        return;
      }
      final picked = result.files.single;
      setState(() {
        selectedFile = File(picked.path!);
        isLoading = true;
      });

      ///  CONVERT USING BACKEND
      final pdfName = await _fileName();
      final pdfFile =
          await apiCallingController.convertOfficeToPdf(selectedFile!, pdfName);

      setState(() => isLoading = false);

      ///  PREVIEW REAL PDF

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfficeToPdfPreview(
            pdfFile: pdfFile,
          ),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
