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
| `tam_1` | Same layout, size and 3x3 arrangement as the attached image (`lua_1`), all 9 plants identical and at the same growth stage: young fragrant-rice (lúa tám) seedlings, thinner and slightly taller than ordinary rice, bright green. Plants only, no water, no ground. |
| `tam_2` | Same layout, size and 3x3 arrangement as the attached image (`lua_2`), all 9 plants identical and at the same growth stage: growing fragrant-rice plants, slender tall green clumps, taller than ordinary rice. Plants only, no ground. |
| `tam_3` | Same layout, size and 3x3 arrangement as the attached image (`lua_3`), all 9 plants identical and at the same growth stage: ripe fragrant rice, slender tall stalks with long drooping heads of thin elongated grains in a pale shimmering gold, lighter than ordinary rice. Plants only, no ground. |
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

> `cho` là cái chuồng (**không vẽ chó** trong đó). Con chó là hai ảnh riêng: `cho_thuc` (đã cho ăn, đứng canh) và `cho_ngu` (đói, nằm ngủ). Tạo `cho_thuc` trước, rồi **đính kèm `cho_thuc`** khi tạo `cho_ngu` để cùng một con chó. Thiếu ảnh nào thì game tạm vẽ bằng code.

| Tên file | Lời nhắc riêng |
|---|---|
| `cho` | A small Vietnamese wooden dog kennel with a thatched roof and an arched dark doorway facing lower-right, a little clay food bowl in front, standing directly on the ground: no base tile, no platform. No dog. |
| `cho_thuc` | One cute Vietnamese village dog (chó ta): short tan-yellow coat, pointed upright ears, curled tail raised, alert happy face, standing on all four legs, facing lower-left, full body. |
| `cho_ngu` | The exact same dog as the attached image (same colors, size, style), now curled up lying on the ground asleep, eyes closed, tail wrapped around its body, facing lower-left, full body. |

## Đợt 6 — tư thế con vật (không bắt buộc, làm dần)

> Game đã tự làm con vật đi lại, cúi ăn, nhảy, nằm nghỉ bằng cách nghiêng/nén ảnh gốc. Ảnh tư thế dưới đây làm cho đẹp hơn: con nào có ảnh thì game tự dùng, con nào chưa có vẫn chạy bình thường.
>
> **Cách làm:** đính kèm ảnh gốc của chính con vật đó (ví dụ `ga.png`) rồi dán lời nhắc. Câu đầu lời nhắc bắt buộc giữ nguyên để con vật giống hệt ảnh gốc: cùng màu, cùng cỡ, cùng hướng nhìn xuống trái.

| Tên file | Lời nhắc riêng |
|---|---|
| `ga_an` | The exact same chicken as the attached image (same colors, size, style, facing lower-left), now bending its head down to peck at the ground, full body. |
| `ga_nam` | The exact same chicken as the attached image (same colors, size, style, facing lower-left), now sitting down on the ground resting with eyes closed, feathers fluffed, full body. |
| `vit_an` | The exact same duck as the attached image (same colors, size, style, facing lower-left), now bending its head down to dabble at the ground, full body. |
| `vit_nam` | The exact same duck as the attached image (same colors, size, style, facing lower-left), now sitting on the ground resting with eyes closed, head tucked a little, full body. |
| `lon_an` | The exact same pig as the attached image (same colors, size, style, facing lower-left), now with its snout down to the ground eating, full body. |
| `lon_nam` | The exact same pig as the attached image (same colors, size, style, facing lower-left), now lying down on its belly asleep with eyes closed, full body. |
| `trau_an` | The exact same water buffalo as the attached image (same colors, size, style, facing lower-left), now lowering its head to graze grass, full body. |
| `trau_nam` | The exact same water buffalo as the attached image (same colors, size, style, facing lower-left), now lying down on the ground resting with legs folded under, eyes half closed, full body. |
| `bo_an` | The exact same cow as the attached image (same colors, size, style, facing lower-left), now lowering its head to graze grass, full body. |
| `bo_nam` | The exact same cow as the attached image (same colors, size, style, facing lower-left), now lying down on the ground resting with legs folded under, eyes half closed, full body. |
| `de_an` | The exact same goat as the attached image (same colors, size, style, facing lower-left), now lowering its head to nibble grass, full body. |
| `de_nam` | The exact same goat as the attached image (same colors, size, style, facing lower-left), now lying down on the ground resting with legs folded under, full body. |

