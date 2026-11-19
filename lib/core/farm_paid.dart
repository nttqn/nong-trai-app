// Paid packs (1.6.0): what each in-app purchase gives the farm. The store
// side (Google Play, signature check, restore) is services/purchase.dart.
//
// - Bỏ quảng cáo: no interstitial / app-open ads (services/ads.dart; it
//   belongs to the store account, not the farm, so nothing here).
// - Gói khởi đầu: once per farm: coins by level, +50 storage, 10 Vé Xong
//   ngay, a lotus pot and a lantern to place.
// - Hầm chứa: unlocks the Hầm chứa building (+250 storage while it stands).
// - Thẻ Nhà Nông: 30 days of 5 free Xong ngay a day, +20% coins on new
//   orders and the login gift doubled without an ad. Buying again adds 30
//   days.

part of 'farm.dart';

const skuNoAds = 'bo_quang_cao', skuStarter = 'goi_khoi_dau', skuHamChua = 'ham_chua', skuCard = 'the_nha_nong';
const allSkus = {skuNoAds, skuStarter, skuHamChua, skuCard};

/// Bought once per store account (restored on a new phone); the card is
/// bought again and again.
const oneTimeSkus = {skuNoAds, skuStarter, skuHamChua};

const hamChuaStorage = 250;
const starterStorage = 50, starterTickets = 10;
const starterDecos = ['chau_sen', 'den_long'];
int starterCoins(int level) => 3000 + 300 * level;

const cardDays = 30, cardSpeedUps = 5, cardOrderBonus = .2;

extension FarmPaid on Farm {
  int get _todayKey => Farm.dayKey(now());

  static int _addDays(int key, int n) {
    final d = DateTime(key ~/ 10000, key ~/ 100 % 100, key % 100 + n, 12);
    return Farm.dayKey(d.millisecondsSinceEpoch);
  }

  bool get cardActive => cardUntil != 0 && _todayKey <= cardUntil;

  /// Days of Thẻ Nhà Nông left, today included (0 = none).
  int get cardDaysLeft {
    if (!cardActive) return 0;
    final a = DateTime(_todayKey ~/ 10000, _todayKey ~/ 100 % 100, _todayKey % 100);
    final b = DateTime(cardUntil ~/ 10000, cardUntil ~/ 100 % 100, cardUntil % 100);
    return b.difference(a).inHours ~/ 24 + 1;
  }

  /// Free Xong ngay left today from the card.
  int get cardSpeedUpsLeft {
    if (!cardActive) return 0;
    return cardUseDay == _todayKey ? (cardSpeedUps - cardUsed).clamp(0, cardSpeedUps) : cardSpeedUps;
  }

  /// Xong ngay with no ad: a card use first, else a Vé. Null when done.
  String? speedUpPaid(Obj o) {
    final viaCard = cardSpeedUpsLeft > 0;
    if (!viaCard && tickets <= 0) return 'Hết lượt Xong ngay miễn phí';
    final err = speedUp(o);
    if (err != null) return err;
    if (viaCard) {
      if (cardUseDay != _todayKey) {
        cardUseDay = _todayKey;
        cardUsed = 0;
      }
      cardUsed++;
    } else {
      tickets--;
    }
    _ev('speedup_paid', {'via': viaCard ? 'card' : 'ticket'});
    _changed();
    return null;
  }

  // ------------------------------------------------------------ grants

  /// Gives [sku] to this farm; the lines to show, or null when it gives
  /// nothing new (a one-time pack this farm already has).
  List<String>? grantPaid(String sku) {
    final out = <String>[];
    switch (sku) {
      case skuStarter:
        if (starterTaken) return null;
        starterTaken = true;
        final c = starterCoins(level);
        coins += c;
        paidStorage += starterStorage;
        tickets += starterTickets;
        for (final d in starterDecos) {
          giftDeco[d] = giftCount(d) + 1;
        }
        out.addAll([
          '+${fmtNum(c)} xu',
          '+$starterStorage chỗ chứa',
          '$starterTickets Vé Xong ngay',
          '${bdef(starterDecos[0]).name}, ${bdef(starterDecos[1]).name} (Xây dựng → Trang trí)',
        ]);
      case skuHamChua:
        if (hamChua) return null;
        hamChua = true;
        out.add('Mở khóa Hầm chứa (+$hamChuaStorage chỗ chứa). Vào Xây dựng → Nhà cửa để đặt.');
      case skuCard:
        final from = cardActive ? _addDays(cardUntil, 1) : _todayKey;
        cardUntil = _addDays(from, cardDays - 1);
        out.add('Thẻ Nhà Nông còn $cardDaysLeft ngày');
      default:
        return null;
    }
    _snd('sparkle');
    _ev('paid_grant', {'sku': sku, 'level': level});
    _changed();
    return out;
  }
}
