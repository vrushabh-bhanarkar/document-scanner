import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'subscription_service.dart';

class CloudSyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Check Pro status via RevenueCat with local fallback
  Future<bool> checkIsPro() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasRCPro = customerInfo.entitlements.all['pro_features']?.isActive ?? false;
      if (hasRCPro) return true;
    } catch (_) {
      // Offline fallback
    }

    try {
      return await SubscriptionService().isSubscribed();
    } catch (_) {
      return false; // Fallback to free tier when offline
    }
  }

  /// Pro-Only Feature: Sync document and OCR text to Firebase Cloud (Storage + Firestore)
  Future<void> syncDocumentToCloud({
    required File pdfFile,
    required String title,
    required String extractedText,
  }) async {
    final isPro = await checkIsPro();
    if (!isPro) {
      throw Exception('Cloud Sync is a Pro feature. Upgrade to enable web access.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to your SleekScan account to sync.');
    }

    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedTitle.pdf';
    final storagePath = 'user_scans/${user.uid}/$fileName';

    // 1. Upload to Firebase Storage
    final storageRef = _storage.ref().child(storagePath);
    final uploadTask = await storageRef.putFile(
      pdfFile,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    final fileSize = await pdfFile.length();

    // 2. Insert record in Cloud Firestore for Web Portal access
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('documents')
        .add({
      'user_id': user.uid,
      'title': title,
      'storage_path': storagePath,
      'download_url': downloadUrl,
      'extracted_text': extractedText,
      'file_size_bytes': fileSize,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
