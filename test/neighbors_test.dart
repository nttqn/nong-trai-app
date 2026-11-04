import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/village.dart';

void main() {
  late int t;
  late Farm owner;
  late Obj field;

  setUp(() {
    t = DateTime(2026, 11, 4, 10).millisecondsSinceEpoch;
    owner = Farm.fresh(now: () => t, seed: 5)..name = 'Trại Bác Ba';
    field = owner.objs.firstWhere((o) => o.type == 'ruong');
    expect(owner.plant(field, 'lua'), isNull);
    t = field.end + 1; // ripe
  });

  test('a village snapshot round-trips into a read-only farm', () {
    final snap = jsonDecode(jsonEncode(villageSnapshot(owner))) as Map<String, dynamic>;
    expect(snap.containsKey('coins'), isFalse);
    expect(snap.containsKey('inv'), isFalse);
    final copy = farmFromVillage(snap, now: () => t);
    final f2 = copy.byId(field.id)!;
    expect(copy.readyProduct(f2), 'thoc');
    expect(copy.name, 'Trại Bác Ba');
  });

  test('help harvest applies on the owner side, once, if still ripe', () {
    final before = owner.countOf('thoc');
    expect(owner.applyVisit('help', field.id, field.start), isTrue);
    expect(owner.countOf('thoc'), before + crops['lua']!.yield);
    expect(field.crop, isNull);
    // stale: already harvested
    expect(owner.applyVisit('help', field.id, 123), isFalse);
  });

  test('steals lower the next harvest but always leave one', () {
    final start = field.start;
    expect(owner.readyYield(field), 2);
    expect(owner.applyVisit('steal', field.id, start), isTrue);
    expect(owner.readyYield(field), 1);
    expect(owner.canBeStolen(field), isFalse);
    expect(owner.applyVisit('steal', field.id, start), isFalse);
    final before = owner.countOf('thoc');
    expect(owner.harvest(field), isNull);
    expect(owner.countOf('thoc'), before + 1);
    expect(field.stolen, 0);
  });

  test('caught visitors pay a fine that the owner receives', () {
    final visitor = Farm.fresh(now: () => t, seed: 9)..level = 10;
    visitor.coins = 1000;
    final fine = visitor.payFine('owner');
    expect(fine, visitor.stealFine.clamp(0, 1000));
    expect(visitor.coins, 1000 - fine);
    final c = owner.coins;
    owner.applyVisit('caught', 0, 0, fine: fine);
    expect(owner.coins, c + fine);
  });

  test('daily limits per neighbour; scarecrows raise the catch chance', () {
    final v = Farm.fresh(now: () => t, seed: 9);
    for (var i = 0; i < Farm.helpLimit; i++) {
      expect(v.rewardHelp('n1', 'thoc'), isNull);
    }
    expect(v.rewardHelp('n1', 'thoc'), isNotNull);
    expect(v.rewardHelp('n2', 'thoc'), isNull); // another neighbour
    for (var i = 0; i < Farm.stealLimit; i++) {
      expect(v.takeStolen('n1', 'thoc'), isNull);
    }
    expect(v.takeStolen('n1', 'thoc'), isNotNull);
    t += const Duration(days: 1).inMilliseconds;
    expect(v.rewardHelp('n1', 'thoc'), isNull); // new day
    expect(owner.catchChance, 0);
    owner.objs.add(Obj(999, 'bu_nhin', 0, 0));
    expect(owner.catchChance, closeTo(.15, 1e-9));
  });
}
