import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/quests.dart';

int now() => DateTime(2026, 11, 18, 10).millisecondsSinceEpoch;

Farm loadAt(int quest, int qv, Map<String, int> stats, {int level = 44}) {
  final j = jsonDecode(jsonEncode(Farm.fresh(now: now).toJson())) as Map<String, dynamic>;
  j['quest'] = quest;
  j['questBase'] = 0;
  j['qv'] = qv;
  j['level'] = level;
  j['stats'] = stats;
  return Farm.fromJson(j, now: now);
}

void main() {
  final firstLate = questChain.indexWhere((q) => q.v == 3);

  test('the cấp 31+ quests follow the old chain end', () {
    expect(firstLate, 50);
    expect(questChain[firstLate - 1].key, 'project_lv:dinh_lang');
    expect(questChain[firstLate].text, 'Đạt cấp 31');
    expect(questChain.where((q) => q.v == 3).length, 54);
    expect(questChain.where((q) => q.v == 4).length, greaterThan(20));
  });

  test('every cấp 31+ quest watches something that exists and can be redone', () {
    const repeatable = {'daily', 'order', 'dry', 'fertilize'};
    for (final q in questChain.skip(firstLate)) {
      final (kind, id) = q.key.contains(':') ? (q.key.split(':')[0], q.key.split(':')[1]) : (q.key, '');
      switch (kind) {
        case 'level':
        case 'house':
          expect(q.absolute, isTrue, reason: q.text);
          if (kind == 'house') expect(q.target, lessThan(houseLevels.length), reason: q.text);
        case 'project_lv':
          expect(q.absolute, isTrue, reason: q.text);
          expect(projectUpgrades.containsKey(id), isTrue, reason: q.text);
          expect(q.target, 3, reason: q.text);
        case 'build':
          // buildings that can always be built again (not unique)
          expect(q.absolute, isTrue, reason: q.text);
          expect(buildings[id]!.unique, isFalse, reason: q.text);
        case 'get':
          expect(items.containsKey(id), isTrue, reason: q.text);
          expect(q.absolute, isFalse, reason: q.text);
        case 'harvest':
        case 'plant':
          expect(crops.containsKey(id), isTrue, reason: q.text);
          expect(q.absolute, isFalse, reason: q.text);
        case 'stock':
          expect(fishes.containsKey(id), isTrue, reason: q.text);
          expect(q.absolute, isFalse, reason: q.text);
        default:
          expect(repeatable.contains(kind), isTrue, reason: q.text);
          expect(q.absolute, isFalse, reason: q.text);
      }
    }
    // levels go up along the chain, and nothing asks for content locked
    // above the last level milestone before it
    var last = 30;
    for (final q in questChain.skip(firstLate)) {
      if (q.key == 'level') {
        expect(q.target, greaterThan(last));
        last = q.target;
        continue;
      }
      final id = q.key.contains(':') ? q.key.split(':')[1] : '';
      final need = switch (q.key.split(':')[0]) {
        'plant' || 'harvest' => crops[id]!.level,
        'build' => buildings[id]!.level,
        'stock' => fishes[id]!.level,
        'get' => recipes[id]?.level ?? 0,
        _ => 0,
      };
      expect(need, lessThanOrEqualTo(last), reason: q.text);
    }
  });

  test('saves keep their quest when quests are inserted', () {
    for (var saved = 1; saved < questChainVersion; saved++) {
      final old = [for (final q in questChain) if (q.v <= saved) q];
      for (var i = 0; i < old.length; i++) {
        final (at, finished) = migrateQuest(i, saved);
        expect(questChain[at], same(old[i]), reason: 'v$saved #$i');
        expect(finished, isFalse);
      }
    }
    expect(migrateQuest(70, questChainVersion), (70, false));
  });

  test('a lv44 farm that had finished the 1.1 chain gets no free counting quests', () {
    final f = loadAt(firstLate, 2, {
      'level': 44, 'house': 4, 'order': 900, 'daily': 300, 'plant:nghe': 400,
      'get:matong': 500, 'project_lv:truong': 3,
    });
    expect(f.currentQuest!.text, 'Đạt cấp 31');
    f.claimQuest();
    // the first counting quest starts from zero
    expect(f.currentQuest!.key, 'plant:nghe');
    expect(f.questValue(f.currentQuest!), 0);
  });

  test('a farm on a 1.2 quest stays on it', () {
    final v3 = [for (final q in questChain) if (q.v <= 3) q];
    final i = v3.indexWhere((q) => q.text == 'Đạt cấp 36');
    final f = loadAt(i, 3, {'level': 37});
    expect(f.currentQuest!.text, 'Đạt cấp 36');
    f.claimQuest();
    // then the new silk / jam quests come next
    expect(f.currentQuest!.key, 'stock:luon');
  });

  test('new content is wired up end to end', () {
    for (final r in recipes.values) {
      expect(buildings.containsKey(r.building), isTrue, reason: r.id);
      expect(r.level, greaterThanOrEqualTo(buildings[r.building]!.level), reason: r.id);
      expect(items.containsKey(r.product), isTrue, reason: r.id);
      for (final i in r.inputs.keys) {
        expect(items.containsKey(i), isTrue, reason: '${r.id} <- $i');
      }
      // the made thing is worth more than what goes in
      final cost = r.inputs.entries.fold(0, (a, e) => a + item(e.key).price * e.value);
      expect(item(r.product).price * r.out, greaterThan(cost), reason: r.id);
    }
    for (final t in trees.values) {
      expect(buildings[t.id]!.kind, BKind.tree, reason: t.id);
      expect(buildings[t.id]!.level, t.level, reason: t.id);
    }
    for (final a in animals.values) {
      expect(buildings[a.pen]!.kind, BKind.pen, reason: a.id);
      expect(items.containsKey(a.feed), isTrue, reason: a.id);
    }
  });

  test('a lv44 farm can build, raise and make the new things', () {
    final f = loadAt(0, questChainVersion, {'level': 44});
    f.coins = 1 << 30;
    f.lots.addAll([for (var i = 0; i < lotsPerSide * lotsPerSide; i++) i]);
    f.objs.removeWhere((o) => o.def.kind == BKind.obstacle);
    String? place(String type) {
      for (var i = 0; i < mapSize * mapSize; i++) {
        if (f.canPlace(type, i % mapSize, i ~/ mapSize)) return f.build(type, i % mapSize, i ~/ mapSize);
      }
      return 'no room';
    }
    for (final t in ['nha_tam', 'khung_cui', 'xuong_mut', 'cay_cam', 'cay_mit', 'cay_cau', 'luong', 'ruong']) {
      expect(place(t), isNull, reason: t);
    }
    final bed = f.objs.lastWhere((o) => o.type == 'luong');
    expect(f.plant(bed, 'nghe'), isNull);
    final paddy = f.objs.lastWhere((o) => o.type == 'ruong');
    expect(f.plant(paddy, 'nep_cam'), isNull);
    final p = f.producible();
    for (final id in ['nghe', 'nepcam', 'camvinh', 'mit', 'cau']) {
      expect(p, contains(id));
    }
  });

  test('a farm from a newer version with unknown crops still loads', () {
    final f0 = Farm.fresh(now: now)..coins = 100000;
    for (var i = 0; i < mapSize * mapSize; i++) {
      if (f0.canPlace('luong', i % mapSize, i ~/ mapSize)) {
        f0.build('luong', i % mapSize, i ~/ mapSize);
        break;
      }
    }
    expect(f0.plant(f0.objs.last, 'rau'), isNull);
    final j = jsonDecode(jsonEncode(f0.toJson())) as Map<String, dynamic>;
    final bed = (j['objs'] as List).firstWhere((o) => o['c'] == 'rau') as Map;
    bed['c'] = 'cay_tu_tuong_lai';
    final f = Farm.fromJson(j, now: now);
    expect(f.objs.where((o) => o.crop == 'cay_tu_tuong_lai'), isEmpty);
    expect(f.objs.length, f0.objs.length);
  });
}
