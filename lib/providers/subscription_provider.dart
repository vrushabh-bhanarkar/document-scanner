import 'package:flutter/foundation.dart';
import '../services/subscription_service.dart';
import '../widgets/ad_config.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();
  bool _isSubscribed = false;
  String? _userEmail;
  DateTime? _lastPaymentDate;
  bool _isProcessing = false;

  bool get isSubscribed => _isSubscribed;
  bool get isLoggedIn => (_userEmail ?? '').isNotEmpty;
  String? get userEmail => _userEmail;
  DateTime? get lastPaymentDate => _lastPaymentDate;
  bool get isProcessing => _isProcessing;

  Future<void> load() async {
    _isSubscribed = await _service.isSubscribed();
    _userEmail = await _service.getLoggedInEmail();
    _lastPaymentDate = await _service.getLastPaymentDate();
    _syncAdState();
    notifyListeners();
  }

  Future<void> setSubscribed(bool value) async {
    _isSubscribed = value;
    if (!value) {
      _lastPaymentDate = null;
    }
    await _service.setSubscribed(value);
    _syncAdState();
    notifyListeners();
  }

  Future<void> login(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }

    _isProcessing = true;
    notifyListeners();

    await _service.setLoggedInEmail(trimmedEmail);
    _userEmail = trimmedEmail;

    _isProcessing = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isProcessing = true;
    notifyListeners();

    await _service.clearSubscriptionData();
    _userEmail = null;
    _lastPaymentDate = null;
    _isSubscribed = false;
    _syncAdState();

    _isProcessing = false;
    notifyListeners();
  }

  Future<void> payAndSubscribe() async {
    if (!isLoggedIn) {
      throw StateError('You need to log in before subscribing.');
    }

    _isProcessing = true;
    notifyListeners();

    final now = DateTime.now();
    _isSubscribed = true;
    _lastPaymentDate = now;

    await _service.setSubscribed(true);
    await _service.setLastPaymentDate(now);

    _syncAdState();

    _isProcessing = false;
    notifyListeners();
  }

  void _syncAdState() {
    // Disable ads for subscribed users
    AdConfig.enableAds = !_isSubscribed;
  }
}
