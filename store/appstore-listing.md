# App Store Connect – Mùa Lúa Chín (bản iOS đầu tiên 1.9.0)

Giới hạn: Tên 30, Phụ đề 30, Văn bản quảng cáo 170, Từ khóa 100 (cách nhau dấu phẩy, không cần dấu cách), Mô tả 4000.
Không dùng emoji (App Store báo "invalid characters"). Không nhắc Android / Google Play (2.3.10).
Tên và phụ đề nằm ở App Information (theo từng ngôn ngữ); Mô tả, Từ khóa, Văn bản quảng cáo nằm ở trang phiên bản 1.9.0.
Bản đầu tiên không có ô "Có gì mới".
Thêm ngôn ngữ English (U.S.) ở thanh bên → "Thêm ngôn ngữ"; nếu không tải ảnh riêng, App Store dùng ảnh của tiếng Việt.

## Thông tin ứng dụng

| Ô | Giá trị |
|---|---|
| Bundle ID | com.trungsmail.nongtrai |
| SKU | nongtrai |
| Ngôn ngữ chính | Vietnamese |
| Danh mục | Games → Simulation; phụ: Games → Casual |
| Support URL | https://nttqn.github.io/nong-trai-app/support.html |
| Marketing URL (tùy chọn) | https://nttqn.github.io/nong-trai-app/ |
| Privacy Policy URL | https://nttqn.github.io/nong-trai-app/privacy.html |
| Copyright | 2026 Ngo Thanh Trung |
| Giá | Miễn phí |
| Export compliance | Chỉ HTTPS chuẩn → không có mã hóa phải khai (ITSAppUsesNonExemptEncryption = NO đã có trong Info.plist) |

**Age Rating** (bảng câu hỏi): mọi mục nội dung = None. Phần tính năng:
- **Messaging and Chat = Yes** (Kênh Thế Giới), **User-Generated Content = Yes** (tin chat, tên nông trại, sạp chợ phiên).
- **Advertising = Yes** (AdMob). Thiếu một trong ba mục này là bị từ chối tự động 2.3.6.
- In-App Purchases = Yes. Unrestricted Web Access = No. Gambling / Contests = No.
- Kết quả dự kiến: 12+ (do có chat).

Ảnh (tạo bằng `node tool/store_shots.js iphone-6.3in` và `ipad-13in`, có `store=ios` để cửa hàng ghi "App Store"):
- iPhone 6,3" 1206×2622: store/iphone-6.3in/ (8 ảnh)
- iPad 13" 2064×2752: store/ipad-13in/ (8 ảnh)
- Icon app lấy từ build (ios/Runner/Assets.xcassets, 1024×1024).

Mua trong ứng dụng: xem store/iap-ios.md. Riêng tư và ghi chú người duyệt: store/appstore-privacy.md, store/appstore-review-notes.txt.

---

# Tiếng Việt (vi) – ngôn ngữ chính

## Tên (≤ 30, 27)
Mùa Lúa Chín: Nông Trại Quê

## Phụ đề (≤ 30, 26)
Làm nông làng quê Việt Nam

## Văn bản quảng cáo (≤ 170, 144)
Cấy lúa, nuôi trâu, phơi thóc, gói bánh chưng và ăn Tết theo lịch âm. Đua top câu cá mỗi tuần, ghé nông trại hàng xóm và xây làng nông thôn mới!

## Từ khóa (≤ 100, 93)
nông trại,làm nông,trồng trọt,chăn nuôi,làng quê,lịch âm,câu cá,thư giãn,offline,farm,tết,lúa

## Mô tả (≤ 4000, 3776)
Về quê thôi! Cấy lúa, nuôi trâu, phơi thóc, gói bánh chưng và cùng cả xóm xây làng nông thôn mới trong Mùa Lúa Chín, nông trại thư thả mang đậm hồn làng quê Bắc Bộ.

RUỘNG LÚA, VƯỜN RAU, AO CÁ
- Cấy lúa, lúa nếp, lúa tám thơm, nếp cẩm; trồng rau muống, ngô, khoai, lạc, mía, dưa hấu, hoa cúc, chè, nghệ, cói…
- Vườn cây trái: chuối, xoài, dừa, bưởi, vải thiều, nhãn lồng, hồng, cam, mít, cau.
- Nuôi gà, vịt, lợn, trâu, bò, dê, đàn ong và tằm; đào ao thả cá rô, cá trắm, cá chép, tôm càng, lươn.
- Vuốt ngón tay qua cả dãy ruộng để gặt hay gieo một lượt; nút Thu hết và Gieo lại cho cả nông trại.
- Mọi thứ vẫn lớn khi bạn tắt game, chín rồi thì có thông báo nhắc.

