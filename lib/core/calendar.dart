// Mùa vụ và lễ hội: the farm follows the real lunar calendar. Each season
// some crops grow faster ("hợp mùa"); around each traditional festival the
// village asks for festival goods and gives a festival decoration.

import 'lunar.dart';

/// Dev screenshots (?day=2026-09-25 on web): pretend today is this date.
DateTime? calendarOverride;

DateTime calendarDay(int ms) {
  final o = calendarOverride;
  if (o != null) return o;
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day);
}

// ------------------------------------------------------------------ seasons
enum Season { xuan, ha, thu, dong }

class SeasonDef {
  final String name, vu, icon;
  final List<String> crops; // crop ids that grow faster this season
  const SeasonDef(this.name, this.vu, this.icon, this.crops);
}

const seasons = <Season, SeasonDef>{
  Season.xuan: SeasonDef('Mùa xuân', 'Vụ chiêm xuân', '🌸', ['lua', 'lac', 'dau', 'che']),
  Season.ha: SeasonDef('Mùa hạ', 'Vụ hè thu', '☀️', ['ngo', 'dua', 'mia', 'ot']),
  Season.thu: SeasonDef('Mùa thu', 'Vụ mùa', '🍂', ['lua', 'nep', 'tam', 'cuc']),
  Season.dong: SeasonDef('Mùa đông', 'Vụ đông', '❄️', ['khoai', 'rau', 'dautuong']),
};

/// Crops in season grow this much faster.
const seasonSpeed = .15;

/// Season of a tiết khí: spring runs from Lập xuân to Cốc vũ, and so on.
Season seasonOfTerm(int term) => switch ((term + 3) % 24 ~/ 6) {
      0 => Season.xuan,
      1 => Season.ha,
      2 => Season.thu,
      _ => Season.dong,
    };

int solarTermOf(DateTime d) => LunarCalendar.solarTerm(d.day, d.month, d.year);
Season seasonOf(DateTime d) => seasonOfTerm(solarTermOf(d));
bool inSeason(String cropId, DateTime d) => seasons[seasonOf(d)]!.crops.contains(cropId);

/// A farmer's saying for each tiết khí.
const termSayings = [
  'Nắng tốt dưa, mưa tốt lúa.', // Xuân phân
  'Tháng Ba cày vỡ ruộng ra, tháng Tư làm mạ, mưa sa đầy đồng.', // Thanh minh
  'Mưa tháng Ba hoa đất, mưa tháng Tư hư đất.', // Cốc vũ
  'Lúa chiêm lấp ló đầu bờ, hễ nghe tiếng sấm phất cờ mà lên.', // Lập hạ
  'Nhất nước, nhì phân, tam cần, tứ giống.', // Tiểu mãn
  'Chuồn chuồn bay thấp thì mưa, bay cao thì nắng, bay vừa thì râm.', // Mang chủng
  'Đêm tháng Năm chưa nằm đã sáng.', // Hạ chí
  'Ráng mỡ gà, có nhà thì giữ.', // Tiểu thử
  'Cày đồng đang buổi ban trưa, mồ hôi thánh thót như mưa ruộng cày.', // Đại thử
  'Mạ chiêm ba tháng không già, mạ mùa tháng rưỡi ắt là không non.', // Lập thu
  'Tháng Bảy kiến đàn, đại hàn hồng thủy.', // Xử thử
  'Tháng Tám nắng rám trái bưởi.', // Bạch lộ
  'Trăng quầng thì hạn, trăng tán thì mưa.', // Thu phân
  'Ai ơi bưng bát cơm đầy, dẻo thơm một hạt đắng cay muôn phần.', // Hàn lộ
  'Ngày tháng Mười chưa cười đã tối.', // Sương giáng
  'Tấc đất tấc vàng.', // Lập đông
  'Gió đông là chồng lúa chiêm, gió bấc là duyên lúa mùa.', // Tiểu tuyết
  'Ruộng không phân như thân không của.', // Đại tuyết
  'Tháng Chạp là tháng trồng khoai, tháng Giêng trồng đậu, tháng Hai trồng cà.', // Đông chí
  'Có làm thì mới có ăn, không dưng ai dễ đem phần đến cho.', // Tiểu hàn
  'Thịt mỡ, dưa hành, câu đối đỏ; cây nêu, tràng pháo, bánh chưng xanh.', // Đại hàn
  'Tháng Giêng là tháng ăn chơi.', // Lập xuân
  'Mồng một tết cha, mồng hai tết mẹ, mồng ba tết thầy.', // Vũ thủy
  'Một nắng hai sương.', // Kinh trập
];

// ------------------------------------------------------------------ festivals
class FestivalDef {
  final String id, name, icon, desc;
  /// Lunar (day, month) when it starts and ends; may wrap over new year.
  final (int, int) from, to;
  /// Goods its orders prefer (the ones the player can make are asked for).
  final List<String> goods;
  /// Decoration given for delivering all its orders.
  final String deco;
  const FestivalDef(this.id, this.name, this.icon, this.from, this.to, this.goods, this.deco, this.desc);
}

