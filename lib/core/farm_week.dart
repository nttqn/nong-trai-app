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
      _rankQueue(0, weekKey, weekPts);
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

  /// A finished week on leaderboard [board] (0 event, 1 fishing): its place
  /// prize is looked up once the server can be reached.
  void _rankQueue(int board, int week, int pts) {
    if (pts <= 0 || week <= rankDone[board]) return;
    if (rankDue.any((d) => d[0] == board && d[1] == week)) return;
    rankDue.add([board, week, pts]);
  }

  /// Place [place] on [board] in [week] was looked up: gives its prize.
  /// Returns what was given, or null (no prize for that place, or already
  /// settled).
  String? grantRank(int board, int week, int place) {
    rankDue.removeWhere((d) => d[0] == board && d[1] == week);
    if (week <= rankDone[board]) {
      _changed();
      return null;
    }
    rankDone[board] = week;
    final tier = rankTierOf(place);
    if (tier == null) {
      _changed();
      return null;
    }
    final c = rankCoins(tier, level), x = rankXp(tier, level), t = rankTickets[tier];
    coins += c;
    addXp(x);
    tickets += t;
    _stat(board == 0 ? 'week_rank' : 'fish_rank');
    _ev('rank_prize', {'board': board, 'place': place, 'level': level});
    _snd('quest');
    _changed();
    final what = board == 0 ? 'sự kiện tuần' : 'đua top câu cá';
    return '🏆 Hạng $place $what tuần trước: +${fmtNum(c)} xu, +$x KN${t > 0 ? ', +$t Vé Xong ngay' : ''}';
  }

  /// Drops lookups older than [oldestWeek] (too late to matter).
  void dropOldRanks(int oldestWeek) {
    rankDue.removeWhere((d) => d[1] < oldestWeek);
  }
}

/// Place prizes on the weekly boards (event and fishing): the last place
/// of each tier and its multipliers. Coins and xp grow with the level.
const rankPlaces = [1, 3, 10, 30];
const rankCoinMult = [10, 6, 3, 1];
const rankXpMult = [8, 5, 3, 1];
const rankTickets = [3, 2, 1, 0];

int? rankTierOf(int place) {
  for (var i = 0; i < rankPlaces.length; i++) {
    if (place >= 1 && place <= rankPlaces[i]) return i;
  }
  return null;
}

int rankCoins(int tier, int level) => rankCoinMult[tier] * (60 + 15 * level);
int rankXp(int tier, int level) => rankXpMult[tier] * (5 + level);

/// "Hạng 1", "Hạng 2–3"... for the prize list.
String rankLabel(int tier) {
  final from = tier == 0 ? 1 : rankPlaces[tier - 1] + 1, to = rankPlaces[tier];
  return from == to ? 'Hạng $from' : 'Hạng $from–$to';
}
