// Chợ phiên: players put goods on a stall (`stalls/{uid}_{slot}`); another
// player buys one in a transaction (claims it by writing `buyer`), and the
// seller collects the coins next time their inbox is pulled.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import 'analytics.dart';
import 'neighbors.dart';

/// A stall someone else is selling from.
class StallOffer {
  final String docId, owner, ownerName, item;
  final int qty, price;
  const StallOffer(this.docId, this.owner, this.ownerName, this.item, this.qty, this.price);
}

class Market {
  Market._();
  static final Market instance = Market._();

  Neighbors get _nb => Neighbors.instance;
  bool get available => _nb.available;
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('stalls');
  static const _t = Duration(seconds: 12);

  String _docId(String uid, int slot) => '${uid}_$slot';

  /// Puts [qty] [id] on a free stall for [price] xu. Null when done.
  Future<String?> list(Farm f, String id, int qty, int price, String myName) async {
    final uid = _nb.myUid;
    if (!available || uid == null) return 'Cần đăng nhập Google để bán ở chợ phiên';
    final err = f.canListStall(id, qty, price);
    if (err != null) return err;
    final slot = f.freeStallSlot!;
    try {
      await _col.doc(_docId(uid, slot)).set({
        'owner': uid,
        'name': myName.isEmpty ? 'Hàng xóm' : myName,
        'item': id,
        'qty': qty,
        'price': price,
        'slot': slot,
        'buyer': null,
        'created': FieldValue.serverTimestamp(),
      }).timeout(_t);
    } catch (e) {
      debugPrint('stall list failed: $e');
      return 'Không lên sạp được, thử lại sau';
    }
    f.listStall(id, qty, price, slot: slot);
    Analytics.instance.log('market_list', {'item': id});
    return null;
  }

  /// Takes a stall's goods back, unless someone bought them meanwhile (then
  /// the coins come in instead). Returns a message for the player.
  Future<String> withdraw(Farm f, Stall s) async {
    final uid = _nb.myUid;
    if (!available || uid == null) {
      return 'Cần đăng nhập để dọn sạp';
    }
    final ref = _col.doc(_docId(uid, s.slot));
    try {
      final sold = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final d = await tx.get(ref);
        final buyer = d.data()?['buyer'];
        tx.delete(ref);
        return d.exists && buyer != null;
      }).timeout(_t);
      if (sold) {
        f.stallSold(s.slot);
        return 'Hàng đã có người mua: +${fmtNum(s.price)} xu';
      }
      f.withdrawStall(s.slot);
      return 'Đã mang ${s.qty} ${item(s.item).name.toLowerCase()} về kho';
    } catch (e) {
      debugPrint('stall withdraw failed: $e');
      return 'Không dọn sạp được, thử lại sau';
    }
  }

  /// Stalls with goods still for sale: one player's ([owner]) or the
  /// newest across the region.
  Future<List<StallOffer>> browse({String? owner}) async {
    final me = _nb.myUid;
    if (!available) return const [];
    final q = owner != null
        ? _col.where('owner', isEqualTo: owner)
        : _col.orderBy('created', descending: true).limit(80);
    final snap = await q.get().timeout(_t);
    final out = <StallOffer>[];
    for (final d in snap.docs) {
      final m = d.data();
      if (m['buyer'] != null || m['owner'] == me) continue;
      final id = m['item'];
      if (id is! String || !items.containsKey(id)) continue;
      out.add(StallOffer(d.id, m['owner'] as String, (m['name'] as String?) ?? 'Hàng xóm', id,
          (m['qty'] as num).toInt(), (m['price'] as num).toInt()));
    }
    return out;
  }

  /// Buys a stall. Null when done, else why not.
  Future<String?> buy(Farm f, StallOffer s, String myName) async {
    final me = _nb.myUid;
    if (!available || me == null) return 'Cần đăng nhập Google';
    final err = f.canBuyStall(s.qty, s.price);
    if (err != null) return err;
    final ref = _col.doc(s.docId);
    try {
      final ok = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final d = await tx.get(ref);
        final m = d.data();
        if (m == null || m['buyer'] != null) return false;
        if ((m['price'] as num).toInt() != s.price || (m['qty'] as num).toInt() != s.qty || m['item'] != s.item) {
          return false;
        }
        tx.update(ref, {
          'buyer': me,
          'buyerName': myName.isEmpty ? 'Hàng xóm' : myName,
          'sold': FieldValue.serverTimestamp(),
        });
        return true;
      }).timeout(_t);
      if (!ok) return 'Hàng này vừa có người mua mất rồi';
    } catch (e) {
      debugPrint('stall buy failed: $e');
      return 'Không mua được, thử lại sau';
    }
    f.boughtStall(s.item, s.qty, s.price);
    Analytics.instance.log('market_buy', {'item': s.item});
    return null;
  }

  /// Seller side: coins for stalls that were bought. Lines for the inbox.
  Future<List<String>> collect(Farm f) async {
    final uid = _nb.myUid;
    if (!available || uid == null) return const [];
    final lines = <String>[];
    try {
      final snap = await _col.where('owner', isEqualTo: uid).get().timeout(_t);
      for (final d in snap.docs) {
        final m = d.data();
        final slot = (m['slot'] as num?)?.toInt() ?? -1;
        final mine = f.stalls.any((s) => s.slot == slot);
        if (m['buyer'] != null) {
          if (mine && f.stallSold(slot)) {
            final id = m['item'] as String? ?? '';
            lines.add('🛒 ${m['buyerName'] ?? 'Hàng xóm'} đã mua ${m['qty']} '
                '${items[id]?.name.toLowerCase() ?? id}: +${fmtNum((m['price'] as num).toInt())} xu');
          }
          await d.reference.delete();
        } else if (!mine) {
          await d.reference.delete(); // left over from a farm that was reset
        }
      }
    } catch (e) {
      debugPrint('stall collect failed: $e');
    }
    return lines;
  }
}
