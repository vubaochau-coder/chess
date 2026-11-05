# Giai đoạn 1 — Chuẩn bị phát hành

Mục tiêu giai đoạn: có thể build một AAB đã ký, có icon/splash, âm thanh hợp lệ để upload Google Play.
Không thêm tính năng gameplay trong giai đoạn này.

---

## T1.1 — Cấu hình build release (R8) và tinh gọn CI

**Mục tiêu:** bản release được thu gọn mã/tài nguyên; CI chỉ kiểm tra (format, analyze, test) để PR chạy
nhanh, việc build release chỉ còn ở workflow `Distribute`.

> Đặc tả đổi theo quyết định owner (2026-11-04): bản đầu yêu cầu CI build thêm AAB; nay bỏ hẳn bước build
> khỏi `ci.yml` vì `Distribute` đã build APK release trên `main`. AAB đã ký do T1.4 (`release.yml`) tạo.

**Phạm vi**
- Trong `android/app/build.gradle.kts`, block `buildTypes.release`: khai báo tường minh
  `isMinifyEnabled = true`, `isShrinkResources = true`,
  `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`.
- Tạo `android/app/proguard-rules.pro` (được phép rỗng, chỉ thêm rule khi build/chạy release lỗi;
  mỗi rule có comment giải thích).
- Trong `.github/workflows/ci.yml`: xóa job `build-android`. Giữ nguyên job `check`.
- Chạy bản release trên thiết bị/emulator, kiểm tra: mở app, đi vài nước, âm thanh phát, chiếu hết hiển thị đúng.

**Ngoài phạm vi:** ký app bằng keystore thật (T1.4), build AAB, sửa `distribute.yml`, đổi version, icon,
đổi `applicationId`.

**File được sửa:** `android/app/build.gradle.kts`, `android/app/proguard-rules.pro`, `.github/workflows/ci.yml`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] `fvm flutter build apk --release` thành công cục bộ.
- [ ] CI xanh và không còn job build; workflow `Distribute` trên `main` build và đẩy bản release thành công.
- [ ] Bản release chạy đúng trên Android (ghi model thiết bị/emulator + API level trong PR).
- [ ] Ghi kích thước APK trước/sau trong mô tả PR.

---

## T1.2 — Icon app và splash screen

**Mục tiêu:** app có icon riêng (kể cả adaptive icon) và màn hình khởi động theo màu thương hiệu.

**Đầu vào cần owner** (đặt sẵn trong repo trước khi bắt đầu):
- `assets/branding/icon.png` — 1024×1024, nền đặc (không trong suốt).
- `assets/branding/icon_foreground.png` — 1024×1024, nền trong suốt, nội dung nằm trong vùng an toàn
  ở giữa (~66%) cho adaptive icon.
- `assets/branding/icon_background.png` — 1024×1024, nền đặc, dùng làm lớp nền adaptive icon
  (owner chốt dùng ảnh thay cho mã màu vì nền logo chia đôi hai màu).
- Mã màu nền splash (hex).
- Tên hiển thị của app trên launcher (hiện là `Chess`).

**Phạm vi**
- Thêm 2 dev dependency bên dưới, cấu hình trong file riêng `flutter_launcher_icons.yaml` và
  `flutter_native_splash.yaml` ở thư mục gốc (không cấu hình trong `pubspec.yaml`).
- Chỉ bật cho Android (`android: true`, `ios: false`, không web/desktop).
- Adaptive icon: `adaptive_icon_background` trỏ tới `assets/branding/icon_background.png`,
  `adaptive_icon_foreground` trỏ tới `assets/branding/icon_foreground.png`.
- Splash: màu nền + `assets/branding/icon_foreground.png` ở giữa, có cấu hình `android_12`.
- Chạy generator, commit các file sinh ra trong `android/app/src/main/res/`.
- Đổi `android:label` trong `AndroidManifest.xml` thành tên owner cung cấp.
- Thêm vào `AGENTS.md` mục 4 hai lệnh tái tạo icon/splash.

**Ngoài phạm vi:** splash động/animation, đổi icon iOS, thay đổi UI trong Flutter.

**File được sửa:** `pubspec.yaml`, `pubspec.lock`, `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml`,
`android/app/src/main/res/**`, `android/app/src/main/AndroidManifest.xml`, `AGENTS.md` (chỉ mục 4).

**Package được phép (dev_dependencies):** `flutter_launcher_icons: 0.14.4`, `flutter_native_splash: 2.4.8`.

