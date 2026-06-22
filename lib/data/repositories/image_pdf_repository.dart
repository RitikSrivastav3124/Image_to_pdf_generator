import 'dart:io';

import 'package:pdf_converter/data/datasources/image_pdf_local_datasource.dart';

class ImagePdfRepository {
  ImagePdfRepository({ImagePdfLocalDatasource? localDatasource})
      : _localDatasource = localDatasource ?? ImagePdfLocalDatasource();

  final ImagePdfLocalDatasource _localDatasource;

  Future<File> createPdf({
    required List<File> images,
    required String pdfFileName,
  }) {
    return _localDatasource.createPdf(
      images: images,
      pdfFileName: pdfFileName,
    );
  }
}
