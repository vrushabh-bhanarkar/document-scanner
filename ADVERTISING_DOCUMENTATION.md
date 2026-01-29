# Advertising Implementation Documentation

## Overview
This document details all advertising placements in the Document Scanner app and explains how ads are controlled by the subscription system.

---

## Ad Types Implemented

### 1. **Banner Ads**
- **Widget:** `BannerAdWidget`
- **Location:** `lib/widgets/banner_ad_widget.dart`
- **Size:** Standard banner (320x50)
- **Behavior:** Always visible at bottom of screen when subscription is inactive

### 2. **Native Ads**
- **Widget:** `NativeAdWidget`
- **Location:** `lib/widgets/native_ad_widget.dart`
- **Size:** Custom (100px height)
- **Behavior:** Blends with app content, respects subscription status

### 3. **Interstitial Ads**
- **Helper:** `InterstitialAdHelper`
- **Location:** `lib/widgets/interstitial_ad_helper.dart`
- **Type:** Full-screen ads shown at strategic points
- **Behavior:** Non-intrusive, shown between major actions

---

## Ad Placements by Screen

### 🏠 **Home Screen** (`lib/views/home_screen.dart`)
**Ad Type:** Banner Ad  
**Location:** Bottom navigation bar  
**When Shown:** Always displayed when user is on home screen (if not subscribed)  
**User Impact:** Minimal - doesn't interfere with quick actions  
**Line:** ~113

```dart
bottomNavigationBar: const BannerAdWidget(),
```

---

### 📊 **Dashboard Screen** (`lib/views/dashboard_screen.dart`)
**Ad Type:** Native Ad  
**Location:** Between search bar and documents list  
**When Shown:** After user searches or views documents (if not subscribed)  
**User Impact:** Low - integrates naturally with content  
**Line:** ~145

```dart
// Native Ad
const Padding(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: NativeAdWidget(),
),
```

---

### 📄 **Create PDF Screen** (`lib/views/create_pdf_screen.dart`)

#### **Ad Type 1:** Native Ad
**Location:** PDF preview screen, after success message  
**When Shown:** When user previews generated PDF (if not subscribed)  
**User Impact:** Low - doesn't block save/share actions  
**Line:** ~2551

```dart
// Native Ad
const Padding(
  padding: EdgeInsets.all(16.0),
  child: NativeAdWidget(),
),
```

#### **Ad Type 2:** Interstitial Ad
**Location:** Before PDF generation starts  
**When Shown:** When user clicks "Generate PDF" button (if not subscribed)  
**User Impact:** Medium - brief delay before PDF creation  
**Line:** ~3453

```dart
InterstitialAdHelper.showInterstitialAd(
  onAdClosed: () async {
    // PDF generation logic...
  },
);
```

---

### 📁 **Document Management Screen** (`lib/views/document_management_screen.dart`)
**Ad Type:** Native Ad  
**Location:** Between page grid and bottom action buttons  
**When Shown:** When managing document pages (if not subscribed)  
**User Impact:** Low - positioned naturally  
**Line:** ~68

```dart
// Native Ad
const Padding(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: NativeAdWidget(),
),
```

---

### 👁️ **PDF Viewer Screen** (`lib/views/pdf_viewer_screen.dart`)

#### **Ad Type 1:** Banner Ad
**Location:** Bottom of screen  
**When Shown:** While viewing any PDF (if not subscribed)  
**User Impact:** Minimal - doesn't obscure PDF content  
**Line:** ~318

```dart
bottomNavigationBar: BannerAdWidget(),
```

#### **Ad Type 2:** Interstitial Ad
**Location:** After saving PDF successfully  
**When Shown:** After save confirmation (if not subscribed)  
**User Impact:** Low - shown after action completes  
**Line:** ~487

```dart
InterstitialAdHelper.showInterstitialAd(
  onAdClosed: () async {
    await _showPostSaveOptions(context, widget.pdfFile);
  },
);
```

---

## Subscription Control System

### How Ads are Disabled with Subscription

#### **1. Global Ad Control**
**File:** `lib/widgets/ad_config.dart`

