// Static game content: items, crops, animals, fish, trees, recipes,
// buildings and village projects. Everything the farm logic and the
// renderer look up by id lives here.

import 'dart:math' as math;
import 'dart:ui' show Color;

class ItemDef {
  final String id, name, icon;
  final int price; // base market price in xu
  final Color color; // badge colour behind the icon
  const ItemDef(this.id, this.name, this.icon, this.price, this.color);
}

const items = <String, ItemDef>{
  // field crops
  'thoc': ItemDef('thoc', 'Thóc', '🌾', 3, Color(0xFFE8C766)),
  'rom': ItemDef('rom', 'Rơm', '🌾', 2, Color(0xFFC9A55A)),
  'rau': ItemDef('rau', 'Rau muống', '🥬', 5, Color(0xFF7CC46A)),
  'ngo': ItemDef('ngo', 'Ngô', '🌽', 9, Color(0xFFF2D04E)),
  'khoai': ItemDef('khoai', 'Khoai lang', '🍠', 14, Color(0xFFB0577A)),
  'lac': ItemDef('lac', 'Lạc', '🥜', 20, Color(0xFFD9A066)),
  'dau': ItemDef('dau', 'Đậu xanh', '🫛', 25, Color(0xFF8BC34A)),
  'nep': ItemDef('nep', 'Thóc nếp', '🌾', 22, Color(0xFFF5E2A8)),
  'mia': ItemDef('mia', 'Mía', '🎋', 40, Color(0xFF9C5FB5)),
  'ot': ItemDef('ot', 'Ớt', '🌶️', 34, Color(0xFFE5533D)),
  'dua': ItemDef('dua', 'Dưa hấu', '🍉', 62, Color(0xFF4CAF50)),
  'cuc': ItemDef('cuc', 'Hoa cúc', '🌼', 78, Color(0xFFFFC93C)),
  'dautuong': ItemDef('dautuong', 'Đậu tương', '🫘', 30, Color(0xFFE6C77A)),
  'che': ItemDef('che', 'Chè búp', '🍃', 45, Color(0xFF6BAA45)),
  'thoctam': ItemDef('thoctam', 'Thóc tám thơm', '🌾', 26, Color(0xFFF0D98A)),
  // animals
  'trung': ItemDef('trung', 'Trứng gà', '🥚', 12, Color(0xFFF3E3C3)),
  'trungvit': ItemDef('trungvit', 'Trứng vịt', '🥚', 18, Color(0xFFB9DCD2)),
  'thit': ItemDef('thit', 'Thịt lợn', '🥩', 70, Color(0xFFF08A8A)),
  'sua': ItemDef('sua', 'Sữa bò', '🥛', 55, Color(0xFFE3EEF7)),
  'phan': ItemDef('phan', 'Phân chuồng', '💩', 30, Color(0xFF8D6E4C)),
  'suade': ItemDef('suade', 'Sữa dê', '🍼', 75, Color(0xFFF1F1E6)),
  'matong': ItemDef('matong', 'Mật ong', '🍯', 120, Color(0xFFFFB300)),
  // fish
  'caro': ItemDef('caro', 'Cá rô phi', '🐟', 16, Color(0xFF7FB3D5)),
  'catram': ItemDef('catram', 'Cá trắm', '🐟', 30, Color(0xFF5D8AA8)),
  'cachep': ItemDef('cachep', 'Cá chép', '🐠', 48, Color(0xFFF0A040)),
  'tom': ItemDef('tom', 'Tôm càng', '🦐', 70, Color(0xFFF07860)),
  // fruit
  'chuoi': ItemDef('chuoi', 'Chuối', '🍌', 15, Color(0xFFFFE066)),
  'xoai': ItemDef('xoai', 'Xoài', '🥭', 32, Color(0xFFFFB347)),
  'dua_xiem': ItemDef('dua_xiem', 'Dừa', '🥥', 40, Color(0xFFA1887F)),
  'buoi': ItemDef('buoi', 'Bưởi', '🍈', 55, Color(0xFFC5E1A5)),
  'vai': ItemDef('vai', 'Vải thiều', '🍒', 70, Color(0xFFE57373)),
  'nhan': ItemDef('nhan', 'Nhãn lồng', '🌰', 95, Color(0xFFC8A165)),
  'hong': ItemDef('hong', 'Hồng', '🟠', 85, Color(0xFFFF8A3D)),
  // processed
  'gao': ItemDef('gao', 'Gạo', '🍚', 14, Color(0xFFFFFFFF)),
  'cam': ItemDef('cam', 'Cám', '🟫', 5, Color(0xFFBCAAA4)),
  'banhda': ItemDef('banhda', 'Bánh đa', '🫓', 40, Color(0xFFF5DEB3)),
  'xoi': ItemDef('xoi', 'Xôi lạc', '🍙', 95, Color(0xFFFFF3D6)),
  'banhchung': ItemDef('banhchung', 'Bánh chưng', '🟩', 280, Color(0xFF66BB6A)),
  'banhngo': ItemDef('banhngo', 'Bánh ngô', '🥮', 120, Color(0xFFFFD54F)),
  'nuocmia': ItemDef('nuocmia', 'Nước mía', '🧃', 100, Color(0xFFDCE775)),
  'duong': ItemDef('duong', 'Đường', '🍬', 140, Color(0xFFF8BBD0)),
  'keolac': ItemDef('keolac', 'Kẹo lạc', '🍫', 230, Color(0xFFBF8F5E)),
  'nuocmam': ItemDef('nuocmam', 'Nước mắm', '🍶', 110, Color(0xFFC08B4B)),
  'tuongot': ItemDef('tuongot', 'Tương ớt', '🥫', 260, Color(0xFFD84315)),
  'chaca': ItemDef('chaca', 'Chả cá', '🍥', 150, Color(0xFFFFCC80)),
  'sinhto': ItemDef('sinhto', 'Sinh tố xoài', '🥤', 150, Color(0xFFFFB74D)),
  'dauphu': ItemDef('dauphu', 'Đậu phụ', '⬜', 130, Color(0xFFFFF8E1)),
  'suadaunanh': ItemDef('suadaunanh', 'Sữa đậu nành', '🥛', 240, Color(0xFFFFECB3)),
  'phomai': ItemDef('phomai', 'Phô mai dê', '🧀', 320, Color(0xFFFFE082)),
  'chekho': ItemDef('chekho', 'Chè khô', '🍵', 190, Color(0xFF8BAA5A)),
  'chemat': ItemDef('chemat', 'Trà mật ong', '🧋', 400, Color(0xFFD7A54B)),
  'hongsay': ItemDef('hongsay', 'Hồng sấy', '🍊', 340, Color(0xFFE67E22)),
  'gaotam': ItemDef('gaotam', 'Gạo tám thơm', '🍚', 105, Color(0xFFFFFDF5)),
  'com': ItemDef('com', 'Cốm làng Vòng', '🟢', 110, Color(0xFFA5D66B)),
  'banhdauxanh': ItemDef('banhdauxanh', 'Bánh đậu xanh', '🟨', 300, Color(0xFFFFE57F)),
  'banhcom': ItemDef('banhcom', 'Bánh cốm', '🟩', 460, Color(0xFF7CB342)),
};

