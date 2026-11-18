import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/quests.dart';

int now() => DateTime(2026, 11, 18, 10).millisecondsSinceEpoch;

void main() {
  test('the 1.2 quests are appended after the old chain end', () {
    expect(questChain[questChainV2Length - 1].key, 'project_lv:dinh_lang');
    expect(questChain[questChainV2Length].text, 'Đạt cấp 31');
    expect(questChain.length, greaterThan(questChainV2Length + 40));
  });

  test('every cấp 31+ quest watches something that exists and can be redone', () {
    const repeatable = {'daily', 'order', 'dry', 'fertilize'};
    for (final q in questChain.skip(questChainV2Length)) {
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
        case 'get':
          expect(items.containsKey(id), isTrue, reason: q.text);
          expect(q.absolute, isFalse, reason: q.text);
        case 'harvest':
          expect(crops.containsKey(id), isTrue, reason: q.text);
          expect(q.absolute, isFalse, reason: q.text);
        default:
          expect(repeatable.contains(kind), isTrue, reason: q.text);
          expect(q.absolute, isFalse, reason: q.text);
      }
    }
    // levels go up along the chain
    var last = 30;
    for (final q in questChain.skip(questChainV2Length).where((q) => q.key == 'level')) {
      expect(q.target, greaterThan(last));
      last = q.target;
    }
  });

  test('a lv44 farm that had finished the old chain gets no free counting quests', () {
    final j = jsonDecode(jsonEncode(Farm.fresh(now: now).toJson())) as Map<String, dynamic>;
    j['quest'] = questChainV2Length;
    j['questBase'] = 0;
    j['qv'] = 2;
    j['level'] = 44;
    j['stats'] = {
      'level': 44, 'house': 4, 'order': 900, 'daily': 300, 'get:matong': 500,
      'get:hongsay': 200, 'project_lv:truong': 3, 'harvest:tam': 900,
    };
    final f = Farm.fromJson(j, now: now);
    expect(f.currentQuest!.text, 'Đạt cấp 31');
    // the absolute ones it already meets are claimed one after another...
    var claimed = 0;
    while (f.questDone) {
      f.claimQuest();
      claimed++;
    }
    expect(claimed, 3); // cấp 31, biệt thự, trường cấp 3
    // ...but the first counting quest starts from zero
    expect(f.currentQuest!.key, 'get:matong');
    expect(f.questValue(f.currentQuest!), 0);
  });
}
