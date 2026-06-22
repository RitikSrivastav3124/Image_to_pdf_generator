import 'dart:io';

import 'package:pdf_converter/data/datasources/office_pdf_remote_datasource.dart';

class OfficePdfRepository {
  OfficePdfRepository({OfficePdfRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? OfficePdfRemoteDatasource();

  final OfficePdfRemoteDatasource _remoteDatasource;

  Future<File> convertOfficeToPdf(File officeFile, String pdfName) {
    return _remoteDatasource.convertOfficeToPdf(officeFile, pdfName);
  }
}
