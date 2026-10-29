# Cleanify — Kế hoạch xây dựng app Flutter

> Trạng thái: **bản nháp chờ duyệt**. Chưa có dòng code nào được viết.
> Quy tắc làm việc: mỗi mục dưới đây được trình bày trước, chủ dự án confirm rồi mới triển khai.

## 1. Mục tiêu

Dựng lại toàn bộ app **Cleanify** (dọn ảnh trùng, file lớn, giải phóng dung lượng) bằng **Flutter/Dart** cho Android và iOS, theo thiết kế Figma:
https://www.figma.com/design/VesxbrRh84c6tumqYxgJ6i/Untitled?node-id=0-1

Repo: https://github.com/thanhtri-ba/Cleanify.git (hiện trống, build từ đầu).

## 2. Phạm vi thiết kế (từ Figma, 10 section)

Đã xác định:
- **01 · Bắt đầu:** Onboarding (3 màn), File Access Permissions.
- **02 · Luồng chính:** Home (thẻ dung lượng, nút quét, mục xem nhanh ảnh trùng / file lớn), Đang quét, Có kết quả, Đang dọn, Quét thất bại.
- **10 · Bổ sung:** Large Files (+ trạng thái rỗng), Group Review, Delete Confirmation (bottom sheet), Delete Success (bottom sheet), Clean Hub, Notifications, Language, Cleanup Confirmation, Privacy Policy, Photo Cleaner rỗng.

Chưa liệt kê: section **03–09** (sẽ lấy từng section theo node-id ở Mục 0 và cập nhật file này).

Bottom navigation: 5 tab (tên tab đọc chính xác từ Figma ở Mục 1).

## 3. Quyết định kỹ thuật (đề xuất, chờ confirm)

| Hạng mục | Lựa chọn | Lý do |
|---|---|---|
| State management | flutter_riverpod | Dễ test, hợp logic bất đồng bộ (quét ảnh, tiến độ) |
| Routing | go_router | Hỗ trợ shell route cho bottom navigation |
| Đọc / xóa media | photo_manager | Truy cập thư viện ảnh, xóa qua hộp thoại xác nhận của hệ điều hành |
| Quyền | permission_handler | Xử lý cấp quyền, từ chối, từ chối vĩnh viễn, quyền giới hạn (iOS) |
| Cài đặt cục bộ | shared_preferences | Ngôn ngữ, thông báo, tùy chọn xác nhận xóa |
| Thông báo nhắc quét | flutter_local_notifications | Nhắc quét định kỳ |
| Ngôn ngữ | Tiếng Việt + English trước | Các ngôn ngữ khác trong màn Language thêm sau |
| Thanh toán | Chỉ dựng giao diện "Restore Purchases" | Chưa làm in-app purchase |

Nguyên tắc: không thêm thư viện nếu chưa cần; thư viện của mục nào thì thêm ở mục đó.

## 4. Cấu trúc thư mục dự kiến

```
lib/
  core/        theme (tokens từ Figma), router, l10n, widgets dùng chung
  features/
    onboarding/  permission/  home/  scan/
    duplicates/  large_files/ clean_hub/ settings/
  data/        media_repository, scan_history_store
  domain/      duplicate_detector, photo_scorer, models
test/
```

## 5. Các mục triển khai

Đánh dấu `[ ]` chưa làm, `[~]` đang làm, `[x]` xong và đã kiểm chứng.

- [ ] **Mục 0 — Phân tích Figma:** liệt kê đủ 10 section / mọi màn hình, trích design tokens (màu, font, spacing, bo góc). Kết quả: danh sách màn hình và tính năng cuối cùng, cập nhật vào file này.
- [ ] **Mục 1 — Nền tảng:** `pubspec.yaml`, theme từ tokens, router + bottom navigation 5 tab, các màn khung rỗng, widget test điều hướng, README. *Kiểm chứng:* `flutter pub get`, `flutter analyze`, `flutter test`.
- [ ] **Mục 2 — Onboarding + Permission:** 3 màn onboarding, màn File Access Permissions, xử lý mọi trạng thái quyền (cấp, từ chối, từ chối vĩnh viễn, giới hạn trên iOS, bỏ qua). *Kiểm chứng:* widget test từng trạng thái quyền.
- [ ] **Mục 3 — Logic quét (phần quan trọng nhất):**
  - Lấy danh sách media, tính perceptual hash (dHash) trong isolate để không treo giao diện.
  - Gom nhóm ảnh trùng bằng bucket, tránh so sánh từng cặp O(n²) để thư viện lớn vẫn quét nhanh.
  - Chấm điểm chọn ảnh tốt nhất trong nhóm (độ phân giải, dung lượng, độ mới).
  - Quét có tiến độ, hủy được, tiếp tục được khi bị ngắt; lưu lịch sử quét.
  *Kiểm chứng:* unit test hash, gom nhóm, chấm điểm, và test với dữ liệu giả lớn.