ItemDef item(String id) => items[id]!;

/// Which kind of plot a crop grows on.
enum Plot { paddy, bed }

class CropDef {
  final String id, name;
  final Plot plot;
  final int level, seconds, seed, yield, xp;
  final String product;
  final String? bonus; // extra item on harvest (rơm from rice)
  const CropDef(this.id, this.name, this.plot, this.level, this.seconds,
      this.seed, this.product, this.yield, this.xp, {this.bonus});
}

const crops = <String, CropDef>{
  'lua': CropDef('lua', 'Lúa', Plot.paddy, 1, 120, 1, 'thoc', 2, 1, bonus: 'rom'),
  'rau': CropDef('rau', 'Rau muống', Plot.bed, 1, 240, 2, 'rau', 2, 1),
  'ngo': CropDef('ngo', 'Ngô', Plot.bed, 2, 480, 4, 'ngo', 2, 2),
  'khoai': CropDef('khoai', 'Khoai lang', Plot.bed, 3, 900, 6, 'khoai', 2, 3),
  'lac': CropDef('lac', 'Lạc', Plot.bed, 5, 1500, 8, 'lac', 2, 4),
  'dau': CropDef('dau', 'Đậu xanh', Plot.bed, 6, 2100, 10, 'dau', 2, 5),
  'nep': CropDef('nep', 'Lúa nếp', Plot.paddy, 7, 1800, 8, 'nep', 2, 5, bonus: 'rom'),
  'mia': CropDef('mia', 'Mía', Plot.bed, 9, 3600, 15, 'mia', 2, 7),
  'ot': CropDef('ot', 'Ớt', Plot.bed, 11, 2700, 12, 'ot', 2, 6),
  'dua': CropDef('dua', 'Dưa hấu', Plot.bed, 13, 5400, 20, 'dua', 2, 9),
  'cuc': CropDef('cuc', 'Hoa cúc', Plot.bed, 15, 7200, 25, 'cuc', 2, 11),
  'dautuong': CropDef('dautuong', 'Đậu tương', Plot.bed, 20, 3600, 18, 'dautuong', 2, 9),
  'che': CropDef('che', 'Chè', Plot.bed, 22, 6000, 22, 'che', 2, 12),
  'tam': CropDef('tam', 'Lúa tám thơm', Plot.paddy, 25, 4800, 20, 'thoctam', 2, 11, bonus: 'rom'),
};

