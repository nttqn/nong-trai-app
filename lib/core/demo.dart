// Dev-only farms for screenshots (web builds, ?demo=N).

import 'defs.dart';
import 'farm.dart';

Farm demoFarm(int stage, {int house = -1}) {
  final f = Farm.fresh(seed: 11);
  if (stage <= 0) return f;
  final now = f.now();
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
  f.inv.clear();
  f.inv.addAll({'thoc': 24, 'rom': 6, 'trung': 5, 'gao': 4});
  f.coins = 12450;
  f.xp = 40;
  f.fx.clear();
  return f;
}
