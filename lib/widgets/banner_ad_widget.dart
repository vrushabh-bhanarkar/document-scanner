import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

class BannerAdWidget extends StatefulWidget {
  final String? adUnitId;
  final AdSize adSize;
  const BannerAdWidget({Key? key, this.adUnitId, this.adSize = AdSize.banner})
      : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    if (AdConfig.enableAds) {
      _bannerAd = BannerAd(
        adUnitId: widget.adUnitId ?? AdConfig.bannerAdUnitId,
        size: widget.adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isBannerAdReady = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            setState(() {
              _isBannerAdReady = false;
            });
          },
        ),
      )..load();
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
      return SizedBox.shrink();
    }
    if (!_isBannerAdReady || _bannerAd == null) {
      return SizedBox(height: widget.adSize.height.toDouble());
    }
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
