import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Production AdMob Banner Wrapper
/// Enforces a fixed-height container (50dp standard banner) with a dedicated layout placeholder
/// to eliminate GPU surface recreation cycles (`ImageReader_init`) and avoid main-thread jank.
class BannerAdWidget extends StatefulWidget {
  final String? adUnitId;
  final AdSize adSize;
  final double fixedHeight;

  const BannerAdWidget({
    super.key,
    this.adUnitId,
    this.adSize = AdSize.banner,
    this.fixedHeight = 50.0,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdConfig.enableAds) return;

    try {
      _bannerAd = BannerAd(
        adUnitId: widget.adUnitId ?? AdConfig.bannerAdUnitId,
        size: widget.adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isBannerAdReady = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isBannerAdReady = false;
              });
            }
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('[BannerAdWidget] Ad load error: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.enableAds) {
      return const SizedBox.shrink();
    }

    final targetHeight = widget.adSize.height > 0
        ? widget.adSize.height.toDouble()
        : widget.fixedHeight;

    // Fixed-height container with placeholder eliminates GPU surface recreation cycles
    return SizedBox(
      height: targetHeight,
      width: double.infinity,
      child: Center(
        child: _isBannerAdReady && _bannerAd != null
            ? SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : Container(
                height: targetHeight,
                width: double.infinity,
                color: Colors.transparent, // Layout placeholder
              ),
      ),
    );
  }
}
