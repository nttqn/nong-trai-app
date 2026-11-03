# Lời nhắc tạo ảnh cho Làng Quê

## Cách làm

1. **Công cụ**: nên dùng **ChatGPT**, vì nó xuất được ảnh PNG nền trong suốt và giữ phong cách theo ảnh mẫu tốt. Gemini hay Midjourney cũng được; nếu ảnh ra nền trắng thì công cụ của mình tự xóa nền.
2. **Tạo ảnh mẫu trước**: tạo `nha_0` (nhà tranh) đầu tiên, sửa đến khi ưng phong cách thì thôi. Ảnh này sẽ là **ảnh mẫu**.
3. **Mỗi ảnh tiếp theo**: dán **ảnh mẫu** vào, rồi gõ:
   `Same art style, same camera angle and lighting as the attached image. ` + **PHONG CÁCH** + **lời nhắc riêng** của ảnh đó.
   Có thể xin 3–4 ảnh trong cùng một cuộc trò chuyện, nhưng cách 10–15 ảnh nên dán lại ảnh mẫu để phong cách không bị trôi.
4. **Lưu ảnh**: đặt tên file **đúng như cột "Tên file"**, đuôi png, jpg hay webp đều được. Bỏ vào thư mục `art_src/` của project.
5. Báo mình. Mình chạy `dart run tool/sprites.dart` để xóa nền, cắt viền thừa và thu nhỏ, rồi chỉnh kích cỡ, vị trí trong game.

Không cần làm đủ một lần: thứ nào chưa có ảnh, game vẫn tạm vẽ bằng code.

### Yêu cầu chung để ảnh khớp vào bản đồ

- Góc nhìn **isometric 2:1**: mặt đất là hình thoi, rộng gấp đôi cao.
- Mặt chính (cửa ra vào) quay về **phía dưới bên trái**.
- Chỉ **một vật** trên **nền trắng trơn hoặc trong suốt**. Không chữ, không khung viền, không bóng đổ lan ra nền.
- Thấy **trọn vẹn** vật, không bị cắt mép.
- **Cây, đồ trang trí, vật cản**: đứng thẳng trên đất, **không có bục/ô đất vuông bên dưới**, vì rải nhiều trên bản đồ trông sẽ như các khối gạch. Nhà, chuồng, xưởng thì có sân nền như đợt 1 là đẹp.
- Đợt 1 đã xong (trừ `bui`). Nếu muốn, làm lại `da`, `goc_cay`, `tre`, `rom_dong` theo lời nhắc mới (không có ô đất) cho đồng bộ.

### PHONG CÁCH (dán vào mọi lời nhắc)

```
Cute colorful casual mobile farm game asset, isometric 2:1 view (camera 30° from above, looking from the lower-left and lower-right equally), soft cel shading with gentle gradients, clean dark-brown outlines, warm sunny light from the top-left, rural northern Vietnam countryside theme, single object centered, isolated on a plain white background (transparent if possible), no text, no border, no cast shadow on the background, whole object visible.
```

---

## Đợt 1 — thấy ngay khi bắt đầu chơi (17 ảnh)

| Tên file | Lời nhắc riêng |
|---|---|
| `nha_0` | A small Vietnamese thatched-roof cottage with yellow mud-plaster walls, wooden door and a tiny porch, standing on a small square dirt yard (3x3 tile base). Door on the lower-left face. |
| `ruong` | One square flooded rice paddy plot seen as an isometric diamond: low earthen dike around the edge, shallow muddy-green water inside reflecting the sky. Empty, no plants. Flat, ground-level tile. |
| `luong` | One square vegetable bed plot as an isometric diamond: dark tilled brown soil with three raised furrows, empty, no plants. Flat, ground-level tile. |
| `lua_1` | Young rice seedlings, small bright green tufts planted in a neat 3x3 grid, plants only, no water, no ground. |
| `lua_2` | Growing rice plants, taller lush green clumps in a 3x3 grid, plants only, no ground. |
| `lua_3` | Ripe rice ready to harvest, golden-yellow stalks with heavy drooping grain heads in a 3x3 grid, plants only, no ground. |
| `rau_1` | Tiny water-spinach (rau muống) sprouts in 3 rows, plants only, no ground. |
| `rau_2` | Half-grown water spinach, leafy green clumps in 3 rows, plants only, no ground. |
| `rau_3` | Lush full-grown water spinach ready to pick, bushy green with hollow stems, 3 rows, plants only, no ground. |
| `ga` | One cute brown Vietnamese free-range chicken (gà ta) with red comb, standing, facing lower-left, full body. |
| `chuong_ga` | A chicken pen on a 2x2 tile base: packed sandy ground, low bamboo fence around it with a small gate at the front, a small thatched coop at the back corner, a wooden feed trough. No animals. |
| `bui` | A small wild bush with some weeds and tiny flowers (an obstacle to clear), standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `da` | A grey boulder with moss, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `goc_cay` | An old cut tree stump with roots and a few mushrooms, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `tre` | A dense clump of tall green Vietnamese bamboo, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `rom_dong` | A Vietnamese rice-straw stack (đống rơm), round haystack around a wooden pole, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `may_xay` | A small village rice-milling workshop on a 2x2 tile base: corrugated tin roof, plastered walls, a metal hopper on top, rice sacks by the door. Door on the lower-left face. |

