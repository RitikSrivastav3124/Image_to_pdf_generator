// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pdf_converter/presentation/viewmodels/add_docs_viewmodel.dart';
import 'package:pdf_converter/presentation/views/office_to_pdf/office_to_pdf_preview_view.dart';

class AddDocsView extends StatefulWidget {
  const AddDocsView({super.key});

  @override
  State<AddDocsView> createState() => _AddDocsViewState();
}

class _AddDocsViewState extends State<AddDocsView> {
  final AddDocsViewModel _viewModel = AddDocsViewModel();

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String> _fileName() async {
    if (!mounted) return _viewModel.pdfFileName;
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
                _viewModel.pdfFileName = value;
                Navigator.pop(context);
              },
              child: const Text("Create PDF")),
        ],
      ),
    );
    return _viewModel.pdfFileName;
  }

  Future<void> _pickOfficeFile() async {
    try {
      final picked = await _viewModel.pickOfficeFile(context);

      if (!picked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected")),
        );
        return;
      }

      final pdfName = await _fileName();
      final pdfFile = await _viewModel.convertSelectedFile(pdfName);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfficeToPdfPreviewView(
            pdfFile: pdfFile,
          ),
        ),
      );
    } catch (e) {
      _viewModel.stopLoading();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
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
                onTap: _viewModel.isLoading ? null : _pickOfficeFile,
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
                          child: _viewModel.isLoading
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
                            _viewModel.isLoading
                                ? "Converting..."
                                : _viewModel.selectedFile != null
                                    ? _viewModel.selectedFile!.path
                                        .split('/')
                                        .last
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
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
