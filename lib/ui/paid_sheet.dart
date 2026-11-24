// Cửa hàng (1.6.0): the four paid packs, restore and purchase history.

import 'package:flutter/material.dart';

import '../core/farm.dart';
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
        Text(icon, style: const TextStyle(fontSize: 34)),
        const SizedBox(width: 10),
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
