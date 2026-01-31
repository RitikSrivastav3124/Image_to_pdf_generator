import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_converter/Controllers/permission_controller.dart';

import 'package:pdf_converter/Screens/office-to-pdf/office_to_pdf_preview.dart';

class AddDocsPage extends StatefulWidget {
  const AddDocsPage({super.key});

  @override
  State<AddDocsPage> createState() => _AddDocsPageState();
}

class _AddDocsPageState extends State<AddDocsPage> {
  String pdfFileName = "My File";
  File? selectedFile;
  bool isLoading = false;
  Controllers controllers = Controllers();

  ///   BACKEND CALL (Office → PDF)
  /// Returns the converted PDF file
  Future<File> _convertOfficeToPdf(File officeFile, String pdfName) async {
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String> _fileName() async {
    if (!mounted) return pdfFileName;
    final controller = TextEditingController(text: pdfFileName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter PDF File Name"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "MyDocument"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  _showSnackBar("File name cannot be empty!");
                  return;
                }
                pdfFileName = value;
                Navigator.pop(context);
              },
              child: const Text("Create PDF")),
        ],
      ),
    );
    return pdfFileName;
  }

  ///  PICK OFFICE FILE

  Future<void> _pickOfficeFile() async {
    try {
      final permission = await controllers.checkStoragePermission(context);
      if (!permission) return;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx', 'ppt', 'pptx'],
      );

      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected")),
        );
        return;
      }
      final picked = result.files.single;
      setState(() {
        selectedFile = File(picked.path!);
        isLoading = true;
      });

      ///  CONVERT USING BACKEND
      final pdfName = await _fileName();
      final pdfFile = await _convertOfficeToPdf(selectedFile!, pdfName);

      setState(() => isLoading = false);

      ///  PREVIEW REAL PDF

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfficeToPdfPreview(
            pdfFile: pdfFile,
          ),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 241, 251),
      appBar: AppBar(
        title: const Text(
          'Office to PDF',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: const Color.fromARGB(255, 126, 83, 244),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : _pickOfficeFile,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 126, 83, 244),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(
                              Icons.note_add_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        isLoading
                            ? "Converting..."
                            : selectedFile != null
                                ? selectedFile!.path.split('/').last
                                : "Select your document",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
