// 🎪 Sự kiện tuần: this week's theme, its five milestones and the weekly
// leaderboard (services/week_board.dart).

import 'package:flutter/material.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import '../core/weekly.dart';
import '../render/farm_painter.dart';
import '../services/week_board.dart';
import 'board_view.dart';
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
  int _carried = 0;

  @override
  void initState() {
    super.initState();
    f.rollWeek();
    _carried = f.weekCarried;
    f.weekCarried = 0;
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
          RankPrizeList(f),
          const SizedBox(height: 10),
          const Text('🏆 Bảng xếp hạng tuần', style: TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15.5)),
          const SizedBox(height: 4),
          BoardList(f, WeekBoard.instance, firstHint: 'Kiếm điểm đầu tiên để có tên trên bảng.'),
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
}
