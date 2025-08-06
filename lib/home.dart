// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf_converter/pdf_creation_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _fileDetails = [];
  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<Directory> _getPdfDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${dir.path}/pdf_converter');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  Future<void> _loadFiles() async {
    final pdfDir = await _getPdfDirectory();
    final files = pdfDir.listSync().whereType<File>();

    final details = await Future.wait(files.map((file) async {
      final stat = await file.stat();
      return {
        'file': file,
        'modified': stat.modified,
        'size': '${(stat.size / 1024).toStringAsFixed(2)} KB',
      };
    }));

    details.sort((a, b) =>
        (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));

    if (!mounted) return;
    setState(() => _fileDetails = details);
  }

  Future<bool> _requestPermission(
      Permission permission, String permissionName) async {
    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      if (!mounted) return false;
      _showPermissionDeniedDialog(permissionName);
      return false;
    }
    return true;
  }

  Future<bool> _checkCameraPermission() =>
      _requestPermission(Permission.camera, 'Camera');

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName permission denied'),
        content: Text('$permissionName permission is required to continue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (!await _checkCameraPermission()) return;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFCreationPage(
          source: ImageSource.camera,
          onPdfCreated: (file) {
            _loadFiles();
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm a · dd MMM yyyy').format(dateTime);
  }

  void _openPdf(File file) {
    OpenFile.open(file.path);
  }

  Future<void> _renamePdf(File file) async {
    String newName = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename PDF'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new file name'),
          onChanged: (value) => newName = value.trim(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (newName.isNotEmpty) {
                final newPath = '${file.parent.path}/$newName.pdf';
                final renamedFile = await file.rename(newPath);

                final stat = await renamedFile.stat();
                final newDetail = {
                  'file': renamedFile,
                  'modified': stat.modified,
                  'size': '${(stat.size / 1024).toStringAsFixed(2)} KB',
                };

                if (!mounted) return;
                setState(() {
                  _fileDetails.removeWhere(
                      (element) => element['file'].path == file.path);
                  _fileDetails.add(newDetail);
                  _fileDetails.sort((a, b) => (b['modified'] as DateTime)
                      .compareTo(a['modified'] as DateTime));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          )
        ],
      ),
    );
  }

  Future<void> _sharePdf(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Check out this PDF!');
  }

  Future<void> _deletePdf(File file) async {
    await file.delete();
    if (!mounted) return;
    setState(() {
      _fileDetails.removeWhere((element) => element['file'].path == file.path);
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF Deleted Successfully')));
  }

  Future<void> _confirmDelete(File file) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you really want to delete this file?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete == true) {
      _deletePdf(file);
    }
  }

  Future<bool> _checkManageStoragePermission() async {
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return true;

    final result = await Permission.manageExternalStorage.request();

    if (result.isDenied || result.isPermanentlyDenied) {
      if (!mounted) return false;
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
              'Storage permission is permanently denied. Please enable it from app settings.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context, true);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return openSettings == true;
    }
    return result.isGranted;
  }

  Future<void> _downloadPdf(File file) async {
    if (Platform.isAndroid) {
      final hasPermission = await _checkManageStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')));
        return;
      }
    }

    final destinationDir = Platform.isAndroid
        ? '/storage/emulated/0/Download'
        : (await getApplicationDocumentsDirectory()).path;

    final fileName = file.uri.pathSegments.last;
    File destFile = File('$destinationDir/$fileName');

    try {
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded to ${newFile.path}')));
      } else {
        await file.copy(destFile.path);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded to ${destFile.path}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  void _showFileOptions(File file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.indigo),
              title: const Text('Open PDF'),
              onTap: () {
                Navigator.pop(context);
                _openPdf(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Rename PDF'),
              onTap: () {
                Navigator.pop(context);
                _renamePdf(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Download PDF'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Download PDF'),
                    content: const Text(
                        'Do you want to download this PDF to your device?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Download')),
                    ],
                  ),
                );
                if (confirm == true) _downloadPdf(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share PDF'),
              onTap: () {
                Navigator.pop(context);
                _sharePdf(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete PDF'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Converter',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: const Color(0xFF7E53F4),
        elevation: 5,
      ),
      body: Container(
        color: const Color.fromARGB(255, 236, 234, 248),
        child: _fileDetails.isEmpty
            ? const Center(
                child: Text('No PDFs created yet.',
                    style: TextStyle(fontSize: 16)))
            : ListView.builder(
                itemCount: _fileDetails.length,
                itemBuilder: (context, index) {
                  final file = _fileDetails[index]['file'] as File;
                  final modified = _fileDetails[index]['modified'] as DateTime;
                  final size = _fileDetails[index]['size'] as String;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        tileColor: Colors.white,
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Colors.deepPurple, size: 30),
                        title: Text(file.path.split('/').last,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('${_formatDateTime(modified)} • $size'),
                        onTap: () => _showFileOptions(file),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Tooltip(
              message: 'Pick from Gallery',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size.fromRadius(35),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFCreationPage(
                        source: ImageSource.gallery,
                        onPdfCreated: (file) {
                          _loadFiles();
                        },
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.photo_library,
                    size: 28, color: Colors.white),
              ),
            ),
            Tooltip(
              message: 'Take Photo',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size.fromRadius(35),
                ),
                onPressed: _pickImageFromCamera,
                child:
                    const Icon(Icons.camera_alt, size: 28, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
