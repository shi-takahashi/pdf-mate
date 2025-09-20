import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const bool _isDebug = kDebugMode;
  static const bool _hideAdsForScreenshots = false; // スクリーンショット用

  // スクリーンショット用の広告非表示フラグ
  static bool get hideAdsForScreenshots => _hideAdsForScreenshots;

  // テスト用広告ID
  static const String _testBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';

  static const String _testInterstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialAdUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910';

  // 本番用広告ID
  static const String _productionBannerAdUnitIdAndroid = 'ca-app-pub-4630894580841955/8057702698';
  static const String _productionBannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716'; // iOSはテストIDのまま

  static const String _productionInterstitialAdUnitIdAndroid = 'ca-app-pub-4630894580841955/9558486629';
  static const String _productionInterstitialAdUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910'; // iOSはテストIDのまま

  // 使用する広告ID
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _isDebug ? _testBannerAdUnitIdAndroid : _productionBannerAdUnitIdAndroid;
    } else {
      return _isDebug ? _testBannerAdUnitIdIOS : _productionBannerAdUnitIdIOS;
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _isDebug ? _testInterstitialAdUnitIdAndroid : _productionInterstitialAdUnitIdAndroid;
    } else {
      return _isDebug ? _testInterstitialAdUnitIdIOS : _productionInterstitialAdUnitIdIOS;
    }
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();

    // リクエスト設定（テスト用デバイスID設定）
    if (_isDebug) {
      final requestConfiguration = RequestConfiguration(
        testDeviceIds: ['C774D381A6F78EB27EBA6CB37B4551E3'],
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    }
  }

  // バナー広告の作成
  static BannerAd createBannerAd({
    required Function() onAdLoaded,
    required Function() onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad();
        },
      ),
    )..load();
  }

  // インタースティシャル広告の作成
  static Future<InterstitialAd?> createInterstitialAd() async {
    final completer = Completer<InterstitialAd?>();

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          completer.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  // インタースティシャル広告を表示
  static Future<void> showInterstitialAd(InterstitialAd? ad, {Function()? onAdDismissed}) async {
    if (ad == null) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        onAdDismissed?.call();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      onAdDismissed?.call();
    }
  }
}
