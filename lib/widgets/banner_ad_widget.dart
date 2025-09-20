import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(
      onAdLoaded: () {
        setState(() {
          _isAdLoaded = true;
        });
      },
      onAdFailedToLoad: () {
        setState(() {
          _isAdLoaded = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // スクリーンショット用に広告を非表示
    if (AdService.hideAdsForScreenshots) {
      return const SizedBox.shrink();
    }
    
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox(height: 50); // バナー広告の高さ分のスペースを確保
    }

    return SizedBox(
      height: 50,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}