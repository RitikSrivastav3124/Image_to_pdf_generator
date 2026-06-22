import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pdf_converter/core/services/pdf_storage_service.dart';

class OfficePdfRemoteDatasource {
  OfficePdfRemoteDatasource({PdfStorageService? pdfStorageService})
      : _pdfStorageService = pdfStorageService ?? PdfStorageService();

  final PdfStorageService _pdfStorageService;

  Future<File> convertOfficeToPdf(File officeFile, String pdfName) async {
    final uri = Uri.parse(
        "https://pdf-backend-2-nhgm.onrender.com"); // Replace with your backend URL  https://pdf-backend-2-nhgm.onrender.com/api/office-to-pdf

    final request = http.MultipartRequest("POST", uri);
    request.files.add(
      await http.MultipartFile.fromPath("file", officeFile.path),
    );

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception("Server error");
    }

    final bytes = await streamedResponse.stream.toBytes();

    final safeName = pdfName.trim().isEmpty ? "Converted_File" : pdfName.trim();

    return _pdfStorageService.writePdfBytes(safeName, bytes);
  }
}
