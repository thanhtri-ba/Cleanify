# Hướng dẫn kiểm thử: Cleanify (quét ảnh trùng, gần giống, cắt/che)

Đối tượng: tester kiểm thử thủ công trên iPhone hoặc simulator.
Phiên bản: pipeline v2 (SHA-256 + PDQ + SQLite + ORB/RANSAC) và các yêu cầu quét nền bên dưới.

---

## 1. Mục tiêu sản phẩm

- Tìm ảnh/video trùng, gần giống, bị cắt hoặc che trong thư viện.
- **Không bao giờ tự xoá.** Mọi lần xoá cần người dùng xác nhận, rồi iOS hỏi thêm một lần.
- **Mới (yêu cầu của phiên bản này):** quét nền để khi khách mở app, kết quả đã có sẵn, không cần bấm Scan.

---

## 2. Chuẩn bị môi trường

| Mục | Yêu cầu |
|---|---|
| Thiết bị | iPhone thật (ưu tiên, dùng cho quét nền) hoặc iPhone simulator iOS 17+ |
| Quyền ảnh | Cho phép "Full Access" khi app hỏi |
| Dữ liệu | Thư viện có ít nhất 300 ảnh; có ảnh trùng, ảnh gần giống, ảnh cắt, ảnh che |
| Bộ thử | Thư mục `testset` (1.944 ảnh) hoặc bộ 360 biến thể (cắt, che, đổi tỷ lệ) |
| Công cụ | Xcode (đọc log), `xcrun simctl` nếu dùng simulator |

Cách nạp ảnh vào simulator:
```
xcrun simctl addmedia booted /đường/dẫn/thư_mục/*
```
Nạp theo đợt không quá 50 file, không dùng xargs (đã có lỗi khi quá nhiều file).

Reset trạng thái app trước một lượt kiểm thử: xoá app khỏi máy, cài lại, hoặc xoá file `cleanify_hashes.db` trong thư mục Databases của app.

---

## 3. Các trường hợp kiểm thử (quét thủ công)

Ký hiệu: **P** = đạt, **F** = lỗi, **B** = bị chặn (ghi rõ lý do).

### 3.1 Quyền và khởi động
| ID | Bước | Kết quả mong đợi |
|---|---|---|
| T-01 | Mở app lần đầu, đi qua onboarding | Không crash; màn "Access your files" hiện đúng |
| T-02 | Chọn Continue, từ chối quyền ảnh | Hiện trạng thái "Denied", bấm lại mở Settings |
| T-03 | Cấp quyền rồi bấm Scan | Quét chạy, không báo lỗi quyền |
| T-04 | Thư viện trống | Hiện "No duplicate or similar photos found", không crash |

### 3.2 Ảnh trùng hoàn toàn
| ID | Bước | Kết quả mong đợi |
|---|---|---|
| T-10 | Nạp 2 ảnh giống hệt byte | Thành 1 nhóm trùng; giữ ảnh cũ nhất |
| T-11 | Nạp 2 ảnh khác 1 byte | Không thành nhóm trùng |
| T-12 | Nạp bộ testset (có nhóm trùng) | Khoảng 320 nhóm trùng (kiểm tra bằng đếm) |

### 3.3 Ảnh gần giống
| ID | Bước | Kết quả mong đợi |
|---|---|---|
| T-20 | Ảnh gốc và bản nén lại chất lượng thấp | Thành nhóm tương tự |
| T-21 | Hai ảnh khác cảnh | Không thành nhóm |
| T-22 | Ảnh gần như đơn sắc (tường trắng) | Không thành nhóm (bị loại vì chất lượng thấp) |

### 3.4 Ảnh cắt, che, đổi tỷ lệ (ORB)
| ID | Bước | Kết quả mong đợi |
|---|---|---|
| T-30 | Ảnh gốc và ảnh cắt 60–80% | Thành nhóm tương tự (tham khảo: khoảng 84% trường hợp) |
| T-31 | Ảnh gốc và ảnh che một phần | Thành nhóm tương tự (tham khảo: khoảng 85%) |
| T-32 | Ảnh gốc và ảnh đổi tỷ lệ 0.5× | Thành nhóm (tham khảo: khoảng 70%) |
| T-33 | Hai ảnh khác cảnh có chi tiết | Không thành nhóm |

Ghi chú: tỷ lệ tham khảo đo trên bộ 360 biến thể. Không coi là đạt/không đạt tuyệt đối; ghi số liệu thực tế vào báo cáo.

### 3.5 Xác nhận và xoá
| ID | Bước | Kết quả mong đợi |
|---|---|---|
| T-40 | Vào Review, bỏ chọn một ảnh | Không xoá ảnh đó |
| T-41 | Không chọn mục nào | Nút xoá bị vô hiệu hoá |
| T-42 | Xoá, nhưng từ chối hộp thoại iOS | Không mất ảnh nào; app không xoá thêm |
| T-43 | Xoá và xác nhận | Ảnh vào Recently Deleted; kết quả cập nhật |

