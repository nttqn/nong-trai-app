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

/// Bumped when quests are inserted into the chain; see Farm.fromJson.
const questChainVersion = 3;

/// Index where the 1.1 quests were inserted, and how many.
const questInsertAt = 14, questInserted = 2;

/// Length of the chain before 1.2 appended the cấp 31+ quests. A farm that
/// had finished it has questBase 0, so it restarts counting at the first
/// new quest (see Farm.fromJson).
const questChainV2Length = 50;

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
  // added in 1.1 (questChainVersion 2): saves from before are shifted
  QuestDef('Đạt cấp 4', 'level', 4, 100, 0, absolute: true),
  QuestDef('Dựng bù nhìn rơm giữ ruộng', 'build:bu_nhin', 1, 100, 10, absolute: true),
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
  // cấp 31+ (1.2, questChainVersion 3): only things that are always doable
  // again (no land or one-off buildings), so the chain never gets stuck
  QuestDef('Đạt cấp 31', 'level', 31, 8000, 0, absolute: true),
  QuestDef('Lên biệt thự nhà vườn', 'house', 4, 10000, 800, absolute: true),
  QuestDef('Nâng trường mầm non lên cấp 3', 'project_lv:truong', 3, 10000, 800, absolute: true),
  QuestDef('Thu 30 hũ mật ong', 'get:matong', 30, 10000, 900),
  QuestDef('Làm 10 túi hồng sấy', 'get:hongsay', 10, 12000, 1000),
  QuestDef('Đạt cấp 32', 'level', 32, 9000, 0, absolute: true),
  QuestDef('Nâng trạm y tế lên cấp 3', 'project_lv:tram_y_te', 3, 12000, 1000, absolute: true),
  QuestDef('Cấy và gặt 40 ô lúa tám thơm', 'harvest:tam', 40, 12000, 1000),
  QuestDef('Làm 10 bánh phô mai dê', 'get:phomai', 10, 14000, 1100),
  QuestDef('Giao 30 đơn đặc biệt', 'daily', 30, 15000, 1200),
  QuestDef('Đạt cấp 34', 'level', 34, 10000, 0, absolute: true),
  QuestDef('Nâng chợ quê lên cấp 3', 'project_lv:cho_que', 3, 15000, 1200, absolute: true),
  QuestDef('Thu 60 quả hồng', 'get:hong', 60, 15000, 1200),
  QuestDef('Pha 15 ấm trà mật ong', 'get:chemat', 15, 16000, 1300),
  QuestDef('Giao 100 đơn hàng', 'order', 100, 18000, 1400),
  QuestDef('Đạt cấp 36', 'level', 36, 12000, 0, absolute: true),
  QuestDef('Nâng nhà văn hóa lên cấp 3', 'project_lv:nha_van_hoa', 3, 18000, 1400, absolute: true),
  QuestDef('Làm 15 bánh cốm', 'get:banhcom', 15, 18000, 1500),
  QuestDef('Thu 80 con tôm càng', 'get:tom', 80, 18000, 1500),
  QuestDef('Phơi khô 200 thóc trên sân', 'dry', 200, 20000, 1600),
  QuestDef('Đạt cấp 38', 'level', 38, 14000, 0, absolute: true),
  QuestDef('Nâng giếng làng lên cấp 3', 'project_lv:gieng', 3, 15000, 1200, absolute: true),
  QuestDef('Nâng cổng làng lên cấp 3', 'project_lv:cong_lang', 3, 18000, 1400, absolute: true),
  QuestDef('Gói 20 chiếc bánh chưng', 'get:banhchung', 20, 22000, 1800),
  QuestDef('Bón phân chuồng cho 30 ruộng', 'fertilize', 30, 20000, 1600),
  QuestDef('Đạt cấp 40', 'level', 40, 16000, 0, absolute: true),
  QuestDef('Nâng đường bê tông lên cấp 3', 'project_lv:duong_be_tong', 3, 20000, 1600, absolute: true),
  QuestDef('Nâng trạm bơm lên cấp 3', 'project_lv:tram_bom', 3, 20000, 1600, absolute: true),
  QuestDef('Nâng trạm biến áp lên cấp 3', 'project_lv:tram_dien', 3, 20000, 1600, absolute: true),
  QuestDef('Làm 20 hộp sữa đậu nành', 'get:suadaunanh', 20, 22000, 1800),
  QuestDef('Làm 20 lọ tương ớt', 'get:tuongot', 20, 22000, 1800),
  QuestDef('Đạt cấp 42', 'level', 42, 18000, 0, absolute: true),
  QuestDef('Thu 60 sữa dê', 'get:suade', 60, 24000, 2000),
  QuestDef('Thu 100 quả nhãn lồng', 'get:nhan', 100, 24000, 2000),
  QuestDef('Giao 50 đơn đặc biệt', 'daily', 50, 28000, 2200),
  QuestDef('Đạt cấp 44', 'level', 44, 20000, 0, absolute: true),
  QuestDef('Làm 20 bánh đậu xanh', 'get:banhdauxanh', 20, 26000, 2200),
  QuestDef('Làm 25 gói kẹo lạc', 'get:keolac', 25, 26000, 2200),
  QuestDef('Thu 100 bình sữa bò', 'get:sua', 100, 28000, 2300),
  QuestDef('Đạt cấp 46', 'level', 46, 22000, 0, absolute: true),
  QuestDef('Thu 80 hũ mật ong', 'get:matong', 80, 30000, 2500),
  QuestDef('Làm 30 túi hồng sấy', 'get:hongsay', 30, 32000, 2600),
  QuestDef('Giao 200 đơn hàng', 'order', 200, 35000, 2800),
  QuestDef('Đạt cấp 48', 'level', 48, 24000, 0, absolute: true),
  QuestDef('Làm 30 bánh cốm', 'get:banhcom', 30, 36000, 3000),
  QuestDef('Làm 25 bánh phô mai dê', 'get:phomai', 25, 36000, 3000),
  QuestDef('Pha 30 ấm trà mật ong', 'get:chemat', 30, 38000, 3100),
  QuestDef('Đạt cấp 50', 'level', 50, 30000, 0, absolute: true),
  QuestDef('Gói 40 chiếc bánh chưng', 'get:banhchung', 40, 40000, 3300),
  QuestDef('Giao 100 đơn đặc biệt', 'daily', 100, 45000, 3600),
  QuestDef('Đạt cấp 55', 'level', 55, 40000, 0, absolute: true),
  QuestDef('Giao 400 đơn hàng', 'order', 400, 50000, 4000),
  QuestDef('Làm 50 bánh cốm', 'get:banhcom', 50, 55000, 4500),
  QuestDef('Đạt cấp 60', 'level', 60, 60000, 0, absolute: true),
];