**Tiêu chí nghiệm thu**
- [ ] Icon hiển thị đúng trên launcher Android 8+ (adaptive) và Android 7 (legacy).
- [ ] Splash hiển thị đúng màu/logo trên Android 12+ và dưới 12.
- [ ] Tên app trên launcher đúng tên owner cung cấp.
- [ ] Ảnh chụp màn hình launcher + splash đính kèm trong PR.

---

## T1.3 — Thay bộ âm thanh có giấy phép

**Mục tiêu:** toàn bộ âm thanh trong app có nguồn và giấy phép rõ ràng, bỏ file không dùng.

**Đầu vào cần owner:** 8 file âm thanh (mp3 hoặc ogg) cho các hiệu ứng `select, illegal, move, capture,
castle, check, promote, gameEnd`, kèm nguồn tải và tên giấy phép của từng file.

**Phạm vi**
- Đặt file vào `assets/audio/standard/` với tên: `select`, `illegal`, `move`, `capture`, `castle`,
  `check`, `promote`, `game_end` (giữ phần mở rộng gốc).
- **Xóa toàn bộ** file cũ trong `assets/audio/` (cả các file đang không dùng).
- Cập nhật đường dẫn trong `lib/core/audio/sound_effect.dart` (chỉ đổi chuỗi đường dẫn, giữ nguyên tên enum).
- Đổi khai báo asset trong `pubspec.yaml` thành `assets/audio/standard/`.
- Tạo `assets/LICENSES.md`: bảng gồm file, nguồn (URL), tác giả, giấy phép.
- Thêm `Credit` cho bộ âm thanh vào `lib/core/credits/credits.dart` (T1.5); nếu giấy phép yêu cầu kèm văn bản,
  lưu vào `assets/licenses/` và đặt `licenseAsset`.

**Ngoài phạm vi:** thêm hiệu ứng mới, chỉnh âm lượng, chọn bộ âm thanh (T5.x), sửa `SoundPlayer`.

**File được sửa:** `assets/audio/**`, `assets/LICENSES.md`, `lib/core/audio/sound_effect.dart`, `pubspec.yaml`,
`lib/core/credits/credits.dart`, `assets/licenses/**`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] `assets/audio/` chỉ còn thư mục `standard/` với đúng 8 file.
- [ ] Mỗi file có dòng tương ứng trong `assets/LICENSES.md`; giấy phép cho phép dùng thương mại
      (CC0, CC-BY, MIT… — CC-BY phải ghi công trong app sẽ được xử lý ở task khác, ghi chú trong PR).
- [ ] Chạy app trên Android: cả 8 âm thanh phát đúng tình huống.

---

## T1.4 — Ký app trong CI bằng GitHub Secrets

**Mục tiêu:** tạo AAB đã ký bằng upload key từ CI để owner tải lên Play Console.

