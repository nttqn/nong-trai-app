// Ký ức làng quê: an album of little memories, each opened by a milestone
// on the farm. A painting (assets/memories/<id>.jpg, art/PROMPTS.md batch
// 10), a few nostalgic lines, and a small gift the first time it is read.

import 'farm.dart';

class MemoryDef {
  final String id, icon, title, hint, text;
  /// A letter from the children in the city (drawn as a letter).
  final bool letter;
  final int coins;
  final bool Function(Farm f) done;
  const MemoryDef(this.id, this.icon, this.title, this.hint, this.coins, this.done, this.text, {this.letter = false});
}

int _s(Farm f, String k) => f.stats[k] ?? 0;
int _prefix(Farm f, String p) =>
    f.stats.entries.where((e) => e.key.startsWith(p)).fold(0, (a, e) => a + e.value);
int _houseLv(Farm f) => f.house?.level ?? 0;

final memories = <MemoryDef>[
  MemoryDef('mua_dau', '🌾', 'Mùa gặt đầu tiên', 'Gặt lúa lần đầu', 100, (f) => _s(f, 'harvest:lua') >= 1,
      'Bó lúa đầu tiên trĩu hạt trên tay. Mùi rơm mới, mùi bùn non, tiếng chim sẻ ríu rít trên bờ ruộng. Ngày ấy ai cũng nghĩ đồng mình nghèo, vậy mà lúa vẫn chín vàng như thế.'),
  MemoryDef('don_dau', '🧺', 'Đơn hàng của bà Tư', 'Giao đơn hàng đầu tiên', 100, (f) => _s(f, 'order') >= 1,
      'Bà Tư đầu ngõ móm mém cười, dúi vào tay mấy đồng tiền lẻ còn thơm mùi trầu. "Rau nhà cháu ngọt lắm, mai bà lại sang." Thế là có mối hàng đầu tiên.'),
  MemoryDef('ga_gay', '🐓', 'Tiếng gà gáy sớm', 'Làm chuồng gà', 150, (f) => _s(f, 'build:chuong_ga') >= 1,
      'Bốn giờ sáng, con gà trống tía đã nhảy lên đống rơm gáy vang. Cả xóm thức dậy theo nó: tiếng chổi tre quét sân, tiếng nồi niêu lách cách, khói bếp lam chiều đã thành khói bếp ban mai.'),
  MemoryDef('com_gao_moi', '🍚', 'Bát cơm gạo mới', 'Xay thóc thành gạo', 150, (f) => _s(f, 'get:gao') >= 1,
      'Nồi cơm gạo mới sôi lục bục, hạt gạo trắng ngần dẻo thơm. Mẹ bảo ăn bát cơm thì nhớ người cày ruộng, nhớ cả nắng mưa đã đổ xuống mấy sào đồng.'),
  MemoryDef('nha_ngoi', '🏠', 'Mái ngói đỏ', 'Nâng nhà lên mái ngói', 300, (f) => _houseLv(f) >= 1,
      'Ngày dỡ mái tranh lợp ngói, cả xóm sang phụ một tay. Chiều về, mái ngói đỏ au dưới nắng, bố ngồi hút điếu thuốc lào, ngắm mãi không chán.'),
  MemoryDef('ao_ca', '🐟', 'Ao cá sau nhà', 'Đào ao thả cá', 200, (f) => _s(f, 'build:ao') >= 1,
      'Lũ trẻ ngồi vắt vẻo trên cầu ao, thả cần câu bằng cành tre. Cá rô quẫy nước lách tách, bóng tre in xuống mặt ao xanh ngắt cả buổi trưa hè.'),
  MemoryDef('gieng_lang', '🪣', 'Giếng làng', 'Xây giếng làng', 300, (f) => f.projects.contains('gieng'),
      'Sáng sớm các bà các chị ra giếng gánh nước, vừa múc vừa kể chuyện nhà chuyện xóm. Nước giếng mát lạnh, uống một ngụm là nhớ cả đời.'),
  MemoryDef('con_trau', '🐃', 'Con trâu là đầu cơ nghiệp', 'Làm chuồng trâu', 300, (f) => _s(f, 'build:chuong_trau') >= 1,
      'Thằng cu ngồi vắt vẻo trên lưng trâu, thổi sáo trúc giữa cánh đồng chiều. Con trâu hiền lành gặm cỏ, cái đuôi phe phẩy đuổi ruồi, chậm rãi như cả làng quê.'),
  MemoryDef('phoi_thoc', '☀️', 'Nắng lên phơi thóc', 'Phơi khô một mẻ thóc', 200, (f) => _s(f, 'dry') >= 1,
      'Nắng vừa lên là cả nhà khiêng thóc ra sân, cào thành từng luống. Hễ trời kéo mây đen là bỏ cả bát cơm chạy ra vun thóc, ai cũng ướt áo mà vẫn cười.'),
  MemoryDef('cho_vang', '🐕', 'Con chó vàng giữ nhà', 'Nuôi chó giữ nhà', 200, (f) => _s(f, 'build:cho') >= 1,
      'Con Vàng nằm dài ở hiên, nghe tiếng xe đạp đầu ngõ là vẫy đuôi chạy ra. Người lạ thì nó sủa vang, người quen thì nó quấn lấy chân không rời.'),
  MemoryDef('cong_lang', '⛩️', 'Cổng làng', 'Xây cổng làng', 400, (f) => f.projects.contains('cong_lang'),
      'Đi đâu xa, cứ thấy cổng làng rêu phong là biết mình đã về tới nhà. Dưới gốc cây bên cổng, mấy cụ già ngồi chờ con cháu đi làm về.'),
  MemoryDef('hang_xom', '🤝', 'Tối lửa tắt đèn có nhau', 'Thu hoạch hộ hàng xóm', 200, (f) => _s(f, 'help') >= 1,
      'Nhà bên ốm, cả xóm kéo sang gặt hộ mấy sào lúa. Bán anh em xa, mua láng giềng gần: ở quê, chẳng ai phải một mình.'),
  MemoryDef('cho_phien', '🛒', 'Phiên chợ quê', 'Bán hàng ở chợ phiên', 300, (f) => _s(f, 'market_sold') >= 1,
      'Phiên chợ quê họp từ tinh mơ: rổ rau, buồng chuối, mẹt bánh đúc. Đứa trẻ nào cũng ngóng mẹ đi chợ về, chỉ để được cái kẹo bột hay tấm bánh đa.'),
  MemoryDef('banh_chung', '🟩', 'Nồi bánh chưng', 'Gói bánh chưng', 400, (f) => _s(f, 'get:banhchung') >= 1,
      'Đêm hai mươi tám Tết, cả nhà quây quần bên nồi bánh chưng. Lửa reo tí tách, khói thơm lá dong, lũ trẻ ngủ gục bên bếp mà vẫn đòi thức canh bánh.'),
  MemoryDef('tet_sum_vay', '🧧', 'Tết sum vầy', 'Giao đủ đơn Tết Nguyên đán', 800, (f) => _s(f, 'fest:tet') >= 1,
      'Sáng mồng Một, áo mới còn thơm mùi vải, bao lì xì đỏ nằm gọn trong túi. Cả nhà thắp hương ông bà, chúc nhau một năm mới mưa thuận gió hòa.'),
  MemoryDef('trung_thu', '🥮', 'Đêm rằm tháng Tám', 'Giao đủ đơn Tết Trung thu', 600, (f) => _s(f, 'fest:trung_thu') >= 1,
      'Đèn ông sao đỏ rực đi khắp ngõ, tiếng trống ếch tùng tùng. Mâm cỗ có bưởi, có hồng, có chiếc bánh nướng bố mua tận chợ huyện, lũ trẻ chia nhau từng miếng.'),
  MemoryDef('com_moi', '🌾', 'Tết cơm mới', 'Giao đủ đơn Tết cơm mới', 600, (f) => _s(f, 'fest:com_moi') >= 1,
      'Mồng mười tháng Mười, mẹ nấu nồi cơm gạo mới đầu mùa dâng tổ tiên. Hương cốm, hương gạo mới thơm khắp nhà, báo một vụ mùa no ấm.'),
  MemoryDef('thu_con', '✉️', 'Lá thư từ thành phố', 'Đạt cấp 15', 500, (f) => f.level >= 15,
      'Bố mẹ ơi, con ở thành phố vẫn khỏe. Phố đông lắm, nhưng chẳng ở đâu có mùi rơm rạ như quê mình. Tết này con xin nghỉ sớm, về phụ bố mẹ gói bánh chưng. Con nhớ nhà nhiều lắm.',
      letter: true),
  MemoryDef('truong_lang', '🏫', 'Tiếng trẻ học bài', 'Xây trường mầm non', 500, (f) => f.projects.contains('truong'),
      'Buổi sáng, tiếng trẻ đánh vần vọng ra từ lớp học mới quét vôi vàng. Các bà đứng ngoài cổng nhìn vào, mắt ai cũng sáng lên vì con cháu có chỗ học đàng hoàng.'),
  MemoryDef('con_chau_ve', '👨‍👩‍👧', 'Con cháu về quê', 'Xây nhà con cháu', 1000, (f) => _s(f, 'build:nha_phu') >= 1,
      'Thằng út dẫn vợ con về quê dựng nhà ngay cạnh nhà bố mẹ. Sân nhà lại rộn tiếng trẻ con, bữa cơm lại đông đủ như ngày xưa.'),
  MemoryDef('thu_chau', '✉️', 'Thư của cháu nội', 'Đạt cấp 25', 800, (f) => f.level >= 25,
      'Ông bà ơi, cháu được điểm mười môn vẽ! Cháu vẽ cánh đồng nhà mình, có con trâu, có cánh diều và có ông đang gặt lúa. Hè này cháu về, ông dạy cháu thả diều nhé!',
      letter: true),
  MemoryDef('hoi_dinh', '🏯', 'Hội đình', 'Xây đình làng', 1000, (f) => f.projects.contains('dinh_lang'),
      'Mùa xuân, trống hội đình làng rộn rã. Trai làng đánh đu, kéo co, các cụ ngồi chiếu giữa sân đình nghe hát chèo, cả làng như trẻ lại.'),
  MemoryDef('biet_thu', '🏡', 'Ngôi nhà mơ ước', 'Xây biệt thự nhà vườn', 1500, (f) => _houseLv(f) >= 4,
      'Từ mái tranh vách đất đến ngôi nhà vườn khang trang, bao mùa mưa nắng đã qua. Nhưng góc sân phơi thóc, cây cau trước ngõ vẫn giữ nguyên như ngày đầu.'),
  MemoryDef('lao_nong', '👴', 'Lão nông tri điền', 'Thu hoạch 1.000 lần', 2000, (f) => _prefix(f, 'harvest:') >= 1000,
      'Đôi bàn tay chai sạn đã gặt cả nghìn mùa lúa. Nhìn trời biết mưa, nhìn mây biết gió, đất nuôi người và người cũng thương đất như thương con.'),
  MemoryDef('nong_thon_moi', '🎉', 'Làng nông thôn mới', 'Xây đủ 10 công trình', 3000, (f) => f.projects.length >= 10,
      'Đường làng đổ bê tông, điện sáng khắp ngõ, trường mới, trạm y tế mới. Làng đổi khác nhiều lắm, nhưng tiếng sáo diều chiều quê và tình làng nghĩa xóm thì vẫn vẹn nguyên.'),
];

MemoryDef? memoryById(String id) {
  for (final m in memories) {
    if (m.id == id) return m;
  }
  return null;
}
