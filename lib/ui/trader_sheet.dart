// ⛵ Thương lái: what the trader's boat asks for this visit, each line sold
// on its own. The rules are in core/farm_trader.dart.

import 'package:flutter/material.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import 'sheets.dart' show Report;
import 'widgets.dart';

class TraderSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const TraderSheet(this.farm, this.report, {super.key});
  @override
  State<TraderSheet> createState() => _TraderSheetState();
}

class _TraderSheetState extends State<TraderSheet> {
  Farm get f => widget.farm;

  @override
  Widget build(BuildContext context) {
    f.rollTrader();
    final here = f.traderHere;
    return Column(children: [
      SheetHeader('⛵ Thương lái', trailing: Coin(f.coins, size: 15)),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: cardDeco(color: const Color(0xFFE3F0F7)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                  'Ghe thương lái cập bến đầu cầu vào mỗi giờ chẵn (0h, 2h, 4h…) và neo lại một tiếng. '
                  'Thương lái mua giá cao hơn ngoài chợ, bán món nào cũng được.',
                  style: TextStyle(color: brown, fontSize: 13, height: 1.35)),
              const SizedBox(height: 6),
              Ticking(const Duration(seconds: 1), builder: (_) {
                final ms = f.traderMs;
                if (ms <= 0 || f.traderHere != here) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {});
                  });
                }
                return Text(here ? '⏳ Ghe rời bến sau ${fmtTime(ms)}' : '🛶 Ghe sẽ cập bến sau ${fmtTime(ms)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1565C0)));
              }),
            ]),
          ),
          const SizedBox(height: 10),
          if (here)
            for (final o in f.trader) _line(o)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                  f.trader.isNotEmpty && f.trader.every((o) => o.waitUntil < 0) && f.traderVisit == f.traderVisitNow
                      ? 'Thương lái đã mua đủ hàng và xuôi dòng rồi. Hẹn chuyến sau nhé!'
                      : 'Bến sông đang vắng. Chuẩn bị sẵn hàng ngon chờ ghe tới nhé!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: brownLight, fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    ]);
  }

  Widget _line(Order o) {
    final sold = o.waitUntil < 0;
    final e = o.need.entries.first;
    final have = f.countOf(e.key);
    final ok = !sold && have >= e.value;
    final market = f.sellPrice(e.key) * e.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sold ? const Color(0xFFEFF5E4) : (ok ? const Color(0xFFFFF6D6) : const Color(0xFFFFFCF2)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sold ? const Color(0xFFB5D69A) : const Color(0xFF64A5D8), width: 2),
      ),
      child: Row(children: [
        NeedChip(e.key, e.value, have, size: 40),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.value} ${item(e.key).name.toLowerCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 14.5)),
            const SizedBox(height: 2),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
              Coin(o.coins, size: 14),
              Text('⭐ ${o.xp}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E88E5))),
            ]),
            Text('Ngoài chợ: ${fmtNum(market)} xu',
                style: const TextStyle(fontSize: 11.5, color: brownLight, decoration: TextDecoration.lineThrough)),
          ]),
        ),
        if (sold)
          const Text('✅ Đã bán', style: TextStyle(fontWeight: FontWeight.w800, color: greenDark))
        else
          PillButton('Bán',
              color: const Color(0xFF1E88E5),
              onTap: ok
                  ? () {
                      widget.report(f.sellTrader(o), ok: '+${fmtNum(o.coins)} xu');
                      setState(() {});
                    }
                  : null),
      ]),
    );
  }
}
