import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/pdf_viewmodel.dart';

class PdfCompressScreen extends StatefulWidget {
  @override
  _PdfCompressScreenState createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends State<PdfCompressScreen> {
  File? _selectedPdf;
  String _selectedPdfName = '';
  int _originalSize = 0;
  
  // 圧縮オプション
  String _compressionLevel = 'normal'; // 'low', 'normal', 'high'

  Future<void> _selectPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: null,
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        
        // PDFファイルかチェック
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          _showErrorDialog('ファイル形式エラー', 'PDFファイルを選択してください。');
          return;
        }
        
        setState(() {
          _selectedPdf = file;
          _selectedPdfName = fileName;
          _originalSize = file.lengthSync();
        });
      }
    } catch (e) {
      _showErrorDialog('ファイル選択エラー', 'ファイルの選択中にエラーが発生しました。');
    }
  }

  Future<void> _compressPdf() async {
    if (_selectedPdf == null) return;

    // 保存とシェアのオプションを選択
    bool? shareOption = await _showSaveOptionsDialog();
    if (shareOption == null) {
      // キャンセルされた場合
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final viewModel = Provider.of<PdfViewModel>(context, listen: false);
    
    try {
      String savedPath = await viewModel.compressPdf(
        _selectedPdf!, 
        _compressionLevel, 
        shareAfterSave: shareOption
      );
      
      Navigator.pop(context); // ローディングダイアログを閉じる
      
      // 圧縮後のファイルサイズを取得
      int compressedSize = File(savedPath).lengthSync();
      double compressionRatio = ((_originalSize - compressedSize) / _originalSize * 100);
      
      // 圧縮効果が悪い場合（サイズが増加した場合）の警告
      if (compressionRatio < 0) {
        bool? shouldKeep = await _showCompressionWarningDialog(compressedSize, compressionRatio);
        if (shouldKeep != true) {
          // ユーザーが削除を選択した場合、圧縮ファイルを削除
          File(savedPath).deleteSync();
          return;
        }
      }
      
      _showSuccessDialog(savedPath, shareOption, compressedSize, compressionRatio);
      
      // リセット
      setState(() {
        _selectedPdf = null;
        _selectedPdfName = '';
        _originalSize = 0;
      });
    } catch (e) {
      Navigator.pop(context); // ローディングダイアログを閉じる
      
      _showErrorDialog('圧縮エラー', 'PDF圧縮中にエラーが発生しました: ${e.toString()}');
    }
  }

  Future<bool?> _showSaveOptionsDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('保存オプション'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('圧縮されたPDFファイルをどのように処理しますか？'),
            SizedBox(height: 16),
            Text(
              Platform.isAndroid 
                ? '※ ファイルは「ダウンロード」フォルダに保存されます'
                : '※ ファイルはアプリ内に保存されます',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('保存のみ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('保存してシェア'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String savedPath, bool wasShared, int compressedSize, double compressionRatio) {
    String fileName = savedPath.split('/').last;
    String originalSizeStr = (_originalSize / 1024).toStringAsFixed(1);
    String compressedSizeStr = (compressedSize / 1024).toStringAsFixed(1);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('圧縮完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDFファイルが正常に圧縮されました。'),
            SizedBox(height: 8),
            Text(
              'ファイル名: $fileName',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('圧縮結果:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('元のサイズ: ${originalSizeStr} KB'),
                  Text('圧縮後: ${compressedSizeStr} KB'),
                  Text(
                    '削減率: ${compressionRatio.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: compressionRatio > 0 ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              Platform.isAndroid
                ? '保存場所: ダウンロードフォルダ'
                : '保存場所: アプリ内ストレージ',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (!wasShared && Platform.isAndroid) ...[
              SizedBox(height: 8),
              Text(
                'ファイルマネージャーの「ダウンロード」フォルダで確認できます。',
                style: TextStyle(fontSize: 12, color: Colors.blue[600]),
              ),
            ],
          ],
        ),
        actions: [
          if (!wasShared) 
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Share.shareXFiles(
                  [XFile(savedPath)],
                  text: 'PDFを圧縮しました（${compressionRatio.toStringAsFixed(1)}%削減）',
                );
              },
              child: Text('今すぐシェア'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showCompressionWarningDialog(int compressedSize, double compressionRatio) async {
    String originalSizeStr = (_originalSize / 1024).toStringAsFixed(1);
    String compressedSizeStr = (compressedSize / 1024).toStringAsFixed(1);
    double increaseRatio = compressionRatio.abs();
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('圧縮効果が期待できませんでした'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('圧縮処理により、ファイルサイズが大きくなりました：'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('元のサイズ: ${originalSizeStr} KB'),
                  Text('圧縮後: ${compressedSizeStr} KB'),
                  Text(
                    '増加: +${increaseRatio.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'このPDFは既に最適化されているか、圧縮に適さない内容のようです。',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('削除する'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('保存する'),
          ),
        ],
      ),
    );
  }

  String _getCompressionDescription() {
    switch (_compressionLevel) {
      case 'low':
        return '軽微な圧縮を行います。品質を最優先に保ちます。';
      case 'high':
        return '最大の圧縮を行います。ファイルサイズを最小限に抑えます。';
      default:
        return 'バランスの取れた圧縮を行います。品質とサイズの両方を考慮します。';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF圧縮'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PDFファイル選択セクション
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '圧縮するPDFファイルを選択',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _selectPdf,
                      icon: Icon(Icons.file_upload),
                      label: Text(_selectedPdf == null ? 'PDFを選択' : 'PDFを変更'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    if (_selectedPdf != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedPdfName,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'ファイルサイズ: ${(_originalSize / 1024).toStringAsFixed(1)} KB',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // 圧縮オプションセクション
            if (_selectedPdf != null) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '圧縮レベルを選択',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      
                      RadioListTile<String>(
                        title: Text('軽圧縮'),
                        subtitle: Text('品質優先（削減効果は低め）'),
                        value: 'low',
                        groupValue: _compressionLevel,
                        onChanged: (value) {
                          setState(() {
                            _compressionLevel = value!;
                          });
                        },
                      ),
                      
                      RadioListTile<String>(
                        title: Text('標準圧縮'),
                        subtitle: Text('バランス重視（推奨）'),
                        value: 'normal',
                        groupValue: _compressionLevel,
                        onChanged: (value) {
                          setState(() {
                            _compressionLevel = value!;
                          });
                        },
                      ),
                      
                      RadioListTile<String>(
                        title: Text('高圧縮'),
                        subtitle: Text('サイズ優先（品質は若干低下）'),
                        value: 'high',
                        groupValue: _compressionLevel,
                        onChanged: (value) {
                          setState(() {
                            _compressionLevel = value!;
                          });
                        },
                      ),
                      
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getCompressionDescription(),
                                style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 圧縮に関する注意書き
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '圧縮効果について',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• 画像が多いPDFや既に最適化されたPDFでは効果が限定的です\n'
                              '• テキスト中心のPDFでより高い効果が期待できます\n'
                              '• 場合によっては元のサイズより大きくなることがあります',
                              style: TextStyle(fontSize: 13, color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 圧縮実行ボタン
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _selectedPdf != null ? _compressPdf : null,
                icon: Icon(Icons.compress),
                label: Text('PDFを圧縮'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}