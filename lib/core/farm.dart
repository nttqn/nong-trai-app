// The whole farm state and every rule that changes it. Pure Dart (no
// Flutter widgets) so it can be unit-tested; time comes from [now].

import 'dart:math' as math;

import 'achievements.dart';
import 'calendar.dart';
import 'defs.dart';
import 'memories.dart';
import 'quests.dart';
import 'weather.dart';

part 'farm_more.dart';
part 'farm_season.dart';

typedef NowFn = int Function();
int wallClock() => DateTime.now().millisecondsSinceEpoch;

class Job {
  final String recipe;
  int end;
  Job(this.recipe, this.end);
  Map<String, dynamic> toJson() => {'r': recipe, 'e': end};
  factory Job.fromJson(Map<String, dynamic> j) => Job(j['r'], j['e']);
}

class Obj {
  final int id;
  final String type;
  int x, y;
  String? crop; // field crop or pond fish
  int start = 0, end = 0; // growth/production window, ms epoch; end 0 = idle
  int count = 0; // animals in a pen
  int level = 0; // house level
  int stolen = 0; // taken by neighbours from the current harvest
  List<Job> jobs = [];
  Obj(this.id, this.type, this.x, this.y);

  BuildingDef get def => bdef(type);
  int get w => def.w;
  int get h => def.h;
  bool contains(int tx, int ty) => tx >= x && ty >= y && tx < x + w && ty < y + h;

  Map<String, dynamic> toJson() => {
        'i': id, 't': type, 'x': x, 'y': y,
        if (crop != null) 'c': crop,
        if (start != 0) 's': start,
        if (end != 0) 'e': end,
        if (count != 0) 'n': count,
        if (level != 0) 'l': level,
        if (stolen != 0) 'st': stolen,
        if (jobs.isNotEmpty) 'j': [for (final j in jobs) j.toJson()],
      };
  factory Obj.fromJson(Map<String, dynamic> j) => Obj(j['i'], j['t'], j['x'], j['y'])
    ..crop = j['c']
    ..start = j['s'] ?? 0
    ..end = j['e'] ?? 0
    ..count = j['n'] ?? 0
    ..level = j['l'] ?? 0
    ..stolen = j['st'] ?? 0
    ..jobs = [for (final e in (j['j'] as List? ?? [])) Job.fromJson(e)];
}

class Order {
  final int id;
  final String who;
  final Map<String, int> need;
  final int coins, xp;
  int waitUntil; // >0: slot is empty until then (after a discard)
  Order(this.id, this.who, this.need, this.coins, this.xp, {this.waitUntil = 0});
  Map<String, dynamic> toJson() =>
      {'i': id, 'w': who, 'n': need, 'c': coins, 'x': xp, 'u': waitUntil};
  factory Order.fromJson(Map<String, dynamic> j) => Order(j['i'], j['w'],
      Map<String, int>.from(j['n']), j['c'], j['x'], waitUntil: j['u'] ?? 0);
}

/// Something worth a floating label on the map (tile coords + text).
class Fx {
  final double x, y;
  final String text;
  /// An experience badge (drawn blue, a moment after the item label).
  final bool xp;
  Fx(this.x, this.y, this.text, {this.xp = false});
}

class Farm {
  NowFn now;
  int coins = 300, xp = 0, level = 1;
  int nextId = 1, seed = 1;
  final Set<int> lots = {};
  final Map<String, int> inv = {};
  final List<Obj> objs = [];
  final Set<String> projects = {}; // finished village projects
  final Map<String, int> projectLv = {}; // upgrades: 2 or 3 (absent = 1)
  // Đơn đặc biệt hằng ngày: rolled each local day; waitUntil -1 = delivered.
  int dailyDay = 0;
  final List<Order> daily = [];
  final List<Order> orders = [];
  final Map<String, int> stats = {};
  int quest = 0, questBase = 0;
  /// Quà đăng nhập: day key of the last gift and the streak day it was.
  int loginDay = 0, loginStreak = 0;
  /// Achievement tiers claimed, and the title shown to neighbours.
  final Map<String, int> ach = {};
  String title = '';
  /// Goods on this player's market stall.
  final List<Stall> stalls = [];
  /// Lễ hội: the festival whose orders are in [fest], and festival
  /// decorations won but not placed yet.
  String festKey = '';
  final List<Order> fest = [];
  final Map<String, int> giftDeco = {};
  /// Sân phơi: grain spread out to dry, how long it has dried (ms), when
  /// that was last worked out, the rain block that last soaked it, grain
  /// lost to rain since it was spread, and whether the tarp is on.
  final Map<String, int> yard = {};
  int yardDry = 0, yardT = 0, yardWet = -1, yardLost = 0;
  bool yardCover = false;
  /// Ký ức làng quê: 1 = opened, not read yet; 2 = read (gift taken).
  final Map<String, int> mem = {};
  /// Memories opened while playing, for the "ký ức mới" card (not saved).
  final List<String> memFresh = [];
  bool _memInit = false;
  /// Tutorial step (new farms start at 0; [tutDone] when finished).
  int tut = tutDone;
  int rev = 0; // bumps on every change (render caches, autosave)
  final List<Fx> fx = [];
  void Function(int level)? onLevelUp;
  /// Sound cue for each successful action (file names in SoundService).
  void Function(String cue)? onSound;
  void _snd(String cue) => onSound?.call(cue);
  /// Analytics event for milestones (build, order, quest, ...).
  void Function(String name, Map<String, Object> params)? onEvent;
  void _ev(String name, [Map<String, Object> p = const {}]) => onEvent?.call(name, p);
  /// When this farm was last saved (ms since epoch); newest wins in cloud sync.
  int savedAt = 0;
  /// Farm name shown on the leaderboard (empty until the player picks one).
  String name = '';

  Farm({NowFn? now}) : now = now ?? wallClock;

  // ---------------------------------------------------------------- setup
  static Farm fresh({NowFn? now, int seed = 7}) {
    final f = Farm(now: now)..seed = seed;
    f.lots.addAll([lotIndex(1, 1), lotIndex(2, 1)]);
    f._add('nha', 6, 6);
    for (var i = 0; i < 4; i++) {
      f._add('ruong', 13 + (i % 2), 7 + i ~/ 2);
    }
    f._add('luong', 15, 7);
    f._add('tre', 6, 10);
    f._add('tre', 7, 11);
    f._add('rom_dong', 9, 6);
    f._scatterObstacles();
    f.inv['thoc'] = 6;
    f.tut = 0;
    f._fillOrders();
    return f;
  }