class TreeDef {
  final String id, name, product;
  final int level, cost, seconds, yield, xp;
  const TreeDef(this.id, this.name, this.level, this.cost, this.seconds,
      this.product, this.yield, this.xp);
}

const trees = <String, TreeDef>{
  'cay_chuoi': TreeDef('cay_chuoi', 'Cây chuối', 4, 150, 1800, 'chuoi', 3, 3),
  'cay_xoai': TreeDef('cay_xoai', 'Cây xoài', 8, 400, 3600, 'xoai', 3, 5),
  'cay_dua': TreeDef('cay_dua', 'Cây dừa', 11, 650, 5400, 'dua_xiem', 3, 7),
  'cay_buoi': TreeDef('cay_buoi', 'Cây bưởi', 14, 900, 7200, 'buoi', 3, 9),
  'cay_vai': TreeDef('cay_vai', 'Cây vải', 17, 1300, 9000, 'vai', 3, 11),
  'cay_nhan': TreeDef('cay_nhan', 'Cây nhãn', 23, 1800, 10800, 'nhan', 3, 13),
  'cay_hong': TreeDef('cay_hong', 'Cây hồng', 27, 2400, 12600, 'hong', 3, 15),
};

class AnimalDef {
  final String id, name, pen, feed, product;
  final int level, price, seconds, maxCount, xp;
  const AnimalDef(this.id, this.name, this.pen, this.level, this.price,
      this.feed, this.product, this.seconds, this.maxCount, this.xp);
}

const animals = <String, AnimalDef>{
  'ga': AnimalDef('ga', 'Gà', 'chuong_ga', 2, 30, 'thoc', 'trung', 600, 6, 1),
  'vit': AnimalDef('vit', 'Vịt', 'chuong_vit', 6, 60, 'thoc', 'trungvit', 1200, 6, 2),
  'lon': AnimalDef('lon', 'Lợn', 'chuong_lon', 8, 150, 'cam', 'thit', 3600, 4, 6),
  'bo': AnimalDef('bo', 'Bò sữa', 'chuong_bo', 12, 300, 'rom', 'sua', 2700, 4, 5),
  'trau': AnimalDef('trau', 'Trâu', 'chuong_trau', 10, 250, 'rom', 'phan', 2400, 3, 4),
  'de': AnimalDef('de', 'Dê', 'chuong_de', 21, 400, 'rau', 'suade', 3000, 4, 7),
  'ong': AnimalDef('ong', 'Đàn ong', 'vuon_ong', 24, 500, 'cuc', 'matong', 3600, 3, 9),
};

AnimalDef? animalForPen(String pen) {
  for (final a in animals.values) {
    if (a.pen == pen) return a;
  }
  return null;
}

class FishDef {
  final String id, name, product;
  final int level, fry, seconds, yield, xp;
  const FishDef(this.id, this.name, this.level, this.fry, this.seconds,
      this.product, this.yield, this.xp);
}

const fishes = <String, FishDef>{
  'caro': FishDef('caro', 'Cá rô phi', 4, 20, 1800, 'caro', 4, 3),
  'catram': FishDef('catram', 'Cá trắm', 9, 45, 3600, 'catram', 4, 6),
  'cachep': FishDef('cachep', 'Cá chép', 13, 80, 5400, 'cachep', 4, 9),
  'tom': FishDef('tom', 'Tôm càng', 17, 120, 7200, 'tom', 4, 12),
};

class RecipeDef {
  final String id, building, product;
  final Map<String, int> inputs;
  final int out, seconds, level, xp;
  const RecipeDef(this.id, this.building, this.level, this.inputs,
      this.product, this.out, this.seconds, this.xp);
}