LỊCH ÂM THẬT, MÙA VỤ THẬT
- Game chạy theo âm lịch Việt Nam: 24 tiết khí, mỗi tiết một câu ca dao nhà nông.
- Vụ chiêm xuân, vụ hè thu, vụ mùa, vụ đông: cây hợp mùa lớn nhanh hơn.
- Thời tiết thay đổi: mưa rào giúp cây lớn nhanh, nắng hạn thì cần trạm bơm, giếng làng.
- Đêm trăng làng quê: trời tối theo giờ thật, trăng tròn khuyết đúng lịch âm, đom đóm lập lòe.

PHƠI THÓC, CẤT THÓC
- Gặt lúa xong đem thóc ra sân gạch phơi, khô giòn thì được thêm thóc mẩy hạt.
- Trời kéo mây đen thì nhanh tay che bạt, kẻo mưa ướt hết thóc!

LỄ HỘI QUANH NĂM
- Tết Nguyên đán, Rằm tháng Giêng, Hội làng mùa xuân, Tết Đoan ngọ, Rằm tháng Bảy, Trung thu, Tết cơm mới: tự đến đúng ngày âm lịch.
- Mỗi dịp có đơn hàng riêng và đồ trang trí không bán ở đâu: cây nêu, đèn ông sao, cây đu, cối giã gạo…
- Sự kiện tuần: mỗi tuần một chủ đề, 5 mốc quà, bảng xếp hạng tuần, top 30 nhận thưởng.

CÂU CÁ NGOÀI SÔNG
- Chạm vào dòng sông, canh phao rồi giật cần.
- Đua top câu cá: cá càng khó càng nhiều điểm, bảng xếp hạng mới mỗi tuần.

LÀNG NGHỀ VÀ CHỢ QUÊ
- Xay thóc ra gạo, gói bánh chưng, làm bánh đa, kẹo lạc, nước mắm, đậu phụ, sao chè, sấy hồng, ươm tơ dệt lụa, dệt chiếu cói…
- Giao đơn hàng cho bà con trong xóm, đơn đặc biệt mỗi ngày.
- Chợ phiên: bày hàng lên sạp để người chơi khác mua.

XÂY LÀNG NÔNG THÔN MỚI
- Từ mái tranh vách đất lên nhà ngói, nhà ống, biệt thự nhà vườn; dựng nhà cho con cháu ra ở riêng.
- Góp công góp của xây giếng làng, cổng làng, đường bê tông, trạm bơm, trường mầm non, trạm y tế, chợ quê, đình làng. Mỗi công trình cho một lợi ích lâu dài.
- Mua thêm đất, mở rộng tới 36 mảnh; hàng rào tre, ngõ gạch, giàn hoa giấy, ao sen, mai vàng để trang trí.

HÀNG XÓM LÁNG GIỀNG
- Ghé thăm nông trại của người chơi khác trên bản đồ vùng, thu hoạch hộ để nhận quà.
- Hái trộm cũng được, nhưng coi chừng bù nhìn và chó giữ nhà!
- Kênh Thế Giới để trò chuyện với bà con khắp nơi, có báo cáo và chặn tin xấu.
- Bảng xếp hạng nhà nông, thành tựu và danh hiệu.

KÝ ỨC LÀNG QUÊ
- Mỗi chặng đường mở một bức tranh ký ức: mùa gặt đầu tiên, nồi bánh chưng đêm ba mươi, phiên chợ quê, lá thư con gửi từ thành phố…

LÀNG QUÊ NHỘN NHỊP
- Bà con gánh hàng, đạp xe chở hoa, chú bé cưỡi trâu thổi sáo, người chăn vịt lùa cả đàn đi lại trên đường làng.
- Nông dân ra đồng cấy lúa, cuốc đất; gà mẹ dẫn đàn con kiếm ăn trước sân; vịt bơi trên hồ sen, thuyền nan xuôi ngược trên sông.
- Nhạc nền với sáo trúc, đàn bầu, đàn tranh; tiếng gà gáy, trâu kêu, vịt quạc.

Chơi được không cần mạng. Đăng nhập Apple hoặc Google (không bắt buộc) để lưu nông trại lên mây, đổi máy không mất, và giao lưu với hàng xóm.

CỬA HÀNG (KHÔNG BẮT BUỘC)
- Gói khởi đầu: xu, thêm 50 chỗ chứa, 10 Vé Xong ngay, chậu sen và giàn đèn lồng.
- Hầm chứa đá ong: công trình riêng, thêm 250 chỗ chứa, nâng cấp bằng xu lên tới 3000.
- Thẻ Nhà Nông 30 ngày: mỗi ngày 5 lượt Xong ngay miễn phí, đơn hàng thêm 20% xu, quà đăng nhập nhân đôi.
- Bỏ quảng cáo: tắt quảng cáo xen giữa.

Game miễn phí, chơi trọn vẹn không cần nạp. Có quảng cáo; nhiều quảng cáo do bạn tự chọn xem để nhận thưởng: làm xong ngay, nhân đôi quà lên cấp.

