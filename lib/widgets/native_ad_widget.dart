import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({Key? key}) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (AdConfig.enableNativeAds && AdConfig.enableAds) {
      _nativeAd = NativeAd(
        adUnitId: AdConfig.nativeAdUnitId,
        factoryId: 'listTile', // Default factory for test ad
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            print('Native ad loaded!');
            setState(() {
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            print('Native ad failed to load: \\${error.message}');
            ad.dispose();
            setState(() {
              _hasError = true;
            });
          },
        ),
        request: const AdRequest(),
      )..load();
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.enableNativeAds || !AdConfig.enableAds) {
      return const SizedBox.shrink();
    }
    if (_hasError) {
      return Container(
        height: 100,
        color: Colors.red.withOpacity(0.2),
        alignment: Alignment.center,
        child: const Text('Native ad failed to load',
            style: TextStyle(color: Colors.red)),
      );
    }
    if (!_isLoaded) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
