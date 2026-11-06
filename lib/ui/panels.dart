// The contextual card shown above the bottom bar for a tapped object.

import 'package:flutter/material.dart';

import '../core/calendar.dart';
import '../core/defs.dart';
import '../core/weather.dart';
import '../core/farm.dart';
import '../services/ads.dart';
import 'sheets.dart' show Report;
import 'widgets.dart';

class PanelActions {
  final Report report;
  final void Function(String cropId) plantMode;
  final void Function(Obj o) move;
  final VoidCallback close;
  final VoidCallback refresh;
  const PanelActions(this.report, this.plantMode, this.move, this.close, this.refresh);
}

class ObjPanel extends StatelessWidget {
  final Farm farm;
  final Obj o;
  final PanelActions a;
  const ObjPanel(this.farm, this.o, this.a, {super.key});

  void _do(String? err, {String? ok}) {
    a.report(err, ok: ok);
    a.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final d = o.def;
    final body = switch (d.kind) {
      BKind.paddy || BKind.bed => _field(),
      BKind.pen => _pen(),
      BKind.pond => _pond(),
      BKind.tree => _tree(),
      BKind.factory => _factory(),
      BKind.house => o.type == 'nha' ? _house() : _extraHouse(),
      BKind.storage => _warehouse(),
      BKind.obstacle => _obstacle(),
      _ when o.type == 'cho' => _dog(),
      _ when o.type == 'san_phoi' => _yard(),
      _ => _info(),
    };
    final movable = d.kind != BKind.obstacle;
    return Container(
      decoration: cardDeco(),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 10),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(_title(),
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: brown)),
          ),
          if (movable)
            IconButton(
              tooltip: 'Di chuyển',
              visualDensity: VisualDensity.compact,
              onPressed: () => a.move(o),
              icon: const Icon(Icons.open_with_rounded, color: brownLight),
            ),
          if (farm.canRemove(o))
            IconButton(
              tooltip: 'Phá bỏ',
              visualDensity: VisualDensity.compact,
              onPressed: () => _confirmRemove(context),
              icon: const Icon(Icons.delete_outline_rounded, color: brownLight),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: a.close,
            icon: const Icon(Icons.close_rounded, color: brownLight),
          ),
        ]),
        Padding(padding: const EdgeInsets.only(right: 6), child: body),
      ]),
    );
  }

  String _title() {
    if (o.type == 'nha_phu') return 'Nhà con cháu · ${houseLevels[o.level].name}';
    if (o.def.kind == BKind.house) return houseLevels[o.level].name;
    if (o.def.kind == BKind.storage) return warehouseLevels[o.level].name;
    if (o.def.kind == BKind.pen) return '${o.def.name} (${o.count}/${animalForPen(o.type)!.maxCount})';
    return o.def.name;
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cream,
        title: Text('Phá bỏ ${o.def.name}?'),
        content: const Text('Không được hoàn lại xu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Thôi')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Phá bỏ')),
        ],
      ),
    );
    if (yes == true) {
      farm.remove(o);
      a.close();
    }
  }

  Widget _timer(String label) => Ticking(const Duration(seconds: 1), builder: (_) {
          final p = farm.progress(o);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('$label — còn ${fmtTime(farm.remainingMs(o))}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: brown)),
              ),
              _speedUp(),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: p, minHeight: 9, color: green, backgroundColor: creamDark),
            ),
          ]);
        },
      );

  /// Rewarded ad: finish what is growing/working now. Shown only when an
  /// ad is loaded and there is more than half a minute left.
  Widget _speedUp() => ValueListenableBuilder<bool>(
        valueListenable: AdsService.instance.rewardedReady,
        builder: (_, ready, _) {
          if (!ready || farm.speedUpMs(o) < 30 * 1000) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: PillButton('📺 Xong ngay', dense: true, color: gold, onTap: () async {
              if (await AdsService.instance.showRewarded('speedup_${o.def.kind.name}')) {
                _do(farm.speedUp(o));
              }
            }),
          );
        },
      );

  // ---------------------------------------------------------------- fields
  Widget _field() {
    if (o.crop != null) {
      final c = crops[o.crop]!;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _timer('${c.name} đang lớn'),
        const SizedBox(height: 8),
        Row(children: [
          Text('Thu hoạch: ${c.yield} ${item(c.product).icon}',
              style: const TextStyle(color: brownLight, fontSize: 12.5)),
          const Spacer(),
          PillButton('Bón phân (${farm.countOf('phan')} 💩)',
              dense: true,
              color: const Color(0xFF8D6E4C),
              onTap: farm.countOf('phan') > 0 ? () => _do(farm.fertilize(o)) : null),
        ]),
      ]);
    }
    final plot = o.def.kind == BKind.paddy ? Plot.paddy : Plot.bed;
    final list = crops.values.where((c) => c.plot == plot).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Chọn giống để gieo (chạm tiếp các ô trống để gieo nhanh):',
          style: TextStyle(fontSize: 12.5, color: brownLight)),
      const SizedBox(height: 6),
      SizedBox(
        height: 96,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final c in list) _seedCard(c),
        ]),
      ),
    ]);
  }

  Widget _seedCard(CropDef c) {
    final locked = farm.level < c.level;
    return GestureDetector(
      onTap: locked
          ? () => a.report('Cần đạt cấp ${c.level}')
          : () {
              final err = farm.plant(o, c.id);
              a.report(err);
              if (err == null) a.plantMode(c.id);
            },
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(5),
        decoration: cardDeco(color: locked ? const Color(0xFFE9E1CF) : Colors.white),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            Opacity(opacity: locked ? .4 : 1, child: ItemIcon(c.product, size: 34)),
            // in season: grows faster
            if (farm.cropInSeason(c))
              Positioned(
                right: -14,
                top: -4,
                child: Tooltip(
                  message: 'Hợp mùa: lớn nhanh hơn ${(seasonSpeed * 100).round()}%',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Text(seasons[farm.season]!.icon, style: const TextStyle(fontSize: 14)),
                ),
              ),
          ]),
          Text(c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: brown)),
          if (locked)
            Text('🔒 Cấp ${c.level}', style: const TextStyle(fontSize: 10.5, color: red, fontWeight: FontWeight.w700))
          else ...[
            Text('⏱ ${fmtSecs(farm.cropMs(c) ~/ 1000)}', style: const TextStyle(fontSize: 10.5, color: brownLight)),
            Coin(c.seed, size: 10.5),
          ],
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------- pens
  Widget _pen() {
    final an = animalForPen(o.type)!;
    final feedName = item(an.feed).name;
    final producing = o.end != 0 && !farm.isReady(o);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (producing) _timer('${an.name} đang cho ${item(an.product).name.toLowerCase()}'),
      if (!producing && o.count == 0)
        Text('Chuồng còn trống. Mua ${an.name.toLowerCase()} về nuôi nhé!',
            style: const TextStyle(color: brownLight)),
      if (!producing && o.count > 0)
        Text('Cho ăn ${o.count} $feedName → ${o.count} ${item(an.product).name} sau ${fmtSecs(farm.animalMs(an) ~/ 1000)}',
            style: const TextStyle(color: brown, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        PillButton('Mua ${an.name.toLowerCase()}',
            dense: true,
            color: gold,
            leading: Coin(an.price, size: 11.5, color: Colors.white),
            onTap: o.count < an.maxCount ? () => _do(farm.buyAnimal(o)) : null),
        if (!producing)
          PillButton('Cho ăn (${farm.countOf(an.feed)} ${item(an.feed).icon})',
              dense: true, onTap: o.count > 0 ? () => _do(farm.feed(o)) : null),
      ]),
    ]);
  }

  // ---------------------------------------------------------------- pond
  Widget _pond() {
    if (o.crop != null) {
      final f = fishes[o.crop]!;
      return _timer('${f.name} đang lớn');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Thả giống xuống ao:', style: TextStyle(fontSize: 12.5, color: brownLight)),
      const SizedBox(height: 6),
      SizedBox(
        height: 96,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final f in fishes.values)
            GestureDetector(
              onTap: () => _do(farm.stock(o, f.id)),
              child: Container(
                width: 82,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(5),
                decoration: cardDeco(color: farm.level < f.level ? const Color(0xFFE9E1CF) : Colors.white),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ItemIcon(f.product, size: 34),
                  Text(f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: brown)),
                  if (farm.level < f.level)
                    Text('🔒 Cấp ${f.level}', style: const TextStyle(fontSize: 10.5, color: red))
                  else ...[
                    Text('⏱ ${fmtSecs(farm.fishMs(f) ~/ 1000)} · ×${f.yield}',
                        style: const TextStyle(fontSize: 10.5, color: brownLight)),
                    Coin(f.fry, size: 10.5),
                  ],
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }

  // ---------------------------------------------------------------- tree
  Widget _tree() {
    final t = trees[o.type]!;
    return _timer('Quả ${item(t.product).name.toLowerCase()} đang chín (×${t.yield})');
  }

  // ---------------------------------------------------------------- factory
  Widget _factory() {
    final rs = recipesFor(o.type);
    final ready = farm.readyJobs(o);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Hàng chờ ${o.jobs.length}/${Farm.queueMax}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: brown)),
        const SizedBox(width: 8),
        for (final j in o.jobs)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Opacity(
              opacity: farm.now() >= j.end ? 1 : .45,
              child: ItemIcon(recipes[j.recipe]!.product, size: 26),
            ),
          ),
        const Spacer(),
        if (ready > 0) PillButton('Lấy hàng ($ready)', dense: true, onTap: () => _do(farm.collectJobs(o))),
      ]),
      if (o.jobs.isNotEmpty)
        Ticking(const Duration(seconds: 1), builder: (_) {
            final now = farm.now();
            final next = o.jobs.where((j) => j.end > now).toList();
            if (next.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                Expanded(
                  child: Text('Mẻ đang làm xong sau ${fmtTime(next.first.end - now)}',
                      style: const TextStyle(fontSize: 12, color: brownLight)),
                ),
                _speedUp(),
              ]),
            );
          },
        ),
      const SizedBox(height: 6),
      SizedBox(
        height: 118,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final r in rs) _recipeCard(r),
        ]),
      ),
    ]);
  }

  Widget _recipeCard(RecipeDef r) {
    final locked = farm.level < r.level;
    final can = !locked && r.inputs.entries.every((e) => farm.countOf(e.key) >= e.value);
    return GestureDetector(
      onTap: () => _do(locked ? 'Cần đạt cấp ${r.level}' : farm.startJob(o, r.id)),
      child: Container(
        width: 118,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(6),
        decoration: cardDeco(color: can ? Colors.white : const Color(0xFFF1EADA)),
        child: Column(children: [
          Row(children: [
            ItemIcon(r.product, size: 30),
            const SizedBox(width: 4),
            Expanded(
              child: Text(item(r.product).name,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: brown)),
            ),
          ]),
          const Spacer(),
          if (locked)
            Text('🔒 Cấp ${r.level}', style: const TextStyle(fontSize: 11, color: red, fontWeight: FontWeight.w700))
          else
            Wrap(children: [
              for (final e in r.inputs.entries) NeedChip(e.key, e.value, farm.countOf(e.key), size: 22),
            ]),
          Text('⏱ ${fmtSecs(farm.recipeMs(r) ~/ 1000)}', style: const TextStyle(fontSize: 10.5, color: brownLight)),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------- house
  Widget _warehouse() {
    final cur = warehouseLevels[o.level];
    final n = farm.nextWarehouse(o);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Chứa thêm ${cur.storage} · Kho chung: ${farm.stored}/${farm.storageCap}',
          style: const TextStyle(color: brown, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      if (n == null)
        const Text('Đã nâng cấp tối đa', style: TextStyle(color: brownLight))
      else
        Row(children: [
          Expanded(
            child: Text('Nâng lên ${n.name}\nChứa thêm ${n.storage}${farm.level < n.level ? ' · cần cấp ${n.level}' : ''}',
                style: const TextStyle(fontSize: 12.5, color: brownLight)),
          ),
          PillButton('Nâng cấp',
              leading: Coin(n.cost, size: 12, color: Colors.white),
              onTap: farm.level >= n.level && farm.coins >= n.cost ? () => _do(farm.upgradeWarehouse(o)) : null),
        ]),
    ]);
  }

  Widget _house() {
    final n = farm.nextHouse;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Kho chứa: ${farm.stored}/${farm.storageCap}', style: const TextStyle(color: brown, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      if (n == null)
        const Text('Nhà đã khang trang nhất làng! 🎉', style: TextStyle(color: greenDark, fontWeight: FontWeight.w800))
      else
        Row(children: [
          Expanded(
            child: Text('Nâng lên ${n.name}\nKho chứa ${n.storage} · cần cấp ${n.level}',
                style: const TextStyle(fontSize: 12.5, color: brownLight)),
          ),
          PillButton('Nâng cấp',
              leading: Coin(n.cost, size: 12, color: Colors.white),
              onTap: farm.level >= n.level && farm.coins >= n.cost
                  ? () => _do(farm.upgradeHouse(), ok: 'Chúc mừng nhà mới!')
                  : null),
        ]),
    ]);
  }

  Widget _extraHouse() {
    final n = farm.nextExtraHouse(o);
    final top = o.level + 1 >= houseLevels.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Chứa thêm ${farm.extraHouseCap(o)} · Kho chung: ${farm.stored}/${farm.storageCap}',
          style: const TextStyle(color: brown, fontWeight: FontWeight.w700)),
      Text('Con cháu phụ giao hàng: +${(extraHouseOrderBonus * 100).round()}% xu mỗi đơn',
          style: const TextStyle(fontSize: 12.5, color: brownLight)),
      const SizedBox(height: 6),
      if (top)
        const Text('Nhà đã khang trang nhất! 🎉', style: TextStyle(color: greenDark, fontWeight: FontWeight.w800))
      else if (n == null)
        Text('Nâng cấp nhà chính lên ${houseLevels[o.level + 1].name} trước đã.',
            style: const TextStyle(fontSize: 12.5, color: brownLight))
      else
        Row(children: [
          Expanded(
            child: Text('Nâng lên ${n.name}\nChứa thêm ${(n.storage * extraHouseStorage).round()} · cần cấp ${n.level}',
                style: const TextStyle(fontSize: 12.5, color: brownLight)),
          ),
          PillButton('Nâng cấp',
              leading: Coin(n.cost, size: 12, color: Colors.white),
              onTap: farm.level >= n.level && farm.coins >= n.cost
                  ? () => _do(farm.upgradeExtraHouse(o), ok: 'Chúc mừng nhà mới!')
                  : null),
        ]),
    ]);
  }

  Widget _obstacle() {
    final d = o.def;
    final owned = farm.owned(o.x, o.y);
    return Row(children: [
      Expanded(
        child: Text(owned ? 'Dọn sạch để lấy chỗ trồng trọt, xây dựng.' : 'Mua mảnh đất này trước đã.',
            style: const TextStyle(color: brownLight)),
      ),
      PillButton('Phát quang',
          leading: Coin(d.cost, size: 12, color: Colors.white),
          onTap: owned
              ? () {
                  final err = farm.clearObstacle(o);
                  a.report(err);
                  if (err == null) a.close();
                }
              : null),
    ]);
  }

  Widget _dog() {
    final awake = farm.dogAwake(o);
    final food = FarmMore.dogFood.entries.first;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          awake
              ? '🐕 Đang canh vườn: +${(FarmMore.dogCatch * 100).round()}% bắt kẻ hái trộm. Còn no ${fmtTime(o.end - farm.now())}.'
              : '💤 Chó đói nên ngủ khì. Cho ăn để nó canh vườn cả ngày.',
          style: const TextStyle(color: brownLight)),
      const SizedBox(height: 6),
      Row(children: [
        NeedChip(food.key, food.value, farm.countOf(food.key), size: 26),
        const Spacer(),
        PillButton('Cho ăn',
            onTap: () => _do(farm.feedDog(o), ok: 'Gâu gâu! Chó sẽ canh vườn 24 giờ')),
      ]),
    ]);
  }

  Widget _yard() {
    farm.settleYard();
    final n = farm.yardTotal;
    final now = farm.now();
    String clock(int ms) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }

    if (n == 0) {
      return Text(
          'Sân trống. Gặt lúa xong thóc tự đem ra phơi (tối đa ${FarmSeason.yardCap}); phơi khô được thêm ${(FarmSeason.yardBonus * 100).round()}%. Trời mưa nhớ cất thóc!',
          style: const TextStyle(color: brownLight));
    }
    final grains = Wrap(children: [
      for (final e in farm.yard.entries)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ItemIcon(e.key, size: 26),
            Text('${e.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: brown)),
          ]),
        ),
    ]);
    if (farm.yardDone) {
      return Row(children: [
        grains,
        Expanded(
          child: Text('☀️ Thóc khô giòn! Đóng bao được thêm ${farm.yardBonusCount}.',
              style: const TextStyle(color: brown, fontWeight: FontWeight.w700)),
        ),
        PillButton('Đóng bao', onTap: () => _do(farm.collectYard())),
      ]);
    }
    final rain = farm.nextRainAt, ready = farm.yardReadyAt;
    final raining = farm.weather == Weather.rain;
    final status = farm.yardCover
        ? (raining ? '🌧️ Đang mưa, thóc nằm dưới bạt.' : '⛺ Thóc đang che bạt, chưa khô thêm.')
        : ready != null
            ? '☀️ Đang phơi ${(farm.yardProgress * 100).round()}%, khô lúc ${clock(ready)}.'
            : '⚠️ Đang phơi ${(farm.yardProgress * 100).round()}%, nhưng ${rain != null && rain > now ? 'mưa lúc ${clock(rain)}' : 'sắp mưa'}: nhớ cất thóc!';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(status, style: TextStyle(color: farm.yardRainSoon ? red : brownLight, fontWeight: FontWeight.w700)),
      if (farm.yardLost > 0)
        Text('Mưa đã làm hỏng ${farm.yardLost} thóc.', style: const TextStyle(color: brownLight, fontSize: 12)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: grains),
        if (farm.yardCover)
          PillButton('Phơi tiếp', onTap: raining ? null : () => _do(farm.coverYard(false)))
        else
          PillButton('Cất thóc', color: const Color(0xFF1E88E5), onTap: () => _do(farm.coverYard(true), ok: 'Đã che bạt')),
      ]),
    ]);
  }

  Widget _info() {
    final d = o.def;
    return Text(d.desc.isEmpty ? 'Làm đẹp cho xóm làng.' : d.desc,
        style: const TextStyle(color: brownLight));
  }
}

