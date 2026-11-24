# App Store Connect → App Privacy (Mùa Lúa Chín)

Trả lời "Có, app thu thập dữ liệu", rồi khai các loại sau.

| Loại dữ liệu (App Store) | Ai thu | Liên kết người dùng | Dùng để theo dõi (tracking) | Mục đích |
|---|---|---|---|---|
| Contact Info → Email Address | Firebase Auth khi đăng nhập Apple/Google | Có | Không | App Functionality |
| Contact Info → Name | Tên hiển thị Google/Apple khi đăng nhập | Có | Không | App Functionality |
| Identifiers → User ID | Firebase (mã tài khoản) | Có | Không | App Functionality |
| Identifiers → Device ID | AdMob (IDFA, chỉ khi người chơi cho phép ATT) | Không | **Có** | Third-Party Advertising |
| User Content → Gameplay Content | Bản lưu trên mây, làng trên bản đồ vùng, chợ phiên, bảng xếp hạng (tên nông trại, cấp, đơn hàng, công trình) | Có | Không | App Functionality |
| User Content → Other User Content | Tin nhắn Kênh Thế Giới (tự xóa sau 3 ngày) | Có | Không | App Functionality |
| Purchases → Purchase History | Gói đã mua trong Cửa hàng (để trao vật phẩm) | Có | Không | App Functionality |
| Usage Data → Product Interaction | Firebase Analytics, AdMob | Không | Có (AdMob) | Analytics, Third-Party Advertising |
| Usage Data → Advertising Data | AdMob | Không | Có | Third-Party Advertising |
| Location → Coarse Location | AdMob (ước lượng từ IP) | Không | Có | Third-Party Advertising |
| Diagnostics → Crash Data, Performance Data | AdMob SDK | Không | Không | Analytics |

Ghi chú:
- Vì có dòng "Dùng để theo dõi = Có", app phải hỏi App Tracking Transparency: đã thêm trong bản này (hỏi một lần trước quảng cáo đầu tiên, sau form đồng ý của Google nếu có).
- Game không thu số điện thoại, danh bạ, ảnh, vị trí chính xác hay thông tin thanh toán (Apple xử lý thanh toán).
- Privacy Policy URL: https://nttqn.github.io/nong-trai-app/privacy.html (đã cập nhật 24/11/2026: iOS, Sign in with Apple, ATT, mua trong ứng dụng).
- Ghi chú cho người duyệt: dán nội dung `store/appstore-review-notes.txt` vào App Review Information → Notes. Không cần tài khoản demo (bỏ trống, bỏ chọn "Sign-in required").
- Age Rating: **Advertising = Yes**, **Messaging and Chat = Yes**, **User-Generated Content = Yes**; thiếu mục nào là bị từ chối tự động 2.3.6.