## Đợt 7 — biểu tượng nông sản (thay emoji chưa giống)

> Biểu tượng hiện trong Kho, đơn hàng, bong bóng "đã chín" trên bản đồ... Món nào có ảnh thì game tự dùng ảnh, chưa có thì vẫn dùng emoji.
>
> **Khác các đợt trước:** biểu tượng **không** dùng câu PHONG CÁCH ở trên (không cần góc isometric). Tạo `item_gao` hoặc `item_trung` trước làm **ảnh mẫu biểu tượng**, ưng rồi thì mỗi ảnh sau dán ảnh mẫu đó vào và gõ:
> `Same icon style, size and lighting as the attached image. ` + **PHONG CÁCH BIỂU TƯỢNG** + lời nhắc riêng.

### PHONG CÁCH BIỂU TƯỢNG

```
Cute colorful casual mobile farm game item icon, slight 3/4 front view from a little above, soft cel shading with gentle gradients, clean dark-brown outlines, warm light from the top-left, chunky readable shape that still reads at 32 pixels, single item centered and filling most of the square image, isolated on a plain white background (transparent if possible), no text, no border, no background circle, no cast shadow.
```

| Tên file | Lời nhắc riêng |
|---|---|
| `item_rom` | A tied bundle of golden dry rice straw, bound in the middle with a straw cord. |
| `item_nep` | A small woven bamboo basket of sticky-rice paddy: plump golden-white unhusked grains, with a few rice stalks lying across it. |
| `item_thoctam` | A small woven bamboo basket of fragrant jasmine paddy: slender long pale-gold unhusked grains, a sprig of fragrant rice stalk on top. |
| `item_rau` | A bunch of Vietnamese water spinach (rau muống): long hollow green stems with arrow-shaped leaves, tied with a strip of banana leaf. |
| `item_dau` | A small burlap sack open at the top, full of tiny round green mung beans, a few spilled in front. |
| `item_mia` | Two cut purple sugarcane stalks with visible joints, crossed, a few green leaves at the top. |
| `item_che` | A small handful of fresh green tea shoots: the bud plus two young leaves, bright light green. |
| `item_trungvit` | Two duck eggs, larger than chicken eggs, pale blue-green shell. |
| `item_suadaunanh` | A clear glass bottle of creamy pale-beige soy milk with a few soybeans beside it. |
| `item_suade` | A small metal milk can of fresh goat milk with a white goat-milk splash at the top. |
| `item_phan` | A woven bamboo basket filled with dark brown farmyard manure, a little straw sticking out. |
| `item_caro` | One tilapia fish (cá rô phi): grey-green body with faint dark vertical stripes, spiny dorsal fin. |
| `item_catram` | One grass carp (cá trắm): long torpedo-shaped body, olive-grey back, silver-yellow belly, big scales. |
| `item_cachep` | One common carp (cá chép): golden-bronze body, big scales, small barbels by the mouth. |
| `item_buoi` | A Vietnamese green pomelo: large round green-yellow fruit, slightly pear-shaped, with one leaf on the stem. |
| `item_vai` | A small cluster of lychees on a twig: bumpy bright red-pink skins, one peeled showing white flesh. |
| `item_nhan` | A cluster of longans on a twig: small round smooth tan-brown fruits, one peeled showing translucent white flesh. |
| `item_hong` | Two ripe orange persimmons with green four-petal calyx on top. |
| `item_cam` | A small burlap sack of light brown rice bran (cám) open at the top, fine powdery texture. |
| `item_banhda` | A round crispy Vietnamese rice cracker (bánh đa) sprinkled with black sesame seeds, slightly tilted. |
| `item_xoi` | A portion of sticky rice with peanuts (xôi lạc) on a piece of banana leaf. |
| `item_banhchung` | A square Vietnamese bánh chưng: wrapped in green dong leaves, tied with thin bamboo strings in a cross pattern. |
| `item_banhngo` | A few golden pan-fried corn cakes stacked on a little plate. |
| `item_duong` | A small clay bowl of light brown cane sugar crystals, a couple of sugar lumps beside it. |
| `item_keolac` | A few rectangular peanut brittle candy bars (kẹo lạc): golden caramel with whole peanuts. |
| `item_nuocmam` | A traditional glass bottle of amber Vietnamese fish sauce (nước mắm) with a small red cap. |
| `item_tuongot` | A small glass jar of bright red Vietnamese chili sauce with two red chilies beside it. |
| `item_chaca` | A few pieces of golden fried fish cake (chả cá) with fresh dill on top, on a small plate. |
| `item_dauphu` | Three white soft tofu blocks (đậu phụ) on a small round bamboo tray. |
| `item_chemat` | A clay teacup of golden tea with a little honey dipper resting on the saucer. |
| `item_hongsay` | A few flattened dried persimmons (hồng sấy), deep orange-brown, with a light sugar bloom. |
| `item_gaotam` | A small bowl of raw jasmine rice: long slender translucent white grains. |
| `item_com` | Green young rice flakes (cốm làng Vòng) wrapped in a lotus leaf, opened to show the bright green flakes. |
| `item_banhdauxanh` | A few small yellow square mung bean cakes (bánh đậu xanh) in a little paper box. |
| `item_banhcom` | A square green bánh cốm cake wrapped half-open in paper, showing the green outside and yellow mung-bean filling. |

