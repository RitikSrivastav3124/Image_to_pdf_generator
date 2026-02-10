import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiCallingController {
  Future<File> convertOfficeToPdf(File officeFile, String pdfName) async {
    final uri =
        Uri.parse("https://pdf-backend-2-nhgm.onrender.com/api/office-to-pdf");

    final request = http.MultipartRequest("POST", uri);
    request.files.add(
      await http.MultipartFile.fromPath("file", officeFile.path),
    );

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception("Server error");
    }

    final bytes = await streamedResponse.stream.toBytes();

    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory("${dir.path}/pdf_converter");

    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final safeName = pdfName.trim().isEmpty ? "Converted_File" : pdfName.trim();

    final pdfFile = File("${pdfDir.path}/$safeName.pdf");

    await pdfFile.writeAsBytes(bytes, flush: true);

    return pdfFile;
  }
}
