// The guided main-quest chain. Each quest watches one stat key in
// Farm.stats; non-absolute quests count from the value when they started.

class QuestDef {
  final String text, key;
  final int target, coins, xp;
  final bool absolute;
  const QuestDef(this.text, this.key, this.target, this.coins, this.xp,
      {this.absolute = false});
}

const questChain = [
  QuestDef('Gieo lúa trên 4 ô ruộng', 'plant:lua', 4, 30, 5),
  QuestDef('Thu hoạch 4 ô lúa chín', 'harvest:lua', 4, 40, 5),
  QuestDef('Phát quang 2 bụi rậm, gốc cây', 'clear', 2, 40, 5),
  QuestDef('Làm thêm 2 luống rau màu', 'build:luong', 2, 40, 5),
  QuestDef('Trồng 3 luống rau muống', 'plant:rau', 3, 50, 5),
  QuestDef('Giao 2 đơn hàng cho bà con', 'order', 2, 60, 8),
  QuestDef('Đạt cấp 2', 'level', 2, 50, 0, absolute: true),
  QuestDef('Xây chuồng gà', 'build:chuong_ga', 1, 60, 8),
  QuestDef('Mua 3 con gà', 'buy:ga', 3, 60, 8),
  QuestDef('Cho gà ăn thóc', 'feed:ga', 1, 40, 5),
  QuestDef('Thu 6 quả trứng gà', 'get:trung', 6, 80, 10),
  QuestDef('Đạt cấp 3', 'level', 3, 80, 0, absolute: true),
  QuestDef('Xây máy xay xát', 'build:may_xay', 1, 100, 10),
  QuestDef('Xay được 3 bao gạo', 'get:gao', 3, 100, 10),
  QuestDef('Góp công xây giếng làng', 'project:gieng', 1, 150, 15),
  QuestDef('Trồng 4 luống ngô', 'plant:ngo', 4, 100, 10),
  QuestDef('Mua thêm một mảnh đất', 'lot', 1, 200, 20),
  QuestDef('Đào ao cá', 'build:ao', 1, 150, 15),
  QuestDef('Thả cá rô phi xuống ao', 'stock:caro', 1, 100, 10),
  QuestDef('Trồng một cây chuối', 'build:cay_chuoi', 1, 120, 10),
  QuestDef('Nâng cấp lên nhà gạch mái ngói', 'house', 1, 300, 30, absolute: true),
  QuestDef('Xây cổng làng', 'project:cong_lang', 1, 300, 30),
  QuestDef('Giao 15 đơn hàng', 'order', 15, 400, 40),
  QuestDef('Bê tông hóa đường làng', 'project:duong_be_tong', 1, 500, 50),
  QuestDef('Xây chuồng vịt', 'build:chuong_vit', 1, 300, 30),
  QuestDef('Xây bếp làm bánh', 'build:lo_banh', 1, 400, 40),
  QuestDef('Xây trạm bơm thủy lợi', 'project:tram_bom', 1, 600, 60),
  QuestDef('Xây chuồng lợn', 'build:chuong_lon', 1, 500, 50),
  QuestDef('Gói 2 chiếc bánh chưng', 'get:banhchung', 2, 800, 80),
  QuestDef('Nâng cấp lên nhà mái bằng', 'house', 2, 1000, 100, absolute: true),
  QuestDef('Xây trường mầm non', 'project:truong', 1, 1200, 120),
  QuestDef('Nuôi trâu, bón phân cho 5 ruộng', 'fertilize', 5, 800, 80),
  QuestDef('Xây chợ quê', 'project:cho_que', 1, 2000, 200),
  QuestDef('Giao 60 đơn hàng', 'order', 60, 2500, 250),
  QuestDef('Xây đình làng', 'project:dinh_lang', 1, 5000, 500),
];
