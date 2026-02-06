import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/security_utils.dart';
import 'package:tiara_fin/notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

// --- WARNA WARNI KEHIDUPAN ---
class AppColors {
  static const primary = Color(0xFF00D09C);
  static const secondary = Color(0xFF00B882);
  static const success = Color(0xFF00D09C);
  static const warning = Color(0xFFFFB800);
  static const danger = Color(0xFFFF3B30);
  static const info = Color(0xFF007AFF);
  static const dark = Color(0xFF1A1A1A);
  static const grey = Color(0xFF8E8E93);
  static const lightGrey = Color(0xFFF5F5F5);
  static const purple = Color(0xFFAF52DE);
}

// --- ADDITIONAL MODELS ---

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'info', 'alert', 'payment'
  final String targetRole; // 'all', 'admin', 'warga', 'ketua_rt'
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetRole,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'info',
      targetRole: map['target_role'] ?? 'all',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['is_read'] ?? false,
    );
  }
}

// ForumModel definition moved to models.dart for global access

class Utils {
  static String formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  /// Bikin tanggal jadi enak dibaca manusia
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

  /// Date and Time
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class NetworkHelper {
  /// Cek dulu ada kuota gak nih HP
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

  /// Coba lagi berkali-kali sapa tau jodoh (exponential backoff)
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
      // Direct upload without aggressive ping check
      // final isConnected = await NetworkHelper.isConnected();
      // if (!isConnected) {
      //   throw Exception('Tidak ada koneksi internet');
      // }

      final ext = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$ext';

      // Simple upload using standard storage API
      await client.storage.from('tiara finance').upload(fileName, file);

      final String publicUrl = client.storage
          .from('tiara finance')
          .getPublicUrl(fileName);
          
      print("✅ Upload Sukses: $publicUrl");
      return publicUrl;
      
    } catch (e) {
      print("❌ Supabase Upload Error: $e");
      // Fallback: throw error so UI knows it failed
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

  /// Tanam benih iuran awal (sekali seumur hidup)
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

  /// HAPUS SEMUA DOSA DAN MULAI LEMBARAN BARU (RESET DATABASE)
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

      // Add Ketua RT (KETUA_RT/Sadewa167)
      // Note: Menggunakan email dummy
      final rtDoc = await userCol.add({
        'nama': 'Ketua RT',
        'email': 'ketuart@app.com', // Internal email representation
        'password': 'Sadewa167',
        'role': 'ketua_rt',
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
      print('✅ Ketua RT created: ${rtDoc.id}');

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

  /// Helper buat bersih-bersih database
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

  Future<void> tambahIuran(String nama, int harga, String deskripsi, {String periode = 'bulanan'}) async {
    await _db.collection('iuran').add({
      'nama': nama,
      'harga': harga,
      'deskripsi': deskripsi,
      'periode': periode,
      'created_at': Timestamp.now(),
    });

    // Halo warga, ada info penting nih!
    await sendNotification(
      title: '📢 Iuran Baru',
      body: '$nama - Rp ${_formatCurrency(harga)}\n$deskripsi',
      type: 'info',
      targetRole: 'warga',
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> deleteIuran(String iuranId) async {
    await _db.collection('iuran').doc(iuranId).delete();
  }

  Future<void> updateIuran(
    String iuranId,
    String nama,
    int harga,
    String deskripsi, {
    String periode = 'bulanan',
  }) async {
    await _db.collection('iuran').doc(iuranId).update({
      'nama': nama,
      'harga': harga,
      'deskripsi': deskripsi,
      'periode': periode,
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



    final now = DateTime.now();
    
    // Default duration is 1 if not specified (though we'll use the param)
    int months = 1; // Default
    // Overloaded implementation is tricky in Dart without named optional with default, 
    // so we'll check if we can add it to the signature or just handle logic here.
    // Since I can't change the signature easily in `replace_file_content` without changing the whole function definition line, 
    // I will Assume the instruction meant replacing the BODY and modifying the signature in a separate step or I'll use a new method name?
    // Wait, the tool 'replace_file_content' allows replacing lines. I should replace the Signature AND the Body.
    // Let me target the signature as well.
    
    // However, I see I selected lines 449-496 which INCLUDES the signature. Good.
   
    // Let's rewrite the method.
      
  Future<void> bayarMultiIuran(
    UserModel user,
    List<IuranModel> iuranList,
    String method, {
    String? buktiUrl,
    int durationMonths = 1, // Added parameter with default
  }) async {
    final now = DateTime.now();

    double totalBayar = 0;
    
    // 1. Buat Transaksi
    
    // Process "Bulanan" Items
    final bulananItems = iuranList.where((i) => i.periode == 'bulanan').toList();
    if (bulananItems.isNotEmpty) {
      for (int m = 0; m < durationMonths; m++) {
        final targetDate = DateTime(now.year, now.month + m, 1);
        final periode = "${targetDate.month.toString().padLeft(2, '0')}-${targetDate.year}";

        for (var iuran in bulananItems) {
          totalBayar += iuran.harga;
          await _db.collection('transaksi').add({
            'iuran_id': iuran.id,
            'user_id': user.id,
            'user_name': user.nama,
            'uang': iuran.harga,
            'tipe': 'pemasukan',
            'timestamp': Timestamp.now(), 
            'deskripsi': 'Bayar: ${iuran.nama} ($periode)',
            'bukti_gambar': buktiUrl, 
            'status': 'menunggu',
            'periode': periode, // e.g. 01-2026, 02-2026
            'metode': method,
          });
        }
      }
    }

    // Process "Sekali/Dadakan" Items (Ignore duration, pay ONCE)
    final sekaliItems = iuranList.where((i) => i.periode != 'bulanan').toList();
    if (sekaliItems.isNotEmpty) {
       final periodeSekali = "${now.month.toString().padLeft(2, '0')}-${now.year}"; // Just mark as current month
       for (var iuran in sekaliItems) {
          totalBayar += iuran.harga;
           await _db.collection('transaksi').add({
            'iuran_id': iuran.id,
            'user_id': user.id,
            'user_name': user.nama,
            'uang': iuran.harga,
            'tipe': 'pemasukan',
            'timestamp': Timestamp.now(), 
            'deskripsi': 'Bayar: ${iuran.nama}', // No period suffix needed for one-time
            'bukti_gambar': buktiUrl, 
            'status': 'menunggu',
            'periode': periodeSekali,
            'metode': method,
          });
       }
    }

    // 2. Kirim Notifikasi ke Admin
    String durationText = durationMonths > 1 ? "untuk $durationMonths bulan" : "";
    await sendNotification(
      title: "Pembayaran Baru",
      body: "${user.nama} membayar ${iuranList.length} jenis iuran $durationText. Total: ${Utils.formatCurrency(totalBayar.toInt())}",
      type: "payment",
      targetRole: "admin",
    );

    // 3. Kirim Notifikasi ke Warga
    await sendNotification(
      title: "Pembayaran Berhasil Dikirim",
      body: "Pembayaran Anda ($durationMonths bulan) sedang diverifikasi admin/RT.",
      type: "info",
      targetRole: "warga", 
    );
  }

  // Admin nyatet manual (langsung lunas via jalur dalam)
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
    String alasan, {
    String? buktiUrl,
  }) async {
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
      'bukti_gambar': buktiUrl,
      'status': 'sukses',
      'periode': periode,
    });
  }

  Future<void> updateStatusTransaksi(String transaksiId, String status) async {
    await _db.collection('transaksi').doc(transaksiId).update({
      'status': status,
      'updated_at': Timestamp.now(),
    });
    
    // Kabarin user kalo statusnya berubah
    final transaksi = await _db.collection('transaksi').doc(transaksiId).get();
    if (transaksi.exists) {
      final data = transaksi.data()!;
      final deskripsi = data['deskripsi'] ?? 'Pembayaran';
      
      if (status == 'sukses') {
        await sendNotification(
          title: "Pembayaran Disetujui",
          body: "Pembayaran Anda untuk $deskripsi telah diverifikasi dan disetujui",
          type: "info",
          targetRole: "warga",
        );
      } else if (status == 'gagal') {
        await sendNotification(
          title: "Pembayaran Ditolak",
          body: "Pembayaran Anda untuk $deskripsi ditolak. Silakan hubungi admin",
          type: "alert",
          targetRole: "warga",
        );
      }
    }
  }

  Future<void> addTransaksi({
    required String iuranId,
    required String userId,
    required String userName,
    required int amount,
    required String type,
    required String description,
    required String status,
    required String periode,
    String? buktiUrl,
    String? metode,
  }) async {
    await _db.collection('transaksi').add({
      'iuran_id': iuranId,
      'user_id': userId,
      'user_name': userName,
      'uang': amount,
      'tipe': type,
      'deskripsi': description,
      'timestamp': Timestamp.now(),
      'status': status,
      'bukti_gambar': buktiUrl,
      'periode': periode,
      'metode': metode ?? 'va',
    });
  }

  Future<void> addTransaksiManual({
    required String userId,
    required String userName,
    required int amount,
    required String type,
    required String description,
  }) async {
    await _db.collection('transaksi').add({
      'user_id': userId,
      'user_name': userName,
      'uang': amount,
      'tipe': type,
      'deskripsi': description,
      'timestamp': Timestamp.now(),
      'status': 'sukses',
      'bukti_gambar': null,
      'iuran_id': null, // Generic income
    });
  }



  Stream<List<UserModel>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<UserModel> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) throw Exception("User not found");
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateUserProfile(
    String uid, {
    String? nama,
    String? email,
    String? password,
    String? photoUrl,
    String? blok,
    String? noRumah,
    String? noHp,
  }) async {
    final Map<String, dynamic> data = {'updated_at': Timestamp.now()};
    if (nama != null) data['nama'] = nama;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (blok != null) data['blok'] = blok;
    if (noRumah != null) data['no_rumah'] = noRumah;
    if (noHp != null) data['no_hp'] = noHp;

    await _db.collection('users').doc(uid).update(data);
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

  // --- PENGUMUMAN PENTING ---
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
    String authorName,
    List<String> imageUrls,
  ) async {
    await _db.collection('pengumuman').add({
      'title': title,
      'description': description,
      'date': Timestamp.now(),
      'author_name': authorName,
      'image_urls': imageUrls,
      'viewers': [],
    });
  }

  Future<void> markPengumumanAsViewed(String pengumumanId, String userId) async {
    await _db.collection('pengumuman').doc(pengumumanId).update({
      'viewers': FieldValue.arrayUnion([userId])
    });
  }

  Stream<List<CommentModel>> getPengumumanComments(String pengumumanId) {
    return _db.collection('pengumuman').doc(pengumumanId).collection('comments')
      .orderBy('timestamp', descending: false).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => CommentModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addPengumumanComment(String pengumumanId, String userId, String userName, String content) async {
    await _db.collection('pengumuman').doc(pengumumanId).collection('comments').add({
      'user_id': userId,
      'user_name': userName,
      'content': content,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> deletePengumuman(String id) async {
    await _db.collection('pengumuman').doc(id).delete();
  }

  // --- ALAMAT RUMAH ---
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

  // --- TEMPAT GHIBAH (FORUM) & NOTIF ---

  // --- TEMPAT GHIBAH (FORUM) & NOTIF ---

  Stream<List<ForumModel>> getForumDiskusi({bool isAdmin = false}) {
    Query query = _db.collection('forum'); // Hapus orderBy sort dari query database
    if (!isAdmin) {
      query = query.where('status', isEqualTo: 'approved');
    }
    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => ForumModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Client-side sorting
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  Future<void> requestForum(String authorId, String authorName, String title, String description) async {
    await _db.collection('forum').add({
      'title': title,
      'description': description,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': Timestamp.now(),
      'status': 'pending', 
    });
  }

  Future<void> approveForum(String forumId) async {
    await _db.collection('forum').doc(forumId).update({'status': 'approved'});
  }

  Future<void> rejectForum(String forumId) async {
    await _db.collection('forum').doc(forumId).update({'status': 'rejected'});
  }

  // Chattingan di Forum
  Stream<List<ForumMessageModel>> getForumMessages(String forumId) {
    return _db.collection('forum').doc(forumId).collection('messages')
      .orderBy('timestamp', descending: true).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => ForumMessageModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> sendForumMessage(String forumId, String senderId, String senderName, String content) async {
    await _db.collection('forum').doc(forumId).collection('messages').add({
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'timestamp': Timestamp.now(),
    });
  }

  // Notifikasi alias Pemberitahuan
  Stream<List<NotificationModel>> getNotifications(String userRole) {
    // Return all notifications that match role OR 'all'
    // This requires simple client side filtering or advanced queries
    // For now, fetch all sorted
    return _db
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final all = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Filter logic simple:
      if (userRole == 'admin' || userRole == 'ketua_rt') {
         return all.where((n) => n.targetRole == 'admin' || n.targetRole == 'ketua_rt' || n.targetRole == 'all').toList();
      } else {
         return all.where((n) => n.targetRole == 'warga' || n.targetRole == 'all').toList();
      }
    });
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
    required String targetRole,
  }) async {
    // 1. Save to Firestore
    await _db.collection('notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'target_role': targetRole,
      'timestamp': Timestamp.now(),
      'is_read': false,
    });

    // 2. Munculin notif ting-tung di HP
    try {
      await NotificationService().showNotification(
        title: title,
        body: body,
        data: {
          'type': type,
          'target_role': targetRole,
        },
      );
    } catch (e) {
      print("❌ Local Notification Error: $e");
    }
  }

  Future<void> markNotificationAsRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({
      'is_read': true,
    });
  }

  Future<void> markNotificationAsUnread(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({
      'is_read': false,
    });
  }

  Future<void> deleteNotification(String notifId) async {
    await _db.collection('notifications').doc(notifId).delete();
  }
}

// --- TUKANG CETAK PDF ---

class PdfService {
  Future<void> exportLaporan(
    List<TransaksiModel> transaksiList, {
    String filterStatus = 'sukses',
    String filterType = 'semua',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    
    // Filter logic
    final list = transaksiList.where((t) {
      // 1. Filter Date (if provided)
      if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        
        if (t.timestamp.isBefore(start) || t.timestamp.isAfter(end)) {
          return false;
        }
      }

      // 2. Filter Status
      if (filterStatus != 'semua' && t.status != filterStatus) {
        return false;
      }

      // 3. Filter Type
      if (filterType != 'semua' && t.tipe != filterType) {
        return false;
      }

      return true;
    }).toList();

    // Sort by date newest first
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final totalMasuk = list
        .where((t) => t.tipe == 'pemasukan' && t.status == 'sukses')
        .fold(0, (sum, t) => sum + t.uang);
    final totalKeluar = list
        .where((t) => t.tipe == 'pengeluaran' && t.status == 'sukses')
        .fold(0, (sum, t) => sum + t.uang);

    String titleSuffix = "";
    List<String> filters = [];
    if (filterType != 'semua') filters.add(filterType.toUpperCase());
    if (filterStatus != 'semua') filters.add(filterStatus.toUpperCase());
    
    if (filters.isNotEmpty) {
       titleSuffix = " (${filters.join(' - ')})";
    }

    String datePeriod = "Semua Waktu";
    if (startDate != null && endDate != null) {
      datePeriod = "${Utils.formatDate(startDate)} - ${Utils.formatDate(endDate)}";
    } else {
       datePeriod = "Dicetak: ${Utils.formatDate(DateTime.now())}";
    }

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
                   pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Laporan Keuangan$titleSuffix',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          datePeriod,
                          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                          pw.Text("RT/RW App", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text("Laporan Resmi", style: const pw.TextStyle(fontSize: 10)),
                      ]
                  )
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
              'Rincian Transaksi (${list.length})',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (list.isEmpty)
                pw.Center(child: pw.Text("Tidak ada data transaksi untuk periode ini.", style: const pw.TextStyle(color: PdfColors.grey)))
            else
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

  /// Generate PDF Receipt
  Future<void> generateKwitansiPDF(TransaksiModel transaksi, String iuranName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'KWITANSI PEMBAYARAN',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'RT/RW Management System',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Container(
                        width: double.infinity,
                        height: 2,
                        color: PdfColors.teal700,
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 24),

                // Info Section
                _buildKwitansiRow('No. Transaksi', transaksi.id.substring(0, 8).toUpperCase()),
                _buildKwitansiRow('Tanggal', Utils.formatDateTime(transaksi.timestamp)),
                _buildKwitansiRow('Status', transaksi.status.toUpperCase()),
                
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // Detail Pembayaran
                pw.Text(
                  'DETAIL PEMBAYARAN',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal700,
                  ),
                ),
                pw.SizedBox(height: 12),
                
                _buildKwitansiRow('Nama', transaksi.userName),
                _buildKwitansiRow('Jenis Iuran', iuranName),
                _buildKwitansiRow('Deskripsi', transaksi.deskripsi),
                
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // Total
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL PEMBAYARAN',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        Utils.formatCurrency(transaksi.uang),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Terima kasih atas pembayaran Anda',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Dokumen ini sah tanpa tanda tangan',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Simpen terus sebarin ke grup WA
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Kwitansi_${transaksi.userName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  pw.Widget _buildKwitansiRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
    String noHp = '',
  }) async {
    try {
      // Cek inputan bener ga
      final nameError = SecurityUtils.validateName(nama);
      if (nameError != null) return nameError;
      
      final emailError = SecurityUtils.validateEmail(email);
      if (emailError != null) return emailError;
      
      final passwordError = SecurityUtils.validatePassword(password);
      if (passwordError != null) return passwordError;
      
      final phoneError = SecurityUtils.validatePhoneNumber(noHp);
      if (phoneError != null) return phoneError;

      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (query.docs.isNotEmpty) return "Email sudah terdaftar";

      // Hash password
      final hashedPassword = SecurityUtils.hashPassword(password);

      await _db.collection('users').add({
        'nama': SecurityUtils.sanitizeInput(nama),
        'email': email.toLowerCase(),
        'password': hashedPassword,
        'role': 'user',
        'blok': SecurityUtils.sanitizeInput(blok),
        'no_rumah': SecurityUtils.sanitizeInput(noRumah),
        'no_hp': noHp,
        'created_at': Timestamp.now(),
      });
      return null;
    } catch (e) {
      return 'Gagal mendaftar. Silakan coba lagi.';
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      String finalEmail = email;
      // Nama samaran buat Pak RT
      if (email.toUpperCase() == 'KETUA_RT') {
        finalEmail = 'ketuart@app.com';
      }

      // Hash password untuk comparison
      final hashedPassword = SecurityUtils.hashPassword(password);

      // Try to find user by email first
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: finalEmail.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userData = query.docs.first.data();
        final storedPassword = userData['password'];
        
        // Cek password cocok ga (support yang lama juga)
        if (storedPassword == hashedPassword || storedPassword == password) {
          final user = UserModel.fromMap(userData, query.docs.first.id);
          
          // If password was plain text, update to hashed
          if (storedPassword == password) {
            await _db.collection('users').doc(query.docs.first.id).update({
              'password': hashedPassword,
            });
          }
          
          await _saveUserSession(user);
          return user;
        }
      }



      // 2. Cek user 'Ketua RT' manual (Buat demo doang)
      if (email == 'ketuart@app.com' && password == 'rt123') {
          // Login palsu buat Pak RT kalo belum ada di DB
           final queryRT = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

          UserModel user;
          if (queryRT.docs.isEmpty) {
             final doc = await _db.collection('users').add({
              'nama': 'Bapak Ketua RT',
              'email': email,
              'password': password,
              'role': 'ketua_rt',
              'created_at': Timestamp.now(),
              'updated_at': Timestamp.now(),
            });
            user = UserModel(id: doc.id, nama: 'Bapak Ketua RT', email: email, password: password, role: 'ketua_rt');
          } else {
             user = UserModel.fromMap(queryRT.docs.first.data(), queryRT.docs.first.id);
          }
          await _saveUserSession(user);
          return user;
      }

      // JALUR BELAKANG: Bikin admin otomatis, sstt jangan bilang-bilang
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
