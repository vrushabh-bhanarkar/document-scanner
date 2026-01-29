package com.sleekscan.documentscanner

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pdf_renderer"
    private val MEDIA_SCANNER_CHANNEL = "document_scanner/media_scanner"
    private val FILES_CHANNEL = "com.sleekscan.documentscanner/files"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "extractPdfPages" -> {
                        val pdfPath = call.argument<String>("pdfPath")
                        val scale = call.argument<Double>("scale") ?: 2.0
                        if (pdfPath != null) {
                            PdfUtils.extractPdfPages(this, pdfPath, scale, result)
                        } else {
                            result.error("INVALID_ARGUMENTS", "PDF path is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return, MEDIA_SCANNER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanFile") {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        PdfUtils.insertFileIntoDownloads(this, path)
                        result.success(true)
                    } else {
                        result.error("NO_PATH", "No path provided", null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // Add MediaStore file save channel
        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return, FILES_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveFileToDownloads") {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    if (filePath != null && fileName != null) {
                        val success = saveFileToDownloads(filePath, fileName, mimeType)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "filePath and fileName required", null)
                    }
                } else if (call.method == "saveImageToGallery") {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName")
                    if (filePath != null && fileName != null) {
                        val success = saveImageToGallery(filePath, fileName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "filePath and fileName required", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, "listTile", ListTileNativeAdFactory(this)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        super.cleanUpFlutterEngine(flutterEngine)
    }

    // Add saveFileToDownloads implementation
    private fun saveFileToDownloads(filePath: String, fileName: String, mimeType: String): Boolean {
        return try {
            val resolver = applicationContext.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            uri?.let {
                resolver.openOutputStream(it).use { outputStream ->
                    FileInputStream(File(filePath)).use { inputStream ->
                        inputStream.copyTo(outputStream!!)
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentValues.clear()
                    contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                }
                true
            } ?: false
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    // Add saveImageToGallery implementation
    private fun saveImageToGallery(filePath: String, fileName: String): Boolean {
        return try {
            val resolver = applicationContext.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/DocumentScanner")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
            uri?.let {
                resolver.openOutputStream(it).use { outputStream ->
                    FileInputStream(File(filePath)).use { inputStream ->
                        inputStream.copyTo(outputStream!!)
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentValues.clear()
                    contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                }
                true
            } ?: false
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
} 