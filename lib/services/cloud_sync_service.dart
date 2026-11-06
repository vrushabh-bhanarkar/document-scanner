import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'revenuecat_service.dart';

/// Pro-Only Cloud Sync Service
/// Syncs local scans to Supabase Storage ('user_scans') and database ('documents')
class CloudSyncService {
  /// Checks whether user has active 'pro_features' entitlement via RevenueCat
  Future<bool> checkIsPro() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      // Primary check: 'pro_features' entitlement per mission spec
      final hasProFeatures =
          customerInfo.entitlements.all['pro_features']?.isActive ?? false;
      if (hasProFeatures) return true;

      // Secondary check: RevenueCatService handler for fallback / legacy
      return RevenueCatService.instance.isProActive(customerInfo);
    } catch (e) {
      debugPrint('[CloudSyncService] Error checking Pro status: $e');
      return false;
    }
  }

  /// Pro-Only Feature: Sync document and OCR text to Supabase Storage & Database
  Future<Map<String, dynamic>> syncDocumentToCloud({
    required File pdfFile,
    required String title,
    required String extractedText,
  }) async {
    // 1. Verify user entitlement
    final isPro = await checkIsPro();
    if (!isPro) {
      throw Exception(
        'Cloud Sync is a Pro feature. Upgrade to SleekScan Pro to sync scans across devices.',
      );
    }

    if (!await pdfFile.exists()) {
      throw Exception('Scan file not found on local storage: ${pdfFile.path}');
    }

    // 2. Obtain Supabase Client & User ID
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final userId = currentUser?.id ?? 'offline_user_${DateTime.now().millisecondsSinceEpoch}';

    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedTitle.pdf';
    final storagePath = '$userId/$fileName';
    final fileSize = await pdfFile.length();

    // 3. Upload to Supabase Storage bucket 'user_scans'
    try {
      await supabase.storage.from('user_scans').upload(
            storagePath,
            pdfFile,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
    } catch (storageError) {
      debugPrint('[CloudSyncService] Storage upload error: $storageError');
      // If bucket does not exist or network error, rethrow informative message
      throw Exception('Failed to upload PDF to cloud storage: $storageError');
    }

    // 4. Insert metadata into Supabase 'documents' table
    try {
      final record = {
        'user_id': userId,
        'title': title,
        'storage_path': storagePath,
        'extracted_text': extractedText,
        'file_size_bytes': fileSize,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('documents')
          .insert(record)
          .select()
          .single();

      debugPrint('[CloudSyncService] Successfully synced scan: $title');
      return response;
    } catch (dbError) {
      debugPrint('[CloudSyncService] Database insert error: $dbError');
      throw Exception('Failed to register scan metadata in database: $dbError');
    }
  }
}
