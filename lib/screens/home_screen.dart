import 'package:flutter/material.dart';
import 'pdf_merge_screen.dart';
import 'pdf_split_screen.dart';
import 'pdf_compress_screen.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Mate'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
            SizedBox(height: 40),
            Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Colors.blue[700],
            ),
            SizedBox(height: 24),
            Text(
              'PDFツール',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '使用したい機能を選択してください',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 60),
            _buildMenuButton(
              context,
              'PDF結合',
              '複数のPDFファイルを1つに結合',
              Icons.merge,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PdfMergeScreen()),
              ),
            ),
            SizedBox(height: 20),
            _buildMenuButton(
              context,
              'PDF分割',
              'PDFファイルをページごとに分割',
              Icons.content_cut,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PdfSplitScreen()),
              ),
            ),
            SizedBox(height: 20),
            _buildMenuButton(
              context,
              'PDF圧縮',
              'PDFファイルのサイズを小さくする',
              Icons.compress,
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PdfCompressScreen()),
              ),
            ),
                ],
              ),
            ),
          ),
          // バナー広告
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: const BannerAdWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          children: [
            Icon(icon, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature機能は準備中です'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }
}
