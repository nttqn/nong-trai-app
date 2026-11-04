// What to remind the player of after they leave: the first ripe field,
// animals ready, a workshop batch done, fruit to pick, tomorrow's login
// gift. Pure so it can be tested; the notification service schedules it.

import 'dart:math' as math;

import 'defs.dart';
import 'farm.dart';

class Reminder {
  final int id, at; // at: ms epoch
  final String title, body;
  const Reminder(this.id, this.at, this.title, this.body);
  @override
  String toString() => 'Reminder($id, $at, $title)';
}

/// Too soon to bother (the player just left) or too far ahead.
const _minLead = 60 * 1000, _maxLead = 3 * 24 * 3600 * 1000;

List<Reminder> planReminders(Farm f) {
  final now = f.now();
  final out = <Reminder>[];
  void add(int id, int at, String title, String body) {
    if (at - now >= _minLead && at - now <= _maxLead) out.add(Reminder(id, at, title, body));
  }

  int? first(Iterable<int> ends) {
    final l = ends.where((e) => e > now).toList();
    return l.isEmpty ? null : l.reduce(math.min);
  }

  final fields = first([
    for (final o in f.objs)
      if ((o.def.kind == BKind.paddy || o.def.kind == BKind.bed) && o.crop != null) o.end,
  ]);
  if (fields != null) add(1, fields, '🌾 Ruộng đã chín', 'Ra đồng thu hoạch thôi, kẻo hàng xóm hái trộm mất!');

  final pens = first([
    for (final o in f.objs)
      if (o.def.kind == BKind.pen && o.end != 0) o.end,
  ]);
  if (pens != null) add(2, pens, '🐔 Vật nuôi đã có sản phẩm', 'Trứng, sữa đang chờ bạn ra chuồng thu về.');

  final jobs = first([
    for (final o in f.objs)
      if (o.def.kind == BKind.factory)
        for (final j in o.jobs) j.end,
  ]);
  if (jobs != null) add(3, jobs, '🏭 Xưởng đã làm xong hàng', 'Hàng mới ra lò, nhận về rồi làm mẻ tiếp nào.');

  final fruit = first([
    for (final o in f.objs)
      if (o.def.kind == BKind.tree && o.end != 0) o.end,
  ]);
  if (fruit != null) add(4, fruit, '🍌 Cây ăn quả đã chín', 'Vườn nhà đang trĩu quả.');

  // tomorrow morning's gift (or this evening's, if today's is still waiting)
  final d = DateTime.fromMillisecondsSinceEpoch(now);
  final evening = DateTime(d.year, d.month, d.day, 19).millisecondsSinceEpoch;
  final morning = DateTime(d.year, d.month, d.day + 1, 8).millisecondsSinceEpoch;
  if (!f.loginClaimed && evening - now >= _minLead) {
    add(5, evening, '🎁 Quà hôm nay đang chờ', 'Vào làng nhận quà ngày ${f.loginNextDay} nhé!');
  } else {
    final day = f.loginStreak >= 7 || !f.loginClaimed ? 1 : f.loginStreak + 1;
    add(5, morning, '🎁 Quà đăng nhập ngày $day', 'Ghé nông trại nhận quà, đừng để mất chuỗi ngày!');
  }
  return out;
}
