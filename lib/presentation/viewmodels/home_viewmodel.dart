import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_converter/core/services/permission_service.dart';
import 'package:pdf_converter/data/models/pdf_file_detail.dart';
import 'package:pdf_converter/data/repositories/home_pdf_repository.dart';
import 'package:share_plus/share_plus.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    HomePdfRepository? homePdfRepository,
    PermissionService? permissionService,
  })  : _homePdfRepository = homePdfRepository ?? HomePdfRepository(),
        _permissionService = permissionService ?? PermissionService();

  final HomePdfRepository _homePdfRepository;
  final PermissionService _permissionService;

  List<PdfFileDetail> _fileDetails = [];

  List<PdfFileDetail> get fileDetails => _fileDetails;

  Future<void> loadFiles() async {
    _fileDetails = await _homePdfRepository.loadFiles();
    notifyListeners();
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm a · dd MMM yyyy').format(dateTime);
  }

  void openPdf(File file) {
    OpenFile.open(file.path);
  }

  Future<void> renamePdf(File file, String newName) async {
    if (newName.isNotEmpty) {
      final newPath = '${file.parent.path}/$newName.pdf';
      final renamedFile = await file.rename(newPath);

      final stat = await renamedFile.stat();
      final newDetail = PdfFileDetail(
        file: renamedFile,
        modified: stat.modified,
        size: '${(stat.size / 1024).toStringAsFixed(2)} KB',
      );

      _fileDetails.removeWhere((element) => element.file.path == file.path);
      _fileDetails.add(newDetail);
      _fileDetails.sort((a, b) => b.modified.compareTo(a.modified));
      notifyListeners();
    }
  }

  Future<void> sharePdf(File file) async {
    final params = ShareParams(
      text: 'Check out this PDF!',
      files: [XFile(file.path)],
    );
    await SharePlus.instance.share(params);
  }

  Future<void> deletePdf(File file) async {
    await file.delete();
    _fileDetails.removeWhere((element) => element.file.path == file.path);
    notifyListeners();
  }

  Future<String?> downloadPdf(BuildContext context, File file) async {
    if (Platform.isAndroid) {
      final hasPermission = await _permissionService.checkStoragePermission(context);
      if (!hasPermission) {
        return 'Storage permission denied';
      }
    }

    final destinationDir = Platform.isAndroid
        ? '/storage/emulated/0/Download'
        : (await getApplicationDocumentsDirectory()).path;

    final fileName = file.uri.pathSegments.last;
    File destFile = File('$destinationDir/$fileName');

    if (await destFile.exists()) {
      final baseName =
          fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      int counter = 1;
      File newFile;
      do {
        newFile = File('$destinationDir/$baseName ($counter).pdf');
        counter++;
      } while (await newFile.exists());
      await file.copy(newFile.path);
      return 'Downloaded to ${newFile.path}';
    } else {
      await file.copy(destFile.path);
      return 'Downloaded to ${destFile.path}';
    }
  }
}
