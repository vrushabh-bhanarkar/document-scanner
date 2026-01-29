package com.sleekscan.documentscanner

import android.graphics.pdf.PdfRenderer
import android.graphics.Bitmap
import android.graphics.pdf.PdfDocument
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.FileInputStream
import android.content.Context
import io.flutter.plugin.common.MethodChannel

object PdfUtils {
    fun extractPdfPages(context: Context, pdfPath: String, scale: Double, result: MethodChannel.Result) {
        try {
            val pdfFile = File(pdfPath)
            if (!pdfFile.exists()) {
                result.error("FILE_NOT_FOUND", "PDF file not found", null)
                return
            }

            val fileDescriptor = ParcelFileDescriptor.open(pdfFile, ParcelFileDescriptor.MODE_READ_ONLY)
            val pdfRenderer = PdfRenderer(fileDescriptor)
            
            val extractedImages = mutableListOf<String>()
            val tempDir = File(context.cacheDir, "pdf_extracted_${UUID.randomUUID()}")
            tempDir.mkdirs()

            for (i in 0 until pdfRenderer.pageCount) {
                val page = pdfRenderer.openPage(i)
                val width = (page.width * scale).toInt()
                val height = (page.height * scale).toInt()
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                val imageFile = File(tempDir, "page_${i + 1}_${UUID.randomUUID()}.png")
                val outputStream = FileOutputStream(imageFile)
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                outputStream.close()
                extractedImages.add(imageFile.absolutePath)
                bitmap.recycle()
                page.close()
            }
            pdfRenderer.close()
            fileDescriptor.close()
            result.success(extractedImages)
        } catch (e: Exception) {
            result.error("PDF_EXTRACTION_ERROR", "Failed to extract PDF pages: ${e.message}", null)
        }
    }

    fun insertFileIntoDownloads(context: Context, filePath: String) {
        val file = File(filePath)
        if (!file.exists()) return
        val resolver = context.contentResolver
        val mimeType = when (file.extension.lowercase()) {
            "pdf" -> "application/pdf"
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            else -> "application/octet-stream"
        }
        val contentValues = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, file.name)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
        }
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Files.getContentUri("external")
        }
        val itemUri = resolver.insert(collection, contentValues)
        itemUri?.let { uri ->
            resolver.openOutputStream(uri)?.use { outStream ->
                FileInputStream(file).use { inStream ->
                    inStream.copyTo(outStream)
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentValues.clear()
                contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)
            }
        }
    }
} 