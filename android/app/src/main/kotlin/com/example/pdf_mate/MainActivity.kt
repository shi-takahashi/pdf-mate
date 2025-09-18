package com.example.pdf_mate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.itextpdf.kernel.pdf.PdfDocument
import com.itextpdf.kernel.pdf.PdfReader
import com.itextpdf.kernel.pdf.PdfWriter
import com.itextpdf.kernel.utils.PdfMerger
import com.itextpdf.kernel.pdf.canvas.PdfCanvas
import com.itextpdf.kernel.geom.Rectangle
import com.itextpdf.kernel.geom.PageSize
import com.itextpdf.kernel.pdf.WriterProperties
import android.content.Context
import android.content.Intent
import android.os.Environment
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pdf_merge_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "mergePdfs" -> {
                    val filePaths = call.argument<List<String>>("filePaths")
                    val shareAfterSave = call.argument<Boolean>("shareAfterSave") ?: false
                    
                    if (filePaths != null) {
                        try {
                            val mergedPath = mergePdfsNative(filePaths, shareAfterSave)
                            result.success(mergedPath)
                        } catch (e: Exception) {
                            result.error("MERGE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "File paths not provided", null)
                    }
                }
                "splitPdfByPages" -> {
                    val filePath = call.argument<String>("filePath")
                    val pagesPerSplit = call.argument<Int>("pagesPerSplit")
                    val shareAfterSave = call.argument<Boolean>("shareAfterSave") ?: false
                    
                    if (filePath != null && pagesPerSplit != null) {
                        try {
                            val savedPaths = splitPdfByPagesNative(filePath, pagesPerSplit, shareAfterSave)
                            result.success(savedPaths)
                        } catch (e: Exception) {
                            result.error("SPLIT_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "File path or pages per split not provided", null)
                    }
                }
                "splitPdfByRange" -> {
                    val filePath = call.argument<String>("filePath")
                    val startPage = call.argument<Int>("startPage")
                    val endPage = call.argument<Int>("endPage")
                    val shareAfterSave = call.argument<Boolean>("shareAfterSave") ?: false
                    
                    if (filePath != null && startPage != null && endPage != null) {
                        try {
                            val savedPath = splitPdfByRangeNative(filePath, startPage, endPage, shareAfterSave)
                            result.success(savedPath)
                        } catch (e: Exception) {
                            result.error("SPLIT_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "File path or page range not provided", null)
                    }
                }
                "compressPdf" -> {
                    val filePath = call.argument<String>("filePath")
                    val compressionLevel = call.argument<String>("compressionLevel")
                    val shareAfterSave = call.argument<Boolean>("shareAfterSave") ?: false
                    
                    if (filePath != null && compressionLevel != null) {
                        try {
                            val savedPath = compressPdfNative(filePath, compressionLevel, shareAfterSave)
                            result.success(savedPath)
                        } catch (e: Exception) {
                            result.error("COMPRESS_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "File path or compression level not provided", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun mergePdfsNative(filePaths: List<String>, shareAfterSave: Boolean): String {
        // 出力ファイルのパスを設定
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val timestamp = System.currentTimeMillis()
        val outputFile = File(downloadsDir, "merged_pdf_$timestamp.pdf")
        
        // iTextを使用してPDF結合
        val writer = PdfWriter(FileOutputStream(outputFile))
        val mergedDocument = PdfDocument(writer)
        val merger = PdfMerger(mergedDocument)
        
        // 各PDFファイルを結合
        for (filePath in filePaths) {
            val file = File(filePath)
            if (file.exists()) {
                val reader = PdfReader(file.absolutePath)
                val sourceDocument = PdfDocument(reader)
                
                // 全ページを結合
                merger.merge(sourceDocument, 1, sourceDocument.numberOfPages)
                
                sourceDocument.close()
            }
        }
        
        mergedDocument.close()
        
        // 共有処理
        if (shareAfterSave) {
            shareFile(outputFile)
        }
        
        return outputFile.absolutePath
    }
    
    private fun shareFile(file: File) {
        try {
            val uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                file
            )
            
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            
            startActivity(Intent.createChooser(intent, "結合されたPDFファイル"))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun shareFiles(files: List<File>, title: String) {
        try {
            val uris = ArrayList<android.net.Uri>()
            for (file in files) {
                val uri = FileProvider.getUriForFile(
                    this,
                    "${packageName}.fileprovider",
                    file
                )
                uris.add(uri)
            }
            
            val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = "application/pdf"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            
            startActivity(Intent.createChooser(intent, title))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun splitPdfByPagesNative(filePath: String, pagesPerSplit: Int, shareAfterSave: Boolean): List<String> {
        val file = File(filePath)
        val baseName = file.nameWithoutExtension
        val timestamp = System.currentTimeMillis()
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        
        val reader = PdfReader(filePath)
        val sourceDocument = PdfDocument(reader)
        val totalPages = sourceDocument.numberOfPages
        
        val splitFiles = ArrayList<File>()
        var currentPage = 1
        var splitCount = 1
        
        while (currentPage <= totalPages) {
            val outputFile = File(downloadsDir, "${baseName}_split_${splitCount}_$timestamp.pdf")
            val writer = PdfWriter(FileOutputStream(outputFile))
            val splitDocument = PdfDocument(writer)
            
            var pagesAdded = 0
            while (pagesAdded < pagesPerSplit && currentPage <= totalPages) {
                // ページをコピー（元のサイズを保持）
                val sourcePage = sourceDocument.getPage(currentPage)
                val pageRect = sourcePage.pageSize
                val pageSize = PageSize(pageRect)
                val newPage = splitDocument.addNewPage(pageSize)
                
                // ページの内容をコピー
                val canvas = PdfCanvas(newPage)
                val pageCopy = sourcePage.copyAsFormXObject(splitDocument)
                canvas.addXObjectAt(pageCopy, 0f, 0f)
                
                currentPage++
                pagesAdded++
            }
            
            splitDocument.close()
            splitFiles.add(outputFile)
            splitCount++
        }
        
        sourceDocument.close()
        
        // 分割されたファイルをシェア
        if (shareAfterSave) {
            shareFiles(splitFiles, "PDFを${splitFiles.size}個のファイルに分割しました")
        }
        
        return splitFiles.map { it.absolutePath }
    }
    
    private fun splitPdfByRangeNative(filePath: String, startPage: Int, endPage: Int, shareAfterSave: Boolean): String {
        val file = File(filePath)
        val baseName = file.nameWithoutExtension
        val timestamp = System.currentTimeMillis()
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        
        val outputFile = File(downloadsDir, "${baseName}_pages_${startPage}-${endPage}_$timestamp.pdf")
        
        val reader = PdfReader(filePath)
        val sourceDocument = PdfDocument(reader)
        val writer = PdfWriter(FileOutputStream(outputFile))
        val extractedDocument = PdfDocument(writer)
        
        // 指定された範囲のページをコピー
        for (i in startPage..endPage) {
            if (i <= sourceDocument.numberOfPages) {
                // ページをコピー（元のサイズを保持）
                val sourcePage = sourceDocument.getPage(i)
                val pageRect = sourcePage.pageSize
                val pageSize = PageSize(pageRect)
                val newPage = extractedDocument.addNewPage(pageSize)
                
                // ページの内容をコピー
                val canvas = PdfCanvas(newPage)
                val pageCopy = sourcePage.copyAsFormXObject(extractedDocument)
                canvas.addXObjectAt(pageCopy, 0f, 0f)
            }
        }
        
        extractedDocument.close()
        sourceDocument.close()
        
        // 抽出されたファイルをシェア
        if (shareAfterSave) {
            shareFile(outputFile)
        }
        
        return outputFile.absolutePath
    }
    
    private fun compressPdfNative(filePath: String, compressionLevel: String, shareAfterSave: Boolean): String {
        val file = File(filePath)
        val baseName = file.nameWithoutExtension
        val timestamp = System.currentTimeMillis()
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        
        val outputFile = File(downloadsDir, "${baseName}_compressed_$timestamp.pdf")
        
        // より積極的な圧縮設定
        val writerProperties = WriterProperties()
        
        when (compressionLevel) {
            "high" -> {
                writerProperties.setCompressionLevel(9) // 最大圧縮
                writerProperties.setFullCompressionMode(true) // フル圧縮モード
            }
            "low" -> {
                writerProperties.setCompressionLevel(3) // 軽圧縮
            }
            else -> { // "normal"
                writerProperties.setCompressionLevel(6) // 標準圧縮
                writerProperties.setFullCompressionMode(true) // フル圧縮モード
            }
        }
        
        val reader = PdfReader(filePath)
        val writer = PdfWriter(FileOutputStream(outputFile), writerProperties)
        val sourceDocument = PdfDocument(reader)
        val compressedDocument = PdfDocument(writer)
        
        try {
            // ページをコピー（より効率的な方法）
            sourceDocument.copyPagesTo(1, sourceDocument.numberOfPages, compressedDocument)
        } catch (e: Exception) {
            // フォールバック：手動でページをコピー
            for (i in 1..sourceDocument.numberOfPages) {
                val sourcePage = sourceDocument.getPage(i)
                val pageSize = sourcePage.pageSize
                val newPage = compressedDocument.addNewPage(PageSize(pageSize))
                
                // ページの内容をコピー
                val canvas = PdfCanvas(newPage)
                val pageCopy = sourcePage.copyAsFormXObject(compressedDocument)
                canvas.addXObjectAt(pageCopy, 0f, 0f)
            }
        }
        
        compressedDocument.close()
        sourceDocument.close()
        
        // 圧縮されたファイルをシェア
        if (shareAfterSave) {
            shareFile(outputFile)
        }
        
        return outputFile.absolutePath
    }
}
