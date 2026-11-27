// Cửa hàng (1.6.0): the paid packs, restore and purchase history.

import 'package:flutter/material.dart';

import '../core/farm.dart';
import '../render/farm_painter.dart';
import '../services/ads.dart';
import '../services/purchase.dart';
import 'widgets.dart';

class PaidShopSheet extends StatelessWidget {
  final Farm farm;
  const PaidShopSheet(this.farm, {super.key});

  @override
  Widget build(BuildContext context) {
    final shop = PurchaseService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: shop.changed,
      builder: (context, _, _) => ValueListenableBuilder<bool>(
        valueListenable: AdsService.instance.adFree,
        builder: (context, _, _) => Column(children: [
          const SheetHeader('🛍️ Cửa hàng'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 16), children: [
              _Pack(
                sku: skuStarter,
                icon: '🎁',
                title: 'Gói khởi đầu',
                tag: 'Mua 1 lần',
                lines: [
                  '${fmtNum(starterCoins(farm.level))} xu (tăng theo cấp)',
                  '+$starterStorage chỗ chứa vĩnh viễn',
                  '$starterTickets Vé Xong ngay (không cần xem quảng cáo)',
                  'Chậu sen và Giàn đèn lồng để trang trí',
                ],
                owned: farm.starterTaken,
              ),
              _Pack(
                sku: skuHamChua,
                icon: '🏺',
                title: 'Hầm chứa',
                tag: 'Mua 1 lần',
                lines: const [
                  'Mở khóa công trình Hầm chứa đá ong',
                  '+$hamChuaStorage chỗ chứa, thêm vào cả kho chung',
                  'Nâng cấp bằng xu: 500 → 1000 → 3000 chỗ chứa',
                  'Đặt ở đâu tùy thích (Xây dựng → Nhà cửa)',
                ],
                owned: farm.hamChua,
              ),
              _Pack(
                sku: skuVuaLua,
                icon: '🛖',
                title: 'Vựa lúa',
                tag: 'Mua 1 lần · gấp đôi Hầm chứa',
                lines: const [
                  'Mở khóa công trình Vựa lúa sàn gỗ',
                  '+$vuaLuaStorage chỗ chứa, thêm vào cả kho chung',
                  'Nâng cấp bằng xu: 1000 → 2000 → 6000 chỗ chứa',
                  'Dùng cùng lúc với Hầm chứa (Xây dựng → Nhà cửa)',
                ],
                owned: farm.vuaLua,
              ),
              _Pack(
                sku: skuCard,
                icon: '🌾',
                title: 'Thẻ Nhà Nông 30 ngày',
                tag: farm.cardActive ? 'Còn ${farm.cardDaysLeft} ngày, mua thêm cộng 30 ngày' : 'Mua lại khi hết hạn',
                lines: [
                  'Mỗi ngày $cardSpeedUps lượt Xong ngay miễn phí, không cần quảng cáo',
                  'Đơn hàng mới thêm ${(cardOrderBonus * 100).round()}% xu',
                  'Quà đăng nhập tự nhân đôi',
                ],
                owned: false,
              ),
              _Pack(
                sku: skuNoAds,
                icon: '🚫',
                title: 'Bỏ quảng cáo',
                tag: 'Mua 1 lần, dùng cho cả tài khoản ${PurchaseService.storeName}',
                lines: const [
                  'Tắt quảng cáo xen giữa sau khi giao đơn và khi mở game',
                  'Quảng cáo có thưởng vẫn còn, bạn tự chọn xem hay không',
                ],
                owned: AdsService.instance.adFree.value,
              ),
              if (farm.tickets > 0 || farm.cardActive)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [
                      if (farm.tickets > 0) '🎟️ Vé Xong ngay: ${farm.tickets}',
                      if (farm.cardActive) '🌾 Lượt Xong ngay hôm nay: ${farm.cardSpeedUpsLeft}/$cardSpeedUps',
                    ].join('   '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: brown, fontWeight: FontWeight.w800),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                PillButton('Khôi phục giao dịch', dense: true, color: brownLight, onTap: () async {
                  final msg = await shop.restoreNow();
                  if (context.mounted) _info(context, 'Khôi phục giao dịch', msg);
                }),
                PillButton('Lịch sử nạp', dense: true, color: brownLight, onTap: () => _history(context)),
              ]),
              const SizedBox(height: 10),
              Text(
                'Thanh toán qua ${PurchaseService.storeName}. Gói mua 1 lần được khôi phục khi cài lại game hoặc đổi máy '
                '(cùng tài khoản ${PurchaseService.storeName}). Đăng nhập trong ☰ để lưu nông trại lên mây.',
                textAlign: TextAlign.center,
                style: TextStyle(color: brownLight, fontSize: 11.5),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  static Future<void> _history(BuildContext context) async {
    final list = await PurchaseService.instance.history();
    if (!context.mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    _info(
      context,
      'Lịch sử nạp',
      list.isEmpty
          ? 'Máy này chưa có giao dịch nào.'
          : [
              for (final l in list)
                '${two(l.at.day)}/${two(l.at.month)}/${l.at.year} ${two(l.at.hour)}:${two(l.at.minute)}  ${l.product}'
                    '${l.order.isEmpty ? '' : '\n   Mã: ${l.order}'}',
            ].join('\n'),
    );
  }
}

void _info(BuildContext context, String title, String body) => showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cream,
        title: Text(title, style: const TextStyle(color: brown, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(child: SelectableText(body, style: const TextStyle(color: brown))),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Đóng'))],
      ),
    );

/// The pack's picture: `assets/iap/<sku>.png` (made by tool/iap_icons.ps1
/// from the Play icons). A pack without one yet shows its building drawn
/// on the same warm background, or else its emoji.
class _PackPicture extends StatelessWidget {
  final String sku, emoji;
  const _PackPicture(this.sku, this.emoji);

  static const _size = 64.0;
  static const _buildings = {skuVuaLua: 'vua_lua', skuHamChua: 'ham_chua'};
  // the painter only needs a farm for context; one blank farm will do
  static final _farm = Farm.fresh();

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      final b = _buildings[sku];
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(colors: [Color(0xFFFFF9E4), Color(0xFFEEC878)], radius: .9),
        ),
        child: b == null
            ? Center(child: Text(emoji, style: const TextStyle(fontSize: 34)))
            : Padding(
                padding: const EdgeInsets.all(4),
                child: CustomPaint(painter: ObjPreviewPainter(b, _farm)),
              ),
      );
    }

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset('assets/iap/$sku.png',
            width: _size, height: _size, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback()),
      ),
    );
  }
}

class _Pack extends StatelessWidget {
  final String sku, icon, title, tag;
  final List<String> lines;
  final bool owned;
  const _Pack({required this.sku, required this.icon, required this.title, required this.tag, required this.lines, required this.owned});

  @override
  Widget build(BuildContext context) {
    final shop = PurchaseService.instance;
    final price = shop.priceOf(sku);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: cardDeco(color: Colors.white),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PackPicture(sku, icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: brown, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(tag, style: const TextStyle(color: brownLight, fontSize: 11.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $l', style: const TextStyle(color: brown, fontSize: 13, height: 1.3)),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: owned
                  ? const Text('✓ Đã có', style: TextStyle(color: greenDark, fontWeight: FontWeight.w900))
                  : ValueListenableBuilder<bool>(
                      valueListenable: shop.busy,
                      builder: (_, busy, _) => PillButton(
                        price ?? (shop.available ? 'Chưa mở bán' : 'Không kết nối được ${PurchaseService.storeName}'),
                        dense: true,
                        color: gold,
                        onTap: price == null || busy ? null : () => shop.buy(sku),
                      ),
                    ),
            ),
          ]),
        ),
      ]),
    );
  }
}
