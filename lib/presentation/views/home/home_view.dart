// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf_converter/presentation/viewmodels/home_viewmodel.dart';
import 'package:pdf_converter/presentation/views/pdf_options/pdf_options_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeViewModel _viewModel = HomeViewModel();

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      await _viewModel.loadFiles();
    } catch (e) {
      if (mounted) _showSnackBar('Failed to load files: $e');
    }
  }

  void _openPdf(File file) {
    _viewModel.openPdf(file);
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
              try {
                await _viewModel.renamePdf(file, newName);
                if (newName.isNotEmpty) {
                  _showSnackBar('Renamed to $newName.pdf');
                }
              } catch (e) {
                if (mounted) _showSnackBar('Rename failed: $e');
              } finally {
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          )
        ],
      ),
    );
  }

  Future<void> _sharePdf(File file) async {
    try {
      await _viewModel.sharePdf(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  Future<void> _deletePdf(File file) async {
    try {
      await _viewModel.deletePdf(file);
      if (!mounted) return;
      _showSnackBar('PDF Deleted Successfully');
    } catch (e) {
      if (mounted) _showSnackBar('Delete failed: $e');
    }
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

  Future<void> _downloadPdf(File file) async {
    try {
      final message = await _viewModel.downloadPdf(context, file);
      if (!mounted || message == null) return;
      _showSnackBar(message);
    } catch (e) {
      if (mounted) _showSnackBar('Download failed: $e');
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
                if (confirm == true) await _downloadPdf(file);
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
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
            child: _viewModel.fileDetails.isEmpty
                ? RefreshIndicator(
                    onRefresh: _loadFiles,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 60),
                        Center(
                            child: Text('No PDFs created yet.',
                                style: TextStyle(fontSize: 16))),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFiles,
                    child: ListView.builder(
                      itemCount: _viewModel.fileDetails.length,
                      itemBuilder: (context, index) {
                        final detail = _viewModel.fileDetails[index];
                        final file = detail.file;
                        final modified = detail.modified;
                        final size = detail.size;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                  '${_viewModel.formatDateTime(modified)} • $size'),
                              onTap: () => _showFileOptions(file),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PdfOptionsView()),
                  );
                },
                child: const Text(
                  "Create PDF",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