```dart
class AdConfig {
  static bool enableAds = true;  // Controlled by subscription
  static bool enableNativeAds = false;
  static String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
}
```

- `enableAds`: Master switch controlled by `SubscriptionProvider`
- When user subscribes, this is set to `false`
- All ad widgets check this before loading

---

#### **2. Subscription Service**
**File:** `lib/services/subscription_service.dart`

```dart
class SubscriptionService {
  Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_subscribed_v1') ?? false;
  }
  
  Future<void> setSubscribed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_subscribed_v1', value);
  }
}
```

- Persists subscription state using `SharedPreferences`
- Survives app restarts
- Single source of truth for subscription status

---

#### **3. Subscription Provider**
**File:** `lib/providers/subscription_provider.dart`

```dart
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();
  bool _isSubscribed = false;

  bool get isSubscribed => _isSubscribed;

  Future<void> load() async {
    _isSubscribed = await _service.isSubscribed();
    AdConfig.enableAds = !_isSubscribed;  // 🔑 KEY LINE
    notifyListeners();
  }

  Future<void> setSubscribed(bool value) async {
    _isSubscribed = value;
    AdConfig.enableAds = !_isSubscribed;  // 🔑 KEY LINE
    await _service.setSubscribed(value);
    notifyListeners();
  }
}
```

**How it works:**
1. Provider loads at app startup (in `main.dart`)
2. Checks saved subscription status
3. Updates `AdConfig.enableAds` accordingly
4. When subscription changes, all ad widgets automatically react

---

#### **4. Ad Widget Checks**

**Native Ad Widget** (`lib/widgets/native_ad_widget.dart`):
```dart
@override
void initState() {
  super.initState();
  if (AdConfig.enableNativeAds && AdConfig.enableAds) {  // ✅ Double check
    _nativeAd = NativeAd(/* ... */);
  }
}

@override
Widget build(BuildContext context) {
  if (!AdConfig.enableNativeAds || !AdConfig.enableAds) {  // ✅ Hide if disabled
    return const SizedBox.shrink();
  }
  // Show ad...
}
```

**Interstitial Ad Helper** (`lib/widgets/interstitial_ad_helper.dart`):
```dart
static void showInterstitialAd({
  String? adUnitId,
  VoidCallback? onAdClosed,
}) {
  if (!AdConfig.enableAds) {  // ✅ Check before loading
    if (onAdClosed != null) onAdClosed();
    return;
  }
  // Load and show ad...
}
```

**Banner Ad Widget** (`lib/widgets/banner_ad_widget.dart`):
```dart
@override
void initState() {
  super.initState();
  if (AdConfig.enableAds) {  // ✅ Only initialize if enabled
    _loadBannerAd();
  }
}
```

---

## Subscription Purchase Flow

### 1. User Opens Subscription Screen
**Route:** `/subscription`  
**File:** `lib/views/subscription_screen.dart`

### 2. User Sees Current Status
- Shows "Free user" or "You are subscribed"
- Lists premium benefits

### 3. User Taps "Buy Subscription"
```dart
ElevatedButton(
  onPressed: sub.isSubscribed ? null : () async {
    // TODO: Integrate real payment (in_app_purchase)
    await sub.setSubscribed(true);  // Mock for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription activated (mock)'))
    );
  },
  child: const Text('Buy Subscription'),
)
```

### 4. Subscription Activates
**What happens:**
1. `SubscriptionProvider.setSubscribed(true)` called
2. Saves to `SharedPreferences`
3. Sets `AdConfig.enableAds = false`
4. Calls `notifyListeners()`
5. **All ads instantly stop loading/showing**

### 5. Premium Features Unlock
- ✅ HD camera mode enabled
- ✅ Watermark feature unlocked
- ✅ All ads removed

---

## Premium Feature Gating

### 🎥 **HD Camera Mode** (`lib/views/create_pdf_screen.dart`)
**Line:** ~3771

```dart
void _setCameraQuality(bool isHDMode) async {
  final sub = Provider.of<SubscriptionProvider>(context, listen: false);
  if (isHDMode && !sub.isSubscribed) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Premium feature'),
        content: const Text('HD mode is available for subscribed users only.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/subscription');
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
    return;
  }
  // Enable HD mode...
}
```