  Obj _add(String type, int x, int y) {
    final o = Obj(nextId++, type, x, y);
    objs.add(o);
    if (type == 'nha') o.level = 0;
    if (bdef(type).kind == BKind.tree) {
      final t = trees[type]!;
      o.start = now();
      o.end = o.start + _dur(t.seconds, _treeSpeed);
    }
    _occ = null;
    return o;
  }

  /// Bushes, rocks and stumps to clear, on every lot (or only [only]).
  void _scatterObstacles([bool Function(int lot)? only, int salt = 0]) {
    final rng = math.Random(seed + salt);
    const kinds = ['bui', 'bui', 'da', 'goc_cay'];
    for (var lot = 0; lot < lotsPerSide * lotsPerSide; lot++) {
      if (only != null && !only(lot)) continue;
      final starting = lots.contains(lot);
      final n = starting ? 3 : 4 + rng.nextInt(4);
      final lx = (lot % lotsPerSide) * lotSize, ly = (lot ~/ lotsPerSide) * lotSize;
      var tries = 0, placed = 0;
      while (placed < n && tries++ < 60) {
        final x = lx + rng.nextInt(lotSize), y = ly + rng.nextInt(lotSize);
        if (starting && (x < 10 || y < 8 || x > 15)) continue; // keep the yard clear
        if (_canPlaceRaw(1, 1, x, y, ignoreOwnership: true)) {
          _add(kinds[rng.nextInt(kinds.length)], x, y);
          placed++;
        }
      }
    }
  }

  // ---------------------------------------------------------------- map
  static int lotIndex(int lx, int ly) => lx + ly * lotsPerSide;
  static int lotOf(int x, int y) => lotIndex(x ~/ lotSize, y ~/ lotSize);

  static const roadX = 11;

  static String terrain(int x, int y) {
    if (y <= 1 || isLake(x, y)) return 'water';
    if (x == roadX) return 'road';
    return 'grass';
  }

  /// The lake (hồ sen) in the south-east of the outer ring.
  static bool isLake(int x, int y) {
    final dx = (x + .5 - 29.5) / 3.3, dy = (y + .5 - 29.5) / 2.6;
    return dx * dx + dy * dy <= 1;
  }

  /// Buildings that stand across the village road (the gate).
  static bool spansRoad(String type) => type == 'cong_lang';

  /// Where a placement preview of [type] may sit along x: a road-spanning
  /// building is centred on the road, everything else stays put.
  static int snapX(String type, int x) => spansRoad(type) ? roadX - bdef(type).w ~/ 2 : x;

  bool owned(int x, int y) => lots.contains(lotOf(x, y));

  List<int?>? _occ;
  List<int?> get occ {
    if (_occ != null) return _occ!;
    final m = List<int?>.filled(mapSize * mapSize, null);
    for (final o in objs) {
      for (var dx = 0; dx < o.w; dx++) {
        for (var dy = 0; dy < o.h; dy++) {
          final x = o.x + dx, y = o.y + dy;
          if (x < 0 || y < 0 || x >= mapSize || y >= mapSize) continue;
          m[x + y * mapSize] = o.id;
        }
      }
    }
    return _occ = m;
  }

  Obj? objAt(int x, int y) {
    if (x < 0 || y < 0 || x >= mapSize || y >= mapSize) return null;
    final id = occ[x + y * mapSize];
    return id == null ? null : byId(id);
  }

  Obj? byId(int id) {
    for (final o in objs) {
      if (o.id == id) return o;
    }
    return null;
  }

  bool _canPlaceRaw(int w, int h, int x, int y,
      {int? ignore, bool ignoreOwnership = false}) {
    for (var dx = 0; dx < w; dx++) {
      for (var dy = 0; dy < h; dy++) {
        final tx = x + dx, ty = y + dy;
        if (tx < 0 || ty < 0 || tx >= mapSize || ty >= mapSize) return false;
        if (terrain(tx, ty) != 'grass') return false;
        if (!ignoreOwnership && !owned(tx, ty)) return false;
        final id = occ[tx + ty * mapSize];
        if (id != null && id != ignore) return false;
      }
    }
    return true;
  }

  bool canPlace(String type, int x, int y, {int? ignore}) {
    final d = bdef(type);
    if (spansRoad(type)) return _canSpanRoad(d, x, y, ignore: ignore);
    return _canPlaceRaw(d.w, d.h, x, y, ignore: ignore);
  }

