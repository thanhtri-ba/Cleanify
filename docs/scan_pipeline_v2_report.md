# Báo cáo: triển khai quy trình SHA-256 + PDQ + SQLite

Ngày: 29/10/2026. Căn cứ: tài liệu "Báo cáo quy trình so sánh ảnh — Cleanify".

## 1. Đã triển khai theo tài liệu

| Mục trong tài liệu | Triển khai | Nơi |
|---|---|---|
| Tầng 1: SHA-256 cho trùng chính xác | Băm nội dung file theo khối (stream), gom nhóm theo hash | `media_scanner.dart` (`_hashPhoto`), `photo_manager_media_source.dart` (`openOriginal`) |
| Tầng 2: PDQ 256 bit cho gần giống | DCT 64x64 → khối 16x16 → so với trung vị, 256 bit (32 byte) | `domain/pdq.dart` |
| Khoảng cách Hamming | XOR + popcount trên 32 byte | `Pdq.distanceTo` |
| Chỉ mục để tránh O(n²) | 32 đoạn 8 bit: nếu hai ảnh cách ≤ 31 bit thì ít nhất một đoạn trùng nhau | `_pdqClusters` |
| Điểm chất lượng PDQ | Lọc ảnh gần như phẳng khỏi so khớp gần giống | `pdqMinQuality` |
| SQLite lưu hash | Bảng `media_hash` theo đúng các cột của tài liệu, có index `sha256` | `data/sqflite_hash_store.dart` |
| Quét tăng dần | Dùng lại hash nếu ảnh chưa đổi; xoá dòng của ảnh không còn trong thư viện | `_cachedFor`, `retainOnly` |
| Ghi theo lô trong transaction | Ghi mỗi `hashFlushSize` ảnh (mặc định 200) trong một transaction | `SqfliteHashStore.saveAll` |
| Không tự xoá, cần xác nhận | Không đổi: vẫn qua màn Review và hộp thoại của hệ điều hành | — |

## 2. Khác với tài liệu (có chủ đích hoặc do hạn chế)

1. **Kiểm tra cache bằng ngày sửa + kích thước ảnh, không dùng dung lượng file.** Lấy dung lượng file cần đọc `originFile` (có thể tải iCloud), nên không làm trước khi kiểm tra cache. Dung lượng được ghi lại sau khi băm.
2. **PDQ chưa có bộ lọc Jarosz** trước khi thu nhỏ. Ảnh đầu vào được codec thu về 64x64 trực tiếp.
3. **Điểm chất lượng PDQ là ước lượng đơn giản** (độ chênh lệch điểm ảnh kề nhau), chưa theo công thức chính thức.
4. **Ngưỡng PDQ 31 lấy từ tài liệu PDQ**, chưa hiệu chỉnh trên ảnh có nhãn.
5. **Đã gỡ** các hướng thử trước đó: Vision, vân tay theo lưới 256 bit, SSIM, dHash 64 bit và chế độ gom xuyên thời gian. Các mục này không còn trong tài liệu.

## 3. Kết quả đo

Đo trên testset (1.934 ảnh, 177 thư mục), bằng cùng bộ quét với file thật:

| Chỉ số | Kết quả |
|---|---|
| Thời gian quét (máy Mac, test host) | 4,3–4,7 giây |
| Nhóm trùng chính xác (SHA-256) | 320 nhóm, 1.018 ảnh |
| Nhóm gần giống (PDQ ≤ 31) | 84 nhóm, 246 ảnh |
| Nhóm gần giống nằm gọn trong một thư mục | 83 / 84 |
| Nhóm trùng chính xác nằm ở nhiều thư mục | 1 / 320 |
| Ảnh hỏng (không giải mã được) | Bỏ qua từng file, không dừng quét |

Ghi chú: testset không có nhãn đúng/sai. Số "nằm gọn một thư mục" chỉ là chỉ số gián tiếp.

## 4. Kiểm thử