## Đợt 8 — mặt đất, hồ sen, cầu, cây làng xa (không bắt buộc, làm dần)

Thiếu ảnh nào thì game vẫn vẽ phần đó bằng code. Hàng tre quanh bản đồ đã tự dùng ảnh `tre` có sẵn.

> **Ô đất (`dat_*`)**: mỗi ảnh là **một ô hình thoi**, bề mặt phẳng, phủ kín cả hình thoi. Ô sẽ được lát cạnh nhau hàng nghìn lần, nên **không viền, không bóng, không vật nổi**, màu đều từ mép này sang mép kia. Nên làm `dat_co_1` trước, gửi mình thử lát trên bản đồ; ưng rồi mới làm các ô khác.

| Tên file | Lời nhắc riêng |
|---|---|
| `dat_co_1` | One flat isometric 2:1 diamond ground tile completely filled with short lush green grass texture, even color right up to all four edges so it tiles seamlessly with copies of itself, a few tiny grass blades only. No outline, no border, no shadow, no objects, no soil edge or side faces: just the flat top surface, transparent outside the diamond. |
| `dat_co_2` | Same as `dat_co_1` (attach it as reference), same green and brightness, with a few tiny clover leaves scattered on the grass. Must tile seamlessly next to `dat_co_1`. |
| `dat_co_3` | Same as `dat_co_1` (attach it as reference), same green and brightness, with a very small patch of slightly lighter grass. Must tile seamlessly next to `dat_co_1`. |
| `dat_bai_boi` | Same flat diamond tile format as `dat_co_1` (attach it): pale yellow-green river-silt meadow, short sparse grass on light sandy soil, faint ripples. Seamless edges. |
| `dat_che` | Same flat diamond tile format as `dat_co_1` (attach it): a tea hillside seen from above, two neat rows of rounded dark-green tea bushes running across the diamond, soil between rows. Seamless edges. |
| `co_hoa` | A tiny clump of wild grass with two or three small white and yellow wildflowers, standing directly on the ground: no base tile, no platform. Very small, simple. |
| `ho_sen` | A large oval lotus pond seen in isometric 2:1 view from above (the oval is about 1.3 times wider than tall on screen), calm blue-green water, a narrow natural muddy-grass bank all around, many round lotus leaves and pink lotus flowers floating in clusters, a few reeds at the edges, maybe one small wooden plank jetty on the lower-left side. Flat ground-level object, transparent outside the pond bank. |
| `sen_1` | A small floating cluster of 3 round green lotus leaves with one pink lotus flower standing up from the water, seen from isometric view, no water around it (transparent). |
| `sen_2` | A small floating cluster of 2-3 round green lotus leaves only, no flower, seen from isometric view, no water around it (transparent). |
| `lau` | A clump of tall reeds and cattails growing at a pond's edge, standing directly on the ground: no base tile, no water around it. |
| `cau_go` | A rustic wooden plank bridge over a river, seen in isometric view, running from the upper-right down to the lower-left (3 tiles long, 1 tile wide), wooden railings on both sides, sturdy posts going down into the water. Bridge only: no river, no banks, transparent around it. |
| `cau_be_tong` | Same shape and direction as `cau_go` (attach it as reference) but a modern grey concrete village bridge with low concrete railings painted white and blue. Bridge only, transparent around it. |
| `cay_xa_1` | A big old Vietnamese banyan tree (cây đa) with a wide dense canopy and aerial roots, standing directly on the ground: no base tile, no platform. |
| `cay_xa_2` | A tall Vietnamese kapok tree (cây gạo) with bright red flowers on mostly bare branches, standing directly on the ground: no base tile, no platform. |
| `cay_xa_3` | A small group of 3 slender areca palm trees (cây cau) of different heights, standing directly on the ground: no base tile, no platform. |

