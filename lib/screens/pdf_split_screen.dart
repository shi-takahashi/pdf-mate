import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/pdf_viewmodel.dart';
import '../widgets/banner_ad_widget.dart';

class PdfSplitScreen extends StatefulWidget {
  @override
  _PdfSplitScreenState createState() => _PdfSplitScreenState();
}

class _PdfSplitScreenState extends State<PdfSplitScreen> {
  File? _selectedPdf;
  String _selectedPdfName = '';
  int _totalPages = 0;
  
  // 分割オプション
  String _splitMode = 'pages'; // 'pages' or 'range'
  int _pagesPerSplit = 1;
  int _startPage = 1;
  int _endPage = 1;

  Future<void> _selectPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowedExtensions: null,
    );

    if (result != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
        _selectedPdfName = result.files.single.name;
      });
      
      // PDFのページ数を取得
      final viewModel = Provider.of<PdfViewModel>(context, listen: false);
      int pageCount = await viewModel.getPdfPageCount(_selectedPdf!);
      setState(() {
        _totalPages = pageCount;
        _endPage = pageCount;
      });
    }
  }

  Future<void> _splitPdf() async {
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
      List<String> savedPaths;
      if (_splitMode == 'pages') {
        // ページ数ごとに分割
        savedPaths = await viewModel.splitPdfByPages(_selectedPdf!, _pagesPerSplit, shareAfterSave: shareOption);
      } else {
        // ページ範囲で分割
        String savedPath = await viewModel.splitPdfByRange(_selectedPdf!, _startPage, _endPage, shareAfterSave: shareOption);
        savedPaths = [savedPath];
      }
      
      Navigator.pop(context); // ローディングダイアログを閉じる
      
      _showSuccessDialog(savedPaths, shareOption);
      
      // リセット
      setState(() {
        _selectedPdf = null;
        _selectedPdfName = '';
        _totalPages = 0;
        _pagesPerSplit = 1;
        _startPage = 1;
        _endPage = 1;
      });
    } catch (e) {
      Navigator.pop(context); // ローディングダイアログを閉じる
      
      _showErrorDialog('分割エラー', 'PDF分割中にエラーが発生しました: ${e.toString()}');
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
            Text('分割したPDFファイルをどのように処理しますか？'),
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

  void _showSuccessDialog(List<String> savedPaths, bool wasShared) {
    String message = _splitMode == 'pages' 
      ? 'PDFを${savedPaths.length}個のファイルに分割しました。'
      : 'PDFのページ$_startPage-$_endPageを抽出しました。';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('分割完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 8),
            Text(
              'ファイル数: ${savedPaths.length}個',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                List<XFile> xFiles = savedPaths.map((path) => XFile(path)).toList();
                await Share.shareXFiles(
                  xFiles,
                  text: _splitMode == 'pages' 
                    ? 'PDFを${savedPaths.length}個のファイルに分割しました'
                    : 'PDFのページ$_startPage-$_endPageを抽出しました',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF分割'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                      '分割するPDFファイルを選択',
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
                                        '総ページ数: $_totalPages',
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
            
            // 分割オプションセクション
            if (_selectedPdf != null) ...[
              if (_totalPages <= 1) ...[
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '分割できません',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'このPDFは1ページのみなので分割できません。\n複数ページのPDFファイルを選択してください。',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '分割方法を選択',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      
                      // 分割モード選択
                      RadioListTile<String>(
                        title: Text('ページ数で分割'),
                        subtitle: Text('指定したページ数ごとに分割します'),
                        value: 'pages',
                        groupValue: _splitMode,
                        onChanged: (value) {
                          setState(() {
                            _splitMode = value!;
                          });
                        },
                      ),
                      
                      if (_splitMode == 'pages') ...[
                        Padding(
                          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Row(
                            children: [
                              Text('分割するページ数: '),
                              SizedBox(width: 16),
                              Expanded(
                                child: Slider(
                                  value: _pagesPerSplit.toDouble(),
                                  min: 1,
                                  max: _totalPages.toDouble(),
                                  divisions: _totalPages > 1 ? _totalPages - 1 : null,
                                  label: _pagesPerSplit.toString(),
                                  onChanged: _totalPages > 1 ? (value) {
                                    setState(() {
                                      _pagesPerSplit = value.toInt();
                                    });
                                  } : null,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                '$_pagesPerSplit',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      RadioListTile<String>(
                        title: Text('ページ範囲で抽出'),
                        subtitle: Text('指定した範囲のページを抽出します'),
                        value: 'range',
                        groupValue: _splitMode,
                        onChanged: (value) {
                          setState(() {
                            _splitMode = value!;
                          });
                        },
                      ),
                      
                      if (_splitMode == 'range') ...[
                        Padding(
                          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text('開始ページ: '),
                                  Expanded(
                                    child: Slider(
                                      value: _startPage.toDouble(),
                                      min: 1,
                                      max: _totalPages.toDouble(),
                                      divisions: _totalPages > 1 ? _totalPages - 1 : null,
                                      label: _startPage.toString(),
                                      onChanged: _totalPages > 1 ? (value) {
                                        setState(() {
                                          _startPage = value.toInt();
                                          if (_startPage > _endPage) {
                                            _endPage = _startPage;
                                          }
                                        });
                                      } : null,
                                    ),
                                  ),
                                  Text(
                                    '$_startPage',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('終了ページ: '),
                                  Expanded(
                                    child: Slider(
                                      value: _endPage.toDouble(),
                                      min: _startPage.toDouble(),
                                      max: _totalPages.toDouble(),
                                      divisions: (_totalPages - _startPage) > 0 ? (_totalPages - _startPage) : null,
                                      label: _endPage.toString(),
                                      onChanged: (_totalPages - _startPage) > 0 ? (value) {
                                        setState(() {
                                          _endPage = value.toInt();
                                        });
                                      } : null,
                                    ),
                                  ),
                                  Text(
                                    '$_endPage',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              
              // 分割実行ボタン
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _selectedPdf != null && _totalPages > 1 ? _splitPdf : null,
                icon: Icon(Icons.content_cut),
                label: Text('PDFを分割'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ],
            ],
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
}