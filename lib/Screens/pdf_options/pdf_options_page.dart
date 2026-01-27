import 'package:flutter/material.dart';
import 'package:pdf_converter/Screens/add_docs/add_docs_page.dart';
import 'package:pdf_converter/Screens/image_to_pdf/image_to_pdf_page.dart';

class PdfOptionsPage extends StatelessWidget {
  const PdfOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cardData = [
      {
        'title': 'Image to PDF',
        'icon': Icons.image,
        'color': Colors.deepPurpleAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ImageToPdfPage(),
            ),
          );
        },
      },
      {
        'title': 'DOC/PPT to PDF',
        'icon': Icons.description,
        'color': Colors.blueAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddDocsPage(),
            ),
          );
        },
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FB),
      appBar: AppBar(
        title: const Text(
          'Create PDF',
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
                "Choose a conversion type",
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
                  child: Icon(icon, size: 35),
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
