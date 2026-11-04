// Full-height sheets: shop, storage/market, orders, village projects.

import 'package:flutter/material.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import '../render/farm_painter.dart';
import 'widgets.dart';

typedef Report = void Function(String? err, {String? ok});

// ------------------------------------------------------------------ shop
class ShopSheet extends StatefulWidget {
  final Farm farm;
  const ShopSheet(this.farm, {super.key});
  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {
  static const tabs = [
    ('Trồng trọt', ['ruong', 'luong', 'cay_chuoi', 'cay_xoai', 'cay_dua', 'cay_buoi', 'cay_vai', 'cay_nhan', 'cay_hong']),
    ('Chăn nuôi', ['chuong_ga', 'chuong_vit', 'chuong_lon', 'chuong_trau', 'chuong_bo', 'chuong_de', 'vuon_ong', 'ao']),
    ('Chế biến', ['nha_kho', 'may_xay', 'lo_banh', 'xuong_mia', 'xuong_ca', 'xuong_dau', 'xuong_che']),
    ('Trang trí', ['tre', 'rom_dong', 'chum', 'bu_nhin', 'hoa_dao', 'cay_da']),
  ];

  @override
  Widget build(BuildContext context) {
    final f = widget.farm;
    return DefaultTabController(
      length: tabs.length,
      child: Column(children: [
        SheetHeader('Xây dựng', trailing: Coin(f.coins, size: 15)),
        TabBar(
          isScrollable: true,
          labelColor: brown,
          unselectedLabelColor: brownLight,
          indicatorColor: green,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabAlignment: TabAlignment.start,
          tabs: [for (final t in tabs) Tab(text: t.$1)],
        ),
        Expanded(
          child: TabBarView(children: [
            for (final t in tabs)
              GridView.count(
                padding: const EdgeInsets.all(12),
                crossAxisCount: 3,
                childAspectRatio: .68,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [for (final id in t.$2) _card(id)],
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _card(String id) {
    final f = widget.farm;
    final d = bdef(id);
    final err = f.canBuy(id);
    final locked = f.level < d.level;
    final owned = d.kind == BKind.pen || d.kind == BKind.factory || d.kind == BKind.pond || d.kind == BKind.storage
        ? f.objs.where((o) => o.type == id).length
        : null;
    return GestureDetector(
      onTap: err == null ? () => Navigator.pop(context, id) : null,
      child: Container(
        decoration: cardDeco(color: locked ? const Color(0xFFE9E1CF) : Colors.white),
        padding: const EdgeInsets.all(6),
        child: Column(children: [
          Expanded(
            child: Opacity(
              opacity: locked ? .35 : 1,
              child: CustomPaint(painter: ObjPreviewPainter(id, f), size: Size.infinite),
            ),
          ),
          Text(d.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: brown)),
          const SizedBox(height: 2),
          if (locked)
            Text('🔒 Cấp ${d.level}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: red))
          else
            Coin(f.buildCost(id), size: 12.5, color: f.coins >= f.buildCost(id) ? brown : red),
          if (owned != null && owned > 0)
            Text('Đang có: $owned', style: const TextStyle(fontSize: 10.5, color: brownLight)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ storage & market
class StorageSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const StorageSheet(this.farm, this.report, {super.key});
  @override
  State<StorageSheet> createState() => _StorageSheetState();
}

class _StorageSheetState extends State<StorageSheet> {
  @override
  Widget build(BuildContext context) {
    final f = widget.farm;
    final ids = items.keys.where((k) => f.countOf(k) > 0).toList();
    return Column(children: [
      SheetHeader('Kho & Chợ', trailing: Coin(f.coins, size: 15)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Text('📦 ${f.stored}/${f.storageCap}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: brown)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: f.stored / f.storageCap,
                minHeight: 9,
                color: f.stored >= f.storageCap ? red : green,
                backgroundColor: creamDark,
              ),
            ),
          ),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Text('Bán hàng ở chợ được giá gốc. Giao đơn hàng cho bà con lãi hơn nhiều!',
            style: TextStyle(fontSize: 12, color: brownLight)),
      ),
      Expanded(
        child: ids.isEmpty
            ? const Center(child: Text('Kho đang trống', style: TextStyle(color: brownLight)))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [for (final id in ids) _row(id)],
              ),
      ),
    ]);
  }

  Widget _row(String id) {
    final f = widget.farm;
    final n = f.countOf(id);
    void sell(int k) {
      widget.report(f.sell(id, k));
      setState(() {});
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: cardDeco(color: Colors.white),
      child: Row(children: [
        ItemIcon(id),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item(id).name}  ×$n',
                style: const TextStyle(fontWeight: FontWeight.w800, color: brown)),
            Row(children: [
              const Text('Giá: ', style: TextStyle(fontSize: 12, color: brownLight)),
              Coin(f.sellPrice(id), size: 12),
            ]),
          ]),
        ),
        PillButton('Bán 1', dense: true, color: gold, onTap: () => sell(1)),
        const SizedBox(width: 6),
        if (n > 1) PillButton('Bán hết', dense: true, color: const Color(0xFFE08A2E), onTap: () => sell(n)),
      ]),
    );
  }
}

// ------------------------------------------------------------------ orders
class OrdersSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const OrdersSheet(this.farm, this.report, {super.key});
  @override
  State<OrdersSheet> createState() => _OrdersSheetState();
}

class _OrdersSheetState extends State<OrdersSheet> {
  @override
  Widget build(BuildContext context) {
    final f = widget.farm;
    f.tickOrders();
    return Column(children: [
      SheetHeader('Đơn hàng của bà con', trailing: Coin(f.coins, size: 15)),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ..._dailyBlock(),
            for (final o in f.orders) _order(o),
          ],
        ),
      ),
    ]);
  }

  List<Widget> _dailyBlock() {
    final f = widget.farm;
    if (f.level < Farm.dailyLevel) {
      return [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: cardDeco(color: const Color(0xFFF7F1E3)),
          child: const Text('⭐ Đơn đặc biệt hằng ngày mở ở cấp ${Farm.dailyLevel}',
              style: TextStyle(color: brownLight, fontWeight: FontWeight.w800)),
        ),
      ];
    }
    final done = f.daily.where((o) => o.waitUntil < 0).length;
    return [
      Row(children: [
        const Text('⭐ Đơn đặc biệt hôm nay',
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB7791F), fontSize: 15.5)),
        const Spacer(),
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 30)),
          builder: (_, _) => Text('Đổi sau ${fmtTime(f.dailyResetMs)}',
              style: const TextStyle(fontSize: 12, color: brownLight, fontWeight: FontWeight.w700)),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 6),
        child: Row(children: [
          Text('Giao đủ 3 đơn ($done/3) thưởng thêm ', style: const TextStyle(fontSize: 12.5, color: brown)),
          Coin(f.dailyAllBonus, size: 12.5),
          if (f.dailyAllDone) const Text('  ✅', style: TextStyle(fontSize: 12.5)),
        ]),
      ),
      for (final o in f.daily) _dailyOrder(o),
      const Padding(
        padding: EdgeInsets.only(top: 4, bottom: 8),
        child: Text('Đơn thường', style: TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15.5)),
      ),
    ];
  }

  Widget _dailyOrder(Order o) {
    final f = widget.farm;
    final delivered = o.waitUntil < 0;
    final ok = !delivered && o.need.entries.every((e) => f.countOf(e.key) >= e.value);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: delivered ? const Color(0xFFEFF5E4) : (ok ? const Color(0xFFFFF6D6) : const Color(0xFFFFFCF2)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: delivered ? const Color(0xFFB5D69A) : gold, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('⭐ ${o.who}', style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15)),
          const Spacer(),
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
                color: gold,
                onTap: ok
                    ? () {
                        final all = f.daily.where((d) => d.waitUntil >= 0).length == 1;
                        widget.report(f.deliverDaily(o),
                            ok: all
                                ? '+${fmtNum(o.coins + f.dailyAllBonus)} xu (đủ 3 đơn!)'
                                : '+${fmtNum(o.coins)} xu');
                        setState(() {});
                      }
                    : null),
          ),
        ],
      ]),
    );
  }

  Widget _order(Order o) {
    final f = widget.farm;
    if (o.waitUntil > 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(color: const Color(0xFFEFE6D2)),
        child: StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (_, _) {
            final left = o.waitUntil - f.now();
            if (left <= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }
            return Text('🚲 Đơn mới sẽ tới sau ${fmtTime(left)}',
                style: const TextStyle(color: brownLight, fontWeight: FontWeight.w700));
          },
        ),
      );
    }
    final ok = f.canDeliver(o);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: cardDeco(color: ok ? const Color(0xFFF1F8E4) : Colors.white),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('👤 ${o.who}', style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15)),
          const Spacer(),
          Coin(o.coins, size: 14),
          const SizedBox(width: 8),
          Text('⭐ ${o.xp}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E88E5))),
        ]),
        const SizedBox(height: 6),
        Wrap(children: [
          for (final e in o.need.entries) NeedChip(e.key, e.value, f.countOf(e.key), size: 36),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          TextButton(
            onPressed: () {
              f.discard(o);
              setState(() {});
            },
            child: const Text('Bỏ đơn', style: TextStyle(color: brownLight)),
          ),
          const Spacer(),
          PillButton('Giao hàng', onTap: ok
              ? () {
                  widget.report(f.deliver(o), ok: '+${fmtNum(o.coins)} xu');
                  setState(() {});
                }
              : null),
        ]),
      ]),
    );
  }
}