class LotPanel extends StatelessWidget {
  final Farm farm;
  final int lot;
  final Report report;
  final VoidCallback close;
  const LotPanel(this.farm, this.lot, this.report, this.close, {super.key});

  @override
  Widget build(BuildContext context) {
    final err = farm.canBuyLot(lot);
    final adj = farm.lotAdjacent(lot);
    return Container(
      decoration: cardDeco(),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 12),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Mảnh đất chưa có chủ',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: brown)),
          ),
          IconButton(onPressed: close, icon: const Icon(Icons.close_rounded, color: brownLight)),
        ]),
        Row(children: [
          Expanded(
            child: Text(
                adj
                    ? 'Mảnh ${lotSize}x$lotSize ô. Giá ${fmtNum(farm.nextLotPrice)} xu, cần cấp ${farm.nextLotLevel}.'
                    : 'Hãy mua những mảnh liền kề đất nhà trước.',
                style: const TextStyle(color: brownLight)),
          ),
          PillButton('Mua đất',
              leading: Coin(farm.nextLotPrice, size: 12, color: Colors.white),
              onTap: err == null
                  ? () {
                      report(farm.buyLot(lot), ok: 'Đã mua thêm đất!');
                      close();
                    }
                  : () => report(err)),
        ]),
      ]),
    );
  }
}
