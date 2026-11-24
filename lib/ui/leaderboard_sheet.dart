// 🏆 Bảng xếp hạng: three boards (level, orders, village projects) read
// from Firestore. Signing in, naming the farm and hiding oneself are here.

import 'package:flutter/material.dart';

import '../core/farm.dart';
import '../services/cloud.dart';
import 'cloud_tile.dart' show signInPick;
import '../services/leaderboard.dart';
import 'widgets.dart';

/// Asks for the farm's name (leaderboard, region map). True if it changed.
Future<bool> askFarmName(BuildContext context, Farm farm) async {
  final ctl = TextEditingController(text: farm.name);
  final name = await showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: cream,
      title: const Text('Tên nông trại'),
      content: TextField(
        controller: ctl,
        autofocus: true,
        maxLength: 20,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'VD: Trang trại Bác Ba'),
        onSubmitted: (v) => Navigator.pop(d, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Thôi')),
        TextButton(onPressed: () => Navigator.pop(d, ctl.text), child: const Text('Lưu')),
      ],
    ),
  );
  final n = name?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  if (n.isEmpty || n == farm.name) return false;
  farm.name = n;
  farm.rev++; // saves (and later uploads) the new name
  return true;
}

class LeaderboardSheet extends StatefulWidget {
  final Farm farm;
  const LeaderboardSheet(this.farm, {super.key});
  @override
  State<LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<LeaderboardSheet> {
  LbBoard _board = LbBoard.level;
  List<LbEntry>? _rows;
  int? _myRank;
  String? _error;
  bool _loading = false;
  int _req = 0;

  /// Place of the first row: 1 from the top, else where "Vị trí của tôi"
  /// starts.
  int _start = 1;
  bool _around = false;

  /// Where the next page starts; null at the end or around this farm.
  Object? _next;
  bool _more = false;
  final _meKey = GlobalKey();

  Farm get farm => widget.farm;
  Leaderboard get lb => Leaderboard.instance;
  CloudSave get cs => CloudSave.instance;

  @override
  void initState() {
    super.initState();
    cs.addListener(_onCloud);
    _load(submit: true);
  }

  @override
  void dispose() {
    cs.removeListener(_onCloud);
    super.dispose();
  }

  String? _uid;
  void _onCloud() {
    if (!mounted) return;
    if (cs.user?.uid != _uid) {
      _uid = cs.user?.uid;
      _load(submit: true);
    } else {
      setState(() {});
    }
  }

  Future<void> _load({bool submit = false}) async {
    _uid = cs.user?.uid;
    if (!cs.available) {
      setState(() => _error = 'Bảng xếp hạng cần kết nối máy chủ, bản này chưa bật.');
      return;
    }
    final req = ++_req;
    setState(() {
      _loading = true;
      _error = null;
      _start = 1;
      _around = false;
      _next = null;
    });
    try {
      if (submit) await lb.submit(farm, force: true);
      final b = _board;
      final page = await lb.top(b);
      int? mine;
      if (_onBoard) mine = await lb.rankOf(b, _mine(b));
      if (!mounted || req != _req) return;
      setState(() {
        _rows = page.rows;
        _next = page.next;
        _myRank = mine;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || req != _req) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được bảng xếp hạng, thử lại sau.';
      });
    }
  }

  bool get _onBoard => cs.user != null && !lb.hidden && farm.name.isNotEmpty;
  int _mine(LbBoard b) => lbRow(farm)[b.field] as int;

  /// The next [Leaderboard.pageSize] rows under those shown.
  Future<void> _loadMore() async {
    final rows = _rows;
    if (_more || rows == null || _next == null) return;
    final req = _req;
    setState(() => _more = true);
    try {
      final page = await lb.top(_board, after: _next);
      if (!mounted || req != _req) return;
      setState(() {
        _rows = [...rows, ...page.rows];
        _next = page.next;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Không tải thêm được, thử lại sau.')));
      }
    }
    if (mounted) setState(() => _more = false);
  }

  /// Rows around this farm's place, scrolled to it.
  Future<void> _showMe() async {
    final place = _myRank;
    if (place == null || _more) return;
    final req = ++_req;
    setState(() => _more = true);
    try {
      final (above, rest) = await lb.around(_board, _mine(_board));
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được, thử lại sau.')));
      }
    }
    if (mounted) setState(() => _more = false);
  }

  Future<void> _rename() async {
    if (await askFarmName(context, farm)) await _load(submit: true);
  }

