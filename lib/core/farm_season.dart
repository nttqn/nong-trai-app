// Mùa vụ, lễ hội và sân phơi thóc. A part of farm.dart so it can use the
// farm's private helpers.

part of 'farm.dart';

extension FarmSeason on Farm {
  // ------------------------------------------------------------ seasons
  DateTime get today => calendarDay(now());
  Season get season => seasonOf(today);
  bool cropInSeason(CropDef c) => inSeason(c.id, today);

  // ------------------------------------------------------------ festivals
  static const festLevel = 3;

  /// The festival going on today (whether or not its orders are rolled).
  FestivalTime? get festival => festivalOn(today);

  /// Today's festival with its orders ready to deliver.
  FestivalTime? get activeFestival {
    if (level < festLevel) return null;
    final f = festival;
    return f != null && f.key == festKey && fest.isNotEmpty ? f : null;
  }

  int get festAllBonus => 200 * level;
  bool get festAllDone => fest.isNotEmpty && fest.every((o) => o.waitUntil < 0);
  int get festReadyCount => activeFestival == null
      ? 0
      : fest.where((o) => o.waitUntil >= 0 && o.need.entries.every((e) => countOf(e.key) >= e.value)).length;

  /// Festival orders when a festival begins.
  void rollFestival() {
    if (level < festLevel) return;
    final f = festival;
    if (f == null || f.key == festKey) return;
    festKey = f.key;
    fest.clear();
    final rng = math.Random(seed * 53 + f.key.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x3fffffff));
    final can = producible();
    final pool = [for (final g in f.def.goods) if (can.contains(g)) g];
    // not enough festival goods yet: the dearest things the farm makes
    final rest = can.where((g) => !pool.contains(g)).toList()
      ..sort((a, b) => item(b).price.compareTo(item(a).price));
    while (pool.length < 5 && rest.isNotEmpty) {
      pool.add(rest.removeAt(0));
    }
    for (var tier = 0; tier < 3; tier++) {
      fest.add(_makeDaily(rng, tier, goods: pool, pay: 1.2));
    }
    _ev('festival_start', {'festival': f.def.id, 'level': level});
    _changed();
  }

  String? deliverFest(Order o) {
    final f = activeFestival;
    if (f == null) return 'Lễ hội đã qua';
    if (o.waitUntil < 0) return 'Đã giao rồi';
    if (!_spend(o.need)) return 'Chưa đủ hàng';
    coins += o.coins;
    addXp(o.xp);
    o.waitUntil = -1;
    _stat('fest');
    _snd('cash');
    if (festAllDone) {
      coins += festAllBonus;
      giftDeco[f.def.deco] = (giftDeco[f.def.deco] ?? 0) + 1;
      _stat('fest:${f.def.id}');
      if (house != null) _fx(house!, '🎁 ${bdef(f.def.deco).name}');
      _snd('quest');
      _ev('festival_done', {'festival': f.def.id, 'level': level});
    }
    _changed();
    return null;
  }

  int giftCount(String deco) => giftDeco[deco] ?? 0;

  // ------------------------------------------------------------ sân phơi
  static const yardLevel = 3;
  static const yardCap = 40;
  static const yardNeedMs = 90 * 60 * 1000;
  /// Dried grain gives this much more; rain on spread grain spoils this much.
  static const yardBonus = .5, yardRainLoss = .25;
  static const grains = {'thoc', 'nep', 'thoctam'};

  Obj? get dryingYard {
    for (final o in objs) {
      if (o.type == 'san_phoi') return o;
    }
    return null;
  }

  int get yardTotal => yard.values.fold(0, (a, b) => a + b);
  bool get yardDone => yard.isNotEmpty && yardDry >= yardNeedMs;
  bool get yardWetOut => yard.isNotEmpty && !yardDone && !yardCover;
  double get yardProgress => yard.isEmpty ? 0 : (yardDry / yardNeedMs).clamp(0.0, 1.0);
  int get yardBonusCount => yard.values.fold(0, (a, b) => a + (b * yardBonus).ceil());

  /// Work out the drying (and any rain) since the yard was last looked at.
  void settleYard() {
    final t1 = now();
    if (yard.isEmpty || yardDone || yardCover || yardT == 0 || yardT >= t1) {
      yardT = t1;
      return;
    }
    var t = yardT;
    var lost = 0;
    while (t < t1 && yardDry < yardNeedMs) {
      final block = t ~/ weatherBlockMs;
      final end = math.min(weatherEndsAt(t), t1);
      switch (weatherAt(t)) {
        case Weather.rain:
          if (block != yardWet) {
            yardWet = block;
            for (final k in yard.keys.toList()) {
              final l = (yard[k]! * yardRainLoss).ceil();
              lost += l;
              yard[k] = yard[k]! - l;
            }
            yard.removeWhere((_, v) => v <= 0);
            yardDry = 0;
          }
        case Weather.drought:
          yardDry += 2 * (end - t);
        case Weather.sunny:
          yardDry += end - t;
      }
      if (yard.isEmpty) break;
      t = end;
    }
    yardDry = math.min(yardDry, yardNeedMs);
    yardT = t1;
    if (lost > 0) {
      yardLost += lost;
      final o = dryingYard;
      if (o != null) _fx(o, '🌧️ -$lost thóc ướt');
      _changed();
    }
  }

  /// Spread freshly reaped grain on the yard; returns how much went out.
  int _spreadGrain(String product, int n) {
    if (!grains.contains(product) || dryingYard == null) return 0;
    settleYard();
    final add = math.min(n, yardCap - yardTotal);
    if (add <= 0) return 0;
    final old = yardTotal;
    yardDry = old == 0 ? 0 : (yardDry * old / (old + add)).round();
    yard[product] = (yard[product] ?? 0) + add;
    // in the rain the grain goes straight under the tarp
    if (weather == Weather.rain) {
      yardCover = true;
      yardWet = now() ~/ weatherBlockMs;
    }
    yardT = now();
    return add;
  }

  String? collectYard() {
    settleYard();
    if (yard.isEmpty) return 'Sân phơi đang trống: gặt lúa sẽ có thóc đem phơi';
    if (!yardDone) return 'Thóc chưa khô';
    final bonus = {for (final e in yard.entries) e.key: (e.value * yardBonus).ceil()};
    final n = bonus.values.fold(0, (a, b) => a + b);
    if (!roomFor(n)) return 'Kho đầy! Bán bớt hoặc nâng cấp nhà';
    bonus.forEach(_gain);
    final o = dryingYard;
    if (o != null) _fx(o, '+$n ${item(bonus.keys.first).icon}', item: bonus.keys.first);
    addXp(math.max(1, n ~/ 4));
    _stat('dry', n);
    yard.clear();
    yardDry = 0;
    yardCover = false;
    yardLost = 0;
    _snd('collect');
    _changed();
    return null;
  }

  /// Pull the tarp over the grain (pauses drying) or take it off.
  String? coverYard(bool on) {
    settleYard();
    if (yard.isEmpty || yardDone) return null;
    if (yardCover == on) return null;
    if (!on && weather == Weather.rain) return 'Trời đang mưa, tạnh rồi hãy phơi';
    yardCover = on;
    yardT = now();
    _snd('place');
    _changed();
    return null;
  }

  /// Start of the next rain (now if raining), looking a day ahead.
  int? get nextRainAt {
    var t = now();
    for (var i = 0; i < 9; i++) {
      if (weatherAt(t) == Weather.rain) return t;
      t = weatherEndsAt(t);
    }
    return null;
  }

  /// When the spread grain will be dry if left out (null when covered,
  /// empty, done, or rain comes first).
  int? get yardReadyAt {
    if (!yardWetOut) return null;
    var t = now();
    var left = yardNeedMs - yardDry;
    for (var i = 0; i < 16; i++) {
      final w = weatherAt(t);
      if (w == Weather.rain) return null;
      final rate = w == Weather.drought ? 2 : 1;
      final end = weatherEndsAt(t);
      if ((end - t) * rate >= left) return t + (left / rate).ceil();
      left -= (end - t) * rate;
      t = end;
    }
    return null;
  }

  /// Rain is coming before the grain is dry (the tarp should go on).
  bool get yardRainSoon {
    if (!yardWetOut) return false;
    final r = nextRainAt;
    return r != null && yardReadyAt == null && r - now() <= 30 * 60 * 1000;
  }

  // ------------------------------------------------------------ ký ức làng quê
  int get memNewCount => mem.values.where((v) => v == 1).length;

  /// Open the memories whose milestone is reached. Those already reached
  /// when the game starts open quietly (no card for each one at once).
  void checkMemories() {
    var changed = false;
    for (final m in memories) {
      if (mem.containsKey(m.id) || !m.done(this)) continue;
      mem[m.id] = 1;
      changed = true;
      if (_memInit) memFresh.add(m.id);
    }
    _memInit = true;
    if (changed) _changed();
  }

  /// Read a memory for the first time: its gift.
  String? readMemory(String id) {
    final m = memoryById(id);
    if (m == null || mem[id] != 1) return null;
    mem[id] = 2;
    coins += m.coins;
    _stat('memory');
    _snd('coin');
    _ev('memory_read', {'id': id, 'level': level});
    _changed();
    return null;
  }
}
