# Báo cáo: pipeline quét ảnh tương tự (bước 3 và bước 4)

## 1. Pipeline sau khi sửa

| Bước | Việc làm | Code |
|---|---|---|
| 1 | Liệt kê ảnh, đo kích thước | `media_scanner.dart` |
| 2 | Ảnh chụp màn hình | `media_scanner.dart` |
| 3 | Ứng viên: vân tay 256 bit (8 hướng xoay/lật), khoảng cách Hamming ≤ 50, trong cửa sổ 10 phút | `perceptual_hash.dart`, `scan_models.dart` |
| 4 | Xác nhận: SSIM trên ảnh 32×32 (8 hướng), ≥ 0.8 | `ssim.dart`, `media_scanner.dart` |
| Trùng | dHash 64 bit hướng gốc + cùng kích thước + cùng dung lượng | `media_scanner.dart` |

Ảnh trùng hoàn toàn vẫn được xử lý như trước. Ảnh tương tự đi qua bước 3 rồi bước 4.

Các ngưỡng mặc định (trong `ScanConfig`):
- `similarMaxFingerprintDistance = 50` (bước 3)
- `similarMinSsim = 0.8` (bước 4)
- `similarMaxDistance = 6` (chỉ dùng cho dữ liệu cũ 9×8)

## 2. Kết quả đo trên testset

Testset: 1.928 ảnh, 177 thư mục. Đã bỏ 3 file HTML có đuôi `.jpg` và 10 file rỗng. Mỗi thư mục được coi là một cụm, các ảnh trong cụm được đặt trong cửa sổ 10 phút.

| Chỉ số | Đường cũ (9×8, dHash 64 bit ≤ 6) | Đường mới (vân tay 256 bit ≤ 50 + SSIM ≥ 0.8) |
|---|---|---|
| Nhóm tương tự | 93 | 93 |
| Ảnh trong nhóm tương tự | 257 | 264 |
| Nhóm trùng hoàn toàn | 320 | 320 |

Ghi chú về cách đo:
- Không có nhãn đúng/sai cho testset. Phép đo chỉ mang tính tham khảo.
- Khi dùng SSIM làm "đáp án", chỉ các cặp giống về điểm ảnh được tính là đúng. Các ảnh đổi góc có SSIM thấp nên không nằm trong đáp án, vì vậy phép đo này không đo được độ phủ của ảnh đổi góc.
- Trên các cặp giống điểm ảnh, ngưỡng vân tay 50 cho recall khoảng 99%, còn dHash 64 bit ≤ 6 cho khoảng 93%.

## 3. Hạn chế đã biết

1. **Ảnh đổi góc chưa được gom.** Khoảng 65% cặp cùng cụm trong testset không nằm trong ngưỡng ở cả hai đường. Đây là giới hạn của dHash và vân tay theo lưới; xoay và lật đã được xử lý, nhưng thay đổi góc chụp thật thì không. Muốn giải quyết cần đặc trưng học sâu, ví dụ `VNGenerateImageFeaturePrintRequest` của Vision trên iOS, qua platform channel.
2. **Nhóm tương tự xuyên thời gian** (`globalMaxDistance`) vẫn dùng dHash 64 bit và đang tắt mặc định.
3. **Ngưỡng chưa được hiệu chỉnh trên ảnh thật.** 50 và 0.8 lấy từ testset và tài liệu thiết kế.
4. **Hiệu năng chưa đo trên thư viện 10.000 ảnh trên máy thật.** Bước 3 so sánh trong cửa sổ thời gian nên không phải O(n²) toàn bộ, nhưng mỗi cặp cần tới 8 phép so vân tay và có thể có thêm SSIM.
5. **Tài liệu thiết kế nói vân tay 256 bit**, nên bước 3 đã làm đúng theo đó. Phần ORB/AKAZE cho ảnh bị cắt hoặc che chưa làm, vì bạn đã chọn bước 4 bằng Dart.

## 4. Kiểm thử

- Toàn bộ test: 150 test, tất cả pass.
- Test mới:
  - `orientation_hash_test.dart`: ảnh xoay và lật khớp ảnh gốc.
  - `ssim_test.dart`: SSIM với ảnh giống hệt, khác nội dung, lệch sáng, và lật.
  - `ssim_verification_test.dart`: cặp có vân tay gần nhau nhưng khác điểm ảnh không được gom.
- `flutter analyze`: không có cảnh báo mới trong code đã sửa.

## 5. Việc cần làm tiếp

- Chạy app trên simulator với bộ 10.000 ảnh để đo thời gian quét và xem nhóm kết quả.
- Quyết định có làm Vision cho iOS để xử lý ảnh đổi góc hay không.
- Hiệu chỉnh ngưỡng bằng một tập ảnh có nhãn đúng/sai do bạn gán.

---

## 6. Cập nhật: gom ảnh tương tự bằng Vision (iOS)

### Thay đổi
- **Native:** `ios/Runner/AppDelegate.swift` đăng ký kênh `cleanify/vision`, trả về vân tay `VNGenerateImageFeaturePrintRequest` (vector float32) cho một ảnh JPEG.
- **Dart:** [vision_feature_print.dart](lib/features/scan/data/vision_feature_print.dart) gọi kênh. Trên Android hoặc khi lỗi, trả về null.
- **Nguồn ảnh:** `MediaSource.featureVector` lấy thumbnail 256 px rồi gọi Vision.
- **Quy tắc nối (không có ngưỡng cố định):** [feature_links.dart](lib/features/scan/domain/feature_links.dart). Hai ảnh được nối khi mỗi ảnh là láng giềng gần nhất của ảnh kia và `d1/d2 < 0.8`. Mỗi ảnh chỉ so với 40 ảnh trước và sau nó theo thời gian (`visionNeighbourWindow`).
- **Bộ quét:** khi **tất cả** ảnh trong bước gom có vân tay Vision, ảnh tương tự được gom bằng quy tắc trên (các thành phần liên thông). Khi không đủ vân tay, giữ đường cũ: vân tay 256 bit + SSIM.
- **Trùng hoàn toàn** vẫn dùng dHash 64 bit, không đổi.

### Vì sao không dùng SSIM cho đường Vision
SSIM so theo điểm ảnh nên loại đúng những ảnh khác góc mà ta muốn tìm. Đường Vision không dùng SSIM.

### Kiểm chứng
- Trên testset (CLI Swift dùng cùng framework Vision, chạy trên Mac): các cặp giống hệt byte (2.014 cặp) đều có khoảng cách 0.
- Quy tắc tỷ lệ 0.8 tạo 95 liên kết ở 72 thư mục, khoảng cách lớn nhất 0.655. Danh sách để xem lại: `links_0.8.html` trong scratchpad.
- Test: 154 test pass, gồm 4 test mới cho quy tắc nối và cho bộ quét dùng Vision.
- Build iOS simulator (`flutter build ios --simulator`) thành công.

### Chưa kiểm chứng
- **Chưa chạy trên simulator hoặc iPhone thật** để xác nhận kênh Vision trả về vector trong app. Kết quả trên Mac có thể khác iOS.
- **Chưa đo thời gian** trên thư viện 10.000 ảnh. Mỗi ảnh cần một lần Vision và mỗi ảnh so với tối đa 80 ảnh lân cận bằng vector 768 chiều (đo được: 768 phần tử float32, khoảng 3 KB mỗi ảnh).
- **Kết quả đúng/sai chưa được gán nhãn.** Cần bạn xem `links_0.8.html` để đánh giá các cặp được nối.
- Ảnh bị cắt hoặc che chưa được xử lý. Muốn làm cần ORB/AKAZE qua native.
