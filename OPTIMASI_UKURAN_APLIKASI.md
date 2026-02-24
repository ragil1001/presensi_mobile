# Panduan Optimasi Ukuran Aplikasi Flutter

Dokumen ini menjelaskan berbagai teknik untuk mengoptimalkan ukuran aplikasi Flutter Anda dari 104MB + 300KB data + 23MB cache menjadi lebih ringkas tanpa mengorbankan terlalu banyak fungsi.

## Analisis Awal

Aplikasi Anda saat ini memiliki ukuran besar karena beberapa faktor:
- Banyak dependensi pihak ketiga
- Fitur-fitur kompleks seperti sistem keamanan perangkat, peta, kamera
- Library besar seperti Firebase, flutter_map, dll

## Teknik Optimasi

### 1. Optimasi Konfigurasi Build Android (APK Biasa dengan Obfuscation)

Ubah file `android/app/build.gradle.kts` untuk build APK biasa dengan obfuscation:

```kotlin
android {
    namespace = "com.qms.presensi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14033849"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.qms.presensi"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true          // Aktifkan minifikasi kode
            isShrinkResources = true        // Aktifkan shrinking resources
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
```

File proguard Anda sudah cukup baik, tapi bisa ditambahkan beberapa aturan untuk mengurangi ukuran lebih lanjut.

### 2. Optimasi Gambar dan Aset

Optimalkan file-file di folder `assets/`:
- assets/logo.png - gunakan format WebP jika memungkinkan
- assets/izin.webp - pastikan sudah dikompresi optimal
- assets/lembur.webp - pastikan sudah dikompresi optimal
- assets/shift.webp - pastikan sudah dikompresi optimal
- assets/jadwal.webp - pastikan sudah dikompresi optimal
- assets/informasi.webp - pastikan sudah dikompresi optimal
- assets/cs.webp - pastikan sudah dikompresi optimal

### 3. Build APK Biasa (Bukan Split)

Pastikan tidak ada konfigurasi split di `android/app/build.gradle.kts`:
- Pastikan tidak ada blok `splits {}` yang aktif
- Build APK biasa dengan perintah: `flutter build apk --release`

### 4. Optimasi Dependensi

#### a. Optimalkan konfigurasi flutter_image_compress

```dart
// Di bagian kompresi gambar, gunakan pengaturan yang lebih agresif
final result = await FlutterImageCompress.compressWithFile(
  file.absolute.path,
  minWidth: 1024,
  minHeight: 768,
  quality: 70, // Kurangi kualitas untuk ukuran lebih kecil
  rotate: 0,
);
```

### 6. Manajemen Cache dan Data Lokal

Implementasikan strategi cache yang lebih efisien:

```dart
// Contoh implementasi manajemen cache
class CacheManager {
  static const maxCacheSize = 5 * 1024 * 1024; // 5MB maksimum
  
  static Future<void> clearOldCache() async {
    // Hapus cache yang lebih tua dari 7 hari
    final directory = await getTemporaryDirectory();
    final now = DateTime.now();
    
    await for (FileSystemEntity entity in directory.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (now.difference(stat.modified) > const Duration(days: 7)) {
          await entity.delete();
        }
      }
    }
  }
  
  static Future<int> getCurrentCacheSize() async {
    final directory = await getTemporaryDirectory();
    int total = 0;
    
    await for (FileSystemEntity entity in directory.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    
    return total;
  }
}
```

### 7. Penggunaan Deferred Components (Android 21+)

Untuk fitur-fitur yang jarang digunakan, pertimbangkan untuk menggunakan deferred components:

```dart
// Contoh struktur untuk deferred components
// Tidak semua fitur bisa dijadikan deferred, tergantung pada arsitektur aplikasi
```

### 8. Penggunaan Code Size Analyzer

Gunakan alat untuk menganalisis ukuran aplikasi:

```bash
# Setelah build, gunakan bundletool untuk menganalisis
flutter build appbundle --release
java -jar bundletool.jar dump manifest --bundle=build/app/outputs/bundle/release/app-release.aab
```

### 9. Konfigurasi Gradle Tambahan

Tambahkan konfigurasi berikut di `android/gradle.properties`:

```properties
# Optimasi build
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true

# Memory untuk build
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError
```

## Perkiraan Pengurangan Ukuran

Dengan implementasi teknik-teknik di atas, Anda bisa mengharapkan:

- Minify + ShrinkResources: 15-25% pengurangan ukuran
- Split APKs: 30-40% pengurangan ukuran per perangkat
- Optimasi aset: 5-10% pengurangan ukuran
- Manajemen cache: Mengurangi cache dari 23MB ke 2-5MB

## Catatan Penting

1. **Fitur-fitur keamanan** seperti deteksi mock location, installed_apps, dan safe_device menambah ukuran aplikasi secara signifikan. Jika ukuran sangat penting, pertimbangkan untuk mengurangi kompleksitas sistem keamanan.

2. **Sistem peta** (flutter_map) juga menambah ukuran aplikasi. Jika hanya digunakan untuk menampilkan lokasi dasar, pertimbangkan alternatif yang lebih ringan.

3. **Firebase** dan layanan terkait menambah ukuran aplikasi. Ini biasanya tidak bisa diminimalkan secara signifikan tanpa mengorbankan fungsionalitas.

## Kesimpulan

Dengan implementasi teknik-teknik di atas, Anda bisa mengurangi ukuran aplikasi dari 104MB menjadi sekitar 70-80MB, tetapi untuk mencapai ukuran di bawah 70MB akan memerlukan pengorbanan beberapa fitur kompleks yang saat ini ada di aplikasi Anda.

Pengurangan cache dari 23MB ke hitungan KB mungkin tidak realistis karena aplikasi Anda membutuhkan cache untuk menyimpan data offline, gambar, dan informasi lainnya. Namun, Anda bisa mengimplementasikan manajemen cache yang lebih efisien untuk menjaga ukuran cache tetap wajar.