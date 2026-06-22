import 'dart:io';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_converter/core/services/pdf_storage_service.dart';

class ImagePdfLocalDatasource {
  ImagePdfLocalDatasource({PdfStorageService? pdfStorageService})
      : _pdfStorageService = pdfStorageService ?? PdfStorageService();

  final PdfStorageService _pdfStorageService;

  Future<File> createPdf({
    required List<File> images,
    required String pdfFileName,
  }) async {
    final pdf = pw.Document();
    for (var image in images) {
      final imgBytes = await image.readAsBytes();
      final img = pw.MemoryImage(imgBytes);
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(0),
          build: (_) => pw.Center(
            child: pw.Image(img, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    return _pdfStorageService.writePdfBytes(pdfFileName, await pdf.save());
  }
}
