// The whole farm state and every rule that changes it. Pure Dart (no
// Flutter widgets) so it can be unit-tested; time comes from [now].

import 'dart:math' as math;

import 'defs.dart';
import 'quests.dart';

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
        if (jobs.isNotEmpty) 'j': [for (final j in jobs) j.toJson()],
      };
  factory Obj.fromJson(Map<String, dynamic> j) => Obj(j['i'], j['t'], j['x'], j['y'])
    ..crop = j['c']
    ..start = j['s'] ?? 0
    ..end = j['e'] ?? 0
    ..count = j['n'] ?? 0
    ..level = j['l'] ?? 0
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
  Fx(this.x, this.y, this.text);
}

class Farm {
  NowFn now;
  int coins = 300, xp = 0, level = 1;
  int nextId = 1, seed = 1;
  final Set<int> lots = {};
  final Map<String, int> inv = {};
  final List<Obj> objs = [];
  final Set<String> projects = {}; // finished village projects
  final List<Order> orders = [];
  final Map<String, int> stats = {};
  int quest = 0, questBase = 0;
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

  void _scatterObstacles() {
    final rng = math.Random(seed);
    const kinds = ['bui', 'bui', 'da', 'goc_cay'];
    for (var lot = 0; lot < lotsPerSide * lotsPerSide; lot++) {
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
    if (y <= 1) return 'water';
    if (x == roadX) return 'road';
    return 'grass';
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
          m[(o.x + dx) + (o.y + dy) * mapSize] = o.id;
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
  double get _all => has('dinh_lang') ? 0.10 : 0;
  double get _bedSpeed => (has('gieng') ? 0.10 : 0) + _all;
  double get _paddySpeed => (has('tram_bom') ? 0.20 : 0) + _all;
  double get _factorySpeed => (has('tram_dien') ? 0.20 : 0) + _all;
  double get _animalSpeed => (has('tram_y_te') ? 0.15 : 0) + _all;
  double get _treeSpeed => _all;
  double get _fishSpeed => _all;
  double get xpBonus => (has('cong_lang') ? 0.10 : 0) + (has('truong') ? 0.15 : 0);
  double get orderBonus =>
      (has('duong_be_tong') ? 0.10 : 0) + (has('nha_van_hoa') ? 0.10 : 0);
  double get marketBonus => has('cho_que') ? 0.15 : 0;
  int get orderSlots => 4 + (has('cho_que') ? 1 : 0) + (has('nha_van_hoa') ? 1 : 0);

  int _dur(int seconds, double speed) => (seconds * 1000 * (1 - speed)).round();
  int cropMs(CropDef c) =>
      _dur(c.seconds, c.plot == Plot.paddy ? _paddySpeed : _bedSpeed);
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

  int get storageCap =>
      houseLevels[houseLevel].storage +
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
    xp += (n * (1 + xpBonus)).round();
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
  }

  void _fx(Obj o, String text) => fx.add(Fx(o.x + o.w / 2, o.y + o.h / 2, text));

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
    return d.cost;
  }

  String? canBuy(String type) {
    final d = bdef(type);
    if (level < d.level) return 'Cần đạt cấp ${d.level}';
    if (d.unique && (projects.contains(type) || objs.any((o) => o.type == type))) {
      return 'Đã xây rồi';
    }
    if (d.kind == BKind.storage && warehouseCount >= warehouseMax) return 'Tối đa $warehouseMax nhà kho';
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
    if (d.kind == BKind.project) {
      projects.add(type);
      _stat('project:$type');
      _ev('village_project', {'type': type, 'level': level});
    }
    if (d.w > 0) {
      final o = _add(type, x, y);
      _fx(o, d.xp > 0 ? '+${d.xp} KN' : '✓');
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
    return k == BKind.paddy || k == BKind.bed || k == BKind.tree || k == BKind.deco;
  }

  void remove(Obj o) {
    objs.remove(o);
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
    fx.add(Fx(o.x + .5, o.y + .5, '+${d.xp} KN'));
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
    if (!roomFor(c.yield + extra)) return 'Kho đầy! Bán bớt hoặc nâng cấp nhà';
    _gain(c.product, c.yield);
    if (c.bonus != null) _gain(c.bonus!, 1);
    _stat('harvest:${c.id}');
    _snd('harvest');
    addXp(c.xp);
    _fx(f, '+${c.yield} ${item(c.product).icon}');
    f.crop = null;
    f.start = f.end = 0;
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
    if (!roomFor(t.yield)) return 'Kho đầy!';
    _gain(t.product, t.yield);
    _snd('pick');
    addXp(t.xp);
    _fx(o, '+${t.yield} ${item(t.product).icon}');
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
    if (!roomFor(pen.count)) return 'Kho đầy!';
    _gain(a.product, pen.count);
    _snd(a.id);
    addXp(a.xp * pen.count);
    _fx(pen, '+${pen.count} ${item(a.product).icon}');
    pen.start = pen.end = 0;
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
    if (!roomFor(f.yield)) return 'Kho đầy!';
    _gain(f.product, f.yield);
    _snd('splash');
    addXp(f.xp);
    _fx(pond, '+${f.yield} ${item(f.product).icon}');
    pond.crop = null;
    pond.start = pond.end = 0;
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

  /// Turn waiting slots into fresh orders once their timer is up.
  void tickOrders() {
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
        'coins': coins, 'xp': xp, 'level': level, 'nextId': nextId, 'seed': seed,
        'lots': lots.toList(),
        'inv': inv,
        'objs': [for (final o in objs) o.toJson()],
        'projects': projects.toList(),
        'orders': [for (final o in orders) o.toJson()],
        'stats': stats,
        'quest': quest, 'questBase': questBase,
        'savedAt': savedAt,
        if (name.isNotEmpty) 'name': name,
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
      ..name = j['name'] ?? '';
    f.lots.addAll((j['lots'] as List).cast<int>());
    f.inv.addAll(Map<String, int>.from(j['inv']));
    f.objs.addAll([for (final o in j['objs']) Obj.fromJson(o)]);
    f.projects.addAll((j['projects'] as List).cast<String>());
    f.orders.addAll([for (final o in j['orders']) Order.fromJson(o)]);
    f.stats.addAll(Map<String, int>.from(j['stats']));
    f.objs.removeWhere((o) => !buildings.containsKey(o.type));
    f._fixRoadBuildings();
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

String fmtNum(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}
