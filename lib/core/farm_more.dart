// Daily login gifts, the guard dog, market stalls (chợ phiên),
// achievements and the first-time tutorial. A part of farm.dart so it can
// use the farm's private helpers (_gain, _stat, _changed...).

part of 'farm.dart';

/// A gift for one day of the 7-day login streak.
class LoginReward {
  final int day, coins, xp;
  final Map<String, int> goods;
  const LoginReward(this.day, this.coins, this.xp, this.goods);
}

/// Goods put up for sale by this player (mirrors stalls/{uid}_{slot}).
class Stall {
  final int slot, qty, price, at;
  final String item;
  const Stall(this.slot, this.item, this.qty, this.price, this.at);
  Map<String, dynamic> toJson() => {'s': slot, 'i': item, 'q': qty, 'p': price, 'a': at};
  factory Stall.fromJson(Map<String, dynamic> j) => Stall(j['s'], j['i'], j['q'], j['p'], j['a'] ?? 0);
}

/// Tutorial steps; [tutDone] once finished or skipped.
enum Tut { plant, harvest, order, build, end }

const tutDone = 99;

LoginReward loginReward(int day, int level) => switch (day) {
      1 => LoginReward(1, 50 + 20 * level, 0, const {}),
      2 => const LoginReward(2, 0, 0, {'phan': 2}),
      3 => LoginReward(3, 100 + 40 * level, 0, const {}),
      4 => const LoginReward(4, 0, 0, {'trung': 5, 'gao': 5}),
      5 => LoginReward(5, 150 + 60 * level, 0, const {}),
      6 => const LoginReward(6, 0, 0, {'phan': 5}),
      _ => LoginReward(7, 300 + 150 * level, 20 * level, const {'banhchung': 2}),
    };

extension FarmMore on Farm {
  // ------------------------------------------------------------ login gift
  int get _today => Farm.dayKey(now());
  int get _yesterday {
    final d = DateTime.fromMillisecondsSinceEpoch(now());
    return Farm.dayKey(DateTime(d.year, d.month, d.day - 1, 12).millisecondsSinceEpoch);
  }

  bool get loginClaimed => loginDay == _today;

  /// Which day of the streak today's gift is (1..7), counting a missed day
  /// as a restart.
  int get loginNextDay {
    if (loginClaimed) return loginStreak;
    if (loginDay == _yesterday && loginStreak < 7) return loginStreak + 1;
    return 1;
  }

  /// Takes today's gift; null if it was already taken.
  LoginReward? claimLogin() {
    if (loginClaimed) return null;
    final r = loginReward(loginNextDay, level);
    loginStreak = r.day;
    loginDay = _today;
    _giveLogin(r);
    _stat('login');
    _ev('login_gift', {'day': r.day});
    _changed();
    return r;
  }

  /// The same gift once more (rewarded ad).
  void doubleLogin(LoginReward r) {
    _giveLogin(r);
    _changed();
  }

  void _giveLogin(LoginReward r) {
    coins += r.coins;
    if (r.xp > 0) addXp(r.xp);
    r.goods.forEach(_gain);
    _snd('quest');
  }

  // ------------------------------------------------------------ guard dog
  static const dogFood = {'gao': 2};
  static const dogFedMs = 24 * 3600 * 1000;
  static const dogCatch = .25;

  Obj? get dog {
    for (final o in objs) {
      if (o.type == 'cho') return o;
    }
    return null;
  }

  bool dogAwake(Obj o) => o.end > now();

  String? feedDog(Obj o) {
    if (dogAwake(o) && o.end - now() > dogFedMs ~/ 2) return 'Chó vẫn còn no';
    if (!_spend(dogFood)) return 'Cần ${dogFood.entries.map((e) => '${e.value} ${item(e.key).name.toLowerCase()}').join(', ')}';
    o.start = now();
    o.end = o.start + dogFedMs;
    _stat('feed:cho');
    _snd('feed');
    _fx(o, '🐕 Gâu!');
    _changed();
    return null;
  }

  // ------------------------------------------------------------ market stalls
  static const marketLevel = 7;
  int get stallSlots => 4 + (has('cho_que') ? 1 : 0);
  static const stallMaxQty = 20;

