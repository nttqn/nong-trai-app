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

> **Cây trồng (luống):** mỗi ảnh một giai đoạn, đính kèm ảnh `rau_1`/`rau_2`/`rau_3` cùng số làm mẫu bố cục để cây xếp đúng hình thoi và cùng cỡ.


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
| `ngo_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: tiny corn sprouts with two or three small leaves. Plants only, no ground. |
| `ngo_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: knee-high leafy green corn stalks, no cobs yet. Plants only, no ground. |
| `ngo_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: tall corn stalks with long leaves, golden tassels on top and one ripe yellow corn cob on each stalk. Plants only, no ground. |
| `khoai_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: small sweet-potato sprouts with a few heart-shaped leaves. Plants only, no ground. |
| `khoai_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: spreading sweet-potato vines with many heart-shaped green leaves. Plants only, no ground. |
| `khoai_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: thick leafy sweet-potato vines with purple sweet potatoes peeking out of the soil at their base. Plants only, no ground. |
| `lac_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: small peanut sprouts with tiny oval leaves. Plants only, no ground. |
| `lac_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: bushy small peanut plants with little yellow flowers. Plants only, no ground. |
| `lac_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: mature peanut bushes with a few peanut pods visible at the roots. Plants only, no ground. |
| `dau_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: small mung bean sprouts. Plants only, no ground. |
| `dau_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: leafy green mung bean bushes. Plants only, no ground. |
| `dau_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: mung bean bushes hung with long dark-green bean pods. Plants only, no ground. |
| `mia_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: short purple sugarcane shoots with a few leaves. Plants only, no ground. |
| `mia_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: medium purple sugarcane canes with long green leaves. Plants only, no ground. |
| `mia_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: tall jointed purple sugarcane stalks with long arching green leaves. Plants only, no ground. |
| `ot_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: small chili sprouts. Plants only, no ground. |
| `ot_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: small chili bushes with tiny white flowers. Plants only, no ground. |
| `ot_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: chili bushes full of shiny red chili peppers. Plants only, no ground. |
| `dua_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: small watermelon sprouts. Plants only, no ground. |
| `dua_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: spreading watermelon vines with yellow flowers. Plants only, no ground. |
| `dua_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: watermelon vines each with one big round striped green watermelon. Plants only, no ground. |
| `cuc_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: small chrysanthemum sprouts. Plants only, no ground. |
| `cuc_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: green chrysanthemum bushes with closed buds. Plants only, no ground. |
| `cuc_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: chrysanthemum bushes covered in bright yellow flowers. Plants only, no ground. |

## Đợt 3 — nâng cấp nhà, công trình, trang trí

