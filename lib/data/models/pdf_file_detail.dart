import 'dart:io';

class PdfFileDetail {
  final File file;
  final DateTime modified;
  final String size;

  const PdfFileDetail({
    required this.file,
    required this.modified,
    required this.size,
  });
}