const recipes = <String, RecipeDef>{
  'gao': RecipeDef('gao', 'may_xay', 3, {'thoc': 3}, 'gao', 1, 180, 1),
  'cam': RecipeDef('cam', 'may_xay', 3, {'thoc': 2}, 'cam', 2, 120, 1),
  'banhda': RecipeDef('banhda', 'lo_banh', 7, {'gao': 2}, 'banhda', 1, 900, 3),
  'xoi': RecipeDef('xoi', 'lo_banh', 7, {'nep': 2, 'lac': 1}, 'xoi', 1, 1200, 5),
  'banhngo': RecipeDef('banhngo', 'lo_banh', 12, {'ngo': 2, 'sua': 1}, 'banhngo', 1, 1800, 7),
  'banhchung': RecipeDef('banhchung', 'lo_banh', 9,
      {'nep': 2, 'dau': 1, 'thit': 1}, 'banhchung', 1, 3600, 12),
  'nuocmia': RecipeDef('nuocmia', 'xuong_mia', 10, {'mia': 2}, 'nuocmia', 1, 300, 4),
  'duong': RecipeDef('duong', 'xuong_mia', 10, {'mia': 3}, 'duong', 1, 1800, 6),
  'keolac': RecipeDef('keolac', 'xuong_mia', 11, {'lac': 2, 'duong': 1}, 'keolac', 1, 2400, 9),
  'sinhto': RecipeDef('sinhto', 'xuong_mia', 12, {'xoai': 2, 'sua': 1}, 'sinhto', 1, 900, 6),
  'nuocmam': RecipeDef('nuocmam', 'xuong_ca', 13, {'caro': 4}, 'nuocmam', 1, 3600, 7),
  'chaca': RecipeDef('chaca', 'xuong_ca', 13, {'catram': 2, 'trung': 1}, 'chaca', 1, 1800, 8),
  'tuongot': RecipeDef('tuongot', 'xuong_ca', 14, {'ot': 3, 'duong': 1}, 'tuongot', 1, 2700, 10),
  'gaotam': RecipeDef('gaotam', 'may_xay', 25, {'thoctam': 3}, 'gaotam', 1, 600, 6),
  'com': RecipeDef('com', 'may_xay', 26, {'nep': 3}, 'com', 1, 1500, 8),
  'banhdauxanh': RecipeDef('banhdauxanh', 'lo_banh', 23, {'dau': 3, 'duong': 1}, 'banhdauxanh', 1, 2700, 12),
  'banhcom': RecipeDef('banhcom', 'lo_banh', 27, {'com': 2, 'duong': 1}, 'banhcom', 1, 3000, 14),
  'dauphu': RecipeDef('dauphu', 'xuong_dau', 20, {'dautuong': 3}, 'dauphu', 1, 1800, 9),
  'suadaunanh': RecipeDef('suadaunanh', 'xuong_dau', 21, {'dautuong': 2, 'duong': 1}, 'suadaunanh', 1, 1500, 10),
  'phomai': RecipeDef('phomai', 'xuong_dau', 28, {'suade': 3}, 'phomai', 1, 3600, 16),
  'chekho': RecipeDef('chekho', 'xuong_che', 22, {'che': 3}, 'chekho', 1, 2700, 12),
  'chemat': RecipeDef('chemat', 'xuong_che', 24, {'chekho': 1, 'matong': 1}, 'chemat', 1, 2400, 15),
  'hongsay': RecipeDef('hongsay', 'xuong_che', 29, {'hong': 3}, 'hongsay', 1, 4200, 17),
};

List<RecipeDef> recipesFor(String building) =>
    recipes.values.where((r) => r.building == building).toList();

enum BKind { paddy, bed, pen, pond, tree, factory, house, storage, project, deco, obstacle }

class BuildingDef {
  final String id, name, desc;
  final BKind kind;
  final int w, h, level, cost, xp;
  final Map<String, int> goods; // goods contributed (projects)
  final bool unique;
  const BuildingDef(this.id, this.name, this.kind, this.w, this.h, this.level,
      this.cost,
      {this.desc = '', this.xp = 0, this.goods = const {}, this.unique = false});
}