## Đợt 9 — sân phơi thóc và quà lễ hội

Thiếu ảnh nào thì game vẫn vẽ tạm bằng code, nhưng bản vẽ code khá thô. Nên làm **`san_phoi` trước**, rồi đến 3 trạng thái của nó, vì người chơi thấy sân phơi hằng ngày. Đồ lễ hội làm dần, kịp trước **Tết cơm mới (16/11)** và **Tết Nguyên đán (30/1)** là đẹp.

> **Sân phơi**: cả 4 ảnh `san_phoi*` phải **cùng khung hình, cùng góc, cùng kích cỡ sân**, chỉ khác thứ nằm trên sân. Làm `san_phoi` trước rồi đính kèm nó làm mẫu cho 3 ảnh kia.

| Tên file | Lời nhắc riêng |
|---|---|
| `san_phoi` | An empty square drying yard (sân phơi thóc) paved with old red clay bricks in a neat grid, with a very low brick rim, a wooden grain rake (cào) lying on one corner, 2x2 tile flat base, nothing tall on it. Flat ground-level object. |
| `san_phoi_thoc` | Same yard as `san_phoi` (attach it as reference, same framing and size): golden rice grain (thóc) spread evenly over most of the yard in neat raked rows, the rake lying at the edge. |
| `san_phoi_bat` | Same yard as `san_phoi` (attach it): the spread rice grain fully covered by a blue plastic tarp, the tarp corners held down by a few old bricks. |
| `san_phoi_kho` | Same yard as `san_phoi` (attach it): dry golden rice grain with three full jute rice sacks tied at the top standing at the front edge of the yard. |
| `cay_neu` | A Vietnamese Tết cây nêu: a very tall thin bamboo pole with its green leafy top, red paper charms, a small round bamboo hoop and little bells hanging from the top, standing directly on the ground: no base tile, no platform. Tall and narrow. |
| `den_long` | A small wooden frame with three round red silk lanterns with golden tassels hanging from its top bar, standing directly on the ground: no base tile, no platform. |
| `cay_du` | A traditional village festival bamboo swing (cây đu): two tall A-shaped bamboo frames joined by a top bar, a long rope swing with a wooden seat, red ribbons tied at the top, standing directly on the ground, about two tiles wide and one tile deep: no base tile, no platform. |
| `gio_qua` | A round woven bamboo basket (thúng) full of tropical fruit: lychees, mangoes, plums, rambutans, standing directly on the ground: no base tile, no platform. |
| `chau_sen` | A big blue-and-white glazed ceramic pot with lotus leaves and two pink lotus flowers growing out of it, standing directly on the ground: no base tile, no platform. |
| `den_ong_sao` | A Vietnamese Mid-Autumn star lantern (đèn ông sao): a big red five-pointed star lantern made of cellophane on a bamboo frame with yellow tassels, mounted on a bamboo pole stuck in the ground: no base tile, no platform. |
| `coi_gia` | A traditional stone rice mortar (cối giã gạo) with a long wooden pestle leaning in it, a little white rice in the mortar, a small woven tray (nia) beside it, standing directly on the ground: no base tile, no platform. |

