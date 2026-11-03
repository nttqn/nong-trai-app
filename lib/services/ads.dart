import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'analytics.dart';

/// AdMob: rewarded ads the player chooses to watch ("xong ngay" on a crop,
/// pen or workshop; double level-up coins) and a rare interstitial after
/// delivering an order.
///
/// Unit ids are Google's sample ids until the game's own AdMob app exists
/// (App ID in android/app/build.gradle.kts). A no-op on web and in tests;
/// any ad failure just means "no ad", never a blocked game.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  /// The app's navigator, for the short lead-in before each ad.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  // TODO(ads): replace with the game's own units once the AdMob app exists.
  static String get rewardedUnit =>
      _ios ? 'ca-app-pub-3940256099942544/1712485313' : 'ca-app-pub-3940256099942544/5224354917';
  static String get interstitialUnit =>
      _ios ? 'ca-app-pub-3940256099942544/4411468910' : 'ca-app-pub-3940256099942544/1033173712';

  /// No interstitial within this long of any other full-screen ad or of
  /// the app starting, never before [interstitialLevel], and only after
  /// every [interstitialEvery]-th delivered order.
  static const interstitialGap = Duration(minutes: 5);
  static const interstitialLevel = 4;
  static const interstitialEvery = 3;

  final ValueNotifier<bool> rewardedReady = ValueNotifier(false);
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);
  bool _started = false, _loadingRewarded = false;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  DateTime _lastFullScreen = DateTime.now();
  int _orders = 0;

  Future<void> init() async {
    if (!_supported) return;
    try {
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _started = true;
      _loadRewarded();
      _loadInterstitial();
    } catch (e) {
      debugPrint('ads off: $e');
    }
  }

  /// Google's consent form (GDPR and similar); shown only where required.
  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((error) async {
          privacyOptionsRequired.value = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
          if (!done.isCompleted) done.complete();
        });
      },
      (error) {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(const Duration(seconds: 15), onTimeout: () {});
  }

  void showPrivacyOptions() {
    if (_supported) ConsentForm.showPrivacyOptionsForm((_) {});
  }

  /// A short screen that swallows taps, so a fast tap meant for the farm
  /// never lands on the ad as a click.
  Future<void> _leadIn() async {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => const Positioned.fill(
        child: AbsorbPointer(
          child: ColoredBox(
            color: Color(0xCC000000),
            child: Center(
              child: Text('Quảng cáo sắp bắt đầu…',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: Color(0xFFFFF4DC), fontSize: 16, decoration: TextDecoration.none)),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    entry.remove();
  }

  // ------------------------------------------------------------ rewarded

  void _loadRewarded() {
    if (!_started || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded = ad;
          rewardedReady.value = true;
        },
        onAdFailedToLoad: (_) {
          _loadingRewarded = false;
          rewardedReady.value = false;
          Timer(const Duration(minutes: 1), _loadRewarded);
        },
      ),
    );
  }

  /// Shows a rewarded ad; true only if the player earned the reward.
  /// [placement] names the button for analytics.
  Future<bool> showRewarded(String placement) async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    rewardedReady.value = false;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _lastFullScreen = DateTime.now();
        _loadRewarded();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(false);
      },
    );
    await _leadIn();
    await ad.show(onUserEarnedReward: (_, _) {
      earned = true;
      Analytics.instance.log('ad_reward', {'placement': placement});
    });
    return result.future;
  }

  // ------------------------------------------------------------ interstitial

  void _loadInterstitial() {
    if (!_started || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Called after an order is delivered (a natural pause in play).
  void onOrderDelivered(int playerLevel) {
    _orders++;
    if (!_started || playerLevel < interstitialLevel || _orders % interstitialEvery != 0) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    if (DateTime.now().difference(_lastFullScreen) < interstitialGap) return;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _lastFullScreen = DateTime.now();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    Analytics.instance.log('ad_interstitial');
    _leadIn().then((_) => ad.show());
  }
}