const buildings = <String, BuildingDef>{
  'ruong': BuildingDef('ruong', 'Ruộng lúa', BKind.paddy, 1, 1, 1, 10,
      desc: 'Ô ruộng nước để cấy lúa.'),
  'luong': BuildingDef('luong', 'Luống rau màu', BKind.bed, 1, 1, 1, 10,
      desc: 'Luống đất trồng rau, ngô, khoai, lạc, mía...'),
  'chuong_ga': BuildingDef('chuong_ga', 'Chuồng gà', BKind.pen, 2, 2, 2, 150,
      desc: 'Gà ăn thóc, đẻ trứng.', xp: 5),
  'ao': BuildingDef('ao', 'Ao cá', BKind.pond, 2, 2, 4, 300,
      desc: 'Đào ao thả cá, tôm.', xp: 8),
  'chuong_vit': BuildingDef('chuong_vit', 'Chuồng vịt', BKind.pen, 2, 2, 6, 400,
      desc: 'Vịt ăn thóc, đẻ trứng vịt.', xp: 10),
  'chuong_lon': BuildingDef('chuong_lon', 'Chuồng lợn', BKind.pen, 2, 2, 8, 800,
      desc: 'Lợn ăn cám, cho thịt.', xp: 15),
  'chuong_trau': BuildingDef('chuong_trau', 'Chuồng trâu', BKind.pen, 2, 2, 10, 1200,
      desc: 'Trâu ăn rơm, cho phân chuồng để bón ruộng.', xp: 18),
  'chuong_bo': BuildingDef('chuong_bo', 'Chuồng bò', BKind.pen, 2, 2, 12, 1600,
      desc: 'Bò sữa ăn rơm, cho sữa.', xp: 22),
  'nha_kho': BuildingDef('nha_kho', 'Nhà kho', BKind.storage, 2, 2, 3, 600,
      desc: 'Thêm chỗ chứa nông sản cho kho chung. Nâng cấp được.', xp: 10),
  'may_xay': BuildingDef('may_xay', 'Máy xay xát', BKind.factory, 2, 2, 3, 400,
      desc: 'Xay thóc thành gạo và cám.', xp: 8),
  'lo_banh': BuildingDef('lo_banh', 'Bếp làm bánh', BKind.factory, 2, 2, 7, 1200,
      desc: 'Bánh đa, xôi lạc, bánh chưng, bánh ngô.', xp: 15),
  'xuong_mia': BuildingDef('xuong_mia', 'Xưởng mía đường', BKind.factory, 2, 2, 10, 2000,
      desc: 'Nước mía, đường, kẹo lạc, sinh tố.', xp: 20),
  'xuong_ca': BuildingDef('xuong_ca', 'Xưởng nước mắm', BKind.factory, 2, 2, 13, 3200,
      desc: 'Nước mắm, chả cá, tương ớt.', xp: 25),
  'chuong_de': BuildingDef('chuong_de', 'Chuồng dê', BKind.pen, 2, 2, 21, 2200,
      desc: 'Dê ăn rau, cho sữa dê.', xp: 26),
  'vuon_ong': BuildingDef('vuon_ong', 'Vườn ong', BKind.pen, 2, 2, 24, 2800,
      desc: 'Ong hút mật hoa cúc, cho mật ong.', xp: 30),
  'xuong_dau': BuildingDef('xuong_dau', 'Xưởng đậu phụ', BKind.factory, 2, 2, 20, 4500,
      desc: 'Đậu phụ, sữa đậu nành, phô mai dê.', xp: 30),
  'xuong_che': BuildingDef('xuong_che', 'Lò sao sấy', BKind.factory, 2, 2, 22, 6000,
      desc: 'Sao chè khô, pha trà mật ong, sấy hồng.', xp: 35),
  'cay_nhan': BuildingDef('cay_nhan', 'Cây nhãn', BKind.tree, 1, 1, 23, 1800),
  'cay_hong': BuildingDef('cay_hong', 'Cây hồng', BKind.tree, 1, 1, 27, 2400),
  'cay_chuoi': BuildingDef('cay_chuoi', 'Cây chuối', BKind.tree, 1, 1, 4, 150),
  'cay_xoai': BuildingDef('cay_xoai', 'Cây xoài', BKind.tree, 1, 1, 8, 400),
  'cay_dua': BuildingDef('cay_dua', 'Cây dừa', BKind.tree, 1, 1, 11, 650),
  'cay_buoi': BuildingDef('cay_buoi', 'Cây bưởi', BKind.tree, 1, 1, 14, 900),
  'cay_vai': BuildingDef('cay_vai', 'Cây vải', BKind.tree, 1, 1, 17, 1300),
  'nha': BuildingDef('nha', 'Nhà', BKind.house, 3, 3, 1, 0, unique: true),
  'nha_phu': BuildingDef('nha_phu', 'Nhà con cháu', BKind.house, 3, 3, 20, 60000, xp: 300,
      desc: 'Nhà cho con cháu ra ở riêng: thêm chỗ chứa và con cháu phụ giao hàng (+5% xu mỗi đơn). Nâng cấp được như nhà chính.'),
  // decorations
  'rom_dong': BuildingDef('rom_dong', 'Đống rơm', BKind.deco, 1, 1, 2, 40, xp: 1),
  'chum': BuildingDef('chum', 'Chum nước', BKind.deco, 1, 1, 3, 60, xp: 1),
  'bu_nhin': BuildingDef('bu_nhin', 'Bù nhìn', BKind.deco, 1, 1, 4, 80, xp: 1),
  'cho': BuildingDef('cho', 'Chó giữ nhà', BKind.deco, 1, 1, 5, 400, xp: 5, unique: true,
      desc: 'Cho ăn mỗi ngày để chó canh vườn: thêm 25% bắt kẻ hái trộm.'),
  'hoa_dao': BuildingDef('hoa_dao', 'Cây đào', BKind.deco, 1, 1, 6, 200, xp: 2),
  'tre': BuildingDef('tre', 'Bụi tre', BKind.deco, 1, 1, 2, 50, xp: 1),
  'cay_da': BuildingDef('cay_da', 'Cây đa', BKind.deco, 2, 2, 9, 600, xp: 5),
  // obstacles on new land
  'bui': BuildingDef('bui', 'Bụi rậm', BKind.obstacle, 1, 1, 1, 15, xp: 1),
  'da': BuildingDef('da', 'Tảng đá', BKind.obstacle, 1, 1, 1, 40, xp: 2),
  'goc_cay': BuildingDef('goc_cay', 'Gốc cây', BKind.obstacle, 1, 1, 1, 30, xp: 2),
  // village projects (Nông thôn mới)
  'gieng': BuildingDef('gieng', 'Giếng làng', BKind.project, 1, 1, 3, 300,
      goods: {'thoc': 10}, unique: true, xp: 20,
      desc: 'Nước sạch tưới rau: luống rau màu lớn nhanh hơn 10%.'),
  // 3 tiles wide: pillars on the grass either side, the arch over the road.
  'cong_lang': BuildingDef('cong_lang', 'Cổng làng', BKind.project, 3, 1, 5, 1200,
      goods: {'rom': 10, 'gao': 5}, unique: true, xp: 40,
      desc: 'Cổng làng khang trang: +10% kinh nghiệm.'),
  'duong_be_tong': BuildingDef('duong_be_tong', 'Bê tông hóa đường làng',
      BKind.project, 0, 0, 6, 2000,
      goods: {'gao': 10, 'trung': 10}, unique: true, xp: 60,
      desc: 'Đường làng đổ bê tông, xe vào tận nơi: đơn hàng thưởng thêm 10% xu.'),
  'tram_bom': BuildingDef('tram_bom', 'Trạm bơm thủy lợi', BKind.project, 2, 2, 7, 3000,
      goods: {'thoc': 30, 'rau': 10}, unique: true, xp: 80,
      desc: 'Dẫn nước vào đồng: ruộng lúa chín nhanh hơn 20%.'),
  'tram_dien': BuildingDef('tram_dien', 'Trạm biến áp', BKind.project, 1, 1, 9, 4500,
      goods: {'ngo': 10, 'khoai': 10}, unique: true, xp: 100,
      desc: 'Điện về làng: máy móc chế biến nhanh hơn 20%.'),
  'truong': BuildingDef('truong', 'Trường mầm non', BKind.project, 3, 2, 10, 6000,
      goods: {'trung': 15, 'gao': 15, 'sua': 5}, unique: true, xp: 140,
      desc: 'Con em có chỗ học: +15% kinh nghiệm.'),
  'tram_y_te': BuildingDef('tram_y_te', 'Trạm y tế xã', BKind.project, 2, 2, 12, 8000,
      goods: {'trungvit': 10, 'chuoi': 10}, unique: true, xp: 170,
      desc: 'Thú y và y tế: vật nuôi cho sản phẩm nhanh hơn 15%.'),
  'cho_que': BuildingDef('cho_que', 'Chợ quê', BKind.project, 3, 3, 13, 11000,
      goods: {'thit': 5, 'caro': 10, 'rau': 20}, unique: true, xp: 200,
      desc: 'Chợ phiên đông vui: bán ở chợ được giá hơn 15%, thêm 1 ô đơn hàng.'),
  'nha_van_hoa': BuildingDef('nha_van_hoa', 'Nhà văn hóa thôn', BKind.project, 3, 2, 15, 16000,
      goods: {'xoi': 5, 'nuocmia': 5}, unique: true, xp: 260,
      desc: 'Nơi sinh hoạt cộng đồng: thêm 1 ô đơn hàng, đơn thưởng thêm 10% xu.'),
  'dinh_lang': BuildingDef('dinh_lang', 'Đình làng', BKind.project, 3, 3, 18, 30000,
      goods: {'banhchung': 5, 'cuc': 10, 'nuocmam': 3}, unique: true, xp: 400,
      desc: 'Hội làng mỗi năm: mọi thứ lớn nhanh hơn 10%.'),
};

