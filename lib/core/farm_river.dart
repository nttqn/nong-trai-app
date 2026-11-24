// Câu cá ngoài sông (1.8.0): a few casts a day on the river along the top
// of the map. 1.9.0: past them the line can still go in ("câu giải trí",
// a 1★ review called the limit the end of the fun): fish are sold on the
// bank for a few capped coins instead of stored, and every catch counts
// for the weekly fishing leaderboard (Đua top câu cá). The catch is rolled when the line goes in; the mini-game
// (ui/river_sheet.dart) decides whether it is landed. A part of farm.dart.

part of 'farm.dart';

enum BiteKind { fish, junk, coins, ticket }

/// What took the bait: [zone] is the width of the green band on the reel
/// bar (0..1) and [speed] how fast the marker sweeps (sweeps per second).
class RiverBite {
  final BiteKind kind;
  final String? item;
  final int qty;
  final double zone, speed;
  final String name, icon;

  /// Fishing leaderboard points if landed.
  final int pts;

  /// A cast past the daily ones (câu giải trí).
  final bool fun;
  const RiverBite(this.kind, this.item, this.qty, this.zone, this.speed, this.name, this.icon,
      {this.pts = 0, this.fun = false});

  RiverBite asFun() => RiverBite(kind, item, qty, zone, speed, name, icon, pts: pts, fun: true);
}

class _RiverFish {
  final String item;
  final int level, weight, maxQty;
  final double zone, speed;

  /// Points on the fishing leaderboard: the harder the fish, the more.
  final int pts;
  const _RiverFish(this.item, this.level, this.weight, this.maxQty, this.zone, this.speed, this.pts);
}

const _riverFish = [
  _RiverFish('caro', 1, 40, 2, .30, .55, 1),
  _RiverFish('catram', 9, 26, 1, .25, .65, 2),
  _RiverFish('cachep', 13, 20, 1, .22, .75, 3),
  _RiverFish('tom', 17, 15, 2, .22, .8, 3),
  _RiverFish('luon', 35, 11, 1, .17, .95, 5),
  _RiverFish('caqua', 41, 9, 1, .15, 1.05, 6),
];

extension FarmRiver on Farm {
  static const riverLevel = 3;
  static const riverFree = 6, riverAdCasts = 3, riverAdMax = 3, riverCardCasts = 3;

  int get _riverToday => Farm.dayKey(now());

  void _riverRoll() {
    if (riverDay == _riverToday) return;
    riverDay = _riverToday;
    riverUsed = 0;
    riverAds = 0;
  }

  /// Casts left today (free ones, Thẻ Nhà Nông's, and those from ads).
  int get riverCasts {
    final fresh = riverDay != _riverToday;
    final used = fresh ? 0 : riverUsed, ads = fresh ? 0 : riverAds;
    return riverFree + (cardActive ? riverCardCasts : 0) + ads * riverAdCasts - used;
  }

  /// More casts for a rewarded ad (a few times a day).
  bool get riverAdLeft => (riverDay != _riverToday ? 0 : riverAds) < riverAdMax;

  void riverAdGranted() {
    _riverRoll();
    if (riverAds >= riverAdMax) return;
    riverAds++;
    _ev('river_ad', {'level': level});
    _changed();
  }

  /// Past the daily casts: the line still goes in, for fun and points.
  bool get riverFun => riverCasts <= 0;

  /// Coins casts past the daily ones can still bring today.
  int get riverFunCap => 100 + 10 * level;
  int get riverFunLeft =>
      math.max(0, riverFunCap - (riverFunDay == _riverToday ? riverFunCoins : 0));

  /// Puts the line in: uses a cast (or makes a fun one) and decides what
  /// will bite.
  (RiverBite?, String?) cast() {
    if (level < riverLevel) return (null, 'Câu cá mở ở cấp $riverLevel');
    rollFish();
    if (riverFun) {
      _stat('river_fun');
      final rng = math.Random(seed * 977 + now() ~/ 7 + (stats['river_fun'] ?? 0) * 13);
      return (_rollBite(rng, fun: true).asFun(), null);
    }
    _riverRoll();
    riverUsed++;
    _stat('river_cast');
    final rng = math.Random(seed * 977 + now() ~/ 7 + riverUsed);
    return (_rollBite(rng), null);
  }

