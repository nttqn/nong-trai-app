// 🎪 Sự kiện tuần: this week's theme, its five milestones and the weekly
// leaderboard (services/week_board.dart).

import 'package:flutter/material.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import '../core/weekly.dart';
import '../render/farm_painter.dart';
import '../services/cloud.dart';
import '../services/leaderboard.dart';
import '../services/week_board.dart';
import 'leaderboard_sheet.dart' show askFarmName;
import 'sheets.dart' show Report;
import 'widgets.dart';

String fmtDays(int ms) {
  final h = (ms / 3600000).floor();
  if (h >= 24) return '${h ~/ 24} ngày ${h % 24} giờ';
  if (h >= 1) return '$h giờ ${(ms / 60000).floor() % 60} phút';
  return '${(ms / 60000).ceil()} phút';
}

class WeekSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const WeekSheet(this.farm, this.report, {super.key});
  @override
  State<WeekSheet> createState() => _WeekSheetState();
}

class _WeekSheetState extends State<WeekSheet> {
  Farm get f => widget.farm;
  List<WeekRow>? _rows;
  int? _rank;
  String? _error;
  int _carried = 0;

  @override
  void initState() {
    super.initState();
    f.rollWeek();
    _carried = f.weekCarried;
    f.weekCarried = 0;
    _load();
  }

  Future<void> _load() async {
    final cs = CloudSave.instance;
    if (!cs.available) {
      setState(() => _error = 'Bảng xếp hạng tuần cần kết nối máy chủ.');
      return;
    }
    try {
      await WeekBoard.instance.submit(f);
      final rows = await WeekBoard.instance.top(f.weekNow);
      int? rank;
      if (cs.user != null && f.name.isNotEmpty && f.weekPts > 0 && !Leaderboard.instance.hidden) {
        rank = await WeekBoard.instance.rankOf(f.weekNow, f.weekPts);
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _rank = rank;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được bảng xếp hạng tuần, thử lại sau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = f.weekTheme;
    final next = weekThemeOf(weekKeyOf(weekEndMs(f.now()) + 3600000));
    return Column(children: [
      SheetHeader('${t.icon} ${t.name}', trailing: Coin(f.coins, size: 15)),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), children: [
          if (_carried > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: cardDeco(color: const Color(0xFFE8F5E1)),
              child: Text('🎁 Tuần trước bạn còn $_carried mốc quà chưa nhận, đã tự cộng vào nông trại.',
                  style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800)),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: cardDeco(color: const Color(0xFFFFF0C9)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.desc, style: const TextStyle(color: brown, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                Text('Điểm tuần này: ${fmtNum(f.weekPts)}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFD84315))),
                const Spacer(),
                Ticking(const Duration(minutes: 1),
                    builder: (_) => Text('Còn ${fmtDays(f.weekEndsIn)}',
                        style: const TextStyle(fontSize: 12.5, color: brownLight, fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 2),
              Text('Tuần sau: ${next.icon} ${next.name}', style: const TextStyle(fontSize: 12, color: brownLight)),
            ]),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < t.targets.length; i++) _milestone(t, i),
          const SizedBox(height: 6),
          const Text('🏆 Bảng xếp hạng tuần', style: TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15.5)),
          const SizedBox(height: 4),
          ..._board(),
        ]),
      ),
    ]);
  }

  Widget _milestone(WeekTheme t, int i) {
    final done = i < f.weekClaimed;
    final reached = f.weekPts >= t.targets[i];
    final canClaim = !done && reached && i == f.weekClaimed;
    final top = i == t.targets.length - 1;
    final prev = i == 0 ? 0 : t.targets[i - 1];
    final p = ((f.weekPts - prev) / (t.targets[i] - prev)).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: cardDeco(color: done ? const Color(0xFFEFF5E4) : (canClaim ? const Color(0xFFFFF6D6) : Colors.white)),
      child: Row(children: [
        if (top)
          SizedBox(width: 52, height: 52, child: CustomPaint(painter: ObjPreviewPainter(t.deco, f)))
        else
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: creamDark, borderRadius: BorderRadius.circular(12)),
            child: Text('${i + 1}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: brown)),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mốc ${i + 1}: ${fmtNum(t.targets[i])} điểm',
                style: const TextStyle(fontWeight: FontWeight.w900, color: brown)),
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Coin(weekCoins(i, f.level), size: 12.5),
              Text('⭐ ${weekXp(i, f.level)}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E88E5), fontWeight: FontWeight.w800)),
              if (weekTickets[i] > 0)
                Text('⚡ ${weekTickets[i]} Vé Xong ngay', style: const TextStyle(fontSize: 12.5, color: brown, fontWeight: FontWeight.w700)),
              if (top) Text('🎁 ${bdef(t.deco).name}', style: const TextStyle(fontSize: 12.5, color: Color(0xFFC62828), fontWeight: FontWeight.w800)),
            ]),
            if (!done && !reached) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(value: p, minHeight: 7, color: green, backgroundColor: creamDark),
              ),
            ],
          ]),
        ),
        const SizedBox(width: 6),
        if (done)
          const Text('✅', style: TextStyle(fontSize: 20))
        else if (canClaim)
          PillButton('Nhận', color: gold, onTap: () {
            widget.report(f.claimWeek(), ok: top ? 'Nhận ${bdef(t.deco).name}! Đặt ở Xây dựng → Trang trí' : 'Đã nhận quà mốc ${i + 1}');
            setState(() {});
          }),
      ]),
    );
  }

  List<Widget> _board() {
    final cs = CloudSave.instance;
    final hint = cs.user == null
        ? 'Đăng nhập Google (☰ → Lưu trữ đám mây) để lên bảng xếp hạng tuần.'
        : f.name.isEmpty
            ? 'Đặt tên nông trại để lên bảng xếp hạng tuần.'
            : Leaderboard.instance.hidden
                ? 'Bạn đang ẩn tên khỏi bảng xếp hạng.'
                : f.weekPts == 0
                    ? 'Kiếm điểm đầu tiên để có tên trên bảng.'
                    : _rank != null
                        ? 'Bạn đang đứng thứ $_rank tuần này.'
                        : null;
    return [
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
    ];
  }

  Widget _row(int place, WeekRow r) {
    final me = r.uid == WeekBoard.instance.myUid;
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