| Tên file | Lời nhắc riêng |
|---|---|
| `nha_1` | A traditional northern Vietnamese three-room brick house with red clay tile roof, wooden doors, a small brick-paved yard with a water jar, 3x3 tile base. Door on the lower-left face. |
| `nha_2` | A modern one-storey Vietnamese flat-roof concrete house painted pastel yellow, rooftop railing, glass windows, a small paved yard with potted plants, 3x3 tile base. |
| `nha_3` | A narrow two-storey Vietnamese tube house (nhà ống), pastel blue, balcony with flowers, red tile roof accent, small front yard with gate, 3x3 tile base. |
| `nha_4` | A beautiful Vietnamese garden villa, two storeys, red tile roof with curved eaves, white walls, wide porch, a garden with an ornamental pond and bonsai, 3x3 tile base. |
| `nha_kho_0` | A small rustic wooden farm storehouse (nhà kho) on a 2x2 tile base: plank walls, thatched roof, big double wooden door on the lower-left face, a few rice sacks and baskets by the door. |
| `nha_kho_1` | The same storehouse upgraded: red brick walls, red clay tile roof, wooden double door on the lower-left face, rice sacks and baskets by the door, 2x2 tile base. |
| `nha_kho_2` | A large Vietnamese brick granary/warehouse on a 2x2 tile base: taller brick walls, dark tile roof with a small vent, wide double door on the lower-left face, stacked rice sacks and a wooden cart outside. |
| `gieng` | A traditional village well with a round brick rim and a small tiled roof, a wooden bucket, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cong_lang` | A free-standing traditional northern Vietnamese village gate (cổng làng): two brick pillars and a curved red-tiled roof arch with upturned eaves, seen in isometric view with the arch opening facing the lower-left, so the road would pass through it from the lower-left to the upper-right. The gate is about three tiles wide and one tile deep. Standing directly on the ground: no base tile, no platform, no road, no grass or soil underneath, nothing around it. |
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

## Đợt 4 — nội dung cấp 20–30

> Cây trồng: đính kèm `rau_N` (luống) hoặc `lua_N` (ruộng) cùng số làm mẫu bố cục, như đợt 2.

| Tên file | Lời nhắc riêng |
|---|---|
| `dautuong_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: small soybean sprouts. Plants only, no ground. |
| `dautuong_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: bushy green soybean plants with trifoliate leaves. Plants only, no ground. |
| `dautuong_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: mature soybean plants, leaves turning yellow, hung with fuzzy tan pods. Plants only, no ground. |
| `che_1` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_1`), all 9 plants identical and at the same growth stage: small young tea seedlings. Plants only, no ground. |
| `che_2` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_2`), all 9 plants identical and at the same growth stage: round clipped dark-green tea bushes. Plants only, no ground. |
| `che_3` | Same layout, size and isometric diamond 3x3 arrangement as the attached image (`rau_3`), all 9 plants identical and at the same growth stage: round dark-green tea bushes covered in bright light-green new tea buds ready to pick. Plants only, no ground. |
| `tam_1` / `tam_2` / `tam_3` | Như `lua_1/2/3` (đính kèm ảnh lúa cùng số) nhưng là lúa tám thơm: thân mảnh, cao hơn; bông chín ở `tam_3` vàng nhạt óng ánh, hạt thon dài. |
| `cay_nhan` | A longan tree, wide dark-green canopy, no fruit, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cay_nhan_qua` | The same longan tree hung with clusters of small round tan-brown longan fruits. |
| `cay_hong` | A persimmon tree with an open canopy of glossy leaves, no fruit, standing directly on the ground: no base tile, no platform, no soil block underneath. |
| `cay_hong_qua` | The same persimmon tree full of bright orange persimmons. |
| `de` | One white Vietnamese goat with small horns and a little beard, standing, facing lower-left, full body. |
| `chuong_de` | A goat pen on a 2x2 tile base: grassy ground, wooden fence with gate, a small raised wooden goat house with a tiled roof at the back, a hay rack. No animals. |
| `vuon_ong` | A bee garden on a 2x2 tile base: three wooden beehive boxes among yellow chrysanthemum flowers, low bamboo fence. No visible bees. |
| `xuong_dau` | A small Vietnamese tofu workshop on a 2x2 tile base: whitewashed walls, red tile roof, big grey clay pots of soy milk and wooden tofu presses by the door on the lower-left face. |
| `xuong_che` | A tea roasting and drying shed on a 2x2 tile base: mud walls, thatched roof, a big iron tea-roasting pan on a stove, round bamboo trays of drying tea and orange persimmons on trestles. |

## Đợt 5 — chó giữ nhà (không bắt buộc)

> Game đã có chuồng chó vẽ bằng code; ảnh này chỉ thay phần chuồng. Con chó vẫn vẽ bằng code (ngủ khi đói, vẫy đuôi khi no) nên **không vẽ chó** trong ảnh.

| Tên file | Lời nhắc riêng |
|---|---|
| `cho` | A small Vietnamese wooden dog kennel with a thatched roof and an arched dark doorway facing lower-right, a little clay food bowl in front, standing directly on the ground: no base tile, no platform. No dog. |
