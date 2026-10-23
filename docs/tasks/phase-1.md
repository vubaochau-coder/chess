# Giai đoạn 1 — Chuẩn bị phát hành

Mục tiêu giai đoạn: có thể build một AAB đã ký, có icon/splash, âm thanh hợp lệ để upload Google Play.
Không thêm tính năng gameplay trong giai đoạn này.

---

## T1.1 — Cấu hình build release (R8, AAB trong CI)

**Mục tiêu:** bản release được thu gọn mã/tài nguyên, CI xuất cả APK và AAB.

**Phạm vi**
- Trong `android/app/build.gradle.kts`, block `buildTypes.release`: khai báo tường minh
  `isMinifyEnabled = true`, `isShrinkResources = true`,
  `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`.
- Tạo `android/app/proguard-rules.pro` (được phép rỗng, chỉ thêm rule khi build/chạy release lỗi;
  mỗi rule có comment giải thích).
- Trong `.github/workflows/ci.yml`, job `build-android`: thêm bước
  `flutter build appbundle --release` sau bước build APK (CI gọi `flutter` trực tiếp, không qua fvm) và upload `build/app/outputs/bundle/release/app-release.aab`
  thành artifact `app-release-aab` (retention 7 ngày). Giữ nguyên các bước khác.
- Chạy bản release trên thiết bị/emulator, kiểm tra: mở app, đi vài nước, âm thanh phát, chiếu hết hiển thị đúng.

**Ngoài phạm vi:** ký app bằng keystore thật (T1.4), đổi version, icon, đổi `applicationId`.

**File được sửa:** `android/app/build.gradle.kts`, `android/app/proguard-rules.pro`, `.github/workflows/ci.yml`.

**Package được phép:** không.

**Tiêu chí nghiệm thu**
- [ ] `fvm flutter build apk --release` và `fvm flutter build appbundle --release` thành công cục bộ.
- [ ] CI xanh, có 2 artifact `app-release-apk` và `app-release-aab`.
- [ ] Bản release chạy đúng trên Android (ghi model thiết bị/emulator + API level trong PR).
- [ ] Ghi kích thước APK và AAB trước/sau trong mô tả PR.

---

## T1.2 — Icon app và splash screen

**Mục tiêu:** app có icon riêng (kể cả adaptive icon) và màn hình khởi động theo màu thương hiệu.

**Đầu vào cần owner** (đặt sẵn trong repo trước khi bắt đầu):
- `assets/branding/icon.png` — 1024×1024, nền đặc (không trong suốt).
- `assets/branding/icon_foreground.png` — 1024×1024, nền trong suốt, nội dung nằm trong vùng an toàn
  ở giữa (~66%) cho adaptive icon.
- Mã màu nền adaptive icon và màu nền splash (hex).
- Tên hiển thị của app trên launcher (hiện là `Chess`).

**Phạm vi**
- Thêm 2 dev dependency bên dưới, cấu hình trong file riêng `flutter_launcher_icons.yaml` và
  `flutter_native_splash.yaml` ở thư mục gốc (không cấu hình trong `pubspec.yaml`).
- Chỉ bật cho Android (`android: true`, `ios: false`, không web/desktop).
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

**Ngoài phạm vi:** thêm hiệu ứng mới, chỉnh âm lượng, chọn bộ âm thanh (T5.x), sửa `SoundPlayer`.

**File được sửa:** `assets/audio/**`, `assets/LICENSES.md`, `lib/core/audio/sound_effect.dart`, `pubspec.yaml`.

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
