import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf_converter/presentation/viewmodels/pdf_creation_viewmodel.dart';
import 'package:pdf_converter/presentation/views/home/home_view.dart';

class PDFCreationView extends StatefulWidget {
  final Function(File) onPdfCreated;
  final ImageSource source;

  const PDFCreationView({
    super.key,
    required this.onPdfCreated,
    required this.source,
  });

  @override
  State<PDFCreationView> createState() => _PDFCreationViewState();
}

class _PDFCreationViewState extends State<PDFCreationView> {
  final PdfCreationViewModel _viewModel = PdfCreationViewModel();

  Future<void> _pickImages(ImageSource source) async {
    try {
      final shouldCreate = await _viewModel.pickImages(
        context,
        source,
        askTakeAnotherPicture: _cameraDialog,
      );
      if (shouldCreate) {
        _fileNameDialog();
      }
    } catch (e) {
      _showSnackBar("Failed to pick images: $e");
    }
  }

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

  Future<void> _fileNameDialog() async {
    if (!mounted) return;
    final controller = TextEditingController(text: _viewModel.pdfFileName);

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
                Navigator.pop(context);
                _createPDF(value);
              },
              child: const Text("Create PDF")),
        ],
      ),
    );
  }

  Future<void> _createPDF(String pdfFileName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final file = await _viewModel.createPdf(pdfFileName);

      if (!mounted) return;
      Navigator.pop(context); // Close loader
      widget.onPdfCreated(file);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
        (route) => false,
      );

      _showSnackBar("PDF saved as $pdfFileName.pdf");
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader if error
        _showSnackBar("Failed to create PDF: $e");
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("PDF Converter"),
            backgroundColor: const Color.fromARGB(255, 126, 83, 244),
            centerTitle: true,
          ),
          body: Container(
            padding: const EdgeInsets.all(16),
            child: _viewModel.images.isEmpty
                ? const Center(
                    child: Text(
                      "No images selected.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    itemCount: _viewModel.images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _viewModel.images[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 126, 83, 244),
            child: Icon(_viewModel.images.isEmpty
                ? Icons.add_a_photo
                : Icons.picture_as_pdf),
            onPressed: () {
              if (_viewModel.images.isEmpty) {
                _pickImages(widget.source);
              } else {
                _fileNameDialog();
              }
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
