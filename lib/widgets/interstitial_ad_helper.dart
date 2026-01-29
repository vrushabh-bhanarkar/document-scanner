import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'ad_config.dart';

class InterstitialAdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static bool _isLoading = false;

  // Preload ad to avoid lag when showing
  static void preloadAd({String? adUnitId}) {
    if (!AdConfig.enableAds || _isAdLoaded || _isLoading) return;
    
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId ?? AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('InterstitialAd: Ad preloaded successfully');
          _interstitialAd = ad;
          _isAdLoaded = true;
          _isLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd: Failed to preload ad: $error');
          _isAdLoaded = false;
          _isLoading = false;
        },
      ),
    );
  }

  static void showInterstitialAd({
    String? adUnitId,
    VoidCallback? onAdClosed,
  }) {
    if (!AdConfig.enableAds) {
      if (onAdClosed != null) onAdClosed();
      return;
    }
    
    // If ad is already loaded, show it immediately
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
          if (onAdClosed != null) onAdClosed();
          // Preload next ad
          Future.delayed(const Duration(milliseconds: 500), preloadAd);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('InterstitialAd: Failed to show ad: $error');
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
          if (onAdClosed != null) onAdClosed();
          // Preload next ad
          Future.delayed(const Duration(milliseconds: 500), preloadAd);
        },
      );
      _interstitialAd!.show();
      return;
    }
    
    // Ad not preloaded, load and show (fallback)
    InterstitialAd.load(
      adUnitId: adUnitId ?? AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isAdLoaded = false;
              if (onAdClosed != null) onAdClosed();
              // Preload next ad
              Future.delayed(const Duration(milliseconds: 500), preloadAd);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isAdLoaded = false;
              if (onAdClosed != null) onAdClosed();
              // Preload next ad
              Future.delayed(const Duration(milliseconds: 500), preloadAd);
            },
          );
          _interstitialAd!.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoaded = false;
          if (onAdClosed != null) onAdClosed();
        },
      ),
    );
  }
  
  // Clean up when no longer needed
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _isLoading = false;
  }
}
