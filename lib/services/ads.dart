import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'analytics.dart';

/// AdMob: rewarded ads the player chooses to watch ("xong ngay" on a crop,
/// pen or workshop; double level-up coins) and a rare interstitial after
/// delivering an order, plus an App Open ad when the player comes back.
///
/// Android uses the game's own AdMob units; iOS still uses Google samples
/// (App ID in android/app/build.gradle.kts). A no-op on web and in tests;
/// any ad failure just means "no ad", never a blocked game.
class AdsService with WidgetsBindingObserver {
  AdsService._();
  static final AdsService instance = AdsService._();

  /// The app's navigator, for the short lead-in before each ad.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  // Android: the game's own units. iOS: Google samples (no iOS app yet).
  static String get rewardedUnit =>
      _ios ? 'ca-app-pub-3940256099942544/1712485313' : 'ca-app-pub-9078637596840810/6352898077';
  static String get interstitialUnit =>
      _ios ? 'ca-app-pub-3940256099942544/4411468910' : 'ca-app-pub-9078637596840810/5042851680';

  static String get appOpenUnit => _ios ? '' : 'ca-app-pub-9078637596840810/5039816409';

  /// App Open: on a cold start (if the ad loads within [appOpenColdWait])
  /// and when coming back after [appOpenAway] in the background; never
  /// before [appOpenLevel] or within [interstitialGap] of another ad.
  static const appOpenAway = Duration(minutes: 30);
  static const appOpenColdWait = Duration(seconds: 6);
  static const appOpenLevel = 3;

  /// The player's level, set by the farm screen.
  int Function() playerLevel = () => 1;

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
  AppOpenAd? _appOpen;
  DateTime? _pausedAt;
  DateTime? _coldUntil;
  bool _showing = false;
  DateTime _lastFullScreen = DateTime.now();
  int _orders = 0;

  Future<void> init() async {
    if (!_supported) return;
    try {
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _started = true;
      _coldUntil = DateTime.now().add(appOpenColdWait);
      _loadAppOpen();
      _loadRewarded();
      _loadInterstitial();
      WidgetsBinding.instance.addObserver(this);
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
        _showing = false;
        _lastFullScreen = DateTime.now();
        _loadRewarded();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _showing = false;
        _loadRewarded();
        if (!result.isCompleted) result.complete(false);
      },
    );
    await _leadIn();
    _showing = true;
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
        _showing = false;
        _lastFullScreen = DateTime.now();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _showing = false;
        _loadInterstitial();
      },
    );
    Analytics.instance.log('ad_interstitial');
    _leadIn().then((_) {
      _showing = true;
      ad.show();
    });
  }

  // ------------------------------------------------------------ app open

  void _loadAppOpen() {
    if (!_started || _appOpen != null || appOpenUnit.isEmpty) return;
    AppOpenAd.load(
      adUnitId: appOpenUnit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          final cold = _coldUntil;
          _coldUntil = null;
          if (cold != null && DateTime.now().isBefore(cold)) _maybeShowAppOpen(cold: true);
        },
        onAdFailedToLoad: (_) {
          _appOpen = null;
          _coldUntil = null;
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_showing) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (away >= appOpenAway) _maybeShowAppOpen();
    }
  }

  void _maybeShowAppOpen({bool cold = false}) {
    final ad = _appOpen;
    if (!_started || ad == null || _showing) {
      _loadAppOpen();
      return;
    }
    if (playerLevel() < appOpenLevel) return;
    if (!cold && DateTime.now().difference(_lastFullScreen) < interstitialGap) return;
    _appOpen = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        _lastFullScreen = DateTime.now();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _showing = false;
        _loadAppOpen();
      },
    );
    Analytics.instance.log('ad_app_open', {'cold': cold ? 1 : 0});
    _showing = true;
    ad.show();
  }
}
