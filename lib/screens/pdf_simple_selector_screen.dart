import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PdfSimpleSelectorScreen extends StatefulWidget {
  @override
  _PdfSimpleSelectorScreenState createState() => _PdfSimpleSelectorScreenState();
}

class _PdfSimpleSelectorScreenState extends State<PdfSimpleSelectorScreen> {
  List<File> recentPdfFiles = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDFファイルを選択'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 説明セクション
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 48,
                  color: Colors.green[700],
                ),
                SizedBox(height: 8),
                Text(
                  'PDFファイルを選択してください',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '複数のPDFファイルを選択できます',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // メインの選択ボタン
                  Container(
                    width: double.infinity,
                    height: 120,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _selectPdfFiles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'PDFファイルを選択',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'タップしてファイルを選択',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // ヒントセクション
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 24),
                            SizedBox(width: 8),
                            Text(
                              'ヒント',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• 「最近」タブでPDFファイルを探すと見つけやすいです',
                          style: TextStyle(color: Colors.amber[800]),
                        ),
                        Text(
                          '• ダウンロードフォルダをチェックしてみてください',
                          style: TextStyle(color: Colors.amber[800]),
                        ),
                        Text(
                          '• 複数のPDFファイルを一度に選択できます',
                          style: TextStyle(color: Colors.amber[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPdfFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        dialogTitle: 'PDFファイルを選択',
      );

      if (result != null) {
        List<File> selectedFiles = [];
        for (String? path in result.paths) {
          if (path != null) {
            selectedFiles.add(File(path));
          }
        }
        
        if (selectedFiles.isNotEmpty) {
          Navigator.pop(context, selectedFiles);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ファイル選択中にエラーが発生しました'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}