const festivals = [
  FestivalDef('tet', 'Tết Nguyên đán', '🧧', (23, 12), (7, 1),
      ['banhchung', 'gao', 'nep', 'thit', 'dau', 'cuc', 'keolac', 'xoi', 'gaotam', 'banhdauxanh'], 'cay_neu',
      'Từ ông Công ông Táo đến mồng 7: gói bánh chưng, sắm hoa, dựng cây nêu.'),
  FestivalDef('nguyen_tieu', 'Rằm tháng Giêng', '🏮', (13, 1), (16, 1),
      ['xoi', 'chuoi', 'buoi', 'cuc', 'gao', 'nep', 'matong'], 'den_long',
      'Tết Nguyên tiêu: lễ chùa, mâm xôi, treo đèn lồng.'),
  FestivalDef('hoi_lang', 'Hội làng mùa xuân', '🎊', (10, 2), (15, 2),
      ['banhda', 'xoi', 'nuocmia', 'keolac', 'banhngo', 'trungvit', 'com'], 'cay_du',
      'Làng mở hội: đánh đu, kéo co, chọi gà, bánh trái đầy chợ.'),
  FestivalDef('doan_ngo', 'Tết Đoan ngọ', '🍑', (3, 5), (6, 5),
      ['vai', 'xoai', 'nep', 'dua', 'trungvit', 'chuoi', 'dua_xiem'], 'gio_qua',
      'Tết giết sâu bọ mồng 5 tháng 5: ăn hoa quả, rượu nếp, trứng vịt.'),
  FestivalDef('vu_lan', 'Rằm tháng Bảy', '🪷', (12, 7), (16, 7),
      ['xoi', 'chuoi', 'buoi', 'gao', 'dauphu', 'chekho', 'banhda'], 'chau_sen',
      'Lễ Vu lan báo hiếu: mâm chay, xôi chè, hoa sen.'),
  FestivalDef('trung_thu', 'Tết Trung thu', '🥮', (10, 8), (16, 8),
      ['banhngo', 'buoi', 'hong', 'keolac', 'banhdauxanh', 'com', 'banhcom', 'matong'], 'den_ong_sao',
      'Rằm tháng Tám: rước đèn ông sao, bày cỗ trông trăng cho trẻ con.'),
  FestivalDef('com_moi', 'Tết cơm mới', '🍚', (8, 10), (12, 10),
      ['gao', 'gaotam', 'com', 'thoctam', 'nep', 'xoi', 'banhcom'], 'coi_gia',
      'Mồng 10 tháng 10: được mùa, nấu nồi cơm gạo mới dâng tổ tiên.'),
];

FestivalDef? festivalById(String id) {
  for (final f in festivals) {
    if (f.id == id) return f;
  }
  return null;
}

/// Festival decorations (only given by festivals, never sold).
final festivalDecos = {for (final f in festivals) f.deco};

int _ord(int day, int month) => month * 100 + day;

bool _within(FestivalDef f, LunarDate l) {
  final v = _ord(l.day, l.month), a = _ord(f.from.$1, f.from.$2), b = _ord(f.to.$1, f.to.$2);
  return a <= b ? v >= a && v <= b : v >= a || v <= b;
}

/// A festival on the lunar calendar: which one, its lunar year (the year
/// of its last day), and the solar days it starts and ends.
class FestivalTime {
  final FestivalDef def;
  final int year;
  final DateTime start, end; // end = its last day (inclusive)
  const FestivalTime(this.def, this.year, this.start, this.end);

  /// Stable key for this year's festival (orders are rolled once per key).
  String get key => '${def.id}-$year';

  bool contains(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
  int daysLeft(DateTime today) => end.difference(today).inHours ~/ 24 + 1;
  int daysUntil(DateTime today) => (start.difference(today).inHours / 24).round();
}

FestivalTime? _timeOf(FestivalDef f, int year) {
  final wraps = f.from.$2 > f.to.$2;
  final s = solarOf(f.from.$1, f.from.$2, wraps ? year - 1 : year);
  final e = solarOf(f.to.$1, f.to.$2, year);
  if (s == null || e == null) return null;
  return FestivalTime(f, year, s, e);
}

/// The festival on [d], if any (none during a leap month).
FestivalTime? festivalOn(DateTime d) {
  final l = LunarDate.of(d);
  if (l.leap) return null;
  for (final f in festivals) {
    if (!_within(f, l)) continue;
    // the lunar year the festival ends in (Tết that starts in month 12
    // ends in the next lunar year)
    final y = f.from.$2 > f.to.$2 && l.month >= f.from.$2 ? l.year + 1 : l.year;
    final t = _timeOf(f, y);
    if (t != null && t.contains(d)) return t;
  }
  return null;
}

/// The coming festivals after [d] (not the one on now), soonest first.
List<FestivalTime> upcomingFestivals(DateTime d, {int count = 3}) {
  final l = LunarDate.of(d);
  final out = <FestivalTime>[];
  for (var y = l.year; y <= l.year + 2; y++) {
    for (final f in festivals) {
      final t = _timeOf(f, y);
      if (t != null && t.start.isAfter(d)) out.add(t);
    }
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  return out.take(count).toList();
}
