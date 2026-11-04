// The public face of a farm: what neighbours see when they visit. Only the
// layout and what is growing (no coins, storage, orders or stats).

import 'defs.dart';
import 'farm.dart';

Map<String, dynamic> villageSnapshot(Farm f) => {
      'v': 1,
      'map': mapSize,
      'name': f.name.length > 24 ? f.name.substring(0, 24) : f.name,
      'level': f.level,
      'house': f.houseLevel,
      if (f.title.isNotEmpty) 'title': f.title,
      'lots': f.lots.toList(),
      'projects': f.projects.toList(),
      if (f.projectLv.isNotEmpty) 'projectLv': f.projectLv,
      'objs': [
        for (final o in f.objs) {...o.toJson()}..remove('j'),
      ],
    };

/// A read-only farm built from a neighbour's snapshot.
Farm farmFromVillage(Map<String, dynamic> m, {NowFn? now}) => Farm.fromJson({
      'coins': 0,
      'xp': 0,
      'level': m['level'] ?? 1,
      'nextId': 1 << 30,
      'seed': 7,
      'lots': m['lots'] ?? const [],
      'map': m['map'] ?? legacyMapSize,
      'inv': const <String, int>{},
      'objs': m['objs'] ?? const [],
      'projects': m['projects'] ?? const [],
      if (m['projectLv'] != null) 'projectLv': m['projectLv'],
      'orders': const [],
      'stats': const <String, int>{},
      'name': m['name'] ?? '',
    }, now: now);

/// One thing a neighbour did on this farm, waiting in the owner's inbox.
class VisitEvent {
  final String id, kind, fromName; // kind: help | steal | caught
  final int objId, start, fine;
  final String product;
  const VisitEvent(this.id, this.kind, this.fromName, this.objId, this.start, this.product, this.fine);

  static VisitEvent? fromDoc(String id, Map<String, dynamic> m) {
    try {
      return VisitEvent(id, m['kind'] as String, m['name'] as String? ?? 'Hàng xóm', (m['obj'] as num).toInt(),
          (m['start'] as num).toInt(), m['item'] as String? ?? '', (m['fine'] as num?)?.toInt() ?? 0);
    } catch (_) {
      return null;
    }
  }
}
