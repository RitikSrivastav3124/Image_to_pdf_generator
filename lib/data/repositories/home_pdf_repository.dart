import 'dart:io';

import 'package:pdf_converter/core/services/pdf_storage_service.dart';
import 'package:pdf_converter/data/models/pdf_file_detail.dart';

class HomePdfRepository {
  HomePdfRepository({PdfStorageService? pdfStorageService})
      : _pdfStorageService = pdfStorageService ?? PdfStorageService();

  final PdfStorageService _pdfStorageService;

  Future<List<PdfFileDetail>> loadFiles() async {
    final pdfDir = await _pdfStorageService.getPdfDirectory();
    final files = pdfDir.listSync().whereType<File>();

    final details = await Future.wait(files.map((file) async {
      final stat = await file.stat();
      return PdfFileDetail(
        file: file,
        modified: stat.modified,
        size: '${(stat.size / 1024).toStringAsFixed(2)} KB',
      );
    }));

    details.sort((a, b) => b.modified.compareTo(a.modified));
    return details;
  }
}
