# 💰 Tiara Finance - Aplikasi Manajemen Iuran Modern

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-Latest-FFA611?logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Supabase-Latest-3ECF8E?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Platform-Android%20|%20iOS-blue" alt="Platform">
</div>

## 📱 Tentang Aplikasi

Tiara Finance adalah aplikasi mobile modern untuk manajemen keuangan dan iuran komunitas/perumahan. Dibangun dengan Flutter, Firebase Firestore untuk database, dan Supabase Storage untuk penyimpanan gambar.

### ✨ Fitur Utama

#### 👤 **User Features**

- 🏠 **Dashboard Interaktif**

  - Statistik keuangan global dengan chart pie
  - Quick stats (Total Bayar, Pending)
  - Notifikasi pembayaran (setelah tanggal 11)
  - Aktivitas transaksi terbaru
  - Pull-to-refresh
  - Shimmer loading effect

- 💳 **Bayar Iuran**

  - Daftar iuran tersedia
  - Upload bukti pembayaran ke Supabase
  - Status tracking (Menunggu, Sukses, Gagal)
  - Loading indicator saat upload

- 📜 **Riwayat Transaksi**

  - Daftar lengkap transaksi pribadi
  - Filter berdasarkan status
  - Detail transaksi dengan bottom sheet
  - View bukti pembayaran

- 👤 **Profile Management**
  - Edit nama, email, password
  - Logout dengan konfirmasi

#### 🔐 **Admin Features**

- 📊 **Enhanced Dashboard**

  - 4 stat cards (Saldo Kas, Pending, Pemasukan, Pengeluaran)
  - Chart statistik keuangan
  - Quick actions (Tambah Pengeluaran, Buat Iuran, Generate Data)
  - Modern gradient header

- ✅ **Kelola Transaksi**

  - Lihat semua transaksi
  - Filter by status (Semua, Menunggu, Sukses, Gagal)
  - Approve/Reject pembayaran
  - View bukti pembayaran dengan cache

- 💰 **Kelola Iuran**

  - CRUD iuran (Create, Read, Delete)
  - Floating Action Button untuk tambah
  - Konfirmasi sebelum hapus

- 👥 **Kelola User**
  - Daftar semua pengguna
  - Badge role (Admin/User)

## 🚀 **Optimasi yang Telah Dilakukan**

### 1. ✅ **Network & Connectivity**

- Connectivity check realtime
- Retry logic dengan exponential backoff
- Network error handling
- Banner offline notification
- Connection test untuk Supabase

### 2. ⚡ **Performance**

- **High Refresh Rate Support** (60-120Hz)
  - `SystemChrome.setPreferredOrientations`
  - Edge-to-edge display mode
  - Transparent system UI
- Shimmer loading placeholders
- Cached network images
- Pull-to-refresh
- Lazy loading dengan StreamBuilder

### 3. 🔒 **Security & Permissions**

- Network security config
- Proper Android permissions
  - `INTERNET`
  - `ACCESS_NETWORK_STATE`
  - `READ_MEDIA_IMAGES`
  - `READ_EXTERNAL_STORAGE` (legacy)
  - `WRITE_EXTERNAL_STORAGE` (legacy)
- Back button callback enabled
- Cleartext traffic allowed untuk development

### 4. 🎨 **UI/UX Improvements**

- Material 3 design
- Modern Indigo color scheme
- Gradient headers
- Rounded cards & buttons
- Icons with background badges
- Status badges dengan colors
- Bottom sheets untuk detail
- Confirmation dialogs
- Success/Error snackbars dengan emoji
- Pull-to-refresh indicators

### 5. 📱 **Multi-Device Compatibility**

- Responsive layouts
- Hardware acceleration enabled
- Support untuk berbagai screen sizes
- Adaptive untuk 60Hz & 120Hz displays

## 📦 **Dependencies**

```yaml
# Backend
firebase_core: ^3.1.0
cloud_firestore: ^5.0.1
supabase_flutter: ^2.6.0

# Media
image_picker: ^1.1.2

# Charts
fl_chart: ^0.68.0

# Utils
intl: ^0.19.0
shared_preferences: ^2.2.3
uuid: ^4.4.0

# Network & Connectivity
connectivity_plus: ^6.0.5
http: ^1.2.0

# UI Enhancements
shimmer: ^3.0.0
pull_to_refresh: ^2.0.0
flutter_spinkit: ^5.2.1
cached_network_image: ^3.3.1
```