- 135 test pass, gồm: 20 test bộ quét (trùng chính xác, gần giống, kho hash, hủy, lỗi, tiến độ), 5 test PDQ, 4 test kho SQLite (FFI, trên Mac).
- `flutter analyze`: không có lỗi.
- `flutter build ios --simulator`: thành công (có sqflite và nguồn ảnh mới).

## 5. Chưa kiểm chứng

- **Chưa chạy trên simulator hoặc iPhone thật** với thư viện 10.000 ảnh: thời gian băm SHA-256 (đọc file gốc qua `originFile`) và PDQ (thumbnail 64px) cần đo trên thiết bị. Trên iOS có thể chậm hơn đáng kể vì iCloud và sao chép file tạm.
- **Chưa hiệu chỉnh ngưỡng PDQ** trên ảnh thật có nhãn.
- **Ảnh cắt hoặc che** chưa được xử lý (PDQ không bắt được).
- **Đường dẫn SQLite trên thiết bị** là `getDatabasesPath()/cleanify_hashes.db`, chưa có migration cho các phiên bản sau.

## 6. Thử nghiệm: tìm ảnh cắt và ảnh che (chưa tích hợp)

Bộ thử: 360 biến thể từ 120 ảnh testset (cắt 60–80%, che 50% chiều rộng và cao, đổi tỷ lệ 0.5×). Đáp án là ảnh gốc. Ảnh cùng cảnh trong cùng thư mục testset được tính là đúng.

| Cấu hình | Tìm đúng cảnh | Khác cảnh bị xác nhận nhầm | Ghi chú |
|---|---|---|---|
| ORB mặc định, so mọi cặp | cắt 84%, che 88%, tỷ lệ 72% | — | chỉ để tham khảo, không khả thi ở quy mô lớn |
| ORB ngưỡng phát hiện thấp, so mọi cặp | cắt 96%, che 97%, tỷ lệ 86% | — | |
| Chọn 10 ứng viên bằng LSH trên mô tả ORB + RANSAC (500 điểm, 8 bảng) | 311/342 | 1 | |
| Như trên, 300 điểm, 8 bảng | 304/342 | 7 | |
| Như trên, 300 điểm, 4 bảng | 303/342 | 1 | Cấu hình được chọn: dung lượng ~12 KB/ảnh |

Trạng thái tích hợp (đã làm):
- `opencv_dart` build được cho iOS và macOS. Cần hai việc: nâng deployment target của `dartcv4` (bản sao cục bộ trong `third_party/dartcv4`, iOS 15.0, macOS 12.0) và bật module `imgproc`, `imgcodecs`, `calib3d`, `features2d`, `flann` trong `hooks.user_defines` (danh sách này thay thế mặc định).
- Trích ORB (300 điểm, FAST 5) trên ảnh thumbnail 512px. Đặc trưng lưu trong SQLite (cột `features`, schema v2 có nâng cấp).
- Chọn ứng viên bằng chỉ mục LSH 4 bảng x 16 bit, lấy 10 ảnh nhiều phiếu nhất. Xác nhận bằng BFMatcher (Hamming, Lowe 0.75) + RANSAC; cần tối thiểu 15 điểm khớp.
- Gộp cạnh PDQ và cạnh ORB bằng union-find.

Kết quả tích hợp trên bộ thử 360 biến thể (cắt, che, đổi tỷ lệ) qua chính `MediaScanner`:
- Tìm đúng cảnh: 287/360 (80%). Cắt 101/120, che 102/120, đổi tỷ lệ 84/120.
- 1 nhóm trộn ảnh khác thư mục trong 97 nhóm.
- Thời gian quét 480 ảnh: khoảng 6 giây trên máy Mac.

Chưa kiểm chứng:
- Chạy trên simulator/iPhone với thư viện lớn (10.000 ảnh): thời gian LSH, số cặp RANSAC và dung lượng cột `features` (ước tính ~12 KB/ảnh).
- Mỗi lần khớp cặp tạo lại `Mat` và `BFMatcher`; có thể tối ưu bằng cache khi có thời gian đo.
- Ngưỡng 15 điểm chưa hiệu chỉnh trên ảnh thật có nhãn.
