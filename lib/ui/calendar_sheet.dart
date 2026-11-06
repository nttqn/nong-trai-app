// Lịch làng: today's lunar date, tiết khí and its saying, the season's
// crops, and the festival going on (with its orders) or coming next.

import 'package:flutter/material.dart';

import '../core/calendar.dart';
import '../core/defs.dart';
import '../core/farm.dart';
import '../core/lunar.dart';
import 'sheets.dart' show Report;
import 'widgets.dart';

const _festRed = Color(0xFFC62828);

/// Lunar date for the HUD chip (worked out once a day).
LunarDate lunarToday(Farm f) {
  final d = f.today;
  if (_cacheDay != d) {
    _cacheDay = d;
    _cache = LunarDate.of(d);
  }
  return _cache!;
}

DateTime? _cacheDay;
LunarDate? _cache;

const _weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
const _lunarMonths = ['Giêng', 'Hai', 'Ba', 'Tư', 'Năm', 'Sáu', 'Bảy', 'Tám', 'Chín', 'Mười', 'Một', 'Chạp'];

String _dm(DateTime d) => '${d.day}/${d.month}';

class CalendarSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const CalendarSheet(this.farm, this.report, {super.key});
  @override
  State<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<CalendarSheet> {
  @override
  Widget build(BuildContext context) {
    final f = widget.farm;
    f.tickOrders();
    final d = f.today;
    final l = lunarToday(f);
    final term = solarTermOf(d);
    final s = seasons[f.season]!;
    final fest = f.festival;
    final next = upcomingFestivals(d, count: 4);
    return Column(children: [
      const SheetHeader('Lịch làng'),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(14, 4, 14, 16), children: [
          // today
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDeco(color: const Color(0xFFFFF4E0)),
            child: Row(children: [
              Container(
                width: 74,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: _festRed, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('${l.day}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
                  Text('tháng ${_lunarMonths[l.month - 1]}${l.leap ? ' nhuận' : ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Năm ${l.yearName}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: brown)),
                  Text('${_weekdays[d.weekday - 1]}, ${_dm(d)}/${d.year} dương lịch',
                      style: const TextStyle(fontSize: 12.5, color: brownLight, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('🌤️ Tiết ${solarTermNames[term]}',
                      style: const TextStyle(fontSize: 14, color: brown, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
            child: Text('“${termSayings[term]}”',
                textAlign: TextAlign.center,
                style: const TextStyle(fontStyle: FontStyle.italic, color: brown, fontSize: 13.5)),
          ),
          const SizedBox(height: 8),
          // season
          Container(
            padding: const EdgeInsets.all(12),
            decoration: cardDeco(color: Colors.white),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.icon} ${s.name} · ${s.vu}',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: brown)),
              Text('Cây hợp mùa lớn nhanh hơn ${(seasonSpeed * 100).round()}%:',
                  style: const TextStyle(fontSize: 12.5, color: brownLight)),
              const SizedBox(height: 6),
              Wrap(spacing: 10, runSpacing: 6, children: [
                for (final id in s.crops)
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Opacity(opacity: f.level >= crops[id]!.level ? 1 : .4, child: ItemIcon(crops[id]!.product, size: 34)),
                    Text(crops[id]!.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: brown)),
                  ]),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          // festival
          if (fest != null) ..._festival(fest),
          const Text('🏮 Lễ hội sắp tới', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: brown)),
          const SizedBox(height: 6),
          for (final n in next)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                SizedBox(width: 30, child: Text(n.def.icon, style: const TextStyle(fontSize: 20))),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.def.name, style: const TextStyle(fontWeight: FontWeight.w800, color: brown)),
                    Text('${_dm(n.start)} – ${_dm(n.end)} · quà: ${bdef(n.def.deco).name}',
                        style: const TextStyle(fontSize: 11.5, color: brownLight)),
                  ]),
                ),
                Text(n.daysUntil(d) <= 1 ? 'ngày mai' : 'còn ${n.daysUntil(d)} ngày',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _festRed)),
              ]),
            ),
          const SizedBox(height: 6),
          const Text('Lịch tính theo âm lịch Việt Nam ngay trên máy. Lễ hội mở đơn hàng riêng từ cấp ${FarmSeason.festLevel}.',
              style: TextStyle(fontSize: 11.5, color: brownLight)),
        ]),
      ),
    ]);
  }

  List<Widget> _festival(FestivalTime ft) {
    final f = widget.farm;
    final done = f.fest.where((o) => o.waitUntil < 0).length;
    final left = ft.daysLeft(f.today);
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFF57C00)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${ft.def.icon} ${ft.def.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            Text(left <= 1 ? 'Ngày cuối!' : 'Còn $left ngày',
                style: const TextStyle(color: Color(0xFFFFF59D), fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 2),
          Text(ft.def.desc, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
        ]),
      ),
      const SizedBox(height: 8),
      if (f.level < FarmSeason.festLevel)
        const Text('Đạt cấp ${FarmSeason.festLevel} để nhận đơn hàng lễ hội.',
            style: TextStyle(color: brownLight, fontWeight: FontWeight.w700))
      else ...[
        Row(children: [
          Flexible(
            child: Text('Giao đủ 3 đơn ($done/3) được ',
                style: const TextStyle(fontSize: 12.5, color: brown)),
          ),
          Coin(f.festAllBonus, size: 12.5),
          Flexible(
            child: Text(' + 🎁 ${bdef(ft.def.deco).name}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: brown, fontWeight: FontWeight.w800)),
          ),
          if (f.festAllDone) const Text('  ✅'),
        ]),
        const SizedBox(height: 6),
        for (final o in f.fest) FestOrderCard(f, o, widget.report, () => setState(() {})),
      ],
      const SizedBox(height: 10),
    ];
  }
}

/// One festival order (also listed at the top of the orders sheet).
class FestOrderCard extends StatelessWidget {
  final Farm farm;
  final Order o;
  final Report report;
  final VoidCallback changed;
  const FestOrderCard(this.farm, this.o, this.report, this.changed, {super.key});

  @override
  Widget build(BuildContext context) {
    final f = farm;
    final delivered = o.waitUntil < 0;
    final ok = !delivered && o.need.entries.every((e) => f.countOf(e.key) >= e.value);
    final icon = f.activeFestival?.def.icon ?? '🏮';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: delivered ? const Color(0xFFEFF5E4) : (ok ? const Color(0xFFFFEBEE) : const Color(0xFFFFFAF7)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: delivered ? const Color(0xFFB5D69A) : _festRed, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('$icon ${o.who}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15))),
          Coin(o.coins, size: 14),
          const SizedBox(width: 8),
          Text('⭐ ${o.xp}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E88E5))),
        ]),
        const SizedBox(height: 6),
        if (delivered)
          const Text('✅ Đã giao', style: TextStyle(fontWeight: FontWeight.w800, color: greenDark))
        else ...[
          Wrap(children: [
            for (final e in o.need.entries) NeedChip(e.key, e.value, f.countOf(e.key), size: 36),
          ]),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: PillButton('Giao hàng',
                color: _festRed,
                onTap: ok
                    ? () {
                        final last = f.fest.where((d) => d.waitUntil >= 0).length == 1;
                        final gift = f.activeFestival?.def.deco;
                        report(f.deliverFest(o),
                            ok: last && gift != null
                                ? 'Đủ 3 đơn! Nhận ${bdef(gift).name}, đặt ở mục Xây dựng › Trang trí'
                                : '+${fmtNum(o.coins)} xu');
                        changed();
                      }
                    : null),
          ),
        ],
      ]),
    );
  }
}
