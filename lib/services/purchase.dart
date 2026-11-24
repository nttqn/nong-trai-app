import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/farm.dart';
import 'ads.dart';
import 'analytics.dart';
import 'play_verify.dart';

/// One line of the purchase history.
class PurchaseLog {
  const PurchaseLog(this.sku, this.order, this.at);
  final String sku, order;
  final DateTime at;

  String get product => productName(sku);

  static PurchaseLog? parse(String s) {
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return PurchaseLog(m['sku'] as String, m['order'] as String? ?? '', DateTime.fromMillisecondsSinceEpoch(m['at'] as int));
    } catch (_) {
      return null;
    }
  }
}

String productName(String sku) => switch (sku) {
      skuNoAds => 'Bỏ quảng cáo',
      skuStarter => 'Gói khởi đầu',
      skuHamChua => 'Hầm chứa',
      skuCard => 'Thẻ Nhà Nông 30 ngày',
      _ => sku,
    };

/// Google Play purchases (1.6.0), adapted from kiem-hiep-app (live there):
/// Bỏ quảng cáo, Gói khởi đầu and Hầm chứa are non-consumables, restored
/// on every start; Thẻ Nhà Nông is a consumable bought again each month.
///
/// No server checks receipts; each Android purchase's Play signature is
/// checked on the phone ([PlayVerifier]) once [playLicenseKey] is filled
/// in. Every delivery is remembered by purchase id so a replayed one is
/// never granted twice, and one-time packs are idempotent on the farm.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// The store the player pays through, for the shop's wording.
  static String get storeName =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';

  static bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// The farm on screen and how to save it (set by main.dart).
  Farm? Function() farm = () => null;
  Future<void> Function(Farm f) save = (_) async {};

  final Map<String, ProductDetails> products = {};
  bool available = false;

  /// Bumped on every change, for the shop to rebuild.
  final ValueNotifier<int> changed = ValueNotifier(0);

  /// The last thing to tell the player, or an error.
  final ValueNotifier<String?> message = ValueNotifier(null);

  /// A purchase is in flight.
  final ValueNotifier<bool> busy = ValueNotifier(false);

  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Set<String> _done = {};

  /// One-time packs this phone has delivered, and the furthest Thẻ Nhà
  /// Nông day, so a cloud restore of an older save can be topped up.
  final Set<String> _owned = {};
  int _cardUntil = 0;

  /// Bought before any farm was open: given to the next one.
  final List<String> _queue = [];

  static const _doneKey = 'iap_done', _queueKey = 'iap_queue', _ownedKey = 'iap_owned', _cardKey = 'iap_card';

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _done.addAll(p.getStringList(_doneKey) ?? const []);
      _queue.addAll(p.getStringList(_queueKey) ?? const []);
      _owned.addAll(p.getStringList(_ownedKey) ?? const []);
      _cardUntil = p.getInt(_cardKey) ?? 0;
    } catch (_) {}
    if (!_supported) return;
    try {
      final iap = InAppPurchase.instance;
      _sub = iap.purchaseStream.listen(_onPurchases, onError: (Object e) => debugPrint('iap stream: $e'));
      available = await iap.isAvailable();
      if (!available) return;
      final r = await iap.queryProductDetails(allSkus);
      for (final d in r.productDetails) {
        products[d.id] = d;
      }
      changed.value++;
      // brings one-time packs back after a reinstall or on a new phone
      await iap.restorePurchases();
      await _recheckAdFree();
    } catch (e) {
      debugPrint('iap off: $e');
    }
  }

  void dispose() => _sub?.cancel();

  static final PlayVerifier? _verifier = PlayVerifier.fromBase64(playLicenseKey);

  /// Why [p] is refused: 'nosig', 'sku' or 'sig'; null when fine.
  static String? rejectReason(PurchaseDetails p) {
    if (p is! GooglePlayPurchaseDetails) return null;
    final v = _verifier;
    if (v == null) return null;
    final w = p.billingClientPurchase;
    if (w.signature.trim().isEmpty) return 'nosig';
    if (!w.products.contains(p.productID)) return 'sku';
    return v.verify(w.originalJson, w.signature) ? null : 'sig';
  }

  static bool genuine(PurchaseDetails p) => rejectReason(p) == null;

  String? priceOf(String sku) => products[sku]?.price ?? (kIsWeb && Uri.base.queryParameters['shot'] != null ? _demoPrices[sku] : null);

  // store screenshots on web (?shot=1): the suggested Play prices
  static const _demoPrices = {
    skuStarter: '22.000 ₫',
    skuHamChua: '79.000 ₫',
    skuCard: '49.000 ₫',
    skuNoAds: '49.000 ₫',
  };

  /// The farm already has everything [sku] gives once.
  bool owns(String sku) {
    final f = farm();
    return switch (sku) {
      skuNoAds => AdsService.instance.adFree.value,
      skuStarter => f?.starterTaken ?? false,
      skuHamChua => f?.hamChua ?? false,
      _ => false,
    };
  }

  Future<void> buy(String sku) async {
    final d = products[sku];
    if (d == null || busy.value) return;
    busy.value = true;
    Analytics.instance.log('iap_start', {'sku': sku});
    try {
      final param = PurchaseParam(productDetails: d);
      final ok = oneTimeSkus.contains(sku)
          ? await InAppPurchase.instance.buyNonConsumable(purchaseParam: param)
          : await InAppPurchase.instance.buyConsumable(purchaseParam: param);
      if (!ok) busy.value = false;
    } catch (e) {
      busy.value = false;
      message.value = 'Không mở được cửa hàng: $e';
    }
  }

  /// ☰ → Khôi phục giao dịch: asks Play again for the one-time packs.
  Future<String> restoreNow() async {
    if (!_supported) return 'Chỉ khôi phục được trên điện thoại.';
    if (!available) return 'Không kết nối được $storeName. Kiểm tra mạng và tài khoản rồi thử lại.';
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('restore: $e');
    }
    // App Store sends owned one-time packs back through the purchase
    // stream, where they are applied.
    if (defaultTargetPlatform != TargetPlatform.android) {
      return 'Đã gửi yêu cầu khôi phục tới App Store. Gói đã mua sẽ vào nông trại trong giây lát.';
    }
    try {
      final add = InAppPurchase.instance.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final r = await add.queryPastPurchases();
      if (r.error != null) return 'Google Play chưa trả lời. Thử lại sau ít phút.';
      final names = <String>[];
      for (final p in r.pastPurchases) {
        if (p.billingClientPurchase.purchaseState != PurchaseStateWrapper.purchased || !genuine(p)) continue;
        if (!oneTimeSkus.contains(p.productID)) continue;
        _apply(p.productID, quiet: true);
        names.add(productName(p.productID));
      }
      Analytics.instance.log('iap_restore', {'n': names.length});
      changed.value++;
      if (names.isEmpty) {
        return 'Tài khoản Google Play trên máy này chưa mua gói dùng mãi nào. '
            'Nếu bạn mua bằng tài khoản khác, hãy chuyển sang tài khoản đó trong Play Store rồi thử lại. '
            'Thẻ Nhà Nông đã vào nông trại ngay lúc mua.';
      }
      return 'Đã khôi phục: ${names.join(', ')}.';
    } catch (e) {
      return 'Không khôi phục được: $e';
    }
  }

  /// Turns Bỏ quảng cáo off when this Play account does not own a genuine
  /// one (a fake purchase, or a refund). Only on a clean answer from Play.
  Future<void> _recheckAdFree() async {
    if (_verifier == null || defaultTargetPlatform != TargetPlatform.android) return;
    if (!AdsService.instance.adFree.value) return;
    try {
      final add = InAppPurchase.instance.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final r = await add.queryPastPurchases();
      if (r.error != null) return;
      final owns = r.pastPurchases.any((p) =>
          p.productID == skuNoAds && p.billingClientPurchase.purchaseState == PurchaseStateWrapper.purchased && genuine(p));
      if (!owns) {
        AdsService.instance.setAdFree(false);
        Analytics.instance.log('ad_free_revoked');
        changed.value++;
      }
    } catch (e) {
      debugPrint('iap recheck: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          busy.value = true;
          message.value = 'Giao dịch đang chờ xác nhận…';
        case PurchaseStatus.error:
          busy.value = false;
          message.value = 'Giao dịch lỗi: ${p.error?.message ?? 'không rõ'}';
        case PurchaseStatus.canceled:
          busy.value = false;
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          busy.value = false;
          final why = rejectReason(p);
          if (why == null) {
            await _deliver(p);
          } else {
            Analytics.instance.log('iap_bad', {'sku': p.productID, 'why': why});
            message.value = 'Giao dịch không hợp lệ: $storeName không xác nhận giao dịch này.';
          }
      }
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (e) {
          debugPrint('iap complete: $e');
        }
      }
    }
    changed.value++;
  }

  Future<void> _deliver(PurchaseDetails p) async {
    final sku = p.productID;
    final fresh = p.status == PurchaseStatus.purchased;
    final id = p.purchaseID ?? base64Encode(utf8.encode(p.verificationData.serverVerificationData)).substring(0, 40);
    // one-time packs come back on every start: applying them is harmless
    // (each is given once per farm); the card only once per purchase
    if (!oneTimeSkus.contains(sku) && _done.contains(id)) return;
    final firstTime = _done.add(id);
    if (fresh && firstTime) {
      Analytics.instance.log('iap_done', {'sku': sku});
      await _addLog(sku, p.purchaseID ?? '');
    }
    final text = _apply(sku, quiet: !fresh);
    if (fresh && text != null) message.value = text;
    await _persist();
  }

  /// Gives [sku] to the farm on screen (or queues it); the line to show.
  String? _apply(String sku, {bool quiet = false}) {
    if (sku == skuNoAds) {
      AdsService.instance.setAdFree(true);
      return 'Đã bỏ quảng cáo! Cảm ơn bà con đã ủng hộ làng.';
    }
    if (oneTimeSkus.contains(sku)) _owned.add(sku);
    final f = farm();
    if (f == null) {
      _queue.add(sku);
      return 'Đã mua! Quà sẽ vào nông trại khi mở game.';
    }
    final lines = f.grantPaid(sku);
    if (sku == skuCard && f.cardUntil > _cardUntil) _cardUntil = f.cardUntil;
    changed.value++;
    unawaited(save(f));
    if (lines == null) return quiet ? null : '${productName(sku)}: nông trại đã có rồi.';
    return '🎁 ${productName(sku)}:\n${lines.join('\n')}';
  }

  /// After the farm on screen changes (start, cloud restore): hands out
  /// what was bought with no farm open, and gives back one-time packs and
  /// card days an older save is missing.
  String? onFarmReady(Farm f) {
    final lines = <String>[];
    var touched = false;
    for (final s in _queue) {
      final l = f.grantPaid(s);
      if (l != null) lines.add('🎁 ${productName(s)}: ${l.join(', ')}');
    }
    if (_queue.isNotEmpty) touched = true;
    _queue.clear();
    if (_owned.contains(skuHamChua) && !f.hamChua) {
      f.hamChua = true;
      touched = true;
    }
    if (_cardUntil > f.cardUntil) {
      f.cardUntil = _cardUntil;
      touched = true;
    }
    if (touched) {
      unawaited(save(f));
      unawaited(_persist());
      changed.value++;
    }
    return lines.isEmpty ? null : lines.join('\n');
  }

  // ------------------------------------------------------------ history

  static const _logKey = 'iap_log';

  /// Purchases made on this phone, newest first, with Play's order id.
  Future<List<PurchaseLog>> history() async {
    try {
      final p = await SharedPreferences.getInstance();
      return [
        for (final s in (p.getStringList(_logKey) ?? const <String>[]).reversed) ?PurchaseLog.parse(s),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _addLog(String sku, String order) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_logKey) ?? <String>[];
      list.add(jsonEncode({'sku': sku, 'order': order, 'at': DateTime.now().millisecondsSinceEpoch}));
      await p.setStringList(_logKey, list.length > 100 ? list.sublist(list.length - 100) : list);
    } catch (e) {
      debugPrint('iap log: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_doneKey, _done.toList());
      await p.setStringList(_queueKey, _queue);
      await p.setStringList(_ownedKey, _owned.toList());
      await p.setInt(_cardKey, _cardUntil);
    } catch (_) {}
  }
}
