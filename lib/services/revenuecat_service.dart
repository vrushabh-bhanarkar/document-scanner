import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Service responsible for managing RevenueCat SDK configuration,
/// entitlements, offerings, purchases, paywalls, and Customer Center.
class RevenueCatService {
  RevenueCatService._internal();
  static final RevenueCatService instance = RevenueCatService._internal();

  /// RevenueCat API key provided for Void Version app
  static const String apiKey = 'test_JWwLfRsLfTqxhyUzsNwAjqLrLAf';

  /// Primary entitlement identifier for Pro features
  static const String entitlementId = 'void_version_pro';

  /// Product Identifiers configured in RevenueCat & App Stores
  static const String productLifetime = 'lifetime';
  static const String productYearly = 'yearly';
  static const String productMonthly = 'monthly';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the RevenueCat Purchases SDK
  Future<void> init({String? appUserId}) async {
    if (_isInitialized) return;

    try {
      // Set debug log level in development
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      } else {
        await Purchases.setLogLevel(LogLevel.info);
      }

      // Configure SDK with PurchasesConfiguration
      final configuration = PurchasesConfiguration(apiKey);
      if (appUserId != null && appUserId.isNotEmpty) {
        configuration.appUserID = appUserId;
      }

      await Purchases.configure(configuration);
      _isInitialized = true;
      debugPrint('[RevenueCat] SDK initialized successfully with entitlement: $entitlementId');
    } catch (e, stack) {
      debugPrint('[RevenueCat] Error initializing RevenueCat SDK: $e\n$stack');
      rethrow;
    }
  }

  /// Get current customer info from RevenueCat cache / network
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      _handlePlatformException('getCustomerInfo', e);
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] Unexpected error in getCustomerInfo: $e');
      return null;
    }
  }

  /// Check whether the customer has active 'void_version_pro' entitlement
  bool isProActive(CustomerInfo? customerInfo) {
    if (customerInfo == null) return false;
    final entitlement = customerInfo.entitlements.all[entitlementId];
    return entitlement != null && entitlement.isActive;
  }

  /// Fetch offerings configured in RevenueCat dashboard
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        debugPrint('[RevenueCat] No current offering found in dashboard.');
      }
      return offerings;
    } on PlatformException catch (e) {
      _handlePlatformException('getOfferings', e);
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] Unexpected error in getOfferings: $e');
      return null;
    }
  }

  /// Purchase a package using the modern Purchases.purchase(PurchaseParams.package) API
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      debugPrint('[RevenueCat] Purchasing package: ${package.identifier} (${package.packageType})');
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      return purchaseResult.customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[RevenueCat] User cancelled purchase.');
        return null; // Graceful cancellation
      }
      _handlePlatformException('purchasePackage', e);
      rethrow;
    }
  }

  /// Restore previous purchases (e.g. after reinstalling or switching devices)
  Future<CustomerInfo?> restorePurchases() async {
    try {
      debugPrint('[RevenueCat] Restoring purchases...');
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo;
    } on PlatformException catch (e) {
      _handlePlatformException('restorePurchases', e);
      rethrow;
    }
  }

  /// Identify user when they log in to your app
  Future<CustomerInfo?> logIn(String appUserId) async {
    try {
      debugPrint('[RevenueCat] Logging in user: $appUserId');
      final logInResult = await Purchases.logIn(appUserId);
      return logInResult.customerInfo;
    } on PlatformException catch (e) {
      _handlePlatformException('logIn', e);
      return null;
    }
  }

  /// Reset to anonymous user when user logs out
  Future<CustomerInfo?> logOut() async {
    try {
      debugPrint('[RevenueCat] Logging out user');
      return await Purchases.logOut();
    } on PlatformException catch (e) {
      _handlePlatformException('logOut', e);
      return null;
    }
  }

  /// Present RevenueCat Native Paywall modal
  Future<PaywallResult> presentPaywall({Offering? offering}) async {
    try {
      debugPrint('[RevenueCatUI] Presenting Paywall...');
      return await RevenueCatUI.presentPaywall(offering: offering);
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting paywall: $e');
      return PaywallResult.error;
    }
  }

  /// Present RevenueCat Paywall only if 'void_version_pro' entitlement is missing
  Future<PaywallResult> presentPaywallIfNeeded({Offering? offering}) async {
    try {
      debugPrint('[RevenueCatUI] Presenting Paywall if needed for: $entitlementId');
      return await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
        offering: offering,
      );
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting paywall if needed: $e');
      return PaywallResult.error;
    }
  }

  /// Present RevenueCat Customer Center (for managing active subscriptions,
  /// cancellation surveys, refund requests, and support)
  Future<void> presentCustomerCenter() async {
    try {
      debugPrint('[RevenueCatUI] Presenting Customer Center...');
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting Customer Center: $e');
    }
  }

  /// Listen for customer info updates (e.g., subscription renewal, expiration, purchase in background)
  void addCustomerInfoUpdateListener(Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Centralized PlatformException error logging and description
  void _handlePlatformException(String method, PlatformException e) {
    final errorCode = PurchasesErrorHelper.getErrorCode(e);
    debugPrint('[RevenueCat] PlatformException in $method: code=$errorCode, message=${e.message}, details=${e.details}');
  }
}
