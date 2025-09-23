import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFCreationPage extends StatefulWidget {
  final Function(File) onPdfCreated;
  final ImageSource source;

  const PDFCreationPage({
    super.key,
    required this.onPdfCreated,
    required this.source,
  });

  @override
  State<PDFCreationPage> createState() => _PDFCreationPageState();
}

class _PDFCreationPageState extends State<PDFCreationPage> {
  final List<File> _images = [];
  String pdfFileName = "My File";

  // Pick images from gallery/camera
  Future<void> _pickImages(ImageSource source) async {
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final pickedImages = await picker.pickMultiImage();
        if (pickedImages.isNotEmpty) {
          setState(() {
            _images.addAll(pickedImages.map((x) => File(x.path)));
          });
          _fileNameDialog();
        }
      } else {
        bool pickAnother = true;
        while (pickAnother) {
          final pickedFile = await picker.pickImage(source: ImageSource.camera);
          if (pickedFile != null) {
            setState(() {
              _images.add(File(pickedFile.path));
            });
            pickAnother = await _cameraDialog();
          } else {
            pickAnother = false;
          }
        }
        if (_images.isNotEmpty) {
          _fileNameDialog();
        }
      }
    } catch (e) {
      _showSnackBar("Failed to pick images: $e");
    }
  }

  // Camera dialog for multiple captures
  Future<bool> _cameraDialog() async {
    if (!mounted) return false;
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Take Another Picture?"),
            content: const Text("Do you want to take another picture?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Finish")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Take Another")),
            ],
          ),
        ) ??
        false;
  }

  // File name dialog before creating PDF
  Future<void> _fileNameDialog() async {
    if (!mounted) return;
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
                _createPDF();
              },
              child: const Text("Create PDF")),
        ],
      ),
    );
  }

  // PDF creation logic
  Future<void> _createPDF() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final pdf = pw.Document();
      for (var image in _images) {
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

      final dir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory("${dir.path}/pdf_converter");
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final file = File("${pdfDir.path}/$pdfFileName.pdf");
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      Navigator.pop(context); // Close loader
      widget.onPdfCreated(file);
      Navigator.pop(context); // Go back
      _showSnackBar("PDF saved as $pdfFileName.pdf");
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader if error
        _showSnackBar("Failed to create PDF: $e");
      }
    }
  }

  // Snackbar utility
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Converter"),
        backgroundColor: const Color.fromARGB(255, 126, 83, 244),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: _images.isEmpty
            ? const Center(
                child: Text(
                  "No images selected.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : GridView.builder(
                itemCount: _images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_images[index], fit: BoxFit.cover),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 126, 83, 244),
        child: Icon(_images.isEmpty ? Icons.add_a_photo : Icons.picture_as_pdf),
        onPressed: () {
          if (_images.isEmpty) {
            _pickImages(widget.source);
          } else {
            _fileNameDialog();
          }
        },
      ),
    );
  }
}
