// 📜 Nhiệm vụ: the main quest chain — finished ones, the current one with
// its progress and reward, and a peek at the next few.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/farm.dart';
import '../core/quests.dart';
import 'widgets.dart';

class QuestSheet extends StatefulWidget {
  final Farm farm;
  final VoidCallback onClaim;
  const QuestSheet(this.farm, this.onClaim, {super.key});
  @override
  State<QuestSheet> createState() => _QuestSheetState();
}

class _QuestSheetState extends State<QuestSheet> {
  static const _peek = 3;
  final _scroll = ScrollController();

  Farm get farm => widget.farm;

  @override
  void initState() {
    super.initState();
    // Open on the current quest, not at the top of a long finished list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(math.min(_scroll.position.maxScrollExtent, math.max(0, farm.quest - 1) * 58.0));
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _reward(QuestDef q) => Row(mainAxisSize: MainAxisSize.min, children: [
        Coin(q.coins, size: 12),
        if (q.xp > 0) ...[
          const SizedBox(width: 6),
          Text('+${q.xp} KN', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E88E5))),
        ],
      ]);

  @override
  Widget build(BuildContext context) {
    final cur = farm.quest;
    final total = questChain.length;
    final shown = math.min(total, cur + 1 + _peek);
    final hidden = total - shown;
    return Column(children: [
      SheetHeader('📜 Nhiệm vụ',
          trailing: Text('${math.min(cur, total)}/$total',
              style: const TextStyle(fontWeight: FontWeight.w900, color: greenDark))),
      Expanded(
        child: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), children: [
          for (var i = 0; i < shown; i++)
            if (i < cur)
              _done(questChain[i])
            else if (i == cur)
              _current(questChain[i])
            else
              _next(questChain[i]),
          if (hidden > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('🔒 Còn $hidden nhiệm vụ nữa…',
                  textAlign: TextAlign.center, style: const TextStyle(color: brownLight, fontWeight: FontWeight.w700)),
            ),
          if (cur >= total)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('🎉 Bạn đã hoàn thành mọi nhiệm vụ!',
                  textAlign: TextAlign.center, style: TextStyle(color: greenDark, fontWeight: FontWeight.w900)),
            ),
        ]),
      ),
    ]);
  }

  Widget _done(QuestDef q) => Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: cardDeco(color: const Color(0xFFEFF5E4)),
        child: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(q.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: brownLight, fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _current(QuestDef q) {
    final v = math.min(farm.questValue(q), q.target);
    final done = farm.questDone;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFFFF1C4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? gold : green, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📜', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(q.text, style: const TextStyle(color: brown, fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          Text('$v/${q.target}', style: const TextStyle(color: greenDark, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: v / q.target, minHeight: 9, color: green, backgroundColor: creamDark),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Thưởng: ', style: TextStyle(color: brownLight, fontSize: 12.5)),
          _reward(q),
          const Spacer(),
          if (done)
            PillButton('Nhận 🎁', dense: true, color: gold, onTap: () {
              widget.onClaim();
              setState(() {});
            }),
        ]),
      ]),
    );
  }

  Widget _next(QuestDef q) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: cardDeco(color: const Color(0xFFF7F1E3)),
        child: Row(children: [
          const Text('⏳', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(child: Text(q.text, style: const TextStyle(color: brown, fontWeight: FontWeight.w700))),
          Opacity(opacity: .75, child: _reward(q)),
        ]),
      );
}
