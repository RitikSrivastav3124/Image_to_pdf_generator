import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf_converter/Screens/Home/home.dart';
import 'dart:io';

import 'package:pdf_converter/Screens/image_to_pdf/pdf_creation_page.dart';

class ImageToPdfPage extends StatefulWidget {
  const ImageToPdfPage({super.key});

  @override
  State<ImageToPdfPage> createState() => _ImageToPdfPageState();
}

class _ImageToPdfPageState extends State<ImageToPdfPage> {
  List<File> selectedImages = [];

  Future<void> _pickFromGallery() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFCreationPage(
          source: ImageSource.gallery,
          onPdfCreated: (file) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFCreationPage(
          source: ImageSource.camera,
          onPdfCreated: (file) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardData = [
      {
        'title': 'Pick from Camera',
        'icon': Icons.camera_alt_rounded,
        'color': Colors.deepPurpleAccent,
        'onTap': _pickFromCamera,
      },
      {
        'title': 'Pick from Gallery',
        'icon': Icons.photo_library_rounded,
        'color': Colors.blueAccent,
        'onTap': _pickFromGallery,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FB),
      appBar: AppBar(
        title: const Text(
          'Image to PDF',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: const Color(0xFF7E53F4),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Select images to convert into PDF",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              ...cardData.map((item) => _buildOptionCard(
                    title: item['title'] as String,
                    icon: item['icon'] as IconData,
                    color: item['color'] as Color,
                    onTap: item['onTap'] as VoidCallback,
                  )),
              const SizedBox(height: 40),

              // If images selected, show preview count
              if (selectedImages.isNotEmpty)
                Column(
                  children: [
                    Text(
                      "${selectedImages.length} image(s) selected",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7E53F4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                      label: const Text(
                        "Convert to PDF",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PDFCreationPage(
                              source: ImageSource.gallery,
                              onPdfCreated: (file) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomePage()),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.black, size: 35),
                ),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.black45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
