# PHOENIX CV GOLF & RESORT - SMART STARTING OMS v3.0

> **Hệ Thống Điều Hành Xuất Phát & Caddie Master Thời Gian Thực (54 Holes Championship Golf Course)**  
> Ứng dụng Web chạy trực tuyến 24/7 trên mọi thiết bị (PC, Máy tính bảng iPad tại Chòi Starter, Điện thoại di động).

---

## ⛳ Giới Thiệu Hệ Thống

**Phoenix Smart Starting OMS v3.0** là giải pháp điều hành sân golf chuyên nghiệp dành cho sân golf 54 hố (Champion Course, Dragon Course, Phoenix Course) tại **Phoenix CV Golf & Resort (Lương Sơn, Hòa Bình)**.

Hệ thống được thiết kế với **Giao diện Sáng (Luxury Golf Resort Light Mode)** có độ tương phản cao, tối ưu tuyệt đối cho màn hình điều phối ngoài trời có ánh sáng mạnh hoặc nắng chiếu.

---

## 🚀 Các Tính Năng Nổi Bật

1. **3 Trạng Thái Flight Linh Hoạt:**
   - ⏳ **Khách chờ (Waiting):** Chưa phát bóng.
   - 🏌️ **Đang đánh (In-Play):** Đang thi đấu trên sân (On-Course) với hiệu ứng phát sáng nhận diện.
   - 🏁 **Đánh xong (Finished):** Hoàn thành vòng chơi, tự động lưu mốc giờ kết thúc.
   - Đổi trạng thái 1-chạm siêu nhanh trực tiếp trên bảng điều hành.

2. **Cảnh Báo & Giám Sát Tài Nguyên (Locker, Caddie, Xe Cart):**
   - Tự động phát hiện xung đột và cảnh báo ngay trên form khi Caddie, Xe Cart hoặc Tủ Locker đang được ghép cho Flight khác chưa kết thúc.
   - Cửa sổ **"Tài Nguyên"** phân loại trực quan: Caddie đang ra sân, Xe Cart xuất bến (dòng Y / dòng E), Tủ Locker đang cấp.

3. **Xuất Báo Cáo PDF Chuẩn Khổ Ngang A4:**
   - Tạo file PDF sắc nét tải trực tiếp về máy tính (`html2pdf.js`).
   - Đầy đủ tiêu đề thương hiệu Phoenix CV Golf & Resort, bảng KPI chỉ số trong ngày, danh sách Flight chi tiết và 3 vị trí ký duyệt: **Starter - Caddie Master - Giám Đốc Vận Hành**.

4. **Tự Động Chuyển Ngày & Bảo Toàn 100% Lịch Sử Ngày Cũ:**
   - Sang ngày mới, hệ thống tự động reset bảng điều hành mới, không ghi đè dữ liệu cũ.
   - Thanh chọn ngày linh hoạt cho phép tra cứu, đối soát toàn bộ dữ liệu ngày hôm trước (như ngày 1/8/2026) bất kỳ lúc nào.
   - Nút *"Sao chép sang hôm nay"* giúp tái sử dụng nhanh danh sách flight mẫu.

5. **Nhật Ký Thao Tác & Lịch Sử Trong Ngày (Daily Audit Log):**
   - Ghi nhận chính xác từng giây mọi thao tác đổi trạng thái, thêm, sửa, xóa Flight.
   - Hỗ trợ lọc theo loại hành động và ô tìm kiếm nhanh.

6. **Đồng Bộ Đám Mây 2 Lớp Độc Lập:**
   - **Lớp 1:** LocalStorage lưu trữ tức thì, đảm bảo không bao giờ mất dữ liệu ngay cả khi mất mạng.
   - **Lớp 2:** Firebase Realtime Database đồng bộ thời gian thực đa thiết bị qua Server-Sent Events (SSE).

---

## 🌐 Hướng Dẫn Đưa Lên GitHub & Chạy Online 24/7 Miễn Phí (GitHub Pages)

Hệ thống đã được đóng gói sẵn file workflow tự động hóa `.github/workflows/deploy.yml`. Bạn chỉ cần thực hiện 3 bước đơn giản:

### Bước 1: Tạo Repository Mới Trên GitHub
1. Truy cập [github.com/new](https://github.com/new) và đăng nhập tài khoản GitHub của bạn.
2. Đặt tên Repository (ví dụ: `phoenix-starting-oms`).
3. Chọn chế độ **Public** (hoặc Private nếu dùng GitHub Pro), không cần tích chọn README.
4. Bấm **Create repository**.

### Bước 2: Đẩy Mã Nguồn Từ Máy Lên GitHub
Mở Terminal / PowerShell tại thư mục dự án và chạy các lệnh sau:

```bash
# 1. Khởi tạo Git nếu chưa có
git init

# 2. Thêm tất cả các file mã nguồn sạch
git add .

# 3. Tạo commit đầu tiên
git commit -m "feat: release Phoenix Smart Starting OMS v3.0 Light Theme"

# 4. Đặt nhánh chính là main
git branch -M main

# 5. Kết nối với repository GitHub của bạn (thay username và repo của bạn vào link dưới)
git remote add origin https://github.com/<your-username>/phoenix-starting-oms.git

# 6. Đẩy code lên GitHub
git push -u origin main
```

### Bước 3: Kích Hoạt Chạy Online (GitHub Pages)
1. Trên giao diện GitHub của repository, vào mục **Settings** (Cài đặt) > chọn tab **Pages** ở thanh bên trái.
2. Tại mục **Build and deployment > Source**, chọn **GitHub Actions** (hoặc chọn **Deploy from a branch** > nhánh `main` > thư mục `/ (root)`).
3. Bấm **Save**.
4. Chờ khoảng 1-2 phút, GitHub sẽ cung cấp cho bạn một đường link trực tuyến an toàn:
   $$\text{https://<your-username>.github.io/phoenix-starting-oms/}$$

🎉 **Bây giờ bạn có thể gửi đường link này cho toàn bộ Starter, Caddie Master và Ban Quản Lý mở trên điện thoại, iPad hoặc máy tính để điều hành cùng lúc!**

---

## ⚙️ Cấu Hình Firebase Realtime Database

Để bật tính năng đồng bộ trực tuyến giữa nhiều máy tính và iPad:
1. Truy cập [Firebase Console](https://console.firebase.google.com/).
2. Chọn dự án của bạn > vào **Realtime Database** > chọn tab **Rules**.
3. Cài đặt luật đọc và ghi mở cho hệ thống:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
4. Bấm **Publish**. Lúc này hệ thống sẽ tự động chuyển sang đèn xanh **"CSDL Firebase: Trực Tuyến"**.

---
*Bản quyền © 2026 Phoenix CV Golf & Resort. All rights reserved.*
