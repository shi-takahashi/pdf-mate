import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/pdf_viewmodel.dart';
import 'dart:io';
import 'pdf_simple_selector_screen.dart';
import '../widgets/banner_ad_widget.dart';

class PdfMergeScreen extends StatefulWidget {
  @override
  _PdfMergeScreenState createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends State<PdfMergeScreen> {
  List<File> selectedFiles = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF結合'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.merge,
                  size: 48,
                  color: Colors.green[700],
                ),
                SizedBox(height: 8),
                Text(
                  'PDF結合',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '複数のPDFファイルを選択して1つに結合します',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          selectedFiles.isEmpty 
            ? _buildEmptyState()
            : _buildFileList(),
          
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _selectFiles,
                          icon: Icon(Icons.add),
                          label: Text(selectedFiles.isEmpty ? 'PDFファイルを選択' : 'ファイルを追加'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (selectedFiles.isNotEmpty) ...[
                      SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _clearFiles,
                          icon: Icon(Icons.clear_all),
                          label: Text('クリア'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[600],
                            side: BorderSide(color: Colors.red[600]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (selectedFiles.length >= 2) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _mergeFiles,
                      icon: isLoading 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.merge),
                      label: Text(isLoading ? '結合中...' : 'PDF結合実行'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'PDFファイルが選択されていません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '「PDFファイルを選択」ボタンを押して\n結合したいPDFファイルを選択してください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return Container(
      height: 300,
      child: ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: selectedFiles.length,
      itemBuilder: (context, index) {
        final file = selectedFiles[index];
        final fileName = file.path.split('/').last;
        
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.picture_as_pdf,
              color: Colors.red[600],
              size: 32,
            ),
            title: Text(
              fileName,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index > 0)
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_up),
                    onPressed: () => _moveFile(index, index - 1),
                    tooltip: '上に移動',
                  ),
                if (index < selectedFiles.length - 1)
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down),
                    onPressed: () => _moveFile(index, index + 1),
                    tooltip: '下に移動',
                  ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFile(index),
                  tooltip: '削除',
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Future<void> _selectFiles() async {
    // Androidの場合、初回のみヒントを表示（SharedPreferencesで管理）
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenHint = prefs.getBool('pdf_picker_hint_shown') ?? false;
      
      if (!hasSeenHint) {
        await _showFilePickerHint();
        await prefs.setBool('pdf_picker_hint_shown', true);
      }
    }
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        dialogTitle: 'PDFファイルを選択',
      );

      if (result != null) {
        List<File> validPdfFiles = [];
        List<String> invalidFiles = [];
        
        for (String? path in result.paths) {
          if (path != null) {
            File file = File(path);
            String fileName = file.path.split('/').last.toLowerCase();
            
            if (fileName.endsWith('.pdf')) {
              if (!selectedFiles.any((f) => f.path == file.path)) {
                validPdfFiles.add(file);
              }
            } else {
              invalidFiles.add(file.path.split('/').last);
            }
          }
        }
        
        if (validPdfFiles.isNotEmpty) {
          setState(() {
            selectedFiles.addAll(validPdfFiles);
          });
        }
        
        if (invalidFiles.isNotEmpty) {
          _showErrorDialog(
            'ファイル形式エラー', 
            'PDFファイルのみ選択できます。\n\n無効なファイル:\n${invalidFiles.join('\n')}'
          );
        }
      }
    } catch (e) {
      _showErrorDialog('ファイル選択エラー', 'ファイルの選択中にエラーが発生しました。');
    }
  }
  
  Future<void> _showFilePickerHint() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
            SizedBox(width: 8),
            Text('ヒント'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDFファイルの選び方:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 「最近」タブでPDFを探すと見つけやすいです'),
            Text('• ダウンロードフォルダをチェック'),
            Text('• 虫眼鏡アイコンで「pdf」を検索'),
            Text('• 複数ファイルを一度に選択できます'),
            SizedBox(height: 8),
            Text('• 戻るボタン（◁）でキャンセルできます', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK、わかりました'),
          ),
        ],
      ),
    );
  }

  void _moveFile(int oldIndex, int newIndex) {
    setState(() {
      final file = selectedFiles.removeAt(oldIndex);
      selectedFiles.insert(newIndex, file);
    });
  }

  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  void _clearFiles() {
    setState(() {
      selectedFiles.clear();
    });
  }

  Future<void> _mergeFiles() async {
    if (selectedFiles.length < 2) {
      _showErrorDialog('エラー', '結合するには2つ以上のPDFファイルが必要です。');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final viewModel = Provider.of<PdfViewModel>(context, listen: false);
      
      // 保存とシェアのオプションを選択
      bool? shareOption = await _showSaveOptionsDialog();
      if (shareOption == null) {
        // キャンセルされた場合
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      String savedPath = await viewModel.mergepdfs(selectedFiles, shareAfterSave: shareOption);
      
      _showSuccessDialog(savedPath, shareOption);
    } catch (e) {
      _showErrorDialog('結合エラー', 'PDF結合中にエラーが発生しました: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

  Future<bool?> _showSaveOptionsDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('保存オプション'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('結合したPDFファイルをどのように処理しますか？'),
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

  void _showSuccessDialog(String savedPath, bool wasShared) {
    String fileName = savedPath.split('/').last;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('結合完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDFファイルが正常に結合されました。'),
            SizedBox(height: 8),
            Text(
              'ファイル名: $fileName',
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
                await Share.shareXFiles(
                  [XFile(savedPath)],
                  text: '結合されたPDFファイル',
                );
              },
              child: Text('今すぐシェア'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                selectedFiles.clear();
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}