  String _value(LbEntry e) => switch (_board) {
        LbBoard.level => 'Cấp ${e.level}',
        LbBoard.orders => '${fmtNum(e.orders)} đơn',
        LbBoard.village => '${e.projects()} công trình',
      };

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SheetHeader('🏆 Bảng xếp hạng'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SegmentedButton<LbBoard>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: green,
            selectedForegroundColor: Colors.white,
            foregroundColor: brown,
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
          segments: [for (final b in LbBoard.values) ButtonSegment(value: b, label: Text(b.label))],
          selected: {_board},
          onSelectionChanged: (s) {
            setState(() {
              _board = s.first;
              _rows = null;
              _myRank = null;
            });
            _load();
          },
        ),
      ),
      const SizedBox(height: 6),
      Expanded(child: _list()),
      _footer(),
    ]);
  }

  Widget _list() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: brownLight)),
        ),
      );
    }
    final rows = _rows;
    if (rows == null) return const Center(child: CircularProgressIndicator(color: green));
    if (rows.isEmpty) {
      return const Center(child: Text('Chưa có ai trên bảng. Hãy là người đầu tiên!', style: TextStyle(color: brownLight)));
    }
    final me = cs.user?.uid;
    final footer = _around || _next != null;
    // the row standing for this farm when around it: its own, else the
    // first at or under its value
    var mineAt = -1;
    if (_around) {
      mineAt = rows.indexWhere((e) => e.uid == me);
      if (mineAt < 0 && _myRank != null) mineAt = (_myRank! - _start).clamp(0, rows.length - 1);
    }
    return RefreshIndicator(
      color: green,
      onRefresh: () => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        itemCount: rows.length + (footer ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == rows.length) return _moreButton();
          final e = rows[i];
          final mine = e.uid == me;
          final place = _start + i;
          final medal = place <= 3 ? const ['🥇', '🥈', '🥉'][place - 1] : '$place';
          return Container(
            key: i == mineAt ? _meKey : null,
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: cardDeco(color: mine ? const Color(0xFFFFF1C4) : Colors.white),
            child: Row(children: [
              SizedBox(
                width: 34,
                child: Text(medal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: place <= 3 ? 20 : (place >= 1000 ? 11.5 : 14),
                        fontWeight: FontWeight.w900,
                        color: brownLight)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(mine ? '${e.name} (bạn)' : e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: brown)),
              ),
              Text(_value(e), style: const TextStyle(fontWeight: FontWeight.w800, color: greenDark)),
            ]),
          );
        },
      ),
    );
  }

  Widget _moreButton() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: _more
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: green, strokeWidth: 2.5))
              : _around
                  ? PillButton('⬆ Về top', dense: true, color: brownLight, onTap: () => _load())
                  : PillButton('Xem thêm ${Leaderboard.pageSize}', dense: true, color: brownLight, onTap: _loadMore),
        ),
      );

  Widget _footer() {
    final Widget body;
    if (!cs.available) {
      body = const SizedBox.shrink();
    } else if (cs.user == null) {
      body = Row(children: [
        const Expanded(
          child: Text('Đăng nhập để nông trại của bạn có tên trên bảng.',
              style: TextStyle(color: brown, fontSize: 12.5)),
        ),
        PillButton(cs.busy ? '…' : 'Đăng nhập', dense: true, onTap: cs.busy ? null : () => signInPick(context)),
      ]);
    } else if (farm.name.isEmpty) {
      body = Row(children: [
        const Expanded(
          child: Text('Đặt tên nông trại để lên bảng xếp hạng.', style: TextStyle(color: brown, fontSize: 12.5)),
        ),
        PillButton('Đặt tên', dense: true, onTap: _rename),
      ]);
    } else {
      body = Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(farm.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: brown, fontWeight: FontWeight.w900)),
            Text(
                lb.hidden
                    ? 'Đang ẩn khỏi bảng'
                    : _loading
                        ? 'Đang tải…'
                        : _myRank == null
                            ? ''
                            : 'Hạng của bạn: #$_myRank',
                style: const TextStyle(color: brownLight, fontSize: 12.5)),
          ]),
        ),
        if (_myRank != null && _rows != null && !_around && !lb.hidden)
          PillButton('📍 Vị trí của tôi', dense: true, onTap: _more ? null : _showMe),
        IconButton(
          tooltip: 'Đổi tên',
          onPressed: _rename,
          icon: const Icon(Icons.edit_rounded, color: brownLight),
        ),
        TextButton(
          onPressed: () async {
            await lb.setHidden(!lb.hidden, farm);
            await _load();
          },
          child: Text(lb.hidden ? 'Hiện lại' : 'Ẩn tôi', style: const TextStyle(fontSize: 12.5)),
        ),
      ]);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: creamDark, width: 1.5))),
      child: body,
    );
  }
}
