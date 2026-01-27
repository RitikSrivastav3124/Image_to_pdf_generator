import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class OfficeToPdfPreview extends StatelessWidget {
  final File pdfFile;

  const OfficeToPdfPreview({super.key, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    final fileName = pdfFile.path.split('/').last;
    final fileSize = pdfFile.existsSync()
        ? "${(pdfFile.lengthSync() / 1024).toStringAsFixed(2)} KB"
        : "Calculating...";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FB),
      appBar: AppBar(
        title: const Text(
          "PDF Ready",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF7E53F4),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles(
                [XFile(pdfFile.path)],
                text: "Converted using PDF Converter App",
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf,
                    color: Colors.red, size: 40),
                title: Text(
                  fileName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(fileSize),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => OpenFile.open(pdfFile.path),
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              label: const Text("Open PDF",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("Done",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
