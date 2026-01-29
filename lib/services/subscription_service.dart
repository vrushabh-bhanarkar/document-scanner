import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static const _kSubscribedKey = 'is_subscribed_v1';
  static const _kUserEmailKey = 'user_email_v1';
  static const _kLastPaymentKey = 'last_payment_ts_v1';

  Future<bool> isSubscribed() async {
    // First try RevenueCat (Purchases) for entitlement info
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.active.isNotEmpty) {
        return true;
      }
    } catch (e) {
      // ignore and fallback to local prefs
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSubscribedKey) ?? false;
  }

  Future<void> setSubscribed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSubscribedKey, value);
  }

  Future<String?> getLoggedInEmail() async {
    // Prefer Firebase Auth email when available
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null && user.email!.isNotEmpty) {
        return user.email;
      }
    } catch (e) {
      // ignore and fallback to prefs
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserEmailKey);
  }

  Future<void> setLoggedInEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null || email.isEmpty) {
      await prefs.remove(_kUserEmailKey);
      return;
    }
    await prefs.setString(_kUserEmailKey, email);
  }

  Future<DateTime?> getLastPaymentDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_kLastPaymentKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setLastPaymentDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastPaymentKey, date.millisecondsSinceEpoch);
  }

  Future<void> clearSubscriptionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSubscribedKey);
    await prefs.remove(_kUserEmailKey);
    await prefs.remove(_kLastPaymentKey);
  }
}