**Đầu vào cần owner:** upload keystore đã tạo và 4 GitHub Secrets:
`ANDROID_KEYSTORE_BASE64` (keystore mã hóa base64), `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

**Phạm vi**
- Tạo workflow mới `.github/workflows/release.yml`, chạy khi push tag `v*` và `workflow_dispatch`.
- Các bước: checkout → đọc Flutter version từ `.fvmrc` (giống `ci.yml`) → setup Java 17 + Flutter →
  `flutter pub get --enforce-lockfile` → `flutter test` → giải mã keystore ra `android/upload-keystore.jks`
  → ghi `android/key.properties` (đường dẫn `storeFile` trỏ tới file vừa giải mã) →
  `flutter build appbundle --release` → upload artifact `app-release-signed-aab` (retention 30 ngày).
- Nếu thiếu bất kỳ secret nào: job fail ngay với thông báo rõ secret nào thiếu.
- Tag phải khớp version trong `pubspec.yaml` (`v1.2.3` ↔ `version: 1.2.3+N`); không khớp → fail.
- Thêm vào `AGENTS.md` mục 8 một đoạn ngắn: cách phát hành (sửa version → merge → tạo tag).

**Ngoài phạm vi:** tự động upload lên Google Play (fastlane, Play Developer API), tạo GitHub Release, sửa `ci.yml`.

**File được sửa:** `.github/workflows/release.yml`, `AGENTS.md` (chỉ mục 8).

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Chạy `workflow_dispatch` với secrets đầy đủ → có AAB; `jarsigner -verify` báo đã ký bằng upload key (ghi kết quả vào PR).
- [ ] Thiếu secret → fail với thông báo rõ ràng.
- [ ] Không có keystore, mật khẩu hay `key.properties` nào bị commit hoặc in ra log.

---

## T1.5 — Mục Giới thiệu: ghi công và giấy phép

**Mục tiêu:** trước khi phát hành, app hiển thị ghi công tác giả tài nguyên và đầy đủ thông báo giấy phép
(bắt buộc với BSD/MIT/Apache khi phát hành dạng app), từ một mục `Giới thiệu` ở màn Cài đặt.

**Quyết định owner (2026-11-05):** làm ngay, không chờ T1.3; bộ âm thanh hiện tại chưa rõ nguồn nên **chưa**
ghi công — T1.3 thêm `Credit` cho bộ âm thanh mới. Không thêm package; không mở link ngoài (chỉ hiện chữ).

**Đầu vào cần owner:** không.

**Phạm vi**
- `lib/core/credits/credits.dart` (thuần Dart): danh sách ghi công là **nguồn duy nhất** cho cả UI và trang giấy
  phép.
  ```dart
  final class Credit {
    const Credit({required this.title, required this.author, required this.license, this.licenseAsset});
    final String title;        // 'Bộ quân Cổ điển'
    final String author;       // 'Colin M.L. Burnett (Cburnett)'
    final String license;      // 'BSD'
    final String? licenseAsset; // file văn bản giấy phép đầy đủ, null nếu không cần (vd. CC0)
  }
  const List<Credit> credits = [...];
  ```
  Gồm: bộ quân Cổ điển (Cburnett, BSD), bộ quân Gỗ/Phẳng/Hiện đại (RhosGFX, CC0), logo app (ghép từ bộ Gỗ,
  CC0).
- Văn bản giấy phép BSD của Cburnett lưu nguyên văn tại `assets/licenses/CBURNETT_LICENSE.txt` (nguồn: mục
  Licensing trên Wikimedia Commons, vd. `File:Chess_klt45.svg`; trang chỉ ghi chủ sở hữu là "The author" nên thêm
  một dòng đầu nêu tác giả và nguồn), khai báo riêng từng file giấy phép trong `pubspec.yaml`.
- Đăng ký giấy phép tài nguyên vào `LicenseRegistry.addLicense` (trong `main()`, trước `runApp`), đọc file qua
  `rootBundle`, cho mọi `Credit` có `licenseAsset`, để chúng hiện chung với giấy phép package trong trang có sẵn
  của Flutter.
- Màn Cài đặt: thêm nhóm cuối `Giới thiệu` (`SectionLabel` + `Card` như các nhóm khác):
  - Dòng đầu: logo app (`assets/branding/icon.svg`, cắt tròn) + tên `Cờ Vua`.
  - Phần `Ghi công`: mỗi `Credit` một dòng — tiêu đề, tác giả, giấy phép.
  - Dòng `Giấy phép mã nguồn mở` (có mũi tên) mở `showLicensePage(applicationName: 'Cờ Vua', applicationIcon: logo)`.
- Cập nhật `docs/architecture.md`: thêm `lib/core/credits/` vào sơ đồ thư mục.

**Ngoài phạm vi:** hiển thị số phiên bản (cần package `package_info_plus` — task riêng nếu owner muốn), mở link
web, chính sách quyền riêng tư, đánh giá app, trang cảm ơn người ủng hộ.

**File được sửa:** `lib/core/credits/**`, `lib/main.dart`, `lib/features/settings/view/settings_page.dart`,
`assets/licenses/**`, `pubspec.yaml`, `test/**`, `docs/architecture.md`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] Màn Cài đặt có nhóm `Giới thiệu` với logo, tên app, danh sách ghi công khớp `assets/LICENSES.md`
      (trừ âm thanh, chờ T1.3).
- [ ] `Giấy phép mã nguồn mở` mở trang giấy phép; trang có mục giấy phép của bộ quân Cổ điển cùng các package.
- [ ] Mọi tài nguyên trong `assets/LICENSES.md` đều có `Credit` tương ứng (liệt kê đối chiếu trong mô tả PR).
- [ ] Widget test: nhóm `Giới thiệu` hiển thị đủ ghi công; bấm `Giấy phép mã nguồn mở` mở `LicensePage`.
- [ ] Unit test: mỗi `licenseAsset` khai báo tồn tại trong bundle và không rỗng.

