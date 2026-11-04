// Chợ phiên screens: the region's stalls (or one neighbour's), this
// player's own stalls, and the "lên sạp" dialog.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import '../services/cloud.dart';
import '../services/market.dart';
import '../services/sound.dart';
import 'widgets.dart';

/// Stalls for sale: everyone's newest, or one neighbour's ([owner]).
class MarketScreen extends StatefulWidget {
  final Farm farm;
  final String? owner, ownerName;
  const MarketScreen(this.farm, {super.key, this.owner, this.ownerName});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<StallOffer>? _list;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Market.instance.available) return setState(() => _error = 'Đăng nhập Google (trong ☰) để đi chợ phiên.');
    try {
      final l = await Market.instance.browse(owner: widget.owner);
      if (mounted) setState(() => _list = l);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được chợ, thử lại sau.');
    }
  }

  Future<void> _buy(StallOffer s) async {
    setState(() => _busy.add(s.docId));
    final err = await Market.instance.buy(widget.farm, s, widget.farm.name);
    if (!mounted) return;
    setState(() {
      _busy.remove(s.docId);
      if (err == null || err.contains('người mua')) _list?.remove(s);
    });
    SoundService.instance.play(err == null ? 'cash' : 'error');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Đã mua ${s.qty} ${item(s.item).name.toLowerCase()} của ${s.ownerName}'),
      backgroundColor: err == null ? greenDark : red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.farm;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: brown,
        title: Text(widget.owner == null ? '🛒 Chợ phiên' : '🛒 Sạp nhà ${widget.ownerName ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: Coin(f.coins, size: 15))),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null) return _note(_error!);
    final l = _list;
    if (l == null) return const Center(child: CircularProgressIndicator(color: green));
    if (l.isEmpty) {
      return _note(widget.owner == null ? 'Chợ đang vắng. Bày hàng của bạn lên sạp trong 📦 Kho & Chợ nhé!' : 'Nhà này chưa bày gì lên sạp.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        Text('Hàng do người chơi khác bày bán. Còn ${widget.farm.storageCap - widget.farm.stored} chỗ trong kho.',
            style: const TextStyle(color: brownLight, fontSize: 12.5)),
        const SizedBox(height: 8),
        for (final s in l) _row(s),
      ]),
    );
  }

  Widget _row(StallOffer s) {
    final f = widget.farm;
    final base = item(s.item).price * s.qty;
    final cheap = s.price < base;
    final err = f.canBuyStall(s.qty, s.price);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: cardDeco(color: Colors.white),
      child: Row(children: [
        ItemIcon(s.item, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item(s.item).name} ×${s.qty}', style: const TextStyle(fontWeight: FontWeight.w900, color: brown)),
            Text('🏡 ${s.ownerName}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: brownLight, fontSize: 12)),
            if (cheap)
              const Text('Rẻ hơn giá chợ!', style: TextStyle(color: greenDark, fontSize: 11.5, fontWeight: FontWeight.w800)),
          ]),
        ),
        PillButton(_busy.contains(s.docId) ? '…' : 'Mua',
            dense: true,
            color: gold,
            leading: Coin(s.price, size: 11.5, color: Colors.white),
            onTap: err == null && !_busy.contains(s.docId) ? () => _buy(s) : null),
      ]),
    );
  }

  Widget _note(String t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: brown, fontWeight: FontWeight.w600)),
        ),
      );
}

/// The player's stalls, at the top of "Kho & Chợ".
class MyStalls extends StatefulWidget {
  final Farm farm;
  final void Function(String msg, {bool error}) say;
  const MyStalls(this.farm, this.say, {super.key});
  @override
  State<MyStalls> createState() => _MyStallsState();
}

class _MyStallsState extends State<MyStalls> {
  final Set<int> _busy = {};

