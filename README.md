# Cleanify

App Flutter dọn ảnh trùng, file lớn và giải phóng dung lượng. Xem `PLAN.md`.

## Chạy lần đầu

```bash
# 1. Sinh thư mục android/ và ios/ (chỉ một lần; giữ nguyên lib/ và pubspec.yaml)
flutter create . --org com.thanhtri --project-name cleanify --platforms android,ios
#    Nếu lệnh trên tạo test/widget_test.dart mặc định (tham chiếu MyApp) thì xóa file đó.

# 2. Tải icon và ảnh minh họa từ Figma
bash tool/fetch_assets.sh

# 2b. Khai báo quyền ảnh/video cho Android + iOS
bash tool/configure_platforms.sh

# 3. Kiểm tra
flutter pub get
flutter analyze
flutter test

# 4. Chạy
flutter run
```

## Trạng thái

- Đã có: Onboarding (3 slide), Sign in, Create account, Forgot password,
  Verify email, điều hướng theo trạng thái đăng nhập.
- Tạm thời: `FakeAuthRepository` (bộ nhớ, chỉ để phát triển). Cần thay bằng
  backend thật trước khi phát hành.
- Chưa có: font Inter (đang dùng font hệ thống), đa ngôn ngữ, các màn còn lại.