  /// Lowest and highest asking price for [qty] of [id].
  (int, int) stallPriceRange(String id, int qty) {
    final base = item(id).price * qty;
    return (math.max(1, (base * .5).round()), math.max(2, base * 2));
  }

  int? get freeStallSlot {
    for (var s = 0; s < stallSlots; s++) {
      if (!stalls.any((x) => x.slot == s)) return s;
    }
    return null;
  }

  String? canListStall(String id, int qty, int price) {
    if (level < marketLevel) return 'Chợ phiên mở ở cấp $marketLevel';
    if (freeStallSlot == null) return 'Sạp đã đầy hàng';
    if (qty < 1 || qty > stallMaxQty) return 'Mỗi lần bán 1–$stallMaxQty món';
    if (countOf(id) < qty) return 'Không đủ ${item(id).name.toLowerCase()}';
    final (lo, hi) = stallPriceRange(id, qty);
    if (price < lo || price > hi) return 'Giá phải từ ${fmtNum(lo)} đến ${fmtNum(hi)} xu';
    return null;
  }

  /// Puts goods on the stall (taken out of storage until sold or withdrawn).
  Stall? listStall(String id, int qty, int price, {int? slot}) {
    if (canListStall(id, qty, price) != null) return null;
    final st = Stall(slot ?? freeStallSlot!, id, qty, price, now());
    _spend({id: qty});
    stalls.add(st);
    _ev('market_list', {'item': id, 'qty': qty});
    _changed();
    return st;
  }

  /// Seller side: a stall was bought; the coins come in.
  bool stallSold(int slot) {
    final i = stalls.indexWhere((s) => s.slot == slot);
    if (i < 0) return false;
    final st = stalls.removeAt(i);
    coins += st.price;
    _stat('market_sold');
    _stat('market_coins', st.price);
    _snd('cash');
    _changed();
    return true;
  }

  /// Takes unsold goods back home.
  bool withdrawStall(int slot) {
    final i = stalls.indexWhere((s) => s.slot == slot);
    if (i < 0) return false;
    final st = stalls.removeAt(i);
    inv[st.item] = countOf(st.item) + st.qty;
    _changed();
    return true;
  }

  String? canBuyStall(int qty, int price) {
    if (level < marketLevel) return 'Chợ phiên mở ở cấp $marketLevel';
    if (coins < price) return 'Không đủ xu';
    if (!roomFor(qty)) return 'Kho không đủ chỗ';
    return null;
  }

  /// Buyer side (after the stall was claimed on the server).
  void boughtStall(String id, int qty, int price) {
    coins -= price;
    _gain(id, qty);
    _stat('market_bought');
    _snd('cash');
    _changed();
  }

  // ------------------------------------------------------------ achievements
  int achTier(AchDef a) => ach[a.id] ?? 0;

  /// Next tier can be claimed.
  bool achReady(AchDef a) => achTier(a) < a.tiers.length && a.value(this) >= a.tiers[achTier(a)];

  int get achReadyCount => achievements.where(achReady).length;

  /// Titles the player has earned (tier 1 claimed).
  List<AchDef> get earnedTitles => [for (final a in achievements) if (achTier(a) > 0) a];

  String? claimAch(AchDef a) {
    if (!achReady(a)) return 'Chưa đạt';
    final t = achTier(a);
    ach[a.id] = t + 1;
    coins += achCoins[t];
    addXp(achXp[t]);
    _snd('quest');
    _ev('achievement', {'id': a.id, 'tier': t + 1});
    _changed();
    return null;
  }

  String? setTitle(String id) {
    if (id.isNotEmpty) {
      final a = achById(id);
      if (a == null || achTier(a) == 0) return 'Chưa có danh hiệu này';
    }
    title = id;
    _changed();
    return null;
  }

  String get titleText => achById(title)?.title ?? '';

  // ------------------------------------------------------------ tutorial
  bool get tutActive => tut < tutDone;
  Tut? get tutStep => tutActive ? Tut.values[tut.clamp(0, Tut.values.length - 1)] : null;

  int _count(String prefix) => stats.entries.where((e) => e.key.startsWith(prefix)).fold(0, (a, e) => a + e.value);

