// Sự kiện tuần (1.8.0): one theme a week, the same for every player
// (rotating by the calendar week), with five milestones and a weekly
// leaderboard. Points come from what the farm already makes, so a level-5
// farm takes part as well as a level-40 one. The rules are in
// farm_week.dart; this file is only data.

import 'calendar.dart' show festivalDecos;

/// What earns points in a theme.
enum WeekKind { field, animal, fruit, fish, craft, order }

class WeekTheme {
  final String id, name, icon, desc, deco;
  final WeekKind kind;

  /// Points needed for each of the five milestones.
  final List<int> targets;
  const WeekTheme(this.id, this.name, this.icon, this.desc, this.kind, this.targets, this.deco);
}

const weekThemes = [
  WeekTheme('duoc_mua', 'Tuần được mùa', '🌾', 'Mỗi nông sản thu hoạch ở ruộng lúa, luống rau màu được 1 điểm.',
      WeekKind.field, [80, 250, 600, 1200, 2400], 'bo_lua'),
  WeekTheme('chan_nuoi', 'Tuần chăn nuôi', '🐓', 'Mỗi trứng, sữa, thịt, mật... lấy ở chuồng trại được 1 điểm.',
      WeekKind.animal, [30, 100, 250, 500, 1000], 'o_ga'),
  WeekTheme('trai_cay', 'Hội chợ trái cây', '🍉', 'Mỗi quả hái trên cây ăn quả được 1 điểm.',
      WeekKind.fruit, [20, 60, 150, 300, 600], 'gian_bau'),
  WeekTheme('ao_ca', 'Tuần ao cá', '🐟', 'Mỗi con cá, tôm bắt ở ao hoặc câu ngoài sông được 1 điểm.',
      WeekKind.fish, [15, 50, 120, 250, 500], 'thuyen_nan'),
  WeekTheme('lang_nghe', 'Tuần làng nghề', '🏺', 'Mỗi món lấy ra từ máy xay, bếp bánh, xưởng chế biến được 1 điểm.',
      WeekKind.craft, [20, 70, 180, 400, 800], 'binh_gom'),
  WeekTheme('giao_hang', 'Tuần giao hàng', '🛺', 'Mỗi đơn thường được 1 điểm; đơn đặc biệt, đơn lễ hội được 3 điểm.',
      WeekKind.order, [5, 15, 35, 70, 120], 'xe_bo'),
];

/// Decorations only won in the weekly event (top milestone), never sold.
final eventDecos = {for (final t in weekThemes) t.deco};

/// Decorations that come as gifts (festivals, weekly event, packs) and go
/// back to the bag when removed.
bool isGiftDeco(String type) => festivalDecos.contains(type) || eventDecos.contains(type);

const weekLevel = 3;

/// Monday of the local week holding [ms], as a day key (20261116).
int weekKeyOf(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final m = DateTime(d.year, d.month, d.day - (d.weekday - 1), 12);
  return m.year * 10000 + m.month * 100 + m.day;
}

/// Weeks since Monday 5 Jan 1970: picks the theme, same for everyone.
int weekIndex(int key) {
  final m = DateTime.utc(key ~/ 10000, key ~/ 100 % 100, key % 100);
  return m.difference(DateTime.utc(1970, 1, 5)).inDays ~/ 7;
}

WeekTheme weekThemeOf(int key) => weekThemes[weekIndex(key) % weekThemes.length];

/// When the week holding [ms] ends (next local Monday 00:00).
int weekEndMs(int ms) {
  final k = weekKeyOf(ms);
  return DateTime(k ~/ 10000, k ~/ 100 % 100, k % 100 + 7).millisecondsSinceEpoch;
}

/// Milestone reward multipliers (coins and xp grow with the farm's level).
const weekCoinMult = [1, 2, 4, 7, 12];
const weekXpMult = [1, 2, 3, 5, 8];
int weekCoins(int tier, int level) => weekCoinMult[tier] * (60 + 15 * level);
int weekXp(int tier, int level) => weekXpMult[tier] * (5 + level);

/// Vé Xong ngay given at a milestone.
const weekTickets = [0, 0, 1, 0, 2];