## Đợt 2 — vật nuôi, ao, cây trồng, xưởng

| Tên file | Lời nhắc riêng |
|---|---|
| `vit` | One white Vietnamese duck with orange bill, standing, facing lower-left, full body. |
| `lon` | One plump pink pig, standing, facing lower-left, full body. |
| `trau` | One Vietnamese water buffalo (trâu), dark grey, big curved horns, standing, facing lower-left, full body. |
| `bo` | One brown-and-white dairy cow, standing, facing lower-left, full body. |
| `chuong_vit` | A duck pen on a 2x2 tile base: grassy ground with a small round pond inside, low bamboo fence with front gate, small thatched shelter at the back. No animals. |
| `chuong_lon` | A pig sty on a 2x2 tile base: muddy ground, brick low wall and wooden fence, small tiled-roof shed at the back, stone trough. No animals. |
| `chuong_trau` | A buffalo pen on a 2x2 tile base: dirt ground with a mud wallow, sturdy wooden fence with gate, tiled-roof shed at the back, hay. No animals. |
| `chuong_bo` | A cow barn yard on a 2x2 tile base: dirt ground, wooden fence with gate, tiled-roof shed at the back, hay trough. No animals. |
| `ao` | A Vietnamese fish pond on a 2x2 tile base: oval pond with earthen banks, blue-green water, lotus leaves and a pink lotus flower, a small wooden plank jetty at the front. No fish visible. |
| `lo_banh` | A rustic Vietnamese kitchen workshop on a 2x2 tile base: mud walls, red tile roof, brick chimney, a big black pot boiling bánh chưng on a wood fire outside. Door on the lower-left face. |
| `xuong_mia` | A small sugarcane press workshop on a 2x2 tile base: tin roof shed, a wooden sugarcane press with a wheel, bundles of purple sugarcane. |
| `xuong_ca` | A fish-sauce (nước mắm) workshop on a 2x2 tile base: thatched shed and several big wooden fermentation barrels and clay jars. |
| `cay_chuoi` | A banana tree with big leaves, no fruit, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cay_chuoi_qua` | The same banana tree with a hanging bunch of ripe yellow bananas. |
| `cay_xoai` | A mango tree, round green canopy, no fruit, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cay_xoai_qua` | The same mango tree full of ripe yellow-orange mangoes. |
| `cay_dua` | A tall coconut palm, no fruit, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cay_dua_qua` | The same coconut palm with a cluster of green coconuts. |
| `cay_buoi` | A pomelo tree, dense dark-green canopy, no fruit, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cay_buoi_qua` | The same pomelo tree with large round green-yellow pomelos. |
| `cay_vai` | A lychee tree, bushy canopy, no fruit, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cay_vai_qua` | The same lychee tree covered in clusters of red lychees. |
| `nep_1` | Young sticky-rice seedlings, small tufts with slightly darker blue-green leaves, planted in a neat 3x3 grid, plants only, no water, no ground. |
| `nep_2` | Growing sticky-rice plants, taller lush clumps with deep blue-green leaves, in a 3x3 grid, plants only, no ground. |
| `nep_3` | Ripe sticky rice ready to harvest, deep amber-orange stalks with heavy drooping grain heads (darker and more orange than ordinary golden rice), in a 3x3 grid, plants only, no ground. |
| `ngo_1` / `ngo_2` / `ngo_3` | Corn plants in 3 rows: tiny sprouts / knee-high leafy stalks / tall stalks with ripe corn cobs and tassels. Plants only, no ground. |
| `khoai_1` / `khoai_2` / `khoai_3` | Sweet potato vines in 3 rows: small sprouts / spreading heart-shaped leaves / thick leafy vines with purple sweet potatoes peeking out. Plants only, no ground. |
| `lac_1` / `lac_2` / `lac_3` | Peanut plants in 3 rows: sprouts / bushy small plants with yellow flowers / mature bushes with peanuts visible at the roots. Plants only, no ground. |
| `dau_1` / `dau_2` / `dau_3` | Mung bean plants in 3 rows: sprouts / leafy bushes / bushes with long dark bean pods. Plants only, no ground. |
| `mia_1` / `mia_2` / `mia_3` | Sugarcane in 3 rows: short shoots / medium canes / tall purple sugarcane stalks with long leaves. Plants only, no ground. |
| `ot_1` / `ot_2` / `ot_3` | Chili plants in 3 rows: sprouts / small bushes with white flowers / bushes full of red chili peppers. Plants only, no ground. |
| `dua_1` / `dua_2` / `dua_3` | Watermelon vines in 3 rows: sprouts / spreading vines with yellow flowers / vines with big striped green watermelons. Plants only, no ground. |
| `cuc_1` / `cuc_2` / `cuc_3` | Chrysanthemum plants in 3 rows: sprouts / green bushes with buds / bushes full of bright yellow chrysanthemum flowers. Plants only, no ground. |

## Đợt 3 — nâng cấp nhà, công trình, trang trí

| Tên file | Lời nhắc riêng |
|---|---|
| `nha_1` | A traditional northern Vietnamese three-room brick house with red clay tile roof, wooden doors, a small brick-paved yard with a water jar, 3x3 tile base. Door on the lower-left face. |
| `nha_2` | A modern one-storey Vietnamese flat-roof concrete house painted pastel yellow, rooftop railing, glass windows, a small paved yard with potted plants, 3x3 tile base. |
| `nha_3` | A narrow two-storey Vietnamese tube house (nhà ống), pastel blue, balcony with flowers, red tile roof accent, small front yard with gate, 3x3 tile base. |
| `nha_4` | A beautiful Vietnamese garden villa, two storeys, red tile roof with curved eaves, white walls, wide porch, a garden with an ornamental pond and bonsai, 3x3 tile base. |
| `gieng` | A traditional village well with a round brick rim and a small tiled roof, a wooden bucket, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cong_lang` | A traditional northern Vietnamese village gate (cổng làng): brick arch with a curved tiled roof and Chinese-style eaves, 3x1 tile base: two pillars on grass at both ends and the arch spanning a dirt village road in the middle tile; the road runs through the arch from the lower-left to the upper-right, so the arch opening faces the lower-left. |
| `tram_bom` | A small irrigation pumping station: white concrete pump house with a tin roof, big pipes running into a canal, 2x2 tile base. |
| `tram_dien` | A small rural electrical transformer station: concrete posts, a grey transformer box and power lines, fenced, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `truong` | A Vietnamese village kindergarten: one-storey building painted yellow with colorful windows, red tile roof, a small playground with a slide and swing, Vietnamese flag on a pole, 3x2 tile base, the long side faces the lower-left. |
| `tram_y_te` | A commune health station: clean white one-storey building with a red cross sign (no text), blue roof, small garden, 2x2 tile base. |
| `cho_que` | A rural Vietnamese market: several open stalls with tiled roofs on wooden posts, baskets of vegetables, fruit and fish, 3x3 tile base. |
| `nha_van_hoa` | A village cultural house: one-storey hall with a red tile roof, columns at the front porch, a small square in front with a flagpole, 3x2 tile base, the long side faces the lower-left. |
| `dinh_lang` | A grand traditional Vietnamese communal house (đình làng): large wooden hall with a huge dark-tiled roof with upturned curled corners and dragon ornaments, red wooden columns, stone yard, 3x3 tile base. |
| `chum` | A large brown glazed clay water jar (chum) with a wooden lid and a coconut-shell ladle, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `bu_nhin` | A field scarecrow made of straw wearing a conical hat (nón lá) and an old shirt, on a wooden cross, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `hoa_dao` | A small Tết peach blossom tree (cây đào) covered in pink flowers, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cay_da` | A huge ancient banyan tree (cây đa) with a wide canopy and hanging aerial roots, standing directly on the ground: no base tile, no platform. |
