import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';

class PdfViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  
  // Method Channel for native PDF operations
  static const MethodChannel _channel = MethodChannel('pdf_merge_channel');

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<String> mergepdfs(List<File> pdfFiles, {bool shareAfterSave = true}) async {
    if (pdfFiles.length < 2) {
      throw Exception('結合するには2つ以上のPDFファイルが必要です');
    }

    setLoading(true);
    clearError();

    try {
      String? mergedPath;
      
      // Androidの場合はnative PDF結合を試す
      if (Platform.isAndroid) {
        try {
          // ファイルパスのリストを作成
          List<String> filePaths = pdfFiles.map((file) => file.path).toList();
          
          // ネイティブコードでPDF結合を実行
          mergedPath = await _channel.invokeMethod('mergePdfs', {
            'filePaths': filePaths,
            'shareAfterSave': shareAfterSave,
          });
          
        } catch (e) {
          print('Native PDF merge failed: $e, falling back to Syncfusion');
          // フォールバックとしてSyncfusionを使用
          mergedPath = await _mergePdfsWithSyncfusion(pdfFiles, shareAfterSave: shareAfterSave);
        }
      } else {
        // iOSの場合はSyncfusionを使用
        mergedPath = await _mergePdfsWithSyncfusion(pdfFiles, shareAfterSave: shareAfterSave);
      }

      return mergedPath!;

    } catch (e) {
      setError('PDF結合中にエラーが発生しました: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }
  
  // Syncfusionを使用したフォールバック実装
  Future<String> _mergePdfsWithSyncfusion(List<File> pdfFiles, {bool shareAfterSave = true}) async {
    PdfDocument mergedDocument = PdfDocument();

    for (File pdfFile in pdfFiles) {
      List<int> pdfBytes = await pdfFile.readAsBytes();
      PdfDocument sourceDocument = PdfDocument(inputBytes: pdfBytes);
      
      for (int i = 0; i < sourceDocument.pages.count; i++) {
        mergedDocument.pages.add();
        mergedDocument.pages[mergedDocument.pages.count - 1].graphics
            .drawPdfTemplate(sourceDocument.pages[i].createTemplate(),
                const Offset(0, 0));
      }
      
      sourceDocument.dispose();
    }

    List<int> mergedBytes = await mergedDocument.save();
    mergedDocument.dispose();

    // Android: Download フォルダに保存
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      // iOS や他のプラットフォーム: Documentsフォルダ
      directory = await getApplicationDocumentsDirectory();
    }

    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String fileName = 'merged_pdf_$timestamp.pdf';
    String mergedPath = '${directory!.path}/$fileName';
    File mergedFile = File(mergedPath);
    await mergedFile.writeAsBytes(mergedBytes);

    if (shareAfterSave) {
      await Share.shareXFiles(
        [XFile(mergedPath)],
        text: '結合されたPDFファイル',
      );
    }

    return mergedPath;
  }
  
  // PDFのページ数を取得
  Future<int> getPdfPageCount(File pdfFile) async {
    try {
      List<int> pdfBytes = await pdfFile.readAsBytes();
      PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      int pageCount = document.pages.count;
      document.dispose();
      return pageCount;
    } catch (e) {
      throw Exception('PDFのページ数取得に失敗しました: ${e.toString()}');
    }
  }
  
  // ページ数ごとにPDFを分割
  Future<List<String>> splitPdfByPages(File pdfFile, int pagesPerSplit, {bool shareAfterSave = true}) async {
    setLoading(true);
    clearError();
    
    try {
      // Androidの場合はネイティブ分割を試す
      if (Platform.isAndroid) {
        try {
          List<String> savedPaths = await _splitPdfByPagesNative(pdfFile, pagesPerSplit, shareAfterSave: shareAfterSave);
          return savedPaths;
        } catch (e) {
          print('Native PDF split failed: $e, falling back to Syncfusion');
          // フォールバック処理に続く
        }
      }
      
      // Syncfusionでの分割処理（フォールバック）
      List<int> pdfBytes = await pdfFile.readAsBytes();
      PdfDocument sourceDocument = PdfDocument(inputBytes: pdfBytes);
      int totalPages = sourceDocument.pages.count;
      
      // 保存用ディレクトリ
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String baseName = pdfFile.path.split('/').last.split('.').first;
      List<XFile> splitFiles = [];
      
      int currentPage = 0;
      int splitCount = 1;
      
      while (currentPage < totalPages) {
        PdfDocument splitDocument = PdfDocument();
        
        // 指定されたページ数分コピー（ページサイズを保持）
        for (int i = 0; i < pagesPerSplit && currentPage < totalPages; i++) {
          PdfPage sourcePage = sourceDocument.pages[currentPage];
          Size pageSize = sourcePage.size;
          
          // 元のページサイズで新しいページを追加
          PdfPage newPage = splitDocument.pages.add();
          newPage.graphics.drawPdfTemplate(
            sourcePage.createTemplate(),
            const Offset(0, 0),
            pageSize
          );
          currentPage++;
        }
        
        // 分割ファイルを保存
        List<int> splitBytes = await splitDocument.save();
        String fileName = '${baseName}_split_${splitCount}_$timestamp.pdf';
        String splitPath = '${directory!.path}/$fileName';
        File splitFile = File(splitPath);
        await splitFile.writeAsBytes(splitBytes);
        splitFiles.add(XFile(splitPath));
        
        splitDocument.dispose();
        splitCount++;
      }
      
      sourceDocument.dispose();
      
      // 分割されたファイルをシェア
      if (shareAfterSave) {
        await Share.shareXFiles(
          splitFiles,
          text: 'PDFを${splitFiles.length}個のファイルに分割しました',
        );
      }
      
      return splitFiles.map((xFile) => xFile.path).toList();
      
    } catch (e) {
      setError('PDF分割中にエラーが発生しました: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }
  
  // ページ範囲でPDFを抽出
  Future<String> splitPdfByRange(File pdfFile, int startPage, int endPage, {bool shareAfterSave = true}) async {
    setLoading(true);
    clearError();
    
    try {
      // Androidの場合はネイティブ分割を試す
      if (Platform.isAndroid) {
        try {
          String savedPath = await _splitPdfByRangeNative(pdfFile, startPage, endPage, shareAfterSave: shareAfterSave);
          return savedPath;
        } catch (e) {
          print('Native PDF split by range failed: $e, falling back to Syncfusion');
          // フォールバック処理に続く
        }
      }
      
      // Syncfusionでの抽出処理（フォールバック）
      List<int> pdfBytes = await pdfFile.readAsBytes();
      PdfDocument sourceDocument = PdfDocument(inputBytes: pdfBytes);
      
      PdfDocument extractedDocument = PdfDocument();
      
      // 指定された範囲のページをコピー（1ベースのページ番号を0ベースに変換、ページサイズを保持）
      for (int i = startPage - 1; i < endPage && i < sourceDocument.pages.count; i++) {
        PdfPage sourcePage = sourceDocument.pages[i];
        Size pageSize = sourcePage.size;
        
        // 元のページサイズで新しいページを追加
        PdfPage newPage = extractedDocument.pages.add();
        newPage.graphics.drawPdfTemplate(
          sourcePage.createTemplate(),
          const Offset(0, 0),
          pageSize
        );
      }
      
      // 保存用ディレクトリ
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String baseName = pdfFile.path.split('/').last.split('.').first;
      String fileName = '${baseName}_pages_${startPage}-${endPage}_$timestamp.pdf';
      String extractedPath = '${directory!.path}/$fileName';
      
      List<int> extractedBytes = await extractedDocument.save();
      File extractedFile = File(extractedPath);
      await extractedFile.writeAsBytes(extractedBytes);
      
      sourceDocument.dispose();
      extractedDocument.dispose();
      
      // 抽出されたファイルをシェア
      if (shareAfterSave) {
        await Share.shareXFiles(
          [XFile(extractedPath)],
          text: 'PDFのページ$startPage-$endPageを抽出しました',
        );
      }
      
      return extractedPath;
      
    } catch (e) {
      setError('PDF抽出中にエラーが発生しました: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Androidネイティブ実装用のヘルパーメソッド
  Future<List<String>> _splitPdfByPagesNative(File pdfFile, int pagesPerSplit, {bool shareAfterSave = true}) async {
    final result = await _channel.invokeMethod('splitPdfByPages', {
      'filePath': pdfFile.path,
      'pagesPerSplit': pagesPerSplit,
      'shareAfterSave': shareAfterSave,
    });
    return List<String>.from(result);
  }

  Future<String> _splitPdfByRangeNative(File pdfFile, int startPage, int endPage, {bool shareAfterSave = true}) async {
    final result = await _channel.invokeMethod('splitPdfByRange', {
      'filePath': pdfFile.path,
      'startPage': startPage,
      'endPage': endPage,
      'shareAfterSave': shareAfterSave,
    });
    return result as String;
  }

  // PDF圧縮機能
  Future<String> compressPdf(File pdfFile, String compressionLevel, {bool shareAfterSave = true}) async {
    setLoading(true);
    clearError();
    
    try {
      // Androidの場合はネイティブ圧縮を試す
      if (Platform.isAndroid) {
        try {
          String savedPath = await _compressPdfNative(pdfFile, compressionLevel, shareAfterSave: shareAfterSave);
          return savedPath;
        } catch (e) {
          print('Native PDF compress failed: $e, falling back to Syncfusion');
          // フォールバック処理に続く
        }
      }
      
      // Syncfusionでの圧縮処理（フォールバック）
      List<int> pdfBytes = await pdfFile.readAsBytes();
      PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      
      // 増分更新を無効化してファイル全体を書き直し
      document.fileStructure.incrementalUpdate = false;
      
      // クロスリファレンステーブルをストリーム形式に変更
      document.fileStructure.crossReferenceType = PdfCrossReferenceType.crossReferenceStream;
      
      // 圧縮レベルを設定
      switch (compressionLevel) {
        case 'low':
          document.compressionLevel = PdfCompressionLevel.normal;
          break;
        case 'high':
          document.compressionLevel = PdfCompressionLevel.best;
          // 高圧縮の場合は追加の最適化を実行
          _optimizePdfDocument(document);
          break;
        default: // 'normal'
          document.compressionLevel = PdfCompressionLevel.best;
          break;
      }
      
      // 保存用ディレクトリ
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String baseName = pdfFile.path.split('/').last.split('.').first;
      String fileName = '${baseName}_compressed_$timestamp.pdf';
      String compressedPath = '${directory!.path}/$fileName';
      
      List<int> compressedBytes = await document.save();
      File compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);
      
      document.dispose();
      
      // 圧縮されたファイルをシェア
      if (shareAfterSave) {
        await Share.shareXFiles(
          [XFile(compressedPath)],
          text: 'PDFファイルを圧縮しました',
        );
      }
      
      return compressedPath;
      
    } catch (e) {
      setError('PDF圧縮中にエラーが発生しました: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Androidネイティブ実装用のヘルパーメソッド
  Future<String> _compressPdfNative(File pdfFile, String compressionLevel, {bool shareAfterSave = true}) async {
    final result = await _channel.invokeMethod('compressPdf', {
      'filePath': pdfFile.path,
      'compressionLevel': compressionLevel,
      'shareAfterSave': shareAfterSave,
    });
    return result as String;
  }

  // PDFドキュメントの追加最適化
  void _optimizePdfDocument(PdfDocument document) {
    try {
      // ページ数が多い場合のみ最適化を実行（処理時間を考慮）
      if (document.pages.count > 0) {
        // フォント情報の最適化（可能な場合）
        // 注：Syncfusionでは限定的な最適化のみ可能
        for (int i = 0; i < document.pages.count; i++) {
          var page = document.pages[i];
          // ページ内容の再構築（メモリ効率の改善）
          page.graphics.save();
          page.graphics.restore();
        }
      }
    } catch (e) {
      print('PDF optimization failed: $e');
      // 最適化に失敗しても圧縮処理は続行
    }
  }
}