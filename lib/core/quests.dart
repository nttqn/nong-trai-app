// The guided main-quest chain. Each quest watches one stat key in
// Farm.stats; non-absolute quests count from the value when they started.
// "Build one X" and village projects are absolute: one built before the
// quest came up counts (a project can only be built once).

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
  QuestDef('Xây chuồng gà', 'build:chuong_ga', 1, 60, 8, absolute: true),
  QuestDef('Mua 3 con gà', 'buy:ga', 3, 60, 8),
  QuestDef('Cho gà ăn thóc', 'feed:ga', 1, 40, 5),
  QuestDef('Thu 6 quả trứng gà', 'get:trung', 6, 80, 10),
  QuestDef('Đạt cấp 3', 'level', 3, 80, 0, absolute: true),
  QuestDef('Xây máy xay xát', 'build:may_xay', 1, 100, 10, absolute: true),
  QuestDef('Xay được 3 bao gạo', 'get:gao', 3, 100, 10),
  QuestDef('Góp công xây giếng làng', 'project:gieng', 1, 150, 15, absolute: true),
  QuestDef('Trồng 4 luống ngô', 'plant:ngo', 4, 100, 10),
  QuestDef('Mua thêm một mảnh đất', 'lot', 1, 200, 20),
  QuestDef('Đào ao cá', 'build:ao', 1, 150, 15, absolute: true),
  QuestDef('Thả cá rô phi xuống ao', 'stock:caro', 1, 100, 10),
  QuestDef('Trồng một cây chuối', 'build:cay_chuoi', 1, 120, 10, absolute: true),
  QuestDef('Nâng cấp lên nhà gạch mái ngói', 'house', 1, 300, 30, absolute: true),
  QuestDef('Xây cổng làng', 'project:cong_lang', 1, 300, 30, absolute: true),
  QuestDef('Giao 15 đơn hàng', 'order', 15, 400, 40),
  QuestDef('Bê tông hóa đường làng', 'project:duong_be_tong', 1, 500, 50, absolute: true),
  QuestDef('Xây chuồng vịt', 'build:chuong_vit', 1, 300, 30, absolute: true),
  QuestDef('Xây bếp làm bánh', 'build:lo_banh', 1, 400, 40, absolute: true),
  QuestDef('Xây trạm bơm thủy lợi', 'project:tram_bom', 1, 600, 60, absolute: true),
  QuestDef('Xây chuồng lợn', 'build:chuong_lon', 1, 500, 50, absolute: true),
  QuestDef('Gói 2 chiếc bánh chưng', 'get:banhchung', 2, 800, 80),
  QuestDef('Nâng cấp lên nhà mái bằng', 'house', 2, 1000, 100, absolute: true),
  QuestDef('Xây trường mầm non', 'project:truong', 1, 1200, 120, absolute: true),
  QuestDef('Nuôi trâu, bón phân cho 5 ruộng', 'fertilize', 5, 800, 80),
  QuestDef('Xây chợ quê', 'project:cho_que', 1, 2000, 200, absolute: true),
  QuestDef('Giao 60 đơn hàng', 'order', 60, 2500, 250),
  QuestDef('Xây đình làng', 'project:dinh_lang', 1, 5000, 500, absolute: true),
  // cấp 20-30
  QuestDef('Trồng 6 luống đậu tương', 'plant:dautuong', 6, 1500, 150),
  QuestDef('Xây xưởng đậu phụ', 'build:xuong_dau', 1, 2000, 200, absolute: true),
  QuestDef('Giao 3 đơn đặc biệt', 'daily', 3, 2500, 250),
  QuestDef('Xây chuồng dê', 'build:chuong_de', 1, 2500, 250, absolute: true),
  QuestDef('Trồng 6 luống chè', 'plant:che', 6, 2500, 250),
  QuestDef('Xây lò sao sấy', 'build:xuong_che', 1, 3000, 300, absolute: true),
  QuestDef('Nâng cấp 2 công trình làng', 'project_up', 2, 4000, 400),
  QuestDef('Lập vườn ong', 'build:vuon_ong', 1, 4000, 400, absolute: true),
  QuestDef('Thu 5 hũ mật ong', 'get:matong', 5, 4000, 400),
  QuestDef('Cấy 8 ô lúa tám thơm', 'plant:tam', 8, 4500, 450),
  QuestDef('Làm 3 bánh cốm', 'get:banhcom', 3, 6000, 600),
  QuestDef('Giao 20 đơn đặc biệt', 'daily', 20, 8000, 800),
  QuestDef('Nâng đình làng lên cấp 3', 'project_lv:dinh_lang', 3, 15000, 1500, absolute: true),
];
