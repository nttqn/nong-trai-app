// Sự kiện tuần (1.8.0): points, milestones and the week roll-over. Data in
// weekly.dart. A part of farm.dart so it can use the farm's helpers.

part of 'farm.dart';

extension FarmWeek on Farm {
  bool get weekOpen => level >= weekLevel;

  int get weekNow => weekKeyOf(now());
  WeekTheme get weekTheme => weekThemeOf(weekNow);
  int get weekEndsIn => weekEndMs(now()) - now();

  /// A new week: milestones reached but not claimed are given now, so
  /// nothing is lost by not opening the sheet before Monday.
  void rollWeek() {
    final k = weekNow;
    if (k == weekKey) return;
    if (weekKey != 0 && weekPts > 0) {
      final old = weekThemeOf(weekKey);
      var n = 0;
      while (weekClaimed < old.targets.length && weekPts >= old.targets[weekClaimed]) {
        _giveWeek(old, weekClaimed);
        weekClaimed++;
        n++;
      }
      if (n > 0) weekCarried = n;
      _ev('week_end', {'theme': old.id, 'pts': weekPts, 'tiers': weekClaimed});
    }
    weekKey = k;
    weekPts = 0;
    weekClaimed = 0;
    _changed();
  }

  /// Points for [kind] while it is this week's theme.
  void _weekAdd(WeekKind kind, int n) {
    if (!weekOpen || n <= 0) return;
    rollWeek();
    if (weekTheme.kind != kind) return;
    weekPts += n;
    _stat('week_pts', n);
  }

  /// Milestones reached and not claimed yet.
  int get weekReady {
    if (!weekOpen) return 0;
    final t = weekTheme;
    var n = 0;
    for (var i = weekClaimed; i < t.targets.length && weekPts >= t.targets[i]; i++) {
      n++;
    }
    return weekKey == weekNow ? n : 0;
  }

  String? claimWeek() {
    rollWeek();
    final t = weekTheme;
    if (weekClaimed >= t.targets.length) return 'Đã nhận hết quà tuần này';
    if (weekPts < t.targets[weekClaimed]) return 'Chưa đủ điểm';
    _giveWeek(t, weekClaimed);
    weekClaimed++;
    _snd('quest');
    _ev('week_claim', {'theme': t.id, 'tier': weekClaimed, 'level': level});
    _changed();
    return null;
  }

  void _giveWeek(WeekTheme t, int tier) {
    coins += weekCoins(tier, level);
    addXp(weekXp(tier, level));
    tickets += weekTickets[tier];
    if (tier == t.targets.length - 1) {
      giftDeco[t.deco] = giftCount(t.deco) + 1;
      _stat('week_top');
      if (house != null) _fx(house!, '🎁 ${bdef(t.deco).name}');
    }
    _stat('week_tier');
  }
}
