import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_service.dart';

class ScanQuotaService {
  static const _kGuestScanKey = 'guest_scan_count_v1';
  static const _kUserScanPrefix = 'user_scan_count_';
  static const _freeLimit = 5;

  final SubscriptionService _subscriptionService = SubscriptionService();

  Future<bool> canCreateDocument() async {
    final subscribed = await _subscriptionService.isSubscribed();
    if (subscribed) return true;

    final count = await getScanCount();
    return count < _freeLimit;
  }

  Future<int> getScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      return prefs.getInt('$_kUserScanPrefix${user.uid}') ?? 0;
    }
    return prefs.getInt(_kGuestScanKey) ?? 0;
  }

  Future<void> incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final key = '$_kUserScanPrefix${user.uid}';
      final current = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, current + 1);
      return;
    }
    final current = prefs.getInt(_kGuestScanKey) ?? 0;
    await prefs.setInt(_kGuestScanKey, current + 1);
  }

  Future<void> resetScanCountForUser() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      await prefs.remove('$_kUserScanPrefix${user.uid}');
    } else {
      await prefs.remove(_kGuestScanKey);
    }
  }
}