  @override
  Widget build(BuildContext context) {
    final f = widget.farm;
    final open = f.level >= FarmMore.marketLevel;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: cardDeco(color: const Color(0xFFFFF6DD)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(open ? '🛒 Sạp chợ phiên (${f.stalls.length}/${f.stallSlots})' : '🛒 Chợ phiên: mở ở cấp ${FarmMore.marketLevel}',
                style: const TextStyle(fontWeight: FontWeight.w900, color: brown)),
          ),
          if (open)
            PillButton('Đi chợ', dense: true, color: const Color(0xFF8D6E4C), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MarketScreen(f))).then((_) {
                if (mounted) setState(() {});
              });
            }),
        ]),
        if (open && f.stalls.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Bấm 🛒 cạnh một món trong kho để bày bán cho người chơi khác.',
                style: TextStyle(color: brownLight, fontSize: 12)),
          ),
        for (final s in f.stalls)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              ItemIcon(s.item, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${item(s.item).name} ×${s.qty}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: brown, fontSize: 13)),
              ),
              Coin(s.price, size: 12.5),
              const SizedBox(width: 6),
              TextButton(
                onPressed: _busy.contains(s.slot)
                    ? null
                    : () async {
                        setState(() => _busy.add(s.slot));
                        final msg = await Market.instance.withdraw(f, s);
                        if (!mounted) return;
                        setState(() => _busy.remove(s.slot));
                        widget.say(msg, error: msg.contains('thử lại') || msg.contains('Cần'));
                      },
                child: Text(_busy.contains(s.slot) ? '…' : 'Dọn về', style: const TextStyle(color: red)),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// "Lên sạp": how many and for how much. True when listed.
Future<bool> showListStall(BuildContext context, Farm f, String id) async {
  if (!CloudSave.instance.available || CloudSave.instance.user == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập Google (trong ☰) để bán ở chợ phiên')));
    return false;
  }
  final maxQty = math.min(FarmMore.stallMaxQty, f.countOf(id));
  if (maxQty < 1) return false;
  var qty = math.min(5, maxQty);
  double pct = 1.2; // of the market price
  var busy = false;
  String? err;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(builder: (c, set) {
      final (lo, hi) = f.stallPriceRange(id, qty);
      final price = (item(id).price * qty * pct).round().clamp(lo, hi);
      return AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          ItemIcon(id, size: 34),
          const SizedBox(width: 8),
          Expanded(child: Text('Bày bán ${item(id).name.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w900, color: brown))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Số lượng: $qty', style: const TextStyle(fontWeight: FontWeight.w800, color: brown)),
          if (maxQty > 1)
            Slider(
              value: qty.toDouble(),
              min: 1,
              max: maxQty.toDouble(),
              divisions: maxQty - 1,
              activeColor: green,
              onChanged: (v) => set(() => qty = v.round()),
            ),
          Row(children: [
            const Text('Giá bán: ', style: TextStyle(fontWeight: FontWeight.w800, color: brown)),
            Coin(price, size: 15),
            const SizedBox(width: 6),
            Text('(${(pct * 100).round()}% giá chợ)', style: const TextStyle(color: brownLight, fontSize: 12)),
          ]),
          Slider(
            value: pct,
            min: .5,
            max: 2,
            divisions: 15,
            activeColor: gold,
            onChanged: (v) => set(() => pct = v),
          ),
          const Text('Hàng rời kho ngay và nằm trên sạp tới khi có người mua (xu về khi bạn vào game) hoặc bạn dọn về.',
              style: TextStyle(color: brownLight, fontSize: 12)),
          if (err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(err!, style: const TextStyle(color: red))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Thôi')),
          PillButton(busy ? 'Đang bày…' : 'Lên sạp', onTap: busy
              ? null
              : () async {
                  set(() => busy = true);
                  final e = await Market.instance.list(f, id, qty, price, f.name);
                  if (!c.mounted) return;
                  if (e == null) {
                    SoundService.instance.play('cash');
                    Navigator.pop(c, true);
                  } else {
                    set(() {
                      busy = false;
                      err = e;
                    });
                  }
                }),
        ],
      );
    }),
  );
  return ok == true;
}
