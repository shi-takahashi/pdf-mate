import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

class PdfFileSelectorScreen extends StatefulWidget {
  @override
  _PdfFileSelectorScreenState createState() => _PdfFileSelectorScreenState();
}

class _PdfFileSelectorScreenState extends State<PdfFileSelectorScreen> {
  List<File> pdfFiles = [];
  bool isLoading = true;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadFiles();
  }

  Future<void> _checkPermissionAndLoadFiles() async {
    // Android 用のストレージ権限をチェック
    if (Platform.isAndroid) {
      bool granted = false;
      
      // Android バージョンによって異なる権限処理
      if (await Permission.manageExternalStorage.isRestricted || 
          await Permission.manageExternalStorage.isDenied) {
        // Android 11以降: MANAGE_EXTERNAL_STORAGE権限を確認
        var manageStatus = await Permission.manageExternalStorage.status;
        
        if (!manageStatus.isGranted) {
          // 設定画面を開く説明ダイアログを表示
          bool? shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('ストレージアクセス権限'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDFファイルを検索するには、ストレージへのアクセス権限が必要です。',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 16),
                    Text('設定手順:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('1. 「設定を開く」ボタンをタップ'),
                    Text('2. 「権限」または「アプリの権限」をタップ'),
                    Text('3. 「ストレージ」または「ファイルとメディア」を探す'),
                    Text('4. 「すべてのファイルへのアクセスを許可」をONにする'),
                    Text('5. 戻るボタンでこのアプリに戻る'),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '設定後、自動的にPDFファイルの検索が始まります',
                              style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('設定を開く'),
                ),
              ],
            ),
          );
          
          if (shouldOpenSettings == true) {
            await openAppSettings();
            // ユーザーが設定から戻ってきた後、再度権限を確認
            Future.delayed(Duration(milliseconds: 500), () async {
              var newStatus = await Permission.manageExternalStorage.status;
              if (newStatus.isGranted) {
                setState(() {
                  hasPermission = true;
                });
                await _searchPdfFiles();
              }
            });
          }
          return;
        }
        
        granted = manageStatus.isGranted;
      } else {
        // Android 10以下: 通常のストレージ権限を確認
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        granted = status.isGranted;
      }
      
      setState(() {
        hasPermission = granted;
      });
      
      if (hasPermission) {
        await _searchPdfFiles();
      }
    }
  }

  Future<void> _searchPdfFiles() async {
    setState(() {
      isLoading = true;
    });

    List<File> foundFiles = [];
    
    // Androidの一般的なディレクトリを検索
    List<String> searchPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
      '/storage/emulated/0/Telegram/Telegram Documents',
    ];

    // 各ディレクトリでPDFファイルを検索
    for (String path in searchPaths) {
      try {
        Directory dir = Directory(path);
        if (await dir.exists()) {
          await _searchInDirectory(dir, foundFiles);
        }
      } catch (e) {
        print('Error searching in $path: $e');
      }
    }

    // アプリのドキュメントディレクトリも検索
    try {
      final appDir = await getApplicationDocumentsDirectory();
      await _searchInDirectory(appDir, foundFiles);
    } catch (e) {
      print('Error searching app directory: $e');
    }

    // ファイルを更新日時でソート（新しい順）
    foundFiles.sort((a, b) {
      try {
        return b.statSync().modified.compareTo(a.statSync().modified);
      } catch (e) {
        return 0;
      }
    });

    setState(() {
      pdfFiles = foundFiles;
      isLoading = false;
    });
  }

  Future<void> _searchInDirectory(Directory dir, List<File> foundFiles) async {
    try {
      List<FileSystemEntity> entities = dir.listSync(recursive: true, followLinks: false);
      
      for (FileSystemEntity entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          // 隠しファイルやシステムファイルをスキップ
          String fileName = entity.path.split('/').last;
          if (!fileName.startsWith('.')) {
            foundFiles.add(entity);
          }
        }
      }
    } catch (e) {
      // アクセス権限がないディレクトリはスキップ
      print('Error accessing directory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDFファイルを選択'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkPermissionAndLoadFiles,
            tooltip: '更新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!hasPermission) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'ストレージへのアクセス権限が必要です',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'PDFファイルを検索するため、\n端末内のファイルへのアクセスを許可してください',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkPermissionAndLoadFiles,
                icon: Icon(Icons.settings),
                label: Text('権限を設定する'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '設定から戻ったら、下のボタンを押してください',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: _checkPermissionAndLoadFiles,
                icon: Icon(Icons.refresh),
                label: Text('権限を再確認'),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDFファイルを検索中...'),
          ],
        ),
      );
    }

    if (pdfFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'PDFファイルが見つかりません',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'ダウンロードフォルダなどを確認してください',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.green[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green[700]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pdfFiles.length}個のPDFファイルが見つかりました',
                  style: TextStyle(color: Colors.green[700]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: pdfFiles.length,
            itemBuilder: (context, index) {
              final file = pdfFiles[index];
              final fileName = file.path.split('/').last;
              final fileSize = _getFileSize(file);
              final modifiedDate = _getModifiedDate(file);
              final directory = _getDirectory(file.path);

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red[600],
                    size: 40,
                  ),
                  title: Text(
                    fileName,
                    style: TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directory,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$fileSize • $modifiedDate',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context, [file]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return '不明';
    }
  }

  String _getModifiedDate(File file) {
    try {
      DateTime modified = file.statSync().modified;
      Duration difference = DateTime.now().difference(modified);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}分前';
        } else {
          return '${difference.inHours}時間前';
        }
      } else if (difference.inDays < 7) {
        return '${difference.inDays}日前';
      } else {
        return '${modified.year}/${modified.month}/${modified.day}';
      }
    } catch (e) {
      return '不明';
    }
  }

  String _getDirectory(String path) {
    List<String> parts = path.split('/');
    if (parts.contains('Download') || parts.contains('Downloads')) {
      return 'ダウンロード';
    } else if (parts.contains('Documents')) {
      return 'ドキュメント';
    } else if (parts.contains('WhatsApp')) {
      return 'WhatsApp';
    } else if (parts.contains('Telegram')) {
      return 'Telegram';
    } else if (parts.contains('DCIM')) {
      return 'カメラ';
    } else {
      // パスの最後から2番目のディレクトリ名を返す
      if (parts.length >= 2) {
        return parts[parts.length - 2];
      }
      return 'その他';
    }
  }
}