### 3.6 Lưu trữ và quét tăng dần
| ID | Bước | Kết quả mong đợi |
|---|---|---|
| T-50 | Quét lần 1, rồi quét lần 2 không đổi ảnh | Lần 2 nhanh hơn rõ rệt, không đọc lại file gốc |
| T-51 | Sửa ngày của một ảnh rồi quét lại | Ảnh đó được băm lại |
| T-52 | Xoá một ảnh khỏi thư viện rồi quét | Ảnh đó biến mất khỏi kết quả |
| T-53 | Thoát app giữa lúc đang quét | Lần mở sau không mất dữ liệu đã lưu; không crash |

### 3.7 Lỗi
| ID | Bước | Kết quả mong đợi |
|---|---|---|
| T-60 | Một file hỏng (ví dụ file HTML đặt đuôi .jpg) | Bỏ qua file đó, quét vẫn hoàn tất |
| T-61 | Mất quyền ảnh giữa lúc quét | Quét dừng, báo lỗi, giữ kết quả các phần đã xong |
| T-62 | Thư viện iCloud chưa tải về | Mục đó bỏ qua, không treo |

---

## 4. Yêu cầu mới: quét nền

Mục tiêu: khi khách mở app, kết quả đã sẵn sàng. Khách không phải chủ động bấm quét.

| ID | Yêu cầu | Tiêu chí chấp nhận |
|---|---|---|
| BG-1 | App tự quét ở nền theo lịch hệ thống cho phép | Có lượt quét nền được iOS khởi chạy (kiểm tra bằng log) |
| BG-2 | Mở app thì kết quả đã sẵn | Không bắt bấm Scan để thấy kết quả đã quét trước đó |
| BG-3 | Quét dở thì tiếp tục lượt sau | Lượt sau chỉ xử lý phần còn thiếu, không bắt đầu lại từ đầu |
| BG-4 | Ảnh chụp mới được phát hiện | Sau khi chụp ảnh mới, lượt quét nền kế tiếp đưa ảnh đó vào kết quả |
| BG-5 | Không tự xoá | Quét nền chỉ tìm và lưu kết quả, không xoá gì |
| BG-6 | Thông báo khi có kết quả mới | Có thông báo "Có N ảnh trùng, mở để xem"; bật/tắt được trong cài đặt |
| BG-7 | Tiết kiệm pin và nhiệt | Chỉ chạy khi đang sạc hoặc pin trên mức quy định; dừng khi máy nóng |
| BG-8 | Người dùng tắt được quét nền | Tắt trong cài đặt thì không có lượt quét nền nào |
| BG-9 | Mất quyền ảnh | Quét nền dừng, không hỏi lại trong nền; báo người dùng mở app để cấp quyền |

### 4.1 Giới hạn của iOS (tester cần biết)
- iOS **không đảm bảo** thời gian chạy nền. Hệ thống quyết định khi nào cho phép, thường khi máy sạc, khoá màn hình, không dùng.
- Không thể chạy liên tục. Vì vậy BG-2 phải dựa vào kết quả đã lưu từ lượt trước, không phải kết quả chạy ngay lúc mở.
- Trên simulator, lượt nền không tự chạy theo lịch. Phải kích hoạt thủ công bằng LLDB trong Xcode:
  ```
  e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"<mã tác vụ>"]
  ```
  Mã tác vụ lấy từ `Info.plist` (khoá `BGTaskSchedulerPermittedIdentifiers`).
- Để kiểm thử BG-1 đến BG-4 đáng tin, nên dùng iPhone thật, sạc cắm, khoá màn hình, chờ vài giờ.

### 4.2 Cách kiểm thử quét nền
| ID | Bước | Kết quả mong đợi |
|---|---|---|
| BG-T1 | Trên simulator, kích hoạt lượt nền bằng LLDB | Log có dòng bắt đầu và kết thúc lượt nền |
| BG-T2 | Kích hoạt lượt nền khi thư viện đã quét xong | Lượt nền không quét lại ảnh đã có (kiểm tra bằng số file được đọc) |
| BG-T3 | Dừng lượt nền giữa chừng (buộc thoát app) | Lượt kế tiếp tiếp tục, không mất dữ liệu đã lưu |
| BG-T4 | Nạp thêm 10 ảnh rồi kích hoạt lượt nền | Kết quả có thêm ảnh mới |
| BG-T5 | Tắt quét nền trong cài đặt, kích hoạt lượt nền | Không có lượt nào chạy |
| BG-T6 | Thu hồi quyền ảnh, kích hoạt lượt nền | Lượt dừng sớm, không crash |

---

## 5. Báo cáo lỗi

Mỗi lỗi ghi: mã test, thiết bị và phiên bản iOS, các bước tái hiện, kết quả thực tế, kết quả mong đợi, và log (lọc theo `Cleanify` hoặc `scan`). Đính kèm ảnh chụp màn hình nếu là lỗi giao diện.

---

## 6. Các việc chưa làm (để tester không tính vào lỗi)

- Quét nền (mục 4) là **yêu cầu mới, chưa triển khai**. Các test BG-* sẽ đỏ cho đến khi triển khai xong.
- Độ chính xác ORB trên ảnh thật chưa hiệu chỉnh.
- Chưa đo thời gian và dung lượng với thư viện 10.000 ảnh trên iPhone thật.
- Ảnh chụp màn hình và video lớn: chưa có test chi tiết trong tài liệu này.