### 💧 **Watermark Feature** (`lib/views/watermark_screen.dart`)
**Line:** ~60

```dart
@override
Widget build(BuildContext context) {
  final sub = Provider.of<SubscriptionProvider>(context);
  if (!sub.isSubscribed) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Watermark')),
      body: Center(
        child: Column(
          children: [
            const Text('Watermark is a premium feature.'),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
              child: const Text('Subscribe to unlock'),
            ),
          ],
        ),
      ),
    );
  }
  // Show watermark screen...
}
```

---

## Testing Ad Behavior

### Test Ad Removal:
1. Run app
2. Navigate to any screen with ads - **ads should show**
3. Go to `/subscription` route
4. Tap "Buy Subscription" (mock)
5. Navigate back to any screen - **ads should be hidden**

### Test Ad Restoration:
1. In subscription screen
2. Close and reopen app
3. **Ads should stay hidden** (persisted)

### Test Premium Features:
1. Without subscription:
   - Try enabling HD mode → **Blocked with prompt**
   - Try opening Watermark screen → **Blocked with subscribe button**
2. After subscribing:
   - HD mode → **Works**
   - Watermark → **Access granted**

---

## Ad Revenue Optimization

### Current Strategy:
- **Banner Ads:** Persistent, high impression count
- **Native Ads:** Contextual, higher engagement
- **Interstitial Ads:** Strategic, non-intrusive timing

### Frequency Capping:
- Interstitial ads only show at major transitions
- Never show multiple interstitials in sequence
- Always respect user flow

### Premium Conversion:
- Ads visible but not annoying → encourages organic upgrade
- Premium features clearly gated → value proposition
- Easy one-tap subscribe flow

---

## Integration with Real Payment System

### TODO: Replace Mock with Real IAP

**Current (Mock):**
```dart
await sub.setSubscribed(true);
```

**Production (with in_app_purchase):**
```dart
import 'package:in_app_purchase/in_app_purchase.dart';

// Add to pubspec.yaml:
// in_app_purchase: ^3.1.0

final InAppPurchase iap = InAppPurchase.instance;

// 1. Query available products
final ProductDetailsResponse response = await iap.queryProductDetails({'premium_subscription'});

// 2. Purchase
final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
await iap.buyNonConsumable(purchaseParam: purchaseParam);

// 3. Listen to purchases
iap.purchaseStream.listen((purchases) {
  purchases.forEach((purchase) async {
    if (purchase.status == PurchaseStatus.purchased) {
      // Verify with backend
      await verifyPurchase(purchase);
      await sub.setSubscribed(true);
      // Complete purchase
      await iap.completePurchase(purchase);
    }
  });
});
```

---

## Ad Unit IDs (Production)

### ⚠️ IMPORTANT: Replace Test IDs Before Release

**Current (Test IDs):**
```dart
// AdConfig.dart
static String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // TEST
static String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // TEST
static String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110'; // TEST
```

**Production (Get from AdMob Console):**
```dart
static String interstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
static String bannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
static String nativeAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

### Steps to Get Production IDs:
1. Go to [AdMob Console](https://apps.admob.com/)
2. Create ad units for your app
3. Get Ad Unit IDs
4. Replace in `lib/widgets/ad_config.dart`
5. Test thoroughly before release

---

## Summary

### ✅ Ads Show When:
- User is NOT subscribed (`AdConfig.enableAds = true`)
- App has network connection
- Ad successfully loads from AdMob

### ❌ Ads Hidden When:
- User has active subscription (`AdConfig.enableAds = false`)
- Ad fails to load (graceful fallback)
- Premium features in use

### 🎯 Benefits of This System:
1. **Centralized Control:** One provider manages all ads
2. **Persistent:** Subscription survives app restarts
3. **Instant Updates:** All widgets react immediately
4. **Premium Value:** Clear benefits encourage subscriptions
5. **User-Friendly:** Non-intrusive ad placement

---

**Last Updated:** January 20, 2026  
**Version:** 1.0.0  
**Dependencies:** google_mobile_ads ^5.3.1, shared_preferences ^2.1.0
