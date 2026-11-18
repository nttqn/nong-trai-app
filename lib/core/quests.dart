// The guided main-quest chain. Each quest watches one stat key in
// Farm.stats; non-absolute quests count from the value when they started.
// "Build one X" and village projects are absolute: one built before the
// quest came up counts (a project can only be built once).

class QuestDef {
  final String text, key;
  final int target, coins, xp;
  final bool absolute;

  /// The chain version that added this quest (see Farm.fromJson).
  final int v;
  const QuestDef(this.text, this.key, this.target, this.coins, this.xp,
      {this.absolute = false, this.v = 1});
}

/// Bumped when quests are added to the chain; every new quest carries the
/// new number as its [QuestDef.v]. Farm.fromJson moves older saves to the
/// same quest in the longer chain.
const questChainVersion = 4;

/// Where a save made with chain version [saved] at quest [quest] is now,
/// and whether it had finished that chain (then it goes on to the first
/// quest added after the old end and starts counting from now).
(int, bool) migrateQuest(int quest, int saved) {
  if (saved >= questChainVersion) return (quest, false);
  final old = [for (var i = 0; i < questChain.length; i++) if (questChain[i].v <= saved) i];
  if (quest < old.length) return (old[quest], false);
  return (old.isEmpty ? 0 : old.last + 1, true);
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
  // v: 2 = added in 1.1, v: 3 = cấp 31+ in 1.2, v: 4 = new cấp 31+ content in 1.3
  QuestDef('Đạt cấp 4', 'level', 4, 100, 0, absolute: true, v: 2),
  QuestDef('Dựng bù nhìn rơm giữ ruộng', 'build:bu_nhin', 1, 100, 10, absolute: true, v: 2),
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
  QuestDef('Đạt cấp 31', 'level', 31, 8000, 0, absolute: true, v: 3),
  QuestDef('Trồng 6 luống nghệ', 'plant:nghe', 6, 9000, 700, v: 4),
  QuestDef('Xay 5 túi tinh bột nghệ', 'get:tinhbotnghe', 5, 10000, 800, v: 4),
  QuestDef('Lên biệt thự nhà vườn', 'house', 4, 10000, 800, absolute: true, v: 3),
  QuestDef('Nâng trường mầm non lên cấp 3', 'project_lv:truong', 3, 10000, 800, absolute: true, v: 3),
  QuestDef('Thu 30 hũ mật ong', 'get:matong', 30, 10000, 900, v: 3),
  QuestDef('Làm 10 túi hồng sấy', 'get:hongsay', 10, 12000, 1000, v: 3),
  QuestDef('Đạt cấp 32', 'level', 32, 9000, 0, absolute: true, v: 3),
  QuestDef('Xây nhà nuôi tằm', 'build:nha_tam', 1, 10000, 800, absolute: true, v: 4),
  QuestDef('Trồng 6 luống dâu tằm', 'plant:dau_tam', 6, 9000, 700, v: 4),
  QuestDef('Thu 12 kén tằm', 'get:ken', 12, 11000, 900, v: 4),
  QuestDef('Dựng nhà khung cửi', 'build:khung_cui', 1, 12000, 1000, absolute: true, v: 4),
  QuestDef('Ươm 5 cuộn tơ tằm', 'get:to', 5, 12000, 1000, v: 4),
  QuestDef('Nâng trạm y tế lên cấp 3', 'project_lv:tram_y_te', 3, 12000, 1000, absolute: true, v: 3),
  QuestDef('Cấy và gặt 40 ô lúa tám thơm', 'harvest:tam', 40, 12000, 1000, v: 3),
  QuestDef('Làm 10 bánh phô mai dê', 'get:phomai', 10, 14000, 1100, v: 3),
  QuestDef('Giao 30 đơn đặc biệt', 'daily', 30, 15000, 1200, v: 3),
  QuestDef('Đạt cấp 34', 'level', 34, 10000, 0, absolute: true, v: 3),
  QuestDef('Trồng 2 cây cam', 'build:cay_cam', 2, 12000, 1000, absolute: true, v: 4),
  QuestDef('Cấy 8 ô cói', 'plant:coi', 8, 12000, 1000, v: 4),
  QuestDef('Dệt 5 chiếc chiếu cói', 'get:chieu', 5, 14000, 1100, v: 4),
  QuestDef('Nâng chợ quê lên cấp 3', 'project_lv:cho_que', 3, 15000, 1200, absolute: true, v: 3),
  QuestDef('Thu 60 quả hồng', 'get:hong', 60, 15000, 1200, v: 3),
  QuestDef('Pha 15 ấm trà mật ong', 'get:chemat', 15, 16000, 1300, v: 3),
  QuestDef('Giao 100 đơn hàng', 'order', 100, 18000, 1400, v: 3),
  QuestDef('Đạt cấp 36', 'level', 36, 12000, 0, absolute: true, v: 3),
  QuestDef('Thả lươn xuống ao', 'stock:luon', 1, 12000, 1000, v: 4),
  QuestDef('Nấu 5 nồi cháo lươn', 'get:chaoluon', 5, 15000, 1200, v: 4),
  QuestDef('Dệt 3 tấm lụa', 'get:lua_to', 3, 16000, 1300, v: 4),
  QuestDef('Xây bếp chè mứt', 'build:xuong_mut', 1, 16000, 1300, absolute: true, v: 4),
  QuestDef('Sên 5 hũ mứt cam', 'get:mutcam', 5, 17000, 1400, v: 4),
  QuestDef('Trồng một cây mít', 'build:cay_mit', 1, 15000, 1200, absolute: true, v: 4),
  QuestDef('Nâng nhà văn hóa lên cấp 3', 'project_lv:nha_van_hoa', 3, 18000, 1400, absolute: true, v: 3),
  QuestDef('Làm 15 bánh cốm', 'get:banhcom', 15, 18000, 1500, v: 3),
  QuestDef('Thu 80 con tôm càng', 'get:tom', 80, 18000, 1500, v: 3),
  QuestDef('Phơi khô 200 thóc trên sân', 'dry', 200, 20000, 1600, v: 3),
  QuestDef('Đạt cấp 38', 'level', 38, 14000, 0, absolute: true, v: 3),
  QuestDef('Cấy 8 ô lúa nếp cẩm', 'plant:nep_cam', 8, 17000, 1400, v: 4),
  QuestDef('Thổi 5 chõ xôi nếp cẩm', 'get:xoinepcam', 5, 18000, 1500, v: 4),
  QuestDef('Làm 5 hũ nghệ mật ong', 'get:nghematong', 5, 18000, 1500, v: 4),
  QuestDef('Nâng giếng làng lên cấp 3', 'project_lv:gieng', 3, 15000, 1200, absolute: true, v: 3),
  QuestDef('Nâng cổng làng lên cấp 3', 'project_lv:cong_lang', 3, 18000, 1400, absolute: true, v: 3),
  QuestDef('Gói 20 chiếc bánh chưng', 'get:banhchung', 20, 22000, 1800, v: 3),
  QuestDef('Bón phân chuồng cho 30 ruộng', 'fertilize', 30, 20000, 1600, v: 3),
  QuestDef('Đạt cấp 40', 'level', 40, 16000, 0, absolute: true, v: 3),
  QuestDef('Trồng 2 cây cau', 'build:cay_cau', 2, 20000, 1600, absolute: true, v: 4),
  QuestDef('Sấy 5 túi mít sấy', 'get:mitsay', 5, 20000, 1600, v: 4),
  QuestDef('Làm 5 hũ sữa chua nếp cẩm', 'get:suachuanepcam', 5, 21000, 1700, v: 4),
  QuestDef('Nâng đường bê tông lên cấp 3', 'project_lv:duong_be_tong', 3, 20000, 1600, absolute: true, v: 3),
  QuestDef('Nâng trạm bơm lên cấp 3', 'project_lv:tram_bom', 3, 20000, 1600, absolute: true, v: 3),
  QuestDef('Nâng trạm biến áp lên cấp 3', 'project_lv:tram_dien', 3, 20000, 1600, absolute: true, v: 3),
  QuestDef('Làm 20 hộp sữa đậu nành', 'get:suadaunanh', 20, 22000, 1800, v: 3),
  QuestDef('Làm 20 lọ tương ớt', 'get:tuongot', 20, 22000, 1800, v: 3),
  QuestDef('Đạt cấp 42', 'level', 42, 18000, 0, absolute: true, v: 3),
  QuestDef('Thả cá quả xuống ao', 'stock:caqua', 1, 20000, 1600, v: 4),
  QuestDef('Kho 5 nồi cá kho tộ', 'get:cakho', 5, 24000, 2000, v: 4),
  QuestDef('Thu 60 sữa dê', 'get:suade', 60, 24000, 2000, v: 3),
  QuestDef('Thu 100 quả nhãn lồng', 'get:nhan', 100, 24000, 2000, v: 3),
  QuestDef('Giao 50 đơn đặc biệt', 'daily', 50, 28000, 2200, v: 3),
  QuestDef('Đạt cấp 44', 'level', 44, 20000, 0, absolute: true, v: 3),
  QuestDef('Sửa 3 tráp ăn hỏi', 'get:trap_cuoi', 3, 30000, 2500, v: 4),
  QuestDef('Làm 20 bánh đậu xanh', 'get:banhdauxanh', 20, 26000, 2200, v: 3),
  QuestDef('Làm 25 gói kẹo lạc', 'get:keolac', 25, 26000, 2200, v: 3),
  QuestDef('Thu 100 bình sữa bò', 'get:sua', 100, 28000, 2300, v: 3),
  QuestDef('Đạt cấp 46', 'level', 46, 22000, 0, absolute: true, v: 3),
  QuestDef('Thu 80 hũ mật ong', 'get:matong', 80, 30000, 2500, v: 3),
  QuestDef('Làm 30 túi hồng sấy', 'get:hongsay', 30, 32000, 2600, v: 3),
  QuestDef('Giao 200 đơn hàng', 'order', 200, 35000, 2800, v: 3),
  QuestDef('Đạt cấp 48', 'level', 48, 24000, 0, absolute: true, v: 3),
  QuestDef('Dệt 15 tấm lụa', 'get:lua_to', 15, 36000, 3000, v: 4),
  QuestDef('Làm 30 bánh cốm', 'get:banhcom', 30, 36000, 3000, v: 3),
  QuestDef('Làm 25 bánh phô mai dê', 'get:phomai', 25, 36000, 3000, v: 3),
  QuestDef('Pha 30 ấm trà mật ong', 'get:chemat', 30, 38000, 3100, v: 3),
  QuestDef('Đạt cấp 50', 'level', 50, 30000, 0, absolute: true, v: 3),
  QuestDef('Sửa 10 tráp ăn hỏi', 'get:trap_cuoi', 10, 45000, 3600, v: 4),
  QuestDef('Gói 40 chiếc bánh chưng', 'get:banhchung', 40, 40000, 3300, v: 3),
  QuestDef('Giao 100 đơn đặc biệt', 'daily', 100, 45000, 3600, v: 3),
  QuestDef('Đạt cấp 55', 'level', 55, 40000, 0, absolute: true, v: 3),
  QuestDef('Giao 400 đơn hàng', 'order', 400, 50000, 4000, v: 3),
  QuestDef('Làm 50 bánh cốm', 'get:banhcom', 50, 55000, 4500, v: 3),
  QuestDef('Đạt cấp 60', 'level', 60, 60000, 0, absolute: true, v: 3),
];