BuildingDef bdef(String id) => buildings[id]!;

const projectOrder = [
  'gieng', 'cong_lang', 'duong_be_tong', 'tram_bom', 'tram_dien', 'truong',
  'tram_y_te', 'cho_que', 'nha_van_hoa', 'dinh_lang',
];

/// Upgrades of a finished village project (to level 2, then 3).
class ProjectUpgrade {
  final int level, coins;
  final Map<String, int> goods;
  const ProjectUpgrade(this.level, this.coins, this.goods);
}

const projectUpgrades = <String, List<ProjectUpgrade>>{
  'gieng': [
    ProjectUpgrade(20, 3000, {'dautuong': 10, 'rau': 30}),
    ProjectUpgrade(25, 9000, {'che': 15, 'dauphu': 5}),
  ],
  'cong_lang': [
    ProjectUpgrade(20, 5000, {'gao': 30, 'rom': 30}),
    ProjectUpgrade(26, 14000, {'gaotam': 10, 'banhdauxanh': 3}),
  ],
  'duong_be_tong': [
    ProjectUpgrade(21, 6000, {'gao': 30, 'trungvit': 20}),
    ProjectUpgrade(26, 16000, {'dauphu': 8, 'nuocmam': 5}),
  ],
  'tram_bom': [
    ProjectUpgrade(21, 7000, {'thoc': 60, 'nep': 20}),
    ProjectUpgrade(27, 18000, {'thoctam': 30, 'gaotam': 10}),
  ],
  'tram_dien': [
    ProjectUpgrade(22, 9000, {'ngo': 30, 'duong': 5}),
    ProjectUpgrade(27, 20000, {'suadaunanh': 5, 'chekho': 5}),
  ],
  'truong': [
    ProjectUpgrade(22, 11000, {'sua': 15, 'banhngo': 5}),
    ProjectUpgrade(28, 24000, {'suade': 15, 'banhdauxanh': 5}),
  ],
  'tram_y_te': [
    ProjectUpgrade(23, 13000, {'chuoi': 30, 'trung': 30}),
    ProjectUpgrade(28, 26000, {'matong': 10, 'phomai': 3}),
  ],
  'cho_que': [
    ProjectUpgrade(23, 16000, {'thit': 15, 'cachep': 10}),
    ProjectUpgrade(29, 32000, {'chemat': 5, 'hongsay': 3}),
  ],
  'nha_van_hoa': [
    ProjectUpgrade(24, 20000, {'xoi': 10, 'keolac': 5}),
    ProjectUpgrade(29, 38000, {'banhcom': 5, 'chemat': 5}),
  ],
  'dinh_lang': [
    ProjectUpgrade(25, 40000, {'banhchung': 10, 'nhan': 15}),
    ProjectUpgrade(30, 80000, {'banhcom': 10, 'hongsay': 5, 'phomai': 5}),
  ],
};