  /// The gate: centred on the road, every tile owned and free, the side
  /// tiles on grass.
  bool _canSpanRoad(BuildingDef d, int x, int y, {int? ignore}) {
    if (x != snapX(d.id, x) || y <= 1 || y + d.h > mapSize) return false;
    for (var dx = 0; dx < d.w; dx++) {
      for (var dy = 0; dy < d.h; dy++) {
        final tx = x + dx, ty = y + dy;
        if (tx == roadX) {
          if (!owned(tx, ty)) return false;
          final id = occ[tx + ty * mapSize];
          if (id != null && id != ignore) return false;
        } else if (!_canPlaceRaw(1, 1, tx, ty, ignore: ignore)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Saves from before the gate spanned the road: move it onto the road
  /// (nearest free row), or leave it where it is if there is no room.
  void _fixRoadBuildings() {
    for (final o in objs) {
      if (!spansRoad(o.type) || canPlace(o.type, o.x, o.y, ignore: o.id)) continue;
      final rows = [for (var y = 2; y < mapSize; y++) y]..sort((a, b) => (a - o.y).abs().compareTo((b - o.y).abs()));
      for (final y in rows) {
        if (canPlace(o.type, snapX(o.type, o.x), y, ignore: o.id)) {
          o.x = snapX(o.type, o.x);
          o.y = y;
          _occ = null;
          break;
        }
      }
    }
  }

  // ---------------------------------------------------------------- bonuses
  bool has(String project) => projects.contains(project);
  int projectLevel(String id) => has(id) ? (projectLv[id] ?? 1) : 0;
  /// A project's bonus (fraction): base × 1 / 1.5 / 2 by its level.
  double _pb(String id) => has(id) ? projectEffects[id]!.$2 / 100 * projectMult[projectLevel(id) - 1] : 0;
  double get _all => _pb('dinh_lang');
  double get _bedSpeed => _pb('gieng') + _all;
  double get _paddySpeed => _pb('tram_bom') + _all;
  double get _factorySpeed => _pb('tram_dien') + _all;
  double get _animalSpeed => _pb('tram_y_te') + _all;
  double get _treeSpeed => _all;
  double get _fishSpeed => _all;
  double get xpBonus => _pb('cong_lang') + _pb('truong');
  double get orderBonus => _pb('duong_be_tong') + _pb('nha_van_hoa') + extraHouseCount * extraHouseOrderBonus;
  double get marketBonus => _pb('cho_que');

  /// The next upgrade of a finished project, or null at the top.
  ProjectUpgrade? nextProjectUpgrade(String id) {
    final lv = projectLevel(id);
    final ups = projectUpgrades[id];
    if (lv == 0 || ups == null || lv - 1 >= ups.length) return null;
    return ups[lv - 1];
  }

  String? canUpgradeProject(String id) {
    final u = nextProjectUpgrade(id);
    if (u == null) return 'Đã nâng cấp tối đa';
    if (level < u.level) return 'Cần đạt cấp ${u.level}';
    if (coins < u.coins) return 'Không đủ xu';
    for (final e in u.goods.entries) {
      if (countOf(e.key) < e.value) return 'Thiếu ${item(e.key).name}';
    }
    return null;
  }

  String? upgradeProject(String id) {
    final err = canUpgradeProject(id);
    if (err != null) return err;
    final u = nextProjectUpgrade(id)!;
    coins -= u.coins;
    _spend(u.goods);
    final lv = projectLevel(id) + 1;
    projectLv[id] = lv;
    stats['project_lv:$id'] = lv;
    _stat('project_up');
    _snd('build');
    addXp(bdef(id).xp * lv);
    for (final o in objs) {
      if (o.type == id) _fx(o, '⬆️ Cấp $lv');
    }
    _ev('project_upgrade', {'type': id, 'to': lv});
    _changed();
    return null;
  }
  int get orderSlots => 4 + (has('cho_que') ? 1 : 0) + (has('nha_van_hoa') ? 1 : 0);

  int _dur(int seconds, double speed) => (seconds * 1000 * (1 - speed)).round();
  /// Growing time of [c] if planted now: the village bonus, then the
  /// weather (rain helps; a dry spell hurts fields without irrigation).
  int cropMs(CropDef c) {
    final ms = _dur(c.seconds, c.plot == Plot.paddy ? _paddySpeed : _bedSpeed);
    return (ms * weatherCropMult(c) * (cropInSeason(c) ? 1 - seasonSpeed : 1)).round();
  }

  Weather get weather => weatherAt(now());

  /// 0.8 under rain, 1.25 in a dry spell unless irrigated, else 1.
  double weatherCropMult(CropDef c) => switch (weather) {
        Weather.rain => 1 - rainSpeed,
        Weather.drought => has(c.plot == Plot.paddy ? 'tram_bom' : 'gieng') ? 1 : 1 + droughtSlow,
        Weather.sunny => 1,
      };
  int animalMs(AnimalDef a) => _dur(a.seconds, _animalSpeed);
  int fishMs(FishDef f) => _dur(f.seconds, _fishSpeed);
  int recipeMs(RecipeDef r) => _dur(r.seconds, _factorySpeed);

  // ---------------------------------------------------------------- economy
  int get houseLevel => house?.level ?? 0;
  Obj? get house {
    for (final o in objs) {
      if (o.type == 'nha') return o;
    }
    return null;
  }

  /// The extra houses (nhà con cháu) built so far.
  Iterable<Obj> get extraHouses => objs.where((o) => o.type == 'nha_phu');
  int get extraHouseCount => extraHouses.length;
  int extraHouseCap(Obj o) => (houseLevels[o.level].storage * extraHouseStorage).round();

  /// An extra house can go one style up, but never past the main house.
  HouseLevel? nextExtraHouse(Obj o) =>
      o.level + 1 < houseLevels.length && o.level + 1 <= houseLevel ? houseLevels[o.level + 1] : null;

  String? upgradeExtraHouse(Obj o) {
    if (o.level + 1 >= houseLevels.length) return 'Nhà đã nâng cấp tối đa';
    final n = nextExtraHouse(o);
    if (n == null) return 'Nâng cấp nhà chính trước đã';
    if (level < n.level) return 'Cần đạt cấp ${n.level}';
    if (coins < n.cost) return 'Không đủ xu';
    coins -= n.cost;
    o.level++;
    _ev('extra_house_upgrade', {'house': o.level, 'level': level});
    _snd('build');
    addXp(25 * o.level);
    _fx(o, '🏡 ${n.name}');
    _changed();
    return null;
  }

  int get storageCap =>
      houseLevels[houseLevel].storage +
      extraHouses.fold<int>(0, (s, o) => s + extraHouseCap(o)) +
      objs.where((o) => o.def.kind == BKind.storage).fold(0, (s, o) => s + warehouseLevels[o.level].storage);

  int get warehouseCount => objs.where((o) => o.def.kind == BKind.storage).length;

  WarehouseLevel? nextWarehouse(Obj o) =>
      o.level + 1 < warehouseLevels.length ? warehouseLevels[o.level + 1] : null;

  String? upgradeWarehouse(Obj o) {
    final n = nextWarehouse(o);
    if (n == null) return 'Nhà kho đã nâng cấp tối đa';
    if (level < n.level) return 'Cần đạt cấp ${n.level}';
    if (coins < n.cost) return 'Không đủ xu';
    coins -= n.cost;
    o.level++;
    _snd('build');
    addXp(15 * o.level);
    _fx(o, '📦 +${n.storage - warehouseLevels[o.level - 1].storage}');
    _ev('warehouse_upgrade', {'level': o.level});
    _changed();
    return null;
  }
  int get stored => inv.values.fold(0, (a, b) => a + b);
  int countOf(String id) => inv[id] ?? 0;
  bool roomFor(int n) => stored + n <= storageCap;

  void _gain(String id, int n) {
    inv[id] = countOf(id) + n;
    _stat('get:$id', n);
  }

  bool _spend(Map<String, int> goods) {
    for (final e in goods.entries) {
      if (countOf(e.key) < e.value) return false;
    }
    for (final e in goods.entries) {
      inv[e.key] = countOf(e.key) - e.value;
      if (inv[e.key] == 0) inv.remove(e.key);
    }
    return true;
  }

  void addXp(int n) {
    final gained = (n * (1 + xpBonus)).round();
    xp += gained;
    _xpGained += gained;
    while (xp >= xpToNext(level)) {
      xp -= xpToNext(level);
      level++;
      coins += 20 * level;
      onLevelUp?.call(level);
    }
    stats['level'] = level;
  }

  void _stat(String key, [int n = 1]) => stats[key] = (stats[key] ?? 0) + n;

  void _changed() {
    rev++;
    _occ = null;
    _flushXp();
  }

  // experience gained by the current action, shown as one "+N KN" badge
  // where the action happened (at the house when it has no place)
  int _xpGained = 0;
  (double, double)? _xpAt;

  void _flushXp() {
    if (_xpGained > 0) {
      final h = house;
      final at = _xpAt ?? (h == null ? (12.0, 9.0) : (h.x + h.w / 2, h.y + h.h / 2));
      fx.add(Fx(at.$1 + .3, at.$2 + .3, '+$_xpGained KN', xp: true));
    }
    _xpGained = 0;
    _xpAt = null;
  }

  void _fx(Obj o, String text) {
    fx.add(Fx(o.x + o.w / 2, o.y + o.h / 2, text));
    _xpAt ??= (o.x + o.w / 2, o.y + o.h / 2);
  }

  // ---------------------------------------------------------------- building
  int buildCost(String type) {
    final d = bdef(type);
    if (d.kind == BKind.paddy || d.kind == BKind.bed) {
      final n = objs.where((o) => o.type == type).length;
      return d.cost + n * 5; // each extra plot a bit dearer
    }
    if (d.kind == BKind.storage) {
      return warehouseBuildCost[warehouseCount.clamp(0, warehouseBuildCost.length - 1)];
    }
    if (type == 'nha_phu') return extraHouseBuildCost[extraHouseCount.clamp(0, extraHouseBuildCost.length - 1)];
    return d.cost;
  }

  String? canBuy(String type) {
    final d = bdef(type);
    if (festivalDecos.contains(type)) {
      return giftCount(type) > 0 ? null : 'Quà lễ hội: giao đủ đơn lễ hội để nhận';
    }
    if (level < d.level) return 'Cần đạt cấp ${d.level}';
    if (d.unique && (projects.contains(type) || objs.any((o) => o.type == type))) {
      return 'Đã xây rồi';
    }
    if (d.kind == BKind.storage && warehouseCount >= warehouseMax) return 'Tối đa $warehouseMax nhà kho';
    if (type == 'nha_phu') {
      final n = extraHouseCount;
      if (n >= extraHouseLevels.length) return 'Tối đa ${extraHouseLevels.length} nhà con cháu';
      if (level < extraHouseLevels[n]) return 'Cần đạt cấp ${extraHouseLevels[n]}';
    }
    if (coins < buildCost(type)) return 'Không đủ xu';
    for (final e in d.goods.entries) {
      if (countOf(e.key) < e.value) return 'Thiếu ${item(e.key).name}';
    }
    return null;
  }

  String? build(String type, int x, int y) {
    final err = canBuy(type);
    if (err != null) return err;
    final d = bdef(type);
    if (d.w > 0 && !canPlace(type, x, y)) return 'Không đặt được ở đây';
    coins -= buildCost(type);
    _spend(d.goods);
    if (festivalDecos.contains(type)) giftDeco[type] = giftCount(type) - 1;
    if (d.kind == BKind.project) {
      projects.add(type);
      _stat('project:$type');
      _ev('village_project', {'type': type, 'level': level});
    }
    if (d.w > 0) {
      final o = _add(type, x, y);
      if (d.xp > 0) {
        _xpAt = (o.x + o.w / 2, o.y + o.h / 2);
      } else {
        _fx(o, '✓');
      }
    }
    _stat('build:$type');
    _ev('build', {'type': type, 'level': level});
    _snd('build');
    addXp(d.xp);
    _changed();
    return null;
  }

  String? move(Obj o, int x, int y) {
    if (!canPlace(o.type, x, y, ignore: o.id)) return 'Không đặt được ở đây';
    o.x = x;
    o.y = y;
    _snd('place');
    _changed();
    return null;
  }

  /// Plots, trees and decorations can be removed (no refund).
  bool canRemove(Obj o) {
    final k = o.def.kind;
    if (k == BKind.storage) return stored <= storageCap - warehouseLevels[o.level].storage;
    if (o.type == 'san_phoi' && yard.isNotEmpty) return false; // grain on it
    return k == BKind.paddy || k == BKind.bed || k == BKind.tree || k == BKind.deco;
  }

  void remove(Obj o) {
    objs.remove(o);
    // a festival gift goes back to the bag, to put somewhere else
    if (festivalDecos.contains(o.type)) giftDeco[o.type] = giftCount(o.type) + 1;
    _snd('remove');
    _changed();
  }

  String? clearObstacle(Obj o) {
    if (!owned(o.x, o.y)) return 'Phải mua mảnh đất này trước';
    final d = o.def;
    if (coins < d.cost) return 'Không đủ xu';
    coins -= d.cost;
    objs.remove(o);
    _stat('clear');
    _snd('chop');
    addXp(d.xp);
    _xpAt = (o.x + .5, o.y + .5);
    _changed();
    return null;
  }

  // ---------------------------------------------------------------- land
  bool lotAdjacent(int lot) {
    final lx = lot % lotsPerSide, ly = lot ~/ lotsPerSide;
    for (final d in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      final nx = lx + d[0], ny = ly + d[1];
      if (nx < 0 || ny < 0 || nx >= lotsPerSide || ny >= lotsPerSide) continue;
      if (lots.contains(lotIndex(nx, ny))) return true;
    }
    return false;
  }

  int get nextLotPrice => lotPrice(lots.length);
  int get nextLotLevel => lotLevel(lots.length);

  String? canBuyLot(int lot) {
    if (lots.contains(lot)) return 'Đã là đất của bạn';
    if (!lotAdjacent(lot)) return 'Chỉ mua được mảnh liền kề đất nhà';
    if (level < nextLotLevel) return 'Cần đạt cấp $nextLotLevel';
    if (coins < nextLotPrice) return 'Không đủ xu';
    return null;
  }

  String? buyLot(int lot) {
    final err = canBuyLot(lot);
    if (err != null) return err;
    coins -= nextLotPrice;
    lots.add(lot);
    _stat('lot');
    _ev('buy_lot', {'lots': lots.length});
    _snd('build');
    addXp(10 * lots.length);
    _changed();
    return null;
  }

  // ---------------------------------------------------------------- fields
  bool isReady(Obj o) => o.end != 0 && now() >= o.end;
  double progress(Obj o) {
    if (o.end == 0) return 0;
    final total = o.end - o.start;
    if (total <= 0) return 1;
    return ((now() - o.start) / total).clamp(0.0, 1.0);
  }

  int remainingMs(Obj o) => math.max(0, o.end - now());

  bool cropFits(Obj field, CropDef c) =>
      (c.plot == Plot.paddy) == (field.def.kind == BKind.paddy);

  String? plant(Obj f, String cropId) {
    final c = crops[cropId]!;
    if (!cropFits(f, c)) {
      return c.plot == Plot.paddy ? 'Lúa phải cấy dưới ruộng nước' : 'Cây này trồng trên luống';
    }
    if (f.crop != null) return null;
    if (level < c.level) return 'Cần đạt cấp ${c.level}';
    if (coins < c.seed) return 'Không đủ xu mua giống';
    coins -= c.seed;
    f.crop = cropId;
    f.start = now();
    f.end = f.start + cropMs(c);
    _stat('plant:$cropId');
    _snd('plant');
    _changed();
    return null;
  }

  String? harvest(Obj f) {
    if (f.crop == null || !isReady(f)) return null;
    final c = crops[f.crop]!;
    final extra = c.bonus != null ? 1 : 0;
    final n = readyYield(f);
    if (!roomFor(n + extra)) return 'Kho đầy! Bán bớt hoặc nâng cấp nhà';
    _gain(c.product, n);
    if (c.bonus != null) _gain(c.bonus!, 1);
    _stat('harvest:${c.id}');
    _snd('harvest');
    addXp(c.xp);
    _fx(f, '+$n ${item(c.product).icon}');
    if (c.plot == Plot.paddy) _spreadGrain(c.product, n);
    f.crop = null;
    f.start = f.end = 0;
    f.stolen = 0;
    _changed();
    return null;
  }

  String? fertilize(Obj f) {
    if (f.crop == null || isReady(f)) return null;
    if (countOf('phan') < 1) return 'Cần phân chuồng (nuôi trâu)';
    _spend({'phan': 1});
    final t = now();
    f.end = t + (f.end - t) ~/ 2;
    _stat('fertilize');
    _snd('sparkle');
    _fx(f, '⚡');
    _changed();
    return null;
  }

  // ---------------------------------------------------------------- trees
  String? pickTree(Obj o) {
    final t = trees[o.type]!;
    if (!isReady(o)) return null;
    final n = readyYield(o);
    if (!roomFor(n)) return 'Kho đầy!';
    _gain(t.product, n);
    _snd('pick');
    addXp(t.xp);
    _fx(o, '+$n ${item(t.product).icon}');
    o.stolen = 0;
    o.start = now();
    o.end = o.start + _dur(t.seconds, _treeSpeed);
    _changed();
    return null;
  }

  // ---------------------------------------------------------------- pens
  String? buyAnimal(Obj pen) {
    final a = animalForPen(pen.type)!;
    if (pen.count >= a.maxCount) return 'Chuồng đã đầy';
    if (coins < a.price) return 'Không đủ xu';
    coins -= a.price;
    pen.count++;
    _stat('buy:${a.id}');
    _snd(a.id);
    addXp(1);
    _changed();
    return null;
  }

  String? feed(Obj pen) {
    final a = animalForPen(pen.type)!;
    if (pen.count == 0) return 'Chuồng chưa có con nào';
    if (pen.end != 0) return null;
    if (countOf(a.feed) < pen.count) {
      return 'Cần ${pen.count} ${item(a.feed).name} để cho ăn';
    }
    _spend({a.feed: pen.count});
    pen.start = now();
    pen.end = pen.start + animalMs(a);
    _stat('feed:${a.id}');
    _snd('feed');
    _changed();
    return null;
  }

  String? collect(Obj pen) {
    final a = animalForPen(pen.type)!;
    if (!isReady(pen)) return null;
    final n = readyYield(pen);
    if (!roomFor(n)) return 'Kho đầy!';
    _gain(a.product, n);
    _snd(a.id);
    addXp(a.xp * pen.count);
    _fx(pen, '+$n ${item(a.product).icon}');
    pen.start = pen.end = 0;
    pen.stolen = 0;
    _changed();
    return null;
  }

  // ---------------------------------------------------------------- ponds
  String? stock(Obj pond, String fishId) {
    final f = fishes[fishId]!;
    if (pond.crop != null) return null;
    if (level < f.level) return 'Cần đạt cấp ${f.level}';
    if (coins < f.fry) return 'Không đủ xu mua giống';
    coins -= f.fry;
    pond.crop = fishId;
    pond.start = now();
    pond.end = pond.start + fishMs(f);
    _stat('stock:$fishId');
    _snd('splash');
    _changed();
    return null;
  }

  String? catchFish(Obj pond) {
    if (pond.crop == null || !isReady(pond)) return null;
    final f = fishes[pond.crop]!;
    final n = readyYield(pond);
    if (!roomFor(n)) return 'Kho đầy!';
    _gain(f.product, n);
    _snd('splash');
    addXp(f.xp);
    _fx(pond, '+$n ${item(f.product).icon}');
    pond.crop = null;
    pond.start = pond.end = 0;
    pond.stolen = 0;
    _changed();
    return null;
  }

  // ---------------------------------------------------------------- factories
  static const queueMax = 3;

  String? startJob(Obj fac, String recipeId) {
    final r = recipes[recipeId]!;
    if (level < r.level) return 'Cần đạt cấp ${r.level}';
    if (fac.jobs.length >= queueMax) return 'Hàng chờ đã đầy';
    if (!_spend(r.inputs)) return 'Thiếu nguyên liệu';
    final t = now();
    final begin = fac.jobs.isEmpty ? t : math.max(t, fac.jobs.last.end);
    fac.jobs.add(Job(recipeId, begin + recipeMs(r)));
    _snd('work');
    _changed();
    return null;
  }

  int readyJobs(Obj fac) => fac.jobs.where((j) => now() >= j.end).length;

  String? collectJobs(Obj fac) {
    final t = now();
    var got = 0;
    String? err;
    while (fac.jobs.isNotEmpty && t >= fac.jobs.first.end) {
      final r = recipes[fac.jobs.first.recipe]!;
      if (!roomFor(r.out)) {
        err = 'Kho đầy!';
        break;
      }
      fac.jobs.removeAt(0);
      _gain(r.product, r.out);
      addXp(r.xp);
      _fx(fac, '+${r.out} ${item(r.product).icon}');
      got++;
    }
    if (got > 0) {
      _snd('collect');
      _changed();
    }
    return err;
  }

  // ---------------------------------------------------------------- rewards

  /// What [speedUp] would skip on [o], in ms (0 = nothing to speed up).
  int speedUpMs(Obj o) {
    final t = now();
    if (o.def.kind == BKind.factory) {
      for (final j in o.jobs) {
        if (j.end > t) return j.end - t;
      }
      return 0;
    }
    return o.end > t ? o.end - t : 0;
  }

  /// Rewarded-ad boost: finishes what [o] is growing/making right now (for
  /// a workshop, the batch in progress; the queue behind it moves up).
  String? speedUp(Obj o) {
    final d = speedUpMs(o);
    if (d <= 0) return 'Không có gì để làm nhanh';
    if (o.def.kind == BKind.factory) {
      for (final j in o.jobs) {
        if (j.end > now()) j.end -= d;
      }
    } else {
      o.start -= d;
      o.end -= d;
    }
    _stat('speedup');
    _snd('sparkle');
    _fx(o, '⚡');
    _changed();
    return null;
  }

  /// Extra coins (rewarded ad on level-up).
  void bonusCoins(int n) {
    coins += n;
    _fx(house ?? objs.first, '+$n 🪙');
    _snd('coin');
    _changed();
  }

  /// Rough progress score: compares two saves of the same farm.
  int get progressScore => level * 1000000 + xp;

  // ---------------------------------------------------------------- house
  HouseLevel? get nextHouse =>
      houseLevel + 1 < houseLevels.length ? houseLevels[houseLevel + 1] : null;

  String? upgradeHouse() {
    final n = nextHouse;
    if (n == null) return 'Nhà đã nâng cấp tối đa';
    if (level < n.level) return 'Cần đạt cấp ${n.level}';
    if (coins < n.cost) return 'Không đủ xu';
    coins -= n.cost;
    house!.level++;
    stats['house'] = house!.level;
    _ev('house_upgrade', {'house': house!.level, 'level': level});
    _snd('build');
    addXp(25 * house!.level);
    _fx(house!, '🏠 ${n.name}');
    _changed();
    return null;
  }

  // ---------------------------------------------------------------- market
  int sellPrice(String id) => (item(id).price * (1 + marketBonus)).round();

  String? sell(String id, int n) {
    if (countOf(id) < n || n <= 0) return 'Không đủ hàng';
    _spend({id: n});
    coins += sellPrice(id) * n;
    _stat('sell', n);
    _snd('coin');
    _changed();
    return null;
  }

  // ---------------------------------------------------------------- orders
  /// Items the player can currently produce (orders only ask for these).
  List<String> producible() {
    final out = <String>{};
    final types = objs.map((o) => o.type).toSet();
    for (final c in crops.values) {
      if (c.level <= level) {
        final plot = c.plot == Plot.paddy ? 'ruong' : 'luong';
        if (types.contains(plot)) out.add(c.product);
      }
    }
    for (final o in objs) {
      final k = o.def.kind;
      if (k == BKind.pen && o.count > 0) out.add(animalForPen(o.type)!.product);
      if (k == BKind.tree) out.add(trees[o.type]!.product);
    }
    if (types.contains('ao')) {
      for (final f in fishes.values) {
        if (f.level <= level) out.add(f.product);
      }
    }
    for (final r in recipes.values) {
      if (r.level <= level && types.contains(r.building) &&
          r.inputs.keys.every(out.contains)) {
        out.add(r.product);
      }
    }
    out.remove('rom');
    out.remove('phan');
    return out.toList()..sort();
  }

  Order _makeOrder(math.Random rng) {
    final pool = producible();
    if (pool.isEmpty) pool.add('thoc');
    final kinds = math.min(pool.length, 1 + rng.nextInt(level < 3 ? 2 : 3));
    final pick = <String>{};
    while (pick.length < kinds) {
      pick.add(pool[rng.nextInt(pool.length)]);
    }
    final need = <String, int>{};
    var value = 0;
    for (final id in pick) {
      final p = item(id).price;
      final maxQ = p < 10 ? 6 : p < 30 ? 4 : p < 90 ? 3 : 2;
      final q = 1 + rng.nextInt(maxQ);
      need[id] = q;
      value += p * q;
    }
    final coins = (value * (1.45 + rng.nextDouble() * 0.4) * (1 + orderBonus)).round();
    final xpGain = math.max(2, (value / 6).round());
    return Order(nextId++, villagers[rng.nextInt(villagers.length)], need, coins, xpGain);
  }

  void _fillOrders() {
    final rng = math.Random(seed * 7919 + nextId);
    while (orders.length < orderSlots) {
      orders.add(_makeOrder(rng));
    }
  }

  // ---------------------------------------------------------------- neighbours
  /// What a ripe [o] gives (product id), or null if nothing is ready.
  String? readyProduct(Obj o) {
    if (!isReady(o)) return null;
    return switch (o.def.kind) {
      BKind.paddy || BKind.bed => o.crop == null ? null : crops[o.crop]!.product,
      BKind.tree => trees[o.type]!.product,
      BKind.pen => o.count > 0 ? animalForPen(o.type)!.product : null,
      BKind.pond => o.crop == null ? null : fishes[o.crop]!.product,
      _ => null,
    };
  }

  /// How many [o] gives now, less what neighbours took (never below 1).
  int readyYield(Obj o) {
    final full = switch (o.def.kind) {
      BKind.paddy || BKind.bed => o.crop == null ? 0 : crops[o.crop]!.yield,
      BKind.tree => trees[o.type]!.yield,
      BKind.pen => o.count,
      BKind.pond => o.crop == null ? 0 : fishes[o.crop]!.yield,
      _ => 0,
    };
    return math.max(1, full - o.stolen);
  }

  /// Something a neighbour could still take one of.
  bool canBeStolen(Obj o) => readyProduct(o) != null && readyYield(o) > 1;

  /// Harvest/pick/collect/catch, whichever fits [o].
  String? harvestAny(Obj o) => switch (o.def.kind) {
        BKind.paddy || BKind.bed => harvest(o),
        BKind.tree => pickTree(o),
        BKind.pen => collect(o),
        BKind.pond => catchFish(o),
        _ => null,
      };

  static const helpLimit = 10, stealLimit = 3;

  /// Per-day counts of what this player did at each neighbour.
  final Map<String, int> visitLog = {};
  String _vk(String uid, String kind) => '${dayKey(now())}|$uid|$kind';
  int visitCount(String uid, String kind) => visitLog[_vk(uid, kind)] ?? 0;

  void _visitAdd(String uid, String kind) {
    final today = '${dayKey(now())}|';
    visitLog.removeWhere((k, _) => !k.startsWith(today));
    visitLog[_vk(uid, kind)] = visitCount(uid, kind) + 1;
  }

  /// Reward for harvesting [product] for a neighbour: xp and coins.
  (int, int) helpReward(String product) => (math.max(2, item(product).price ~/ 4), 2 * level);

  /// Visitor side: helped neighbour [uid] harvest [product].
  String? rewardHelp(String uid, String product) {
    if (visitCount(uid, 'help') >= helpLimit) return 'Hôm nay đã giúp nhà này đủ $helpLimit lần';
    final (x, c) = helpReward(product);
    _visitAdd(uid, 'help');
    coins += c;
    addXp(x);
    _stat('help');
    _snd('harvest');
    _changed();
    return null;
  }

  /// Fine when a scarecrow catches you picking.
  int get stealFine => 10 * level;

  /// Visitor side: took one [product] from neighbour [uid].
  String? takeStolen(String uid, String product) {
    if (visitCount(uid, 'steal') >= stealLimit) return 'Hôm nay đã hái trộm nhà này đủ $stealLimit lần';
    if (!roomFor(1)) return 'Kho đầy!';
    _visitAdd(uid, 'steal');
    _gain(product, 1);
    _stat('steal');
    _snd('pick');
    _changed();
    return null;
  }

  /// Visitor side: caught by a scarecrow; pays the fine.
  int payFine(String uid) {
    _visitAdd(uid, 'steal');
    final f = math.min(coins, stealFine);
    coins -= f;
    _stat('caught');
    _snd('error');
    _changed();
    return f;
  }

  /// Chance a steal is caught: 15% per scarecrow (at most 45%), plus 25%
  /// while the guard dog is fed.
  double get catchChance {
    final d = dog;
    return math.min(.45, .15 * objs.where((o) => o.type == 'bu_nhin').length) +
        (d != null && dogAwake(d) ? FarmMore.dogCatch : 0);
  }

  /// Owner side: applies what a neighbour did while away. Returns false
  /// when it no longer fits (already harvested, replanted, storage full).
  bool applyVisit(String kind, int objId, int start, {int fine = 0}) {
    if (kind == 'caught') {
      coins += fine;
      _changed();
      return true;
    }
    final o = byId(objId);
    if (o == null || o.start != start || readyProduct(o) == null) return false;
    if (kind == 'help') return harvestAny(o) == null;
    if (kind == 'steal' && canBeStolen(o)) {
      o.stolen++;
      _changed();
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------- daily
  static const dailyLevel = 6;

  static int dayKey(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return d.year * 10000 + d.month * 100 + d.day;
  }

  /// Ms until the daily orders change (local midnight).
  int get dailyResetMs {
    final d = DateTime.fromMillisecondsSinceEpoch(now());
    return DateTime(d.year, d.month, d.day + 1).millisecondsSinceEpoch - now();
  }

  /// Coins for delivering all three daily orders.
  int get dailyAllBonus => 150 * level;

  bool get dailyAllDone => daily.isNotEmpty && daily.every((o) => o.waitUntil < 0);

  /// New special orders when the day changes.
  void rollDaily() {
    if (level < dailyLevel) return;
    final k = dayKey(now());
    if (k == dailyDay && daily.isNotEmpty) return;
    dailyDay = k;
    daily.clear();
    final rng = math.Random(seed * 31 + k);
    for (var tier = 0; tier < 3; tier++) {
      daily.add(_makeDaily(rng, tier));
    }
    _changed();
  }

  /// A special order: bigger, from the dearer goods, paid about double.
  Order _makeDaily(math.Random rng, int tier, {List<String>? goods, double pay = 1}) {
    final pool = [...(goods ?? producible())]..sort((a, b) => item(a).price.compareTo(item(b).price));
    if (pool.isEmpty) pool.add('thoc');
    final from = (pool.length * const [0.0, .35, .6][tier]).floor().clamp(0, pool.length - 1);
    final top = pool.sublist(from);
    final kinds = math.min(top.length, 2 + (tier == 2 ? 1 : 0));
    final pick = <String>{};
    while (pick.length < kinds) {
      pick.add(top[rng.nextInt(top.length)]);
    }
    final need = <String, int>{};
    var value = 0;
    for (final id in pick) {
      final p = item(id).price;
      final base = p < 10 ? 8 : p < 30 ? 6 : p < 90 ? 4 : p < 200 ? 3 : 2;
      final q = base + rng.nextInt(base) + tier;
      need[id] = q;
      value += p * q;
    }
    final coins = (value * (2.1 + tier * .3) * (1 + orderBonus) * pay).round();
    final xpGain = math.max(5, (value / 4).round());
    return Order(nextId++, villagers[rng.nextInt(villagers.length)], need, coins, xpGain);
  }

  String? deliverDaily(Order o) {
    if (o.waitUntil < 0) return 'Đã giao rồi';
    if (!_spend(o.need)) return 'Chưa đủ hàng';
    coins += o.coins;
    addXp(o.xp);
    o.waitUntil = -1;
    _stat('daily');
    _snd('cash');
    _ev('daily_delivered', {'count': stats['daily']!, 'level': level});
    if (dailyAllDone) {
      coins += dailyAllBonus;
      if (house != null) _fx(house!, '🎁 +${fmtNum(dailyAllBonus)} xu');
      _ev('daily_all_done', {'level': level});
    }
    _changed();
    return null;
  }

  /// Turn waiting slots into fresh orders once their timer is up.
  void tickOrders() {
    rollDaily();
    rollFestival();
    settleYard();
    checkMemories();
    final t = now();
    final rng = math.Random(seed * 31 + nextId + t ~/ 1000);
    var changed = false;
    for (var i = 0; i < orders.length; i++) {
      if (orders[i].waitUntil > 0 && t >= orders[i].waitUntil) {
        orders[i] = _makeOrder(rng);
        changed = true;
      }
    }
    if (orders.length < orderSlots) {
      _fillOrders();
      changed = true;
    }
    if (changed) _changed();
  }

  bool canDeliver(Order o) =>
      o.waitUntil == 0 && o.need.entries.every((e) => countOf(e.key) >= e.value);

  String? deliver(Order o) {
    if (o.waitUntil > 0) return null;
    if (!_spend(o.need)) return 'Chưa đủ hàng';
    coins += o.coins;
    addXp(o.xp);
    _stat('order');
    _ev('order_delivered', {'count': stats['order']!, 'level': level});
    _snd('cash');
    final i = orders.indexOf(o);
    orders[i] = Order(nextId++, '', const {}, 0, 0, waitUntil: now() + 20 * 1000);
    _changed();
    return null;
  }

  void discard(Order o) {
    final i = orders.indexOf(o);
    if (i < 0) return;
    orders[i] = Order(nextId++, '', const {}, 0, 0, waitUntil: now() + 90 * 1000);
    _changed();
  }

  // ---------------------------------------------------------------- quests
  QuestDef? get currentQuest => quest < questChain.length ? questChain[quest] : null;

  int questValue(QuestDef q) {
    final v = stats[q.key] ?? (q.key == 'level' ? level : 0);
    return q.absolute ? v : v - questBase;
  }

  bool get questDone {
    final q = currentQuest;
    return q != null && questValue(q) >= q.target;
  }

  void claimQuest() {
    final q = currentQuest;
    if (q == null || !questDone) return;
    coins += q.coins;
    addXp(q.xp);
    quest++;
    _snd('quest');
    _ev('quest_done', {'index': quest, 'level': level});
    final n = currentQuest;
    questBase = n == null ? 0 : (stats[n.key] ?? 0);
    _changed();
  }

  // ---------------------------------------------------------------- save
  Map<String, dynamic> toJson() => {
        'v': 1,
        'map': mapSize,
        'coins': coins, 'xp': xp, 'level': level, 'nextId': nextId, 'seed': seed,
        'lots': lots.toList(),
        'inv': inv,
        'objs': [for (final o in objs) o.toJson()],
        'projects': projects.toList(),
        if (projectLv.isNotEmpty) 'projectLv': projectLv,
        if (dailyDay != 0) 'dailyDay': dailyDay,
        if (daily.isNotEmpty) 'daily': [for (final o in daily) o.toJson()],
        if (visitLog.isNotEmpty) 'visitLog': visitLog,
        'orders': [for (final o in orders) o.toJson()],
        'stats': stats,
        'quest': quest, 'questBase': questBase,
        'savedAt': savedAt,
        if (name.isNotEmpty) 'name': name,
        if (loginDay != 0) 'login': [loginDay, loginStreak],
        if (ach.isNotEmpty) 'ach': ach,
        if (title.isNotEmpty) 'title': title,
        if (stalls.isNotEmpty) 'stalls': [for (final s in stalls) s.toJson()],
        if (tut != tutDone) 'tut': tut,
        if (festKey.isNotEmpty) 'fest': {'k': festKey, 'o': [for (final o in fest) o.toJson()]},
        if (giftDeco.isNotEmpty) 'gift': giftDeco,
        if (mem.isNotEmpty) 'mem': mem,
        if (yard.isNotEmpty)
          'yard': {'g': yard, 'd': yardDry, 't': yardT, 'w': yardWet, 'l': yardLost, 'c': yardCover},
      };

  static Farm fromJson(Map<String, dynamic> j, {NowFn? now}) {
    final f = Farm(now: now)
      ..coins = j['coins']
      ..xp = j['xp']
      ..level = j['level']
      ..nextId = j['nextId']
      ..seed = j['seed'] ?? 7
      ..quest = j['quest'] ?? 0
      ..questBase = j['questBase'] ?? 0
      ..savedAt = j['savedAt'] ?? 0
      ..name = j['name'] ?? ''
      ..title = j['title'] ?? ''
      ..tut = j['tut'] ?? tutDone;
    final login = j['login'] as List?;
    if (login != null && login.length == 2) {
      f.loginDay = login[0];
      f.loginStreak = login[1];
    }
    f.ach.addAll(Map<String, int>.from(j['ach'] ?? const {}));
    f.stalls.addAll([for (final s in (j['stalls'] as List? ?? const [])) Stall.fromJson(Map<String, dynamic>.from(s))]);
    // saves from the smaller map: same tiles, lots renumbered, and the new
    // outer lots get their bushes and rocks
    final oldSide = ((j['map'] as num?)?.toInt() ?? legacyMapSize) ~/ lotSize;
    for (final lot in (j['lots'] as List).cast<int>()) {
      f.lots.add(oldSide == lotsPerSide ? lot : lotIndex(lot % oldSide, lot ~/ oldSide));
    }
    f.inv.addAll(Map<String, int>.from(j['inv']));
    for (final o in j['objs'] as List) {
      try {
        final obj = Obj.fromJson(Map<String, dynamic>.from(o as Map));
        if (buildings.containsKey(obj.type)) f.objs.add(obj);
      } catch (_) {
        // one bad object must not lose the whole farm
      }
    }
    if (oldSide < lotsPerSide) {
      try {
        f._scatterObstacles((lot) => lot % lotsPerSide >= oldSide || lot ~/ lotsPerSide >= oldSide, 1);
      } catch (_) {
        // the outer lots just stay clear
      }
    }
    f.projects.addAll((j['projects'] as List).cast<String>());
    f.projectLv.addAll(Map<String, int>.from(j['projectLv'] ?? const {}));
    f.dailyDay = j['dailyDay'] ?? 0;
    f.visitLog.addAll(Map<String, int>.from(j['visitLog'] ?? const {}));
    f.daily.addAll([for (final o in (j['daily'] as List? ?? const [])) Order.fromJson(o)]);
    f.orders.addAll([for (final o in j['orders']) Order.fromJson(o)]);
    f.stats.addAll(Map<String, int>.from(j['stats']));
    try {
      final fe = j['fest'] as Map?;
      if (fe != null) {
        f.festKey = fe['k'] ?? '';
        f.fest.addAll([for (final o in (fe['o'] as List? ?? const [])) Order.fromJson(Map<String, dynamic>.from(o))]);
      }
      f.giftDeco.addAll(Map<String, int>.from(j['gift'] ?? const {}));
      f.mem.addAll(Map<String, int>.from(j['mem'] ?? const {}));
      final y = j['yard'] as Map?;
      if (y != null) {
        f.yard.addAll(Map<String, int>.from(y['g'] ?? const {}));
        f.yardDry = y['d'] ?? 0;
        f.yardT = y['t'] ?? 0;
        f.yardWet = y['w'] ?? -1;
        f.yardLost = y['l'] ?? 0;
        f.yardCover = y['c'] ?? false;
      }
    } catch (_) {
      // festival and drying yard state is never worth losing a farm over
    }
    f._occ = null;
    try {
      f._fixRoadBuildings();
    } catch (_) {}
    return f;
  }
}

String fmtTime(int ms) {
  final s = (ms / 1000).ceil();
  if (s < 60) return '${s}s';
  final m = s ~/ 60;
  if (m < 60) return '${m}p ${(s % 60).toString().padLeft(2, '0')}s';
  return '${m ~/ 60}g ${(m % 60).toString().padLeft(2, '0')}p';
}

String fmtSecs(int s) => fmtTime(s * 1000);

/// Compact amount for the HUD: 2,97tr above a million, 296k above 100.000.
String fmtShort(int n) {
  String dec(double v) {
    var t = v.toStringAsFixed(v >= 100 ? 0 : (v >= 10 ? 1 : 2));
    if (t.contains('.')) t = t.replaceFirst(RegExp(r'\.?0+$'), '');
    return t.replaceAll('.', ',');
  }

  if (n.abs() >= 1000000000) return '${dec(n / 1e9)}tỷ';
  if (n.abs() >= 1000000) return '${dec(n / 1e6)}tr';
  if (n.abs() >= 100000) return '${n ~/ 1000}k';
  return fmtNum(n);
}

String fmtNum(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}
