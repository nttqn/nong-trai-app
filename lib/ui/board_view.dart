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

/// This week's [board] a page of 50 at a time, the player's place, and the hint for
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
  int _req = 0;

  /// Place of the first row: 1 from the top, else where "Vị trí của tôi"
  /// starts.
  int _start = 1;
  bool _around = false;

  /// Where the next page starts; null at the end or around this farm.
  Object? _next;
  bool _more = false;
  final _meKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _pts => b.weekOf(f) == f.weekNow ? b.ptsOf(f) : 0;

  Future<void> _load({bool settle = true}) async {
    final cs = CloudSave.instance;
    if (!cs.available) {
      setState(() => _error = 'Bảng xếp hạng cần kết nối máy chủ.');
      return;
    }
    final req = ++_req;
    try {
      final prizes = settle ? await RankPrizes.instance.settle(f) : const <String>[];
      if (settle) await b.submit(f, force: true);
      final week = f.weekNow, pts = _pts;
      final (rows, next) = await b.top(week);
      int? rank;
      if (cs.user != null && f.name.isNotEmpty && pts > 0 && !Leaderboard.instance.hidden) {
        rank = await b.rankOf(week, pts);
      }
      if (!mounted || req != _req) return;
      setState(() {
        _rows = rows;
        _next = next;
        _start = 1;
        _around = false;
        _rank = rank;
        _error = null;
        if (prizes.isNotEmpty) _prizes = prizes;
      });
    } catch (_) {
      if (mounted && req == _req) setState(() => _error = 'Không tải được bảng xếp hạng, thử lại sau.');
    }
  }

  /// The next [WeekBoard.pageSize] rows under those shown.
  Future<void> _loadMore() async {
    final rows = _rows;
    if (_more || rows == null || _next == null) return;
    final req = _req;
    setState(() => _more = true);
    try {
      final (more, next) = await b.top(f.weekNow, after: _next);
      if (!mounted || req != _req) return;
      setState(() {
        _rows = [...rows, ...more];
        _next = next;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Không tải thêm được, thử lại sau.')));
      }
    }
    if (mounted) setState(() => _more = false);
  }

  /// Rows around this farm's place, scrolled to it.
  Future<void> _showMe() async {
    final place = _rank;
    if (place == null || _more) return;
    final req = ++_req;
    setState(() => _more = true);
    try {
      final (above, rest) = await b.around(f.weekNow, _pts);
      if (!mounted || req != _req) return;
      setState(() {
        _rows = [...above, ...rest];
        _start = place - above.length;
        _around = true;
        _next = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = _meKey.currentContext;
        if (c != null) Scrollable.ensureVisible(c, alignment: 0.4);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được, thử lại sau.')));
      }
    }
    if (mounted) setState(() => _more = false);
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
            if (_rank != null && pts > 0 && _rows != null && !_around && !Leaderboard.instance.hidden)
              PillButton('📍 Vị trí của tôi', dense: true, onTap: _more ? null : _showMe),
          ]),
        ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: brownLight))
      else if (_rows == null)
        const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
      else if (_rows!.isEmpty)
        const Text('Chưa ai có điểm tuần này. Hãy là người đầu tiên!', style: TextStyle(color: brownLight))
      else ...[
        for (final (i, r) in _rows!.indexed) _row(_start + i, r, key: i == _mineAt ? _meKey : null),
        if (_around || _next != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: _more
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: green, strokeWidth: 2.5))
                  : _around
                      ? PillButton('⬆ Về top', dense: true, color: brownLight, onTap: () => _load(settle: false))
                      : PillButton('Xem thêm ${WeekBoard.pageSize}', dense: true, color: brownLight, onTap: _loadMore),
            ),
          ),
      ],
    ]);
  }

  /// The row standing for this farm when around it: its own, else the
  /// first at or under its points.
  int get _mineAt {
    final rows = _rows;
    if (!_around || rows == null || rows.isEmpty) return -1;
    final i = rows.indexWhere((r) => r.uid == b.myUid);
    if (i >= 0 || _rank == null) return i;
    return (_rank! - _start).clamp(0, rows.length - 1);
  }

  Widget _row(int place, WeekRow r, {Key? key}) {
    final me = r.uid == b.myUid;
    final medal = place <= 3 ? const ['🥇', '🥈', '🥉'][place - 1] : '$place';
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: cardDeco(color: me ? const Color(0xFFFFF0C9) : Colors.white),
      child: Row(children: [
        SizedBox(
            width: 34,
            child: Text(medal,
                style: TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: place >= 1000 ? 11.5 : 15))),
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
