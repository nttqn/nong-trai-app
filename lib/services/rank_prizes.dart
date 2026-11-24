// Place prizes on the weekly leaderboards (1.9.0, players asked for "đua
// top" with small prizes): when a week ends, the farm queues it
// (Farm.rankDue); here its place is counted on the server and the prize
// given (Farm.grantRank). Runs after each cloud sync and when the event or
// fishing sheet opens. Only players who were on the board (signed in, farm
// name, not hidden) get a place.

import 'package:flutter/foundation.dart';

import '../core/farm.dart';
import '../core/weekly.dart';
import 'cloud.dart';
import 'leaderboard.dart';
import 'week_board.dart';

class RankPrizes {
  RankPrizes._();
  static final RankPrizes instance = RankPrizes._();

  /// The latest prize message, for the farm screen's toast.
  final ValueNotifier<String?> news = ValueNotifier<String?>(null);
  bool _busy = false;

  /// Looks up the places still due and gives their prizes. Returns what
  /// was given.
  Future<List<String>> settle(Farm f) async {
    if (_busy || f.rankDue.isEmpty) return const [];
    // a place is only looked up within three weeks of the week's end
    final now = f.now();
    f.dropOldRanks(weekKeyOf(now - 28 * 86400000));
    final cs = CloudSave.instance;
    if (!cs.available || cs.user == null) return const [];
    _busy = true;
    final out = <String>[];
    try {
      for (final d in [...f.rankDue]) {
        final board = d[0] == 0 ? WeekBoard.instance : WeekBoard.fishing;
        final week = d[1], pts = d[2];
        if (week >= weekKeyOf(now)) continue; // not over yet
        // not on the board that week: nothing to look up
        if (f.name.trim().isEmpty || Leaderboard.instance.hidden) {
          f.grantRank(d[0], week, 0);
          continue;
        }
        final place = await board.rankOf(week, pts);
        if (place == null) continue; // offline: try again later
        final msg = f.grantRank(d[0], week, place);
        if (msg != null) out.add(msg);
      }
    } catch (e) {
      debugPrint('rank prizes failed: $e');
    } finally {
      _busy = false;
    }
    if (out.isNotEmpty) news.value = out.join('\n');
    return out;
  }
}
