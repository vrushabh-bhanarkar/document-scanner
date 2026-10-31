import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../services/revenuecat_service.dart';
import '../services/subscription_service.dart';
import '../widgets/ad_config.dart';

/// State management provider for App Subscriptions and RevenueCat In-App Purchases
class SubscriptionProvider extends ChangeNotifier {
  final RevenueCatService _rcService = RevenueCatService.instance;
  final SubscriptionService _legacyService = SubscriptionService();

  CustomerInfo? _customerInfo;
  Offerings? _offerings;

  bool _isSubscribed = false;
  String? _userEmail;
  DateTime? _lastPaymentDate;
  bool _isProcessing = false;
  String? _errorMessage;

  // Getters
  bool get isSubscribed => _isSubscribed;
  bool get isPro => _isSubscribed;
  bool get isLoggedIn => (_userEmail ?? '').isNotEmpty;
  String? get userEmail => _userEmail;
  DateTime? get lastPaymentDate => _lastPaymentDate;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;

  /// Package getters for the 3 products: Lifetime, Yearly, Monthly
  Package? get lifetimePackage {
    final current = _offerings?.current;
    if (current == null) return null;
    return current.lifetime ??
        _findPackage(current, RevenueCatService.productLifetime, PackageType.lifetime);
  }

  Package? get yearlyPackage {
    final current = _offerings?.current;
    if (current == null) return null;
    return current.annual ??
        _findPackage(current, RevenueCatService.productYearly, PackageType.annual);
  }

  Package? get monthlyPackage {
    final current = _offerings?.current;
    if (current == null) return null;
    return current.monthly ??
        _findPackage(current, RevenueCatService.productMonthly, PackageType.monthly);
  }

  Package? _findPackage(Offering offering, String identifier, PackageType type) {
    for (final pkg in offering.availablePackages) {
      if (pkg.identifier == identifier ||
          pkg.storeProduct.identifier == identifier ||
          pkg.packageType == type) {
        return pkg;
      }
    }
    return null;
  }

  /// Initialize and load customer information, offerings, and register listeners
  Future<void> load() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ensure RevenueCat SDK is configured
      await _rcService.init();

      // 2. Load email from storage/auth
      _userEmail = await _legacyService.getLoggedInEmail();

      // 3. Register real-time CustomerInfo update listener
      _rcService.addCustomerInfoUpdateListener((customerInfo) {
        debugPrint('[SubscriptionProvider] CustomerInfo updated via listener');
        _updateCustomerInfo(customerInfo);
      });

      // 4. Fetch initial CustomerInfo
      _customerInfo = await _rcService.getCustomerInfo();
      _isSubscribed = _rcService.isProActive(_customerInfo);

      // Fallback to local storage if offline and was previously subscribed
      if (!_isSubscribed) {
        final legacySub = await _legacyService.isSubscribed();
        if (legacySub) {
          _isSubscribed = true;
        }
      }

      _lastPaymentDate = await _legacyService.getLastPaymentDate();

      // 5. Fetch Offerings (Lifetime, Yearly, Monthly)
      _offerings = await _rcService.getOfferings();

      _syncAdState();
    } catch (e) {
      debugPrint('[SubscriptionProvider] Error loading subscription info: $e');
      _errorMessage = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Internal helper to update state whenever CustomerInfo changes
  void _updateCustomerInfo(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    _isSubscribed = _rcService.isProActive(customerInfo);
    _syncAdState();
    notifyListeners();
  }

  /// Purchase selected package (Lifetime, Yearly, Monthly)
  Future<bool> purchase(Package package) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await _rcService.purchasePackage(package);
      if (info != null) {
        _customerInfo = info;
        _isSubscribed = _rcService.isProActive(info);
        _lastPaymentDate = DateTime.now();

        await _legacyService.setSubscribed(_isSubscribed);
        await _legacyService.setLastPaymentDate(_lastPaymentDate!);

        _syncAdState();
        notifyListeners();
        return _isSubscribed;
      }
      return false; // User cancelled
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Restore purchases from app store
  Future<bool> restorePurchases() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await _rcService.restorePurchases();
      if (info != null) {
        _customerInfo = info;
        _isSubscribed = _rcService.isProActive(info);
        await _legacyService.setSubscribed(_isSubscribed);
        _syncAdState();
        notifyListeners();
        return _isSubscribed;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Present RevenueCat Paywall UI
  Future<PaywallResult> presentPaywall() async {
    final result = await _rcService.presentPaywall();
    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await refreshCustomerInfo();
    }
    return result;
  }

  /// Present RevenueCat Paywall only if 'void_version_pro' entitlement is missing
  Future<PaywallResult> presentPaywallIfNeeded() async {
    final result = await _rcService.presentPaywallIfNeeded();
    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await refreshCustomerInfo();
    }
    return result;
  }

  /// Present RevenueCat Customer Center (subscription management, cancellations, refunds)
  Future<void> presentCustomerCenter() async {
    await _rcService.presentCustomerCenter();
    await refreshCustomerInfo();
  }

  /// Refresh latest CustomerInfo from RevenueCat servers
  Future<void> refreshCustomerInfo() async {
    _customerInfo = await _rcService.getCustomerInfo();
    _isSubscribed = _rcService.isProActive(_customerInfo);
    await _legacyService.setSubscribed(_isSubscribed);
    _syncAdState();
    notifyListeners();
  }

  /// Identify user on login
  Future<void> login(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }

    _isProcessing = true;
    notifyListeners();

    try {
      await _legacyService.setLoggedInEmail(trimmedEmail);
      _userEmail = trimmedEmail;

      // Identify user in RevenueCat
      final info = await _rcService.logIn(trimmedEmail);
      if (info != null) {
        _updateCustomerInfo(info);
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Reset user state on logout
  Future<void> logout() async {
    _isProcessing = true;
    notifyListeners();

    try {
      await _legacyService.clearSubscriptionData();
      _userEmail = null;
      _lastPaymentDate = null;
      _isSubscribed = false;

      // Reset user in RevenueCat
      final info = await _rcService.logOut();
      if (info != null) {
        _updateCustomerInfo(info);
      } else {
        _syncAdState();
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Manually set subscribed state (e.g. testing)
  Future<void> setSubscribed(bool value) async {
    _isSubscribed = value;
    if (!value) {
      _lastPaymentDate = null;
    }
    await _legacyService.setSubscribed(value);
    _syncAdState();
    notifyListeners();
  }

  void _syncAdState() {
    AdConfig.enableAds = !_isSubscribed;
  }
}
