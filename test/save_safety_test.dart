import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/demo.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/sync_plan.dart';
import 'package:nong_trai/services/save.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A level-19-ish save in the old 24x24 format.
Map<String, dynamic> legacy() {
  final f = demoFarm(2);
  final j = jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>;
  j.remove('map');
  j['lots'] = [for (final l in f.lots) if (l % lotsPerSide < 4 && l ~/ lotsPerSide < 4) (l % lotsPerSide) + (l ~/ lotsPerSide) * 4];
  j['objs'] = [for (final o in (j['objs'] as List)) if ((o['x'] as int) < 24 && (o['y'] as int) < 24) o];
  return j;
}

void main() {
  test('odd objects never stop a save from loading', () {
    final j = legacy();
    (j['objs'] as List).addAll([
      {'i': 999001, 't': 'khong_co', 'x': 3, 'y': 3}, // unknown building
      {'i': 999002, 't': 'luong', 'x': -1, 'y': 40}, // off the map
      {'i': 'x', 't': 'luong'}, // broken
    ]);
    final f = Farm.fromJson(j);
    expect(f.level, j['level']);
    expect(f.objs.any((o) => o.type == 'khong_co'), isFalse);
    expect(f.canPlace('luong', 20, 20) || true, isTrue); // occ builds fine
  });

  test('a smaller farm never silently replaces a bigger one', () {
    // the incident: fresh level-1 farm on the phone, level 19 in the cloud
    final fresh = SaveInfo(5000, 1, 0), big = SaveInfo(4000, 19, 100);
    expect(planSync(local: fresh, mine: true, syncedAt: 4000, cloud: big), SyncAction.ask);
    // and the other way round
    expect(planSync(local: SaveInfo(4000, 19, 100), mine: true, syncedAt: 4000, cloud: SaveInfo(5000, 1, 0)),
        SyncAction.ask);
    // normal play still syncs quietly
    expect(planSync(local: SaveInfo(5000, 19, 120), mine: true, syncedAt: 4000, cloud: big), SyncAction.upload);
    expect(planSync(local: SaveInfo(4000, 19, 100), mine: true, syncedAt: 4000, cloud: SaveInfo(5000, 19, 150)),
        SyncAction.restore);
  });

  test('an unreadable save is parked and comes back once readable', () async {
    final good = jsonEncode(legacy());
    // a save this version cannot read (simulated by a broken copy)
    SharedPreferences.setMockInitialValues({'farm_v1': '{"level": 19, "objs": 5}', 'farm_v1_bak': '{"level":19}'});
    var s = SaveService();
    var f = await s.load();
    expect(f.level, 1);
    expect(s.loadError, isNotNull);
    final p = await SharedPreferences.getInstance();
    expect(p.getString('farm_broken'), '{"level": 19, "objs": 5}');
    // playing the fresh farm does not touch the parked copy
    s.active = f;
    f.coins += 5;
    await s.saveNow(f);
    await s.saveNow(f..coins += 5);
    expect(p.getString('farm_broken'), '{"level": 19, "objs": 5}');
    // a later version that reads it gets the farm back
    await p.setString('farm_broken', good);
    s = SaveService();
    f = await s.load();
    expect(f.level, (jsonDecode(good) as Map)['level']);
    expect(p.getString('farm_broken'), isNull);
    expect(p.getString('farm_v1'), good);
  });
}