- [ ] **Mục 4 — Home và luồng quét:** Home (thẻ dung lượng, nút quét), Đang quét, Có kết quả, Quét thất bại. *Kiểm chứng:* test luồng trạng thái.
- [ ] **Mục 5 — Group Review và xóa an toàn:** Group Review, Delete Confirmation, Delete Success. Luôn giữ ít nhất 1 ảnh mỗi nhóm; chỉ xóa sau khi người dùng đồng ý; xử lý lỗi một phần; dung lượng giải phóng tính theo kết quả thật. *Kiểm chứng:* test chặn xóa hết ảnh trong nhóm, test hủy giữa chừng.
- [ ] **Mục 6 — Large Files:** lọc, sắp xếp, chọn nhiều, thanh chọn dính đáy, trạng thái rỗng. *Kiểm chứng:* widget test.
- [ ] **Mục 7 — Clean Hub và Cài đặt:** Clean Hub, Notifications, Language, Cleanup Confirmation, Privacy Policy, Photo Cleaner rỗng. *Kiểm chứng:* widget test.
- [ ] **Mục 8 — Hoàn thiện và kiểm chứng tổng:** nhắc quét định kỳ, rà soát loading / empty / error / success / disabled state ở mọi màn, `flutter analyze`, `flutter test`, build debug Android / iOS.

## 6. Quy trình làm việc

1. Với mỗi mục: Claude trình bày chi tiết việc sẽ làm → chủ dự án confirm → Claude viết code vào thư mục này.
2. Chủ dự án chạy các lệnh kiểm chứng trên máy (Claude không chạy được Flutter ở môi trường của mình) và gửi lại kết quả. Claude chỉ báo "xong" khi có kết quả thực tế.
3. Mỗi mục xong là một commit riêng.

## 7. Rủi ro và hạn chế đã biết

- Claude không chạy được `flutter analyze` / `flutter test` / build; mọi kiểm chứng dựa vào kết quả bạn chạy.
- Xóa ảnh trên iOS và Android 11+ luôn hiện hộp thoại xác nhận của hệ điều hành (giới hạn nền tảng).
- Thư viện ảnh lớn có thể quét lâu; cần đo hiệu năng trên máy thật.
- Section Figma 03–09 chưa liệt kê, phạm vi có thể thay đổi sau Mục 0.

## 8. Lệnh khởi tạo và đẩy lên GitHub (chạy trong thư mục này)

```bash
# Khởi tạo project Flutter (một lần, không ghi đè lib/ nếu đã có)
flutter create . --org com.thanhtri --project-name cleanify --platforms android,ios

# Đẩy lên GitHub
git init
git remote add origin https://github.com/thanhtri-ba/Cleanify.git
git add .
git commit -m "docs: add build plan"
git branch -M main
git push -u origin main
```

---

## Trạng thái (cập nhật 2026-10-28)

**Bước hiện tại: Onboarding + Auth (viết xong, CHƯA chạy analyze/test)**

- [x] Foundation: theme, router (redirect thuần + test), storage, widgets chung
- [x] Onboarding 3 slide
- [x] Sign in / Create account / Forgot password / Verify email (FakeAuthRepository)
- [x] Test: validators, redirect, fake repo, sign-in controller, verify cooldown, widget flow
- [ ] Người dùng chạy: `flutter create`, `bash tool/fetch_assets.sh`, `flutter pub get`, `flutter analyze`, `flutter test`
- [ ] Chốt backend auth (đề xuất: Supabase) và thay FakeAuthRepository
- [ ] Bundle font Inter, đa ngôn ngữ vi/en

**Mục kế tiếp (chờ xác nhận):** File Access Permissions + màn xin quyền ảnh.

## Trạng thái lô 2 (Home + luồng quét/dọn) — CHƯA biên dịch, CHƯA chạy test
- Domain/application/data: scanner, cleanup plan/runner, controllers, PhotoManager source.
- UI: Home, Smart Scan, Scan Complete, Review Cleanup, Cleaning, Cleanup Complete, Scan Error, No Items, Partial Results; bottom nav (Home/Storage/Settings, 2 tab sau là placeholder).
- Chưa nối: Large Videos, App Manager, Storage Analysis, Recent activity, chuông thông báo (các lô sau).
- Cần dọn tay: `rm lib/features/home/presentation/home_placeholder_page.dart` (không còn dùng).
- Việc kiểm tra: `flutter pub get && flutter analyze && flutter test`, rồi chạy thật trên máy có ảnh.

## Trạng thái lô 3 (so ảnh tương tự toàn thư viện) — CHƯA biên dịch, CHƯA chạy test
- Thêm `union_find.dart`, `near_duplicate_index.dart` (chỉ mục 4 đoạn 16 bit, đảm bảo tìm đủ cặp cách nhau <= 3 bit), `ImageHash.bitCount`.
- `MediaScanner`: nếu `ScanConfig.globalMaxDistance > 0`, nối cụm theo cửa sổ thời gian với ảnh ngoài cửa sổ (cùng tỉ lệ khung hình, bỏ ảnh gần phẳng). Mặc định 0 = tắt, nên test cũ giữ nguyên.
- `scanConfigProvider` bật `globalMaxDistance: 3`. Muốn quay lại hành vi cũ: đổi về `const ScanConfig()`.
- Test mới: `union_find_test`, `near_duplicate_index_test` (so với vét cạn), nhóm "so sánh toàn thư viện" trong `media_scanner_test`.
- Việc kiểm tra: `flutter pub get && flutter analyze && flutter test`, rồi quét thật trên máy có ảnh và xem có nhóm sai không (hiệu chỉnh `globalMaxDistance` 1..3).
- Chưa làm: SHA-256 xác nhận trùng y hệt, lưu hash vào SQLite để quét tăng dần, PDQ qua FFI, SSIM / ORB.