  /// A new week of Đua top câu cá: last week's place prize is queued.
  void rollFish() {
    final k = weekKeyOf(now());
    if (k == fishWeek) return;
    if (fishWeek != 0) _rankQueue(1, fishWeek, fishPts);
    fishWeek = k;
    fishPts = 0;
  }

  RiverBite _rollBite(math.Random rng, {bool fun = false}) {
    final pool = [for (final f in _riverFish) if (f.level <= level) f];
    final fishW = pool.fold(0, (s, f) => s + f.weight);
    // the odd old sandal, a jar of coins or a ticket among the fish
    // (treasure only on the daily casts)
    final junkW = 9, coinW = fun ? 0 : 5, ticketW = fun ? 0 : 2;
    var r = rng.nextInt(fishW + junkW + coinW + ticketW);
    for (final f in pool) {
      if (r < f.weight) {
        final it = item(f.item);
        return RiverBite(BiteKind.fish, f.item, 1 + rng.nextInt(f.maxQty), f.zone, f.speed, it.name, it.icon,
            pts: f.pts);
      }
      r -= f.weight;
    }
    r -= junkW;
    if (r < 0) {
      const junk = [('Chiếc dép tổ ong', '🩴'), ('Chiếc nón rách', '👒'), ('Cành củi mục', '🪵')];
      final j = junk[rng.nextInt(junk.length)];
      return RiverBite(BiteKind.junk, null, 0, .34, .5, j.$1, j.$2);
    }
    r -= coinW;
    if (r < 0) return RiverBite(BiteKind.coins, null, 80 + 20 * level, .16, .9, 'Hũ tiền cổ', '🏺', pts: 2);
    return const RiverBite(BiteKind.ticket, null, 1, .14, 1.0, 'Hộp gỗ có Vé Xong ngay', '🎫', pts: 2);
  }

  /// Coins a piece of junk is still worth (sold to the scrap woman).
  int get junkCoins => 5 + 2 * level;

  /// Coins a fun catch sells for on the bank (before the daily cap).
  int funCoinsOf(RiverBite b) => switch (b.kind) {
        BiteKind.fish => math.max(1, item(b.item!).price * b.qty ~/ 5),
        BiteKind.junk => 2,
        _ => 0,
      };

  /// The catch is landed. Null when it went into the farm.
  String? landBite(RiverBite b) {
    rollFish();
    fishPts += b.pts;
    if (b.pts > 0) _stat('fish_pts', b.pts);
    if (b.fun) {
      // sold on the bank: a few coins until today's cap, then just points
      if (riverFunDay != _riverToday) {
        riverFunDay = _riverToday;
        riverFunCoins = 0;
      }
      final c = math.min(funCoinsOf(b), riverFunLeft);
      coins += c;
      riverFunCoins += c;
      lastFunCoins = c;
      _stat(b.kind == BiteKind.fish ? 'river_fish' : 'river_junk', b.kind == BiteKind.fish ? b.qty : 1);
      _snd(b.kind == BiteKind.fish ? 'splash' : 'coin');
      _ev('river_catch', {'kind': b.kind.name, 'level': level, 'fun': 1});
      _changed();
      return null;
    }
    switch (b.kind) {
      case BiteKind.fish:
        if (!roomFor(b.qty)) return 'Kho đầy! Cá nhảy về sông mất rồi';
        _gain(b.item!, b.qty);
        addXp(2 + item(b.item!).price ~/ 15);
        _stat('river_fish', b.qty);
        _weekAdd(WeekKind.fish, b.qty);
      case BiteKind.junk:
        coins += junkCoins;
        addXp(1);
        _stat('river_junk');
      case BiteKind.coins:
        coins += b.qty;
        addXp(5);
        _stat('river_treasure');
      case BiteKind.ticket:
        tickets += b.qty;
        addXp(5);
        _stat('river_treasure');
    }
    _snd(b.kind == BiteKind.fish ? 'splash' : 'coin');
    _ev('river_catch', {'kind': b.kind.name, 'level': level});
    _changed();
    return null;
  }

  /// It got away (struck too early, too late, or missed the band).
  void lostBite() {
    _stat('river_miss');
    _snd('splash');
    _changed();
  }
}
