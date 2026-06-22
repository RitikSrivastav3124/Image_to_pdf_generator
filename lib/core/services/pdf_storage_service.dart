import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf_converter/core/constants/app_constants.dart';

class PdfStorageService {
  Future<Directory> getPdfDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${dir.path}/${AppConstants.pdfDirectoryName}');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  Future<File> writePdfBytes(String pdfFileName, List<int> bytes) async {
    final pdfDir = await getPdfDirectory();
    final file = File('${pdfDir.path}/$pdfFileName.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
