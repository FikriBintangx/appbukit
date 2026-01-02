import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiara_fin/models.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class Utils {
  static String formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  /// Format DateTime ke string readable
  static String formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Format DateTime ke string dengan jam
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class NetworkHelper {
  /// Check apakah device terhubung ke internet
  static Future<bool> isConnected() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.mobile) &&
          !connectivity.contains(ConnectivityResult.wifi)) {
        return false;
      }

      // Double check dengan ping ke Google
      final result = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      return result.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Retry function dengan exponential backoff
  static Future<T?> retryOperation<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int retryCount = 0;
    Duration delay = initialDelay;

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('Failed after $maxRetries attempts: $e');
        }

        // Wait before retry with exponential backoff
        await Future.delayed(delay);
        delay *= 2; // Double the delay each time
      }
    }

    return null;
  }
}

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  Future<String?> uploadImage(File file) async {
    try {
      // Check internet connection first
      final isConnected = await NetworkHelper.isConnected();
      if (!isConnected) {
        throw Exception('Tidak ada koneksi internet');
      }

      final ext = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$ext';

      // Upload dengan retry logic
      await NetworkHelper.retryOperation(
        operation: () =>
            client.storage.from('tiara finance').upload(fileName, file),
        maxRetries: 3,
      );

      final String publicUrl = client.storage
          .from('tiara finance')
          .getPublicUrl(fileName);
      return publicUrl;
    } on SocketException {
      print("❌ Network Error: Tidak ada koneksi internet");
      return null;
    } on TimeoutException {
      print("❌ Timeout: Upload memakan waktu terlalu lama");
      return null;
    } catch (e) {
      print("❌ Supabase Error: $e");
      return null;
    }
  }

  /// Test connection ke Supabase
  Future<bool> testConnection() async {
    try {
      final response = await client.storage.listBuckets();
      return response.isNotEmpty;
    } catch (e) {
      print("❌ Supabase Connection Test Failed: $e");
      return false;
    }
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seed default iuran (one-time setup)
  Future<void> seedDefaultIuran() async {
    final seeds = [
      {
        'nama': 'Iuran Rutin Bulanan',
        'harga': 50000,
        'deskripsi': 'Iuran wajib bulanan warga.',
      },
      {
        'nama': 'Iuran Keamanan',
        'harga': 30000,
        'deskripsi': 'Untuk menjaga keamanan lingkungan.',
      },
      {
        'nama': 'Iuran Kesehatan',
        'harga': 20000,
        'deskripsi': 'Dana kesehatan darurat warga.',
      },
      {
        'nama': 'Iuran Kebersihan',
        'harga': 15000,
        'deskripsi': 'Untuk menjaga kebersihan lingkungan.',
      },
    ];

    final col = _db.collection('iuran');

    for (var s in seeds) {
      // Cek apakah sudah ada iuran dengan nama tersebut
      final check = await col.where('nama', isEqualTo: s['nama']).get();
      if (check.docs.isEmpty) {
        await col.add(s);
      }
    }
  }

  /// CLEAR ALL DATA & SEED NEW DATA (RESET DATABASE)
  Future<void> clearAndSeedAllData() async {
    try {
      print('🗑️ Clearing all collections...');

      // Clear collections
      await _clearCollection('users');
      await _clearCollection('iuran');
      await _clearCollection('transaksi');

      print('✅ Collections cleared!');
      print('🌱 Seeding new data...');

      // Seed Users
      final userCol = _db.collection('users');

      // Add User (aceva/sadewa167)
      final userDoc = await userCol.add({
        'nama': 'Aceva',
        'email': 'aceva@user.com',
        'password': 'sadewa167',
        'role': 'user',
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
      print('✅ User created: ${userDoc.id}');

      // Add Admin (aceva/acevo123)
      final adminDoc = await userCol.add({
        'nama': 'Aceva Admin',
        'email': 'aceva@admin.com',
        'password': 'acevo123',
        'role': 'admin',
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
      print('✅ Admin created: ${adminDoc.id}');

      // Seed Iuran
      final iuranCol = _db.collection('iuran');
      final iuranData = [
        {
          'nama': 'Iuran Keamanan',
          'harga': 150000,
          'deskripsi': 'Iuran keamanan lingkungan per bulan',
          'created_at': Timestamp.now(),
        },
        {
          'nama': 'Iuran Kebersihan',
          'harga': 100000,
          'deskripsi': 'Iuran kebersihan dan sampah',
          'created_at': Timestamp.now(),
        },
        {
          'nama': 'Iuran Sampah',
          'harga': 100000,
          'deskripsi': 'Iuran pengelolaan sampah',
          'created_at': Timestamp.now(),
        },
        {
          'nama': 'Iuran Sosial',
          'harga': 50000,
          'deskripsi': 'Dana sosial untuk kegiatan warga',
          'created_at': Timestamp.now(),
        },
      ];

      final iuranIds = <String>[];
      for (var iuran in iuranData) {
        final doc = await iuranCol.add(iuran);
        iuranIds.add(doc.id);
        print('✅ Iuran created: ${iuran['nama']}');
      }

      // Seed Dummy Transaksi
      final transaksiCol = _db.collection('transaksi');

      // Transaksi sukses (pemasukan)
      await transaksiCol.add({
        'iuran_id': iuranIds[0],
        'user_id': userDoc.id,
        'user_name': 'Aceva',
        'uang': 150000,
        'tipe': 'pemasukan',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 5)),
        ),
        'deskripsi': 'Bayar: Iuran Keamanan',
        'bukti_gambar': null,
        'status': 'sukses',
      });

      // Transaksi menunggu approval
      await transaksiCol.add({
        'iuran_id': iuranIds[1],
        'user_id': userDoc.id,
        'user_name': 'Aceva',
        'uang': 100000,
        'tipe': 'pemasukan',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
        'deskripsi': 'Bayar: Iuran Kebersihan',
        'bukti_gambar': null,
        'status': 'menunggu',
      });

      // Pengeluaran admin
      await transaksiCol.add({
        'iuran_id': null,
        'user_id': adminDoc.id,
        'user_name': 'Aceva Admin',
        'uang': 500000,
        'tipe': 'pengeluaran',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
        'deskripsi': 'Pembelian perlengkapan kebersihan',
        'bukti_gambar': null,
        'status': 'sukses',
      });

      await transaksiCol.add({
        'iuran_id': null,
        'user_id': adminDoc.id,
        'user_name': 'Aceva Admin',
        'uang': 350000,
        'tipe': 'pengeluaran',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'deskripsi': 'Gaji satpam bulan ini',
        'bukti_gambar': null,
        'status': 'sukses',
      });

      print('✅ Transaksi dummy created!');
      print('🎉 Database reset complete!');
      print('═══════════════════════════════════');
      print('📧 User Login:');
      print('   Email: aceva@user.com');
      print('   Password: sadewa167');
      print('═══════════════════════════════════');
      print('👨‍💼 Admin Login:');
      print('   Email: aceva@admin.com');
      print('   Password: acevo123');
      print('═══════════════════════════════════');
    } catch (e) {
      print('❌ Error seeding data: $e');
      rethrow;
    }
  }

  /// Helper: Clear a collection
  Future<void> _clearCollection(String collectionName) async {
    final snapshot = await _db.collection(collectionName).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    print('  ✓ Cleared $collectionName (${snapshot.docs.length} docs)');
  }

  Stream<List<IuranModel>> getIuranList() {
    return _db.collection('iuran').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => IuranModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> tambahIuran(String nama, int harga, String deskripsi) async {
    await _db.collection('iuran').add({
      'nama': nama,
      'harga': harga,
      'deskripsi': deskripsi,
      'created_at': Timestamp.now(),
    });
  }

  Future<void> deleteIuran(String iuranId) async {
    await _db.collection('iuran').doc(iuranId).delete();
  }

  Future<void> updateIuran(
    String iuranId,
    String nama,
    int harga,
    String deskripsi,
  ) async {
    await _db.collection('iuran').doc(iuranId).update({
      'nama': nama,
      'harga': harga,
      'deskripsi': deskripsi,
      'updated_at': Timestamp.now(),
    });
  }

  Stream<List<TransaksiModel>> getTransaksiList() {
    return _db
        .collection('transaksi')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransaksiModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<TransaksiModel>> getUserTransaksi(String userId) {
    return _db
        .collection('transaksi')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransaksiModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> bayarIuran(
    UserModel user,
    IuranModel iuran,
    String buktiUrl,
  ) async {
    final now = DateTime.now();
    final periode =
        "${now.month.toString().padLeft(2, '0')}-${now.year}"; // MM-YYYY

    await _db.collection('transaksi').add({
      'iuran_id': iuran.id,
      'user_id': user.id,
      'user_name': user.nama,
      'uang': iuran.harga,
      'tipe': 'pemasukan',
      'timestamp': Timestamp.now(),
      'deskripsi': 'Bayar: ${iuran.nama}',
      'bukti_gambar': buktiUrl,
      'status': 'menunggu',
      'periode': periode,
    });
  }

  // Admin mencatat pembayaran warga (Langsung Sukses)
  Future<void> catatPembayaranAdmin(
    String userId,
    String userName,
    IuranModel iuran,
  ) async {
    final now = DateTime.now();
    final periode = "${now.month.toString().padLeft(2, '0')}-${now.year}";

    await _db.collection('transaksi').add({
      'iuran_id': iuran.id,
      'user_id': userId,
      'user_name': userName,
      'uang': iuran.harga,
      'tipe': 'pemasukan',
      'timestamp': Timestamp.now(),
      'deskripsi': 'Bayar Manual (Admin): ${iuran.nama}',
      'bukti_gambar': null,
      'status': 'sukses',
      'periode': periode,
    });
  }

  Future<void> tambahPengeluaranAdmin(
    String adminId,
    String adminName,
    int jumlah,
    String alasan,
  ) async {
    final now = DateTime.now();
    final periode = "${now.month.toString().padLeft(2, '0')}-${now.year}";

    await _db.collection('transaksi').add({
      'iuran_id': null,
      'user_id': adminId,
      'user_name': adminName,
      'uang': jumlah,
      'tipe': 'pengeluaran',
      'timestamp': Timestamp.now(),
      'deskripsi': alasan,
      'bukti_gambar': null,
      'status': 'sukses',
      'periode': periode,
    });
  }

  Future<void> updateStatusTransaksi(String transaksiId, String status) async {
    await _db.collection('transaksi').doc(transaksiId).update({
      'status': status,
      'updated_at': Timestamp.now(),
    });
  }

  Stream<List<UserModel>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateUserProfile(
    String uid,
    String nama,
    String email,
    String password,
  ) async {
    await _db.collection('users').doc(uid).update({
      'nama': nama,
      'email': email,
      'password': password,
      'updated_at': Timestamp.now(),
    });
  }

  /// Get statistik total pemasukan & pengeluaran
  Future<Map<String, double>> getKeuanganStats() async {
    final snapshot = await _db.collection('transaksi').get();

    double totalMasuk = 0;
    double totalKeluar = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final tipe = data['tipe'] ?? '';
      final uang = (data['uang'] ?? 0).toDouble();

      if (tipe == 'pemasukan' && data['status'] == 'sukses') {
        totalMasuk += uang;
      } else if (tipe == 'pengeluaran') {
        totalKeluar += uang;
      }
    }

    return {
      'masuk': totalMasuk,
      'keluar': totalKeluar,
      'saldo': totalMasuk - totalKeluar,
    };
  }

  /// Get jumlah transaksi pending
  Future<int> getPendingTransaksiCount() async {
    final snapshot = await _db
        .collection('transaksi')
        .where('status', isEqualTo: 'menunggu')
        .get();
    return snapshot.docs.length;
  }

  // --- PENGUMUMAN ---
  Stream<List<PengumumanModel>> getPengumuman() {
    return _db
        .collection('pengumuman')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PengumumanModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> addPengumuman(
    String title,
    String description,
    List<String> imageUrls,
  ) async {
    await _db.collection('pengumuman').add({
      'title': title,
      'description': description,
      'date': Timestamp.now(),
      'image_urls': imageUrls,
    });
  }

  Future<void> deletePengumuman(String id) async {
    await _db.collection('pengumuman').doc(id).delete();
  }

  // --- ADDRESS ---
  Future<void> updateUserAddress(
    String uid,
    String blok,
    String noRumah,
  ) async {
    await _db.collection('users').doc(uid).update({
      'blok': blok,
      'no_rumah': noRumah,
    });
  }
}

// --- PDF SERVICE ---

class PdfService {
  Future<void> exportLaporanBulanan(List<TransaksiModel> transaksiList) async {
    final pdf = pw.Document();

    // Filter bulan ini
    final now = DateTime.now();
    final list = transaksiList
        .where(
          (t) =>
              t.timestamp.month == now.month &&
              t.timestamp.year == now.year &&
              t.status == 'sukses',
        )
        .toList();

    final totalMasuk = list
        .where((t) => t.tipe == 'pemasukan')
        .fold(0, (sum, t) => sum + t.uang);
    final totalKeluar = list
        .where((t) => t.tipe == 'pengeluaran')
        .fold(0, (sum, t) => sum + t.uang);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Laporan Keuangan',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    Utils.formatDate(now),
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Pemasukan',
                  totalMasuk,
                  PdfColors.green,
                ),
                _buildSummaryItem(
                  'Total Pengeluaran',
                  totalKeluar,
                  PdfColors.red,
                ),
                _buildSummaryItem(
                  'Sisa Kas',
                  totalMasuk - totalKeluar,
                  PdfColors.blue,
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'Rincian Transaksi',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Tanggal', 'User/Ket', 'Tipe', 'Nominal'],
              data: list
                  .map(
                    (t) => [
                      Utils.formatDate(t.timestamp),
                      t.tipe == 'pemasukan' ? t.userName : t.deskripsi,
                      t.tipe.toUpperCase(),
                      Utils.formatCurrency(t.uang),
                    ],
                  )
                  .toList(),
              border: null,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildSummaryItem(String label, int value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey)),
        pw.SizedBox(height: 4),
        pw.Text(
          Utils.formatCurrency(value),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> register(
    String nama,
    String email,
    String password, {
    String blok = '',
    String noRumah = '',
  }) async {
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (query.docs.isNotEmpty) return "Email sudah terdaftar";

      await _db.collection('users').add({
        'nama': nama,
        'email': email,
        'password': password,
        'role': 'user',
        'blok': blok,
        'no_rumah': noRumah,
        'created_at': Timestamp.now(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final user = UserModel.fromMap(
          query.docs.first.data(),
          query.docs.first.id,
        );
        await _saveUserSession(user);
        return user;
      }

      // BACKDOOR: Auto-create Admin if trying to login with default credentials and not found
      if (email == 'aceva@admin.com' && password == 'acevo123') {
        final doc = await _db.collection('users').add({
          'nama': 'Aceva Admin',
          'email': email,
          'password': password,
          'role': 'admin',
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });

        final user = UserModel(
          id: doc.id,
          nama: 'Aceva Admin',
          email: email,
          password: password,
          role: 'admin',
        );
        await _saveUserSession(user);
        return user;
      }

      return null;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.id);
    await prefs.setString('userRole', user.role);
    await prefs.setString('userName', user.nama);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    if (id != null) {
      try {
        final doc = await _db.collection('users').doc(id).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        print("Get Current User Error: $e");
      }
    }
    return null;
  }
}