  /// Moves the tutorial on when its step is done. True if it moved.
  bool tutCheck() {
    final s = tutStep;
    if (s == null) return false;
    final done = switch (s) {
      Tut.plant => _count('plant:') > 0,
      Tut.harvest => _count('harvest:') > 0,
      Tut.order => (stats['order'] ?? 0) > 0,
      Tut.build => _count('build:') > 0,
      Tut.end => false,
    };
    if (!done) return false;
    tut++;
    _ev('tutorial', {'step': tut});
    _changed();
    return true;
  }

  void tutFinish() {
    if (!tutActive) return;
    _ev('tutorial', {'step': tut, 'done': 1});
    tut = tutDone;
    _changed();
  }

  /// The object the current step points at, if any.
  Obj? get tutTarget {
    final s = tutStep;
    if (s == Tut.plant) {
      for (final o in objs) {
        if (o.def.kind == BKind.paddy && o.crop == null) return o;
      }
    }
    if (s == Tut.harvest) {
      Obj? best;
      for (final o in objs) {
        if ((o.def.kind == BKind.paddy || o.def.kind == BKind.bed) && o.crop != null) {
          if (best == null || o.end < best.end) best = o;
        }
      }
      return best;
    }
    return null;
  }
}

// ---------------------------------------------------------------- recovery
/// Rebuilds a lost farm from its public leaderboard row (2026-11-05: an
/// update failed to read a level-19 save and the cloud copy was replaced).
/// The layout is gone, so the farm gets its level, house, village projects
/// and land back, plus coins to rebuild what was on it.
extension FarmRecover on Farm {
  static const recoverMinGap = 3;

  bool get recovered => (stats['recovered'] ?? 0) > 0;

  /// Coins to rebuild fields, pens, workshops and trees of a farm at [lvl].
  static int recoverCoins(int lvl) => 400000 + lvl * lvl * 12000;

  void recoverFrom({required int lvl, required int houseLv, required int projectCount, required int orders, required String farmName}) {
    level = math.max(level, lvl);
    xp = 0;
    final h = house;
    if (h != null) h.level = houseLv.clamp(h.level, houseLevels.length - 1);
    stats['house'] = houseLevel;
    // land: as many lots as the level allows, growing out from the yard
    final maxLots = [for (var n = 0; n < lotsPerSide * lotsPerSide; n++) lotLevel(n)].where((l) => l <= level).length;
    while (lots.length < maxLots) {
      int? pick;
      var best = 1 << 30;
      for (var lot = 0; lot < lotsPerSide * lotsPerSide; lot++) {
        if (lots.contains(lot) || !lotAdjacent(lot)) continue;
        final lx = lot % lotsPerSide, ly = lot ~/ lotsPerSide;
        final d = (lx - 1.5).abs() + (ly - 1.5).abs() + (lx >= 4 || ly >= 4 ? 10 : 0);
        if (d * 100 + lot < best) {
          best = (d * 100 + lot).round();
          pick = lot;
        }
      }
      if (pick == null) break;
      lots.add(pick);
    }
    // village projects, placed on free owned land
    for (final id in projectOrder.take(projectCount)) {
      if (has(id)) continue;
      final d = bdef(id);
      if (d.w > 0) {
        var placed = false;
        for (var y = 2; y < mapSize && !placed; y++) {
          for (var x = 0; x < mapSize && !placed; x++) {
            final px = Farm.snapX(id, x);
            if (canPlace(id, px, y)) {
              _add(id, px, y);
              placed = true;
            }
          }
        }
      }
      projects.add(id);
      stats['project:$id'] = 1;
    }
    stats['order'] = math.max(stats['order'] ?? 0, orders);
    stats['lot'] = lots.length;
    stats['recovered'] = lvl;
    // skip the guided quests the farm had long finished
    var q = 0;
    while (q < questChain.length) {
      final d = questChain[q];
      if (d.key == 'level' && d.target > level) break;
      q++;
    }
    quest = math.max(quest, q);
    final n = currentQuest;
    questBase = n == null ? 0 : (stats[n.key] ?? 0);
    tut = tutDone;
    if (name.isEmpty) name = farmName;
    coins += recoverCoins(lvl);
    for (final e in const {'thoc': 40, 'rom': 20, 'cam': 20, 'gao': 10}.entries) {
      inv[e.key] = (inv[e.key] ?? 0) + e.value;
    }
    _ev('recover', {'level': lvl});
    _changed();
  }
}