/// What a project does: text with {p} for its percentage, and the base
/// percentage at level 1 (×1.5 at level 2, ×2 at level 3).
const projectEffects = <String, (String, int)>{
  'gieng': ('Luống rau màu lớn nhanh hơn {p}%', 10),
  'cong_lang': ('+{p}% kinh nghiệm', 10),
  'duong_be_tong': ('Đơn hàng thưởng thêm {p}% xu', 10),
  'tram_bom': ('Ruộng lúa chín nhanh hơn {p}%', 20),
  'tram_dien': ('Máy móc chế biến nhanh hơn {p}%', 20),
  'truong': ('+{p}% kinh nghiệm', 15),
  'tram_y_te': ('Vật nuôi cho sản phẩm nhanh hơn {p}%', 15),
  'cho_que': ('Bán ở chợ được giá hơn {p}%, thêm 1 ô đơn hàng', 15),
  'nha_van_hoa': ('Thêm 1 ô đơn hàng, đơn thưởng thêm {p}% xu', 10),
  'dinh_lang': ('Mọi thứ lớn nhanh hơn {p}%', 10),
};

const projectMult = [1.0, 1.5, 2.0];

String projectEffect(String id, int lv) {
  final e = projectEffects[id]!;
  return e.$1.replaceAll('{p}', '${(e.$2 * projectMult[lv - 1]).round()}');
}

