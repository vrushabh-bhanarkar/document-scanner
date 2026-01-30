// Central ad configuration for the app
class AdConfig {
  // Enable/disable ads globally
  static bool enableAds = true;

  // Interstitial Ad Unit ID
  // static String interstitialAdUnitId =
  //     'ca-app-pub-6586073221878389/3484062745'; // Real production ID
  static String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // TEST ad unit

  // Banner Ad Unit ID
  // static String bannerAdUnitId =
  //     'ca-app-pub-6586073221878389/7339693065'; // Real production ID
  static String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // TEST ad unit

  static bool enableNativeAds = true; // Set to true to enable native ads
  // static const String nativeAdUnitId =
  //     'ca-app-pub-6586073221878389/1324517855'; // Real production native ad unit
  static const String nativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110'; // TEST native ad unit

  // Optionally, add more ad types/configs here
}
