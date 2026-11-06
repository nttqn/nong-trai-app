// Dev-only farms for screenshots (web builds, ?demo=N).

import 'calendar.dart';
import 'defs.dart';
import 'farm.dart';

Farm demoFarm(int stage, {int house = -1}) {
  final f = Farm.fresh(seed: 11);
  if (stage <= 0) return f;
  final now = f.now();
  f.tut = tutDone;
  f.loginDay = Farm.dayKey(now);
  f.loginStreak = 3;
  f.level = 6 + stage * 4;
  f.coins = 99999;
  // own more land
  f.lots.addAll([Farm.lotIndex(1, 2), Farm.lotIndex(2, 2), Farm.lotIndex(0, 1), Farm.lotIndex(3, 1)]);
  f.objs.removeWhere((o) => o.def.kind == BKind.obstacle && f.owned(o.x, o.y));
  f.house!.level = house >= 0 ? house : (stage * 2 - 1).clamp(0, 4);

  void put(String type, int x, int y, {String? crop, double prog = .5, int count = 0}) {
    if (!f.canPlace(type, x, y)) return;
    f.build(type, x, y);
    final o = f.objs.last;
    if (crop != null) o.crop = crop;
    if (crop != null || count > 0 || o.def.kind == BKind.tree) {
      final len = 600000;
      o.start = now - (len * prog).round();
      o.end = o.start + len;
    }
    o.count = count;
  }

  f.coins = 999999;
  for (var gy = 0; gy < 4; gy++) {
    for (var gx = 0; gx < 4; gx++) {
      put('ruong', 13 + gx, 7 + gy, crop: 'lua', prog: [0.1, 0.45, 0.8, 1.2][(gx + gy) % 4]);
    }
  }
  const beds = ['rau', 'ngo', 'khoai', 'lac', 'dau', 'mia', 'ot', 'dua', 'cuc'];
  for (var i = 0; i < 9; i++) {
    put('luong', 12 + (i % 3), 12 + i ~/ 3, crop: beds[i], prog: i.isEven ? 1.2 : .6);
  }
  put('chuong_ga', 6, 12, count: 5, prog: 1.2);
  put('chuong_vit', 8, 12, count: 4, prog: .4);
  put('chuong_lon', 6, 14, count: 3, prog: .4);
  put('chuong_trau', 8, 14, count: 2, prog: .5);
  put('chuong_bo', 6, 16, count: 3, prog: .5);
  put('ao', 15, 12);
  f.objs.last
    ..crop = 'cachep'
    ..start = now - 700000
    ..end = now - 1000;
  put('ao', 15, 15);
  put('may_xay', 9, 9);
  put('lo_banh', 9, 16);
  put('xuong_mia', 18, 13);
  put('xuong_ca', 18, 15);
  f.objs.last.jobs.add(Job('nuocmam', now + 100000));
  for (final (t, x, y) in [('cay_chuoi', 6, 9), ('cay_xoai', 7, 9), ('cay_dua', 8, 10), ('cay_buoi', 17, 17), ('cay_vai', 16, 17)]) {
    put(t, x, y, prog: 1.2);
  }
  put('hoa_dao', 10, 6);
  put('bu_nhin', 17, 6);
  put('chum', 9, 8);
  put('cay_da', 3, 7);
  f.inv
    ..['thoc'] = 400
    ..['rom'] = 100
    ..['gao'] = 100
    ..['trung'] = 100
    ..['rau'] = 100
    ..['sua'] = 100
    ..['ngo'] = 100
    ..['khoai'] = 100
    ..['trungvit'] = 100
    ..['chuoi'] = 100
    ..['thit'] = 100
    ..['caro'] = 100
    ..['xoi'] = 100
    ..['nuocmia'] = 100
    ..['banhchung'] = 100
    ..['cuc'] = 100
    ..['nuocmam'] = 100;
  // a warehouse on the first free spot
  for (var i = 0; i < mapSize * mapSize && f.warehouseCount == 0; i++) {
    put('nha_kho', i % mapSize, i ~/ mapSize);
  }
  if (f.warehouseCount > 0) f.objs.last.level = stage >= 2 ? 2 : 0;
  if (stage >= 2) {
    f.level = 20;
    for (final (p, x, y) in [
      ('gieng', 10, 10), ('tram_bom', 19, 8), ('tram_dien', 18, 6),
      ('truong', 0, 8), ('tram_y_te', 3, 10), ('cho_que', 19, 17), ('nha_van_hoa', 0, 13),
      ('dinh_lang', 2, 15),
    ]) {
      put(p, x, y);
    }
    // the gate goes on the first free row of the road
    for (var y = 2; y < mapSize && !f.has('cong_lang'); y++) {
      put('cong_lang', Farm.snapX('cong_lang', 0), y);
    }
    f.build('duong_be_tong', 0, 0);
  }
  if (stage >= 3) {
    // late game: new pens, workshops, trees, upgraded projects, daily orders
    f.level = 30;
    f.lots.addAll([for (var i = 0; i < lotsPerSide * lotsPerSide; i++) i]);
    f.objs.removeWhere((o) => o.def.kind == BKind.obstacle);
    void anywhere(String type, {int count = 0, double prog = .5}) {
      for (var i = 0; i < mapSize * mapSize; i++) {
        final x = i % mapSize, y = i ~/ mapSize;
        if (f.canPlace(type, x, y)) {
          put(type, x, y, count: count, prog: prog);
          return;
        }
      }
    }
    anywhere('chuong_de', count: 3, prog: .5);
    anywhere('vuon_ong', count: 3, prog: 1.2);
    anywhere('xuong_dau');
    anywhere('xuong_che');
    anywhere('cay_nhan', prog: 1.2);
    anywhere('cay_hong', prog: 1.2);
    // a house for the children (nhà con cháu)
    final coins = f.coins;
    f.coins = 1 << 30;
    anywhere('nha_phu');
    f.coins = coins;
    for (final o in f.extraHouses) {
      o.level = 2;
    }
    f.projectLv.addAll({'gieng': 3, 'tram_bom': 2, 'dinh_lang': 2});
    f.rollDaily();
  }
  // guard dog, fed, next to the house
  for (var i = 0; i < mapSize * mapSize && f.dog == null; i++) {
    final x = 4 + i % 8, y = 4 + i ~/ 8;
    if (f.canPlace('cho', x, y)) f.build('cho', x, y);
  }
  final dog = f.dog;
  if (dog != null) {
    dog.start = now;
    dog.end = now + FarmMore.dogFedMs;
  }
  // the drying yard, half-dried grain on it
  for (var i = 0; i < mapSize * mapSize && f.dryingYard == null; i++) {
    final x = 8 + i % 10, y = 3 + i ~/ 10;
    if (f.canPlace('san_phoi', x, y)) f.build('san_phoi', x, y);
  }
  if (f.dryingYard != null) {
    f.yard['thoc'] = 24;
    f.yardDry = FarmSeason.yardNeedMs ~/ 2;
    f.yardT = f.now();
  }
  f.stats.addAll({'order': 30 * stage, 'harvest:lua': 120 * stage, 'help': 12, 'steal': 6, 'daily': 4, 'login': 9});
  f.ach.addAll({'harvest': 1, 'help': 1});
  f.title = 'harvest';
  f.inv.clear();
  f.inv.addAll({'thoc': 24, 'rom': 6, 'trung': 5, 'gao': 4, 'ngo': 12});
  if (stage >= 2) {
    f.stalls.addAll([Stall(0, 'dua', 5, 400, now), Stall(1, 'trung', 10, 150, now)]);
  }
  f.coins = 12450;
  f.xp = 40;
  f.fx.clear();
  return f;
}

/// Every festival gift placed near the house (?fest on web demos).
void demoFestivalDecos(Farm f) {
  for (final d in festivalDecos) {
    f.giftDeco[d] = 1;
    for (var i = 0; i < mapSize * mapSize; i++) {
      final x = 1 + i % 14, y = 12 + i ~/ 14;
      if (f.canPlace(d, x, y) && f.build(d, x, y) == null) break;
    }
  }
  f.fx.clear();
}