Hỗ trợ: trungsmail@gmail.com

---

# English (U.S.)

## Name (≤ 30, 26)
Mùa Lúa Chín: Village Farm

## Subtitle (≤ 30, 27)
Rice, buffalo and festivals

## Promotional Text (≤ 170, 160)
Plant rice, raise buffalo, dry the harvest and celebrate Tết on the lunar calendar. Race for the weekly fishing top, visit neighbours and build up your village!

## Keywords (≤ 100, 97)
farm,farming,village,vietnam,rice,harvest,lunar,fishing,relaxing,offline,crops,animals,tet,family

## Description (≤ 4000, 3993)
Head back to the countryside! Plant rice, raise water buffalo, dry the harvest in the sun, wrap Tết rice cakes and build up your village in Mùa Lúa Chín ("Ripe Rice Season"), a relaxing farm game full of the charm of rural northern Vietnam.

PADDIES, GARDENS AND FISH PONDS
- Grow rice, sticky rice, fragrant rice and black sticky rice; water spinach, corn, sweet potato, peanuts, sugarcane, watermelon, tea, turmeric, sedge…
- Orchards of banana, mango, coconut, pomelo, lychee, longan, persimmon, orange, jackfruit and areca.
- Raise chickens, ducks, pigs, buffalo, cows, goats, bees and silkworms; dig ponds for tilapia, carp, river prawns and eels.
- Swipe across a row of fields to harvest or sow them all at once, or use Harvest all and Replant for the whole farm.
- Everything keeps growing while the game is closed, with a reminder when it is ripe.

A REAL LUNAR CALENDAR
- The game follows the Vietnamese lunar calendar: 24 solar terms, each with a farmer's proverb.
- Spring, summer, main and winter crop seasons: in-season crops grow faster.
- Changing weather: rain speeds up crops, a dry spell needs the pump station or the village well.
- Moonlit nights: the village darkens with your clock and the moon follows the real lunar calendar.

DRY THE RICE BEFORE IT RAINS
- Spread the harvested rice on the brick yard to dry for a bonus.
- Dark clouds coming? Pull the tarp over it before the rain soaks it!

FESTIVALS ALL YEAR
- Lunar New Year, the first full moon, the spring village festival, Đoan Ngọ, the seventh-month full moon, Mid-Autumn and the New Rice festival arrive on their real lunar dates.
- Each brings festival orders and decorations you can't buy anywhere: a Tết pole, a star lantern, a bamboo swing, a rice mortar…
- Weekly events: a new theme every week, 5 reward milestones and a weekly leaderboard with prizes for the top 30.

RIVER FISHING
- Tap the river, watch the float and strike.
- Fishing race: harder fish score more, with a new leaderboard every week.

CRAFTS AND THE VILLAGE MARKET
- Mill rice, wrap bánh chưng, bake rice crackers, make peanut candy, fish sauce, tofu, roasted tea and dried persimmons, reel silk and weave sedge mats.
- Fill villagers' orders and daily specials; sell spare goods to other players at the market.

BUILD A NEW VILLAGE
- Upgrade from a thatched hut to a garden villa, and build homes for your grown-up children.
- Build the village well, gate, concrete road, pump station, kindergarten, clinic, market and communal house, each with a lasting bonus.
- Buy more land, up to 36 plots, and decorate with bamboo fences, brick paths, bougainvillea, lotus ponds and apricot blossoms.

NEIGHBOURS
- Visit other players' farms on the region map and help them harvest for a reward.
- Or sneak a few vegetables, but watch out for the scarecrow and the guard dog!
- World chat with farmers everywhere, with report and block.
- Leaderboards, achievements and titles.

VILLAGE MEMORIES
- Every milestone opens a painted memory: the first harvest, the rice cakes on New Year's Eve, the village market, a letter from a child in the city…

A LIVELY VILLAGE
- Villagers carry baskets on shoulder poles, cycle with flowers, a boy rides a buffalo playing his flute and a duck herder drives his flock down the road.
- Farmers plant rice and hoe the beds; hens lead their chicks, ducks swim on the lotus lake and boats sail the river.

Plays offline. Optional Sign in with Apple or Google saves your farm to the cloud and lets you meet neighbours.

SHOP (OPTIONAL)
- Starter Pack: coins, +50 storage, 10 Instant Finish tickets, a lotus pot and a lantern arbor.
- Laterite Cellar: its own building with +250 storage, upgradable with coins up to 3000.
- 30-day Farmer Card: 5 free Instant Finishes a day, +20% coins on orders, doubled login gifts.
- Remove Ads: turns off interstitial ads.

Free to play, fully playable without paying. Contains ads; many are optional and give rewards.

The game is in Vietnamese.

Support: trungsmail@gmail.com
