# Mua trong ứng dụng – iOS (App Store Connect) – Mùa Lúa Chín

Nơi tạo: App Store Connect → app Mùa Lúa Chín → **Monetization → In-App Purchases** → (+).
Product ID trên App Store là duy nhất trong cả tài khoản và **không dùng lại được** sau khi tạo.
`bo_quang_cao` đã thuộc Võ Lâm Quyết Đấu, nên iOS của game này dùng tiền tố **`mlc_`**
(`PurchaseService.storeId` thêm tiền tố trên iOS, Android giữ mã cũ). Gõ ĐÚNG mã dưới đây.

Giới hạn ASC: Reference Name ≤ 64, **Display Name ≤ 30**, **Description ≤ 45** ký tự.
Ảnh App Store Promotion (1024×1024, không chữ): `store/iap-ios/<Product ID>.png`
(vẽ lại: `powershell -NoProfile -File tool/iap_icons.ps1 -Size 1024`).
Review Screenshot (bắt buộc, mỗi sản phẩm một ảnh): dùng chung `store/iphone-6.3in/08-cua-hang.png`
(màn Cửa hàng, cả 4 gói, chữ "App Store").

## Bảng sản phẩm

| Product ID | Type | Reference Name | Giá Android | Giá iOS gợi ý |
|---|---|---|---|---|
| mlc_goi_khoi_dau | Non-Consumable | Starter Pack | 22.000 ₫ | 25.000 ₫ (0.99 USD) |
| mlc_ham_chua | Non-Consumable | Laterite Cellar | 79.000 ₫ | 79.000 ₫ (2.99 USD) |
| mlc_the_nha_nong | Consumable | Farmer Card 30 days | 49.000 ₫ | 49.000 ₫ (1.99 USD) |
| mlc_bo_quang_cao | Non-Consumable | Remove Ads | 49.000 ₫ | 49.000 ₫ (1.99 USD) |

Giá: Price Schedule → **Base Country = Vietnam**, chọn mức VND gần nhất với cột Android; Apple tự quy đổi các nước khác.
Availability: mọi quốc gia đang bán app.
Thẻ Nhà Nông là Consumable: mua lại khi còn hạn được cộng thêm 30 ngày (game tự xử lý).

## Localization

Thêm 2 ngôn ngữ: **Vietnamese** và **English (U.S.)**.

### mlc_goi_khoi_dau
- VI — Display Name: `Gói khởi đầu` · Description: `Xu, +50 chỗ chứa, 10 vé Xong ngay, chậu sen`
- EN — Display Name: `Starter Pack` · Description: `Coins, +50 storage, 10 instant tickets, decor`

### mlc_ham_chua
- VI — Display Name: `Hầm chứa đá ong` · Description: `Thêm 250 chỗ chứa, nâng cấp tới 3000`
- EN — Display Name: `Laterite Cellar` · Description: `+250 storage, upgradable up to 3000`

### mlc_the_nha_nong
- VI — Display Name: `Thẻ Nhà Nông 30 ngày` · Description: `30 ngày: 5 lượt Xong ngay mỗi ngày, +20% xu`
- EN — Display Name: `Farmer Card (30 days)` · Description: `30 days: 5 free finishes a day, +20% coins`

### mlc_bo_quang_cao
- VI — Display Name: `Bỏ quảng cáo` · Description: `Tắt quảng cáo xen giữa, mua một lần`
- EN — Display Name: `Remove Ads` · Description: `Turns off interstitial ads. Buy once.`

## Review Notes (dán vào ô Review Notes của từng sản phẩm)

```
Open the game and tap the shop button on the farm screen (or the menu button >
"Cửa hàng, khôi phục giao dịch"). All four packs are listed there. Starter Pack,
Laterite Cellar and Remove Ads are non-consumable and can be restored with
"Khôi phục giao dịch" (Restore Purchases) at the bottom of the Shop. The 30-day
Farmer Card is consumable; buying it again while active adds 30 more days.
```

## Trước khi nộp version có IAP

1. Paid Apps Agreement + thuế + ngân hàng đã "Active" trong ASC → Business (đã có từ Kiếm Hiệp).
2. Mỗi sản phẩm: đủ 2 ngôn ngữ + Review Screenshot → trạng thái "Ready to Submit".
3. Trang version 1.10.0: mục **In-App Purchases and Subscriptions** → chọn cả 4 sản phẩm, nộp cùng build (thiếu là bị 3.1.1).
4. Build iOS phải có commit đổi mã `mlc_`; build cũ hơn sẽ không tìm thấy sản phẩm nào.