// ------------------------------------------------------------------ village projects
class ProjectsSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const ProjectsSheet(this.farm, this.report, {super.key});
  @override
  State<ProjectsSheet> createState() => _ProjectsSheetState();
}

class _ProjectsSheetState extends State<ProjectsSheet> {
  @override
  Widget build(BuildContext context) {
    final f = widget.farm;
    final done = f.projects.length;
    return Column(children: [
      SheetHeader('Xây dựng nông thôn mới', trailing: Coin(f.coins, size: 15)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: cardDeco(color: const Color(0xFFFFF0C9)),
          child: Row(children: [
            const Text('🏅', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(villageTitle(done),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 16)),
                Text('Đã hoàn thành $done/${projectOrder.length} công trình',
                    style: const TextStyle(color: brownLight, fontSize: 12.5)),
              ]),
            ),
          ]),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [for (final id in projectOrder) _project(id)],
        ),
      ),
    ]);
  }

  /// "Đã hoàn thành" plus the next upgrade: its new effect, cost and button.
  List<Widget> _upgrade(String id) {
    final f = widget.farm;
    final u = f.nextProjectUpgrade(id);
    final lv = f.projectLevel(id);
    if (u == null) {
      return [Text(lv >= 3 ? '🏆 Đã nâng cấp tối đa' : '✅ Đã hoàn thành',
          style: const TextStyle(fontWeight: FontWeight.w800, color: greenDark))];
    }
    final err = f.canUpgradeProject(id);
    return [
      const Text('✅ Đã hoàn thành', style: TextStyle(fontWeight: FontWeight.w800, color: greenDark)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFFFF6DD), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⬆️ Nâng cấp lên cấp ${lv + 1}: ${projectEffect(id, lv + 1)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: brown)),
          const SizedBox(height: 4),
          if (f.level < u.level)
            Text('🔒 Mở ở cấp ${u.level}', style: const TextStyle(fontWeight: FontWeight.w800, color: red))
          else ...[
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Coin(u.coins, size: 14, color: f.coins >= u.coins ? brown : red),
              ),
              for (final e in u.goods.entries) NeedChip(e.key, e.value, f.countOf(e.key), size: 36),
            ]),
            Align(
              alignment: Alignment.centerRight,
              child: PillButton('Nâng cấp',
                  color: gold,
                  onTap: err == null
                      ? () {
                          widget.report(f.upgradeProject(id), ok: '${bdef(id).name} lên cấp ${lv + 1}!');
                          setState(() {});
                        }
                      : null),
            ),
          ],
        ]),
      ),
    ];
  }

  Widget _project(String id) {
    final f = widget.farm;
    final d = bdef(id);
    final done = f.has(id);
    final locked = f.level < d.level;
    final err = f.canBuy(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: cardDeco(color: done ? const Color(0xFFE8F5E1) : Colors.white),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 78,
          height: 78,
          child: Opacity(
            opacity: locked ? .35 : 1,
            child: CustomPaint(painter: ObjPreviewPainter(id, f)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15)),
              ),
              if (done)
                Text('Cấp ${f.projectLevel(id)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: greenDark, fontSize: 12.5)),
            ]),
            const SizedBox(height: 2),
            Text(done ? '${projectEffect(id, f.projectLevel(id))}.' : d.desc,
                style: const TextStyle(fontSize: 12.5, color: brownLight)),
            const SizedBox(height: 6),
            if (done)
              ..._upgrade(id)
            else if (locked)
              Text('🔒 Mở ở cấp ${d.level}', style: const TextStyle(fontWeight: FontWeight.w800, color: red))
            else ...[
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Coin(d.cost, size: 14, color: f.coins >= d.cost ? brown : red),
                ),
                for (final e in d.goods.entries) NeedChip(e.key, e.value, f.countOf(e.key), size: 36),
              ]),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: PillButton(d.w == 0 ? 'Khởi công' : 'Chọn chỗ xây',
                    onTap: err == null
                        ? () {
                            if (d.w == 0) {
                              widget.report(f.build(id, 0, 0), ok: 'Hoàn thành ${d.name}!');
                              setState(() {});
                            } else {
                              Navigator.pop(context, id);
                            }
                          }
                        : null),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