## Đợt 10 — tranh "Ký ức làng quê" (album 📖)

Mỗi ký ức là **một bức tranh cảnh đầy đủ**: có nền, có trời, **khung ngang tỉ lệ 4:3**. Khác các đợt trước, ở đây **không cần nền trong suốt** và công cụ của mình sẽ giữ nguyên nền. Tên file có tiền tố `ky_uc_`. Hai lá thư `thu_con` và `thu_chau` không cần tranh.

Chưa có tranh thì album hiện ô màu nâu ấm với biểu tượng, vẫn đọc được bình thường.

### PHONG CÁCH TRANH KÝ ỨC (dán vào mọi lời nhắc của đợt này)

```
A warm nostalgic illustration in the same cute colorful cel-shaded style as the attached farm game art, but as a full scene with background and sky, landscape 4:3 framing, soft golden afternoon light, gentle painterly textures, rural northern Vietnam village in the 1990s, simple friendly characters with no detailed faces, cozy and heartfelt mood, no text, no letters, no watermark, no border.
```

| Tên file | Lời nhắc riêng |
|---|---|
| `ky_uc_mua_dau` | A farmer in a conical hat holding up the first bundle of golden rice at harvest, sparrows over the paddy bank, rice field stretching to a bamboo hedge. |
| `ky_uc_don_dau` | An old grandmother chewing betel at a village gate smiling and handing coins to a young farmer who gives her a basket of fresh vegetables. |
| `ky_uc_ga_gay` | Dawn in the village: a red rooster crowing on top of a straw stack, morning cooking smoke rising from tiled roofs, pink sky. |
| `ky_uc_com_gao_moi` | A family meal on a bamboo mat: a steaming pot of white new rice, bowls, chopsticks, a mother scooping rice for a child, warm kitchen light. |
| `ky_uc_nha_ngoi` | Neighbours helping lay red clay roof tiles on a small village house, a father sitting on the porch smoking a bamboo water pipe, admiring the new roof. |
| `ky_uc_ao_ca` | Children sitting on a wooden plank jetty over a small pond behind a house, fishing with bamboo rods, bamboo shadows on the green water, summer noon. |
| `ky_uc_gieng_lang` | Women at a round brick village well in the early morning, drawing water with buckets and carrying it on shoulder poles, chatting. |
| `ky_uc_con_trau` | A little boy sitting on a water buffalo's back playing a bamboo flute in a green field at sunset, kites in the sky. |
| `ky_uc_phoi_thoc` | A family raking golden rice grain on a red brick drying yard in bright sun, dark rain clouds appearing at the edge of the sky, someone running with a blue tarp. |
| `ky_uc_cho_vang` | A yellow village dog wagging its tail running to greet someone arriving on an old bicycle at the end of a dirt lane. |
| `ky_uc_cong_lang` | An old moss-covered village gate with a curved tiled roof at dusk, elderly people sitting under a big tree beside it waiting, a dirt road leading in. |
| `ky_uc_hang_xom` | Neighbours harvesting rice together in a field for a sick family, sickles and rice bundles, everyone helping, warm community feeling. |
| `ky_uc_cho_phien` | A busy early-morning rural market: baskets of vegetables, bunches of bananas, trays of rice cakes, women in conical hats, a child holding a sweet. |
| `ky_uc_banh_chung` | Night before Tết: a family gathered around a big pot of bánh chưng boiling over a wood fire in the yard, children sleeping against their parents, glowing embers. |
| `ky_uc_tet_sum_vay` | The first morning of Tết: a family in new clothes in front of the ancestral altar with peach blossoms and a five-fruit tray, children holding red lucky envelopes. |
| `ky_uc_trung_thu` | Mid-Autumn night: children parading through a village lane with red star lanterns and a little drum, a full moon, a table with pomelo and mooncakes. |
| `ky_uc_com_moi` | A mother offering a bowl of new-harvest rice and green young rice flakes (cốm) on the family altar, autumn light through the window. |
| `ky_uc_truong_lang` | A small yellow village kindergarten with children reciting in class, grandmothers watching proudly through the gate. |
| `ky_uc_con_chau_ve` | A young couple with a small child arriving at the old parents' house with bags, grandparents welcoming them at the gate, a new house being built beside. |
| `ky_uc_hoi_dinh` | A spring festival at the village communal house (đình): young people on a tall bamboo swing, tug of war, elders on mats watching, red flags and drums. |
| `ky_uc_biet_thu` | A beautiful village garden house at sunset, with an old rice drying yard and an areca palm by the gate still kept the same as before. |
| `ky_uc_lao_nong` | Close view of an old farmer's weathered hands holding ripe rice ears, behind him the golden field and a calm sky, peaceful and proud. |
| `ky_uc_nong_thon_moi` | A modern Vietnamese countryside village at dusk: concrete lanes with street lights, a new school and clinic, but still bamboo hedges, rice fields and children flying kites. |

