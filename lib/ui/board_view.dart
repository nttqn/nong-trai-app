// A weekly leaderboard (sự kiện tuần or Đua top câu cá) with its place
// prizes, shared by week_sheet.dart and the fishing board in
// river_sheet.dart. Data: services/week_board.dart; prizes: farm_week.dart.

import 'package:flutter/material.dart';

import '../core/farm.dart';
import '../services/cloud.dart';
import '../services/leaderboard.dart';
import '../services/rank_prizes.dart';
import '../services/week_board.dart';
import 'leaderboard_sheet.dart' show askFarmName;
import 'widgets.dart';

/// The prizes for places on a weekly board, given when the week ends.
class RankPrizeList extends StatelessWidget {
  final Farm farm;
  const RankPrizeList(this.farm, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: cardDeco(color: const Color(0xFFFFF6D6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🎁 Quà xếp hạng (phát khi hết tuần)',
            style: TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 14)),
        const SizedBox(height: 4),
        for (var i = 0; i < rankPlaces.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(children: [
              SizedBox(
                width: 104,
                child: Text('${i < 3 ? const ['🥇', '🥈', '🏅'][i] : '🎖️'} ${rankLabel(i)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: brown, fontSize: 12.5)),
              ),
              Expanded(
                child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Coin(rankCoins(i, farm.level), size: 12),
                  Text('⭐ ${rankXp(i, farm.level)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E88E5), fontWeight: FontWeight.w800)),
                  if (rankTickets[i] > 0)
                    Text('⚡ ${rankTickets[i]} Vé',
                        style: const TextStyle(fontSize: 12, color: brown, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
        const SizedBox(height: 4),
        const Text('Cần đăng nhập và đặt tên nông trại để được xếp hạng.',
            style: TextStyle(fontSize: 11.5, color: brownLight)),
      ]),
    );
  }
}

/// This week's top 30 on [board], the player's place, and the hint for
/// getting on it.
class BoardList extends StatefulWidget {
  final Farm farm;
  final WeekBoard board;

  /// What a point is, for the empty hint ("Câu con cá đầu tiên...").
  final String firstHint;
  const BoardList(this.farm, this.board, {required this.firstHint, super.key});
  @override
  State<BoardList> createState() => _BoardListState();
}

class _BoardListState extends State<BoardList> {
  Farm get f => widget.farm;
  WeekBoard get b => widget.board;
  List<WeekRow>? _rows;
  int? _rank;
  String? _error;
  List<String> _prizes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cs = CloudSave.instance;
    if (!cs.available) {
      setState(() => _error = 'Bảng xếp hạng cần kết nối máy chủ.');
      return;
    }
    try {
      final prizes = await RankPrizes.instance.settle(f);
      await b.submit(f);
      final week = f.weekNow, pts = b.weekOf(f) == week ? b.ptsOf(f) : 0;
      final rows = await b.top(week);
      int? rank;
      if (cs.user != null && f.name.isNotEmpty && pts > 0 && !Leaderboard.instance.hidden) {
        rank = await b.rankOf(week, pts);
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _rank = rank;
        _error = null;
        if (prizes.isNotEmpty) _prizes = prizes;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được bảng xếp hạng, thử lại sau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = CloudSave.instance;
    final pts = b.weekOf(f) == f.weekNow ? b.ptsOf(f) : 0;
    final hint = cs.user == null
        ? 'Đăng nhập (☰ → Lưu trữ đám mây) để lên bảng xếp hạng.'
        : f.name.isEmpty
            ? 'Đặt tên nông trại để lên bảng xếp hạng.'
            : Leaderboard.instance.hidden
                ? 'Bạn đang ẩn tên khỏi bảng xếp hạng.'
                : pts == 0
                    ? widget.firstHint
                    : _rank != null
                        ? 'Bạn đang đứng thứ $_rank tuần này.'
                        : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final p in _prizes)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: cardDeco(color: const Color(0xFFE8F5E1)),
          child: Text(p, style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800)),
        ),
      if (hint != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Expanded(child: Text(hint, style: const TextStyle(fontSize: 12.5, color: brownLight, fontWeight: FontWeight.w700))),
            if (cs.user != null && f.name.isEmpty)
              PillButton('Đặt tên', dense: true, onTap: () async {
                if (await askFarmName(context, f)) _load();
              }),
          ]),
        ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: brownLight))
      else if (_rows == null)
        const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
      else if (_rows!.isEmpty)
        const Text('Chưa ai có điểm tuần này. Hãy là người đầu tiên!', style: TextStyle(color: brownLight))
      else
        for (final (i, r) in _rows!.indexed) _row(i + 1, r),
    ]);
  }

  Widget _row(int place, WeekRow r) {
    final me = r.uid == b.myUid;
    final medal = place <= 3 ? const ['🥇', '🥈', '🥉'][place - 1] : '$place';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: cardDeco(color: me ? const Color(0xFFFFF0C9) : Colors.white),
      child: Row(children: [
        SizedBox(width: 30, child: Text(medal, style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15))),
        Expanded(
          child: Text(r.name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: brown)),
        ),
        Text('Cấp ${r.level}  ', style: const TextStyle(fontSize: 12, color: brownLight)),
        Text(fmtNum(r.pts), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD84315))),
      ]),
    );
  }
}