/// Village title by number of finished projects.
String villageTitle(int done) {
  if (done >= 10) return 'Nông thôn mới kiểu mẫu';
  if (done >= 8) return 'Nông thôn mới nâng cao';
  if (done >= 6) return 'Xã Nông thôn mới';
  if (done >= 4) return 'Làng văn hóa';
  if (done >= 2) return 'Thôn khá';
  return 'Thôn nghèo';
}

class HouseLevel {
  final String name;
  final int level, cost, storage;
  const HouseLevel(this.name, this.level, this.cost, this.storage);
}

/// A warehouse (nhà kho) per level: name, extra storage, cost to reach it.
class WarehouseLevel {
  final String name;
  final int storage, cost, level;
  const WarehouseLevel(this.name, this.storage, this.cost, this.level);
}

const warehouseLevels = [
  WarehouseLevel('Nhà kho gỗ', 60, 0, 3),
  WarehouseLevel('Nhà kho gạch', 120, 3000, 8),
  WarehouseLevel('Nhà kho lớn', 200, 9000, 13),
];

/// Extra houses (nhà con cháu): the n-th one needs this level and price.
const extraHouseLevels = [20, 26, 32];
const extraHouseBuildCost = [60000, 180000, 450000];
/// Each extra house adds this share of its level's storage, and order coins.
const extraHouseStorage = .5, extraHouseOrderBonus = .05;

/// At most this many warehouses; each one built costs more.
const warehouseMax = 3;
const warehouseBuildCost = [600, 2500, 7000];

const houseLevels = [
  HouseLevel('Nhà tranh vách đất', 1, 0, 60),
  HouseLevel('Nhà gạch mái ngói', 5, 2000, 120),
  HouseLevel('Nhà mái bằng', 9, 7000, 200),
  HouseLevel('Nhà ống hai tầng', 14, 20000, 300),
  HouseLevel('Biệt thự nhà vườn', 19, 50000, 450),
];

int xpToNext(int level) => (20 * math.pow(level, 1.55)).round();

/// Land is sold in lots of [lotSize]×[lotSize] tiles.
/// The map grew from 24 (4x4 lots) to 36 (6x6 lots) on 2026-11-04; older
/// saves are moved over in Farm.fromJson (see legacyMapSize).
const mapSize = 36, lotSize = 6, lotsPerSide = mapSize ~/ lotSize;
const legacyMapSize = 24;

int lotPrice(int nth) => const [0, 0, 400, 1000, 2000, 3500, 5500, 8000,
    11000, 15000, 20000, 26000, 33000, 41000, 50000, 60000,
    // the outer ring added with the bigger map
    80000, 92000, 105000, 120000, 137000, 156000, 178000, 203000, 231000, 263000,
    300000, 342000, 390000, 445000, 507000, 578000, 659000, 751000, 856000, 980000][nth.clamp(0, 35)];
int lotLevel(int nth) => const [1, 1, 2, 4, 6, 8, 10, 12, 13, 14, 15, 16, 17,
    18, 19, 20,
    21, 21, 22, 22, 23, 24, 24, 25, 26, 26, 27, 28, 28, 29, 30, 31, 32, 33, 34, 35][nth.clamp(0, 35)];

const villagers = [
  'Bà Tư', 'Ông Sáu', 'Cô Lan', 'Chú Bảy', 'Anh Hai', 'Chị Ba', 'Bác Năm',
  'Thầy Minh', 'Cô Hoa', 'Ông Trưởng thôn', 'Bé Na', 'Chú Tám',
];
