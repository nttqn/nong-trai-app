// Thành tựu: long-running goals in three tiers. The first tier unlocks a
// title (danh hiệu) the player can show on the region map.

import 'defs.dart';
import 'farm.dart';

class AchDef {
  final String id, icon, title, what;
  final List<int> tiers;
  final int Function(Farm f) value;
  const AchDef(this.id, this.icon, this.title, this.what, this.tiers, this.value);
}

/// Coins and xp for claiming tier 1, 2, 3.
const achCoins = [200, 1000, 5000];
const achXp = [20, 100, 400];

int _sum(Farm f, Iterable<String> keys) => keys.fold(0, (a, k) => a + (f.stats[k] ?? 0));
int _prefix(Farm f, String p) =>
    f.stats.entries.where((e) => e.key.startsWith(p)).fold(0, (a, e) => a + e.value);
int _s(Farm f, String k) => f.stats[k] ?? 0;

final achievements = <AchDef>[
  AchDef('harvest', '🌾', 'Lão nông tri điền', 'Thu hoạch ruộng, luống', [50, 300, 1500], (f) => _prefix(f, 'harvest:')),
  AchDef('animal', '🐄', 'Chủ trại chăn nuôi', 'Thu sản phẩm vật nuôi', [30, 200, 1000],
      (f) => _sum(f, {for (final a in animals.values) 'get:${a.product}'})),
  AchDef('fish', '🎣', 'Lão ngư', 'Bắt cá, tôm ở ao', [20, 120, 600],
      (f) => _sum(f, {for (final x in fishes.values) 'get:${x.product}'})),
  AchDef('fruit', '🍌', 'Chủ vườn cây trái', 'Hái quả', [30, 200, 1000],
      (f) => _sum(f, {for (final t in trees.values) 'get:${t.product}'})),
  AchDef('craft', '🏺', 'Nghệ nhân làng nghề', 'Làm hàng ở xưởng', [30, 200, 1000],
      (f) => _sum(f, {for (final r in recipes.values) 'get:${r.product}'})),
  AchDef('order', '📋', 'Thương lái', 'Giao đơn hàng', [20, 150, 600], (f) => _s(f, 'order')),
  AchDef('daily', '⭐', 'Người giữ chữ tín', 'Giao đơn đặc biệt', [5, 30, 100], (f) => _s(f, 'daily')),
  AchDef('project', '🏛️', 'Trưởng thôn', 'Xây công trình nông thôn mới', [3, 6, projectOrder.length],
      (f) => f.projects.length),
  AchDef('level', '👑', 'Đại điền chủ', 'Đạt cấp', [10, 20, 30], (f) => f.level),
  AchDef('login', '📅', 'Chăm chỉ', 'Ngày nhận quà đăng nhập', [7, 30, 100], (f) => _s(f, 'login')),
  AchDef('help', '🤝', 'Hàng xóm tốt bụng', 'Thu hoạch hộ hàng xóm', [10, 60, 250], (f) => _s(f, 'help')),
  AchDef('steal', '🧺', 'Vua trộm rau', 'Hái trộm thành công', [5, 40, 150], (f) => _s(f, 'steal')),
  AchDef('caught', '🪧', 'Kẻ trộm xui xẻo', 'Bị bắt quả tang', [1, 10, 40], (f) => _s(f, 'caught')),
  AchDef('market', '🛒', 'Chủ sạp chợ phiên', 'Bán hàng ở chợ phiên', [3, 25, 100], (f) => _s(f, 'market_sold')),
  AchDef('rich', '💰', 'Triệu phú làng', 'Xu đang có', [100000, 1000000, 10000000], (f) => f.coins),
];

AchDef? achById(String id) {
  for (final a in achievements) {
    if (a.id == id) return a;
  }
  return null;
}