## 🛠️ **Setup & Instalasi**

### Prerequisites

- Flutter SDK >= 3.10.0
- Android Studio / VS Code
- Android device/emulator
- Firebase account
- Supabase account

### Langkah Install

1. **Clone repository**

```bash
git clone <repository-url>
cd tiarafin-main
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Setup Firebase**

   - Buat project di [Firebase Console](https://console.firebase.google.com)
   - Download `google-services.json` → `android/app/`
   - Enable Firestore Database
   - Buat collection: `users`, `iuran`, `transaksi`

4. **Setup Supabase**

   - Buat project di [Supabase](https://supabase.com)
   - Buat storage bucket: `tiara finance`
   - Set public access untuk bucket
   - Copy URL & anon key ke `lib/main.dart`

5. **Run aplikasi**

```bash
flutter run
```

## 📂 **Struktur Project**

```
lib/
├── main.dart                    # Entry point, high refresh rate setup
├── models.dart                  # Data models (User, Iuran, Transaksi)
├── services.dart                # Services (Auth, Firestore, Supabase)
├── firebase_options.dart        # Firebase configuration
└── screens/
    ├── auth_screens.dart        # Login & Register
    ├── user_screens.dart        # User dashboard (4 screens)
    └── admin_screens.dart       # Admin dashboard (5 screens)
```

## 🎯 **User Flow**

### User Journey

```
Login → Dashboard → Bayar Iuran → Upload Bukti → Tunggu Verifikasi
                 → Riwayat → View Detail Transaksi
                 → Profile → Edit Info
```

### Admin Journey

```
Login → Dashboard → View Stats & Chart
                 → Transaksi → Approve/Reject
                 → Iuran → CRUD Iuran
                 → Users → View All Users
                 → Quick Actions → Tambah Pengeluaran/Iuran
```

## 🔧 **Configuration Files**

### AndroidManifest.xml

- ✅ Internet permissions
- ✅ Network state access
- ✅ Media permissions (Android 13+)
- ✅ Back button callback enabled
- ✅ Network security config
- ✅ Hardware acceleration

### Network Security Config

- ✅ Cleartext for Supabase & Firebase domains
- ✅ Trust system & user certificates

## 🌟 **Key Features Details**

### High Refresh Rate (60-120Hz)

```dart
// Automatically detects and enables high refresh rate
await SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
]);
```

### Connectivity Monitoring

```dart
// Real-time network status dengan banner
Connectivity().onConnectivityChanged.listen((result) {
  // Auto-update UI
});
```

### Retry Logic

```dart
// Retry dengan exponential backoff
await NetworkHelper.retryOperation(
  operation: () => uploadImage(),
  maxRetries: 3,
);
```

### Shimmer Loading

```dart
// Smooth loading experience
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Container(...),
)
```

## 📱 **Screenshots Preview**

### User Screens

1. **Dashboard** - Stats, Chart, Recent Activity
2. **Bayar Iuran** - List dengan status badges
3. **Riwayat** - Filter & detail bottom sheet
4. **Profile** - Edit dengan password visibility toggle

### Admin Screens

1. **Dashboard** - 4 stats cards + chart + quick actions
2. **Transaksi** - List dengan filter, approve/reject
3. **Iuran** - CRUD dengan FAB
4. **Users** - List dengan role badges
5. **Profile** - Same as user

## 🐛 **Troubleshooting**

### Internet Connection Error

```
❌ Tidak ada koneksi internet
```

**Solusi:**

- Pastikan device terhubung WiFi/Data
- Check `android:permission.INTERNET` di manifest
- Restart aplikasi

### Upload Gagal

```
❌ Gagal upload gambar
```

**Solusi:**

- Check internet connection
- Verify Supabase bucket accessibility
- Check Supabase URL & key

### Build Error

```bash
flutter clean
flutter pub get
flutter run
```

## 📝 **TODO / Future Enhancements**

- [ ] Dark mode support
- [ ] Export laporan ke PDF
- [ ] Push notifications
- [ ] Multi-language support
- [ ] Email verification
- [ ] Forgot password
- [ ] Data analytics dashboard
- [ ] CSV export/import
- [ ] Kategori iuran
- [ ] Recurring payments reminder

## 👨‍💻 **Developer**

Developed with ❤️ using Flutter

## 📄 **License**

Copyright © 2026 Tiara Finance

---

**Happy Coding! 🚀**