## Đợt 11 — các biểu tượng còn lại (cho đồng bộ với đợt 7)

Làm y như đợt 7: dán một biểu tượng đã có (ví dụ `item_gaotam`) làm ảnh mẫu, rồi gõ `Same icon style, size and lighting as the attached image. ` + **PHONG CÁCH BIỂU TƯỢNG** + lời nhắc riêng. Nhớ làm cả **`item_cam`** của đợt 7 (còn thiếu).

| Tên file | Lời nhắc riêng |
|---|---|
| `item_thoc` | A small woven bamboo basket full of golden unhusked rice grains (paddy), a few rice stalks lying across it. |
| `item_gao` | A small ceramic bowl heaped with clean white uncooked rice grains, a few grains spilled in front. |
| `item_ngo` | Two ears of yellow corn, one with the green husk pulled back showing plump kernels. |
| `item_khoai` | Two purple-skinned Vietnamese sweet potatoes, one cut showing yellow flesh. |
| `item_lac` | A small pile of peanuts in their tan wrinkled shells, one cracked open showing red-skinned nuts. |
| `item_ot` | A small bunch of bright red Vietnamese chili peppers with green stems. |
| `item_dua` | A round dark-green striped watermelon with a triangular slice cut out showing red flesh and black seeds. |
| `item_cuc` | A bunch of bright yellow chrysanthemum flowers (hoa cúc) with a few green leaves, tied with a red string. |
| `item_dautuong` | A small burlap sack open at the top, full of round pale-yellow soybeans, a few spilled in front. |
| `item_trung` | Three brown chicken eggs in a little nest of straw. |
| `item_thit` | A piece of fresh pork belly with pink meat and white fat layers, on a banana leaf. |
| `item_sua` | A glass bottle of fresh white cow milk with a blue cap, a little milk splash at the top. |
| `item_matong` | A small clay pot of golden honey with a wooden honey dipper dripping honey. |
| `item_tom` | Two big freshwater prawns (tôm càng) with long blue-grey claws, slightly curled. |
| `item_chuoi` | A hand of ripe yellow bananas with a few brown speckles. |
| `item_xoai` | A ripe golden-yellow Vietnamese mango with a green leaf on the stem. |
| `item_dua_xiem` | A green young coconut with the top cut open and a bamboo straw sticking out. |
| `item_nuocmia` | A tall glass of pale green sugarcane juice with ice and a slice of kumquat on the rim. |
| `item_sinhto` | A tall glass of thick orange mango smoothie with a straw and a mango slice on the rim. |
| `item_phomai` | A small round wheel of white goat cheese with one wedge cut out. |
| `item_chekho` | A small paper packet of dark-green dried rolled tea leaves, a few leaves spilled in front. |
