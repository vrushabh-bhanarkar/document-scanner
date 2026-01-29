# 🎯 Quick Reference: Ads & Subscription

## 📍 Where Ads Are Shown

| # | Screen | Ad Type | When | Disables On Subscribe |
|---|--------|---------|------|----------------------|
| 1️⃣ | Home | Banner | Always visible | ✅ |
| 2️⃣ | Dashboard | Native | Below search | ✅ |
| 3️⃣ | Create PDF (Preview) | Native | After generation | ✅ |
| 4️⃣ | Create PDF | Interstitial | Before generation | ✅ |
| 5️⃣ | Document Management | Native | Above actions | ✅ |
| 6️⃣ | PDF Viewer | Banner | Bottom | ✅ |
| 7️⃣ | PDF Viewer | Interstitial | After save | ✅ |

## 🔧 How It Works

### Subscription State Management
```
SharedPreferences (Persistent Storage)
         ↓
SubscriptionService
         ↓
SubscriptionProvider (ChangeNotifier)
         ↓
AdConfig.enableAds = !isSubscribed
         ↓
All Ad Widgets Check This Flag
```

### When User Subscribes:
1. User taps "Buy Subscription" → `setSubscribed(true)`
2. Saves to phone storage → `SharedPreferences`
3. Updates global flag → `AdConfig.enableAds = false`
4. Notifies all widgets → `notifyListeners()`
5. **All ads disappear instantly** 🎉

## 🔒 Premium Features

| Feature | Free | Premium | How Gated |
|---------|------|---------|-----------|
| **Ads** | ✅ Shown | ❌ Hidden | `AdConfig.enableAds` |
| **HD Camera** | ❌ Blocked | ✅ Enabled | Dialog → Paywall |
| **Watermark** | ❌ Blocked | ✅ Full Access | Redirect to subscribe |

## 📱 Files Modified

### Core System (5 files):
- ✅ `lib/services/subscription_service.dart` - Storage
- ✅ `lib/providers/subscription_provider.dart` - State management
- ✅ `lib/views/subscription_screen.dart` - UI
- ✅ `lib/main.dart` - Provider initialization
- ✅ `pubspec.yaml` - Dependencies

### Ad Integration (5 files):
- ✅ `lib/widgets/ad_config.dart` - Enabled native ads
- ✅ `lib/widgets/native_ad_widget.dart` - Added subscription check
- ✅ `lib/views/dashboard_screen.dart` - Added native ad
- ✅ `lib/views/document_management_screen.dart` - Added native ad
- ✅ `lib/views/create_pdf_screen.dart` - Premium gates

### Documentation (3 files):
- ✅ `ADVERTISING_DOCUMENTATION.md` - Full technical guide
- ✅ `AD_IMPLEMENTATION_SUMMARY.md` - Quick summary
- ✅ `VISUAL_AD_PLACEMENT_GUIDE.md` - Visual diagrams

## 🧪 Testing Commands

### Run App:
```bash
flutter run
```

### Navigate to Subscription Screen:
From anywhere in code, add:
```dart
Navigator.pushNamed(context, '/subscription')
```

Or add to settings/drawer menu.

### Test Subscription Flow:
1. Open subscription screen
2. Tap "Buy Subscription" (mock)
3. See toast: "Subscription activated"
4. Navigate to any screen → ads disappear
5. Try HD mode → works
6. Close and reopen app → still premium ✅

## 💰 Revenue Estimate

### Per 100 Free Users/Day:
- **Banner Ads**: ~800 impressions × $0.001 = **$0.80**
- **Native Ads**: ~100 impressions × $0.003 = **$0.30**
- **Interstitial**: ~60 impressions × $0.01 = **$0.60**
- **Daily Total**: **$1.70**
- **Monthly Total**: **$51.00**

### Subscription Conversion:
- **1% convert** at $9.99/month = **$9.99** per 100 users
- **Total Revenue**: $51 (ads) + $9.99 (subs) = **$60.99/month**

## ⚠️ Before Production

### 1. Replace Test Ad Unit IDs
File: `lib/widgets/ad_config.dart`
```dart
// Change these:
static String interstitialAdUnitId = 'YOUR_REAL_ID';
static String bannerAdUnitId = 'YOUR_REAL_ID';
static String nativeAdUnitId = 'YOUR_REAL_ID';
```

### 2. Integrate Real IAP
File: `lib/views/subscription_screen.dart`
- Add `in_app_purchase` package
- Replace mock with real payment
- Add server-side receipt validation

### 3. Configure AdMob
- Create app in AdMob console
- Generate real ad unit IDs
- Link to Play Store/App Store

### 4. Update Manifest
Android: `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR_APP_ID~YOUR_APP_CODE"/>
```

## 🐛 Common Issues

### Ads Not Showing?
1. Check `AdConfig.enableAds` is `true`
2. Verify network connection
3. Check AdMob test device ID in logs
4. Wait ~30 seconds for initial ad load

### Subscription Not Persisting?
1. Check `SharedPreferences` permissions
2. Verify `SubscriptionProvider.load()` called in main
3. Test on real device (not just emulator)

### Premium Features Still Blocked?
1. Check subscription screen shows "You are subscribed"
2. Verify `AdConfig.enableAds` is `false`
3. Restart app to reload provider state

## 📞 Support

See detailed documentation:
- **Technical Details**: `ADVERTISING_DOCUMENTATION.md`
- **Implementation**: `AD_IMPLEMENTATION_SUMMARY.md`
- **Visual Guide**: `VISUAL_AD_PLACEMENT_GUIDE.md`

---

**Version:** 1.0.0  
**Last Updated:** January 20, 2026  
**Status:** ✅ Ready for testing
