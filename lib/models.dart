import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nama;
  final String email;
  final String password;
  final String role;
  final String blok;
  final String noRumah;
  final String noHp;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.password,
    required this.role,
    this.blok = '',
    this.noRumah = '',
    this.noHp = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'user',
      blok: map['blok'] ?? '',
      noRumah: map['no_rumah'] ?? '',
      noHp: map['no_hp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'password': password,
      'role': role,
      'blok': blok,
      'no_rumah': noRumah,
      'no_hp': noHp,
    };
  }
}

class IuranModel {
  final String id;
  final String nama;
  final int harga;
  final String deskripsi;

  IuranModel({
    required this.id,
    required this.nama,
    required this.harga,
    required this.deskripsi,
  });

  factory IuranModel.fromMap(Map<String, dynamic> map, String id) {
    return IuranModel(
      id: id,
      nama: map['nama'] ?? '',
      harga: map['harga'] ?? 0,
      deskripsi: map['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'nama': nama, 'harga': harga, 'deskripsi': deskripsi};
  }
}

class TransaksiModel {
  final String id;
  final String? iuranId;
  final String userId;
  final String userName;
  final int uang;
  final String tipe;
  final DateTime timestamp;
  final String deskripsi;
  final String? buktiGambar;
  final String status;
  final String periode; // Format: MM-YYYY

  TransaksiModel({
    required this.id,
    this.iuranId,
    required this.userId,
    required this.userName,
    required this.uang,
    required this.tipe,
    required this.timestamp,
    required this.deskripsi,
    this.buktiGambar,
    required this.status,
    required this.periode,
  });

  factory TransaksiModel.fromMap(Map<String, dynamic> map, String id) {
    return TransaksiModel(
      id: id,
      iuranId: map['iuran_id'],
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? 'Unknown',
      uang: map['uang'] ?? 0,
      tipe: map['tipe'] ?? 'pemasukan',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      deskripsi: map['deskripsi'] ?? '',
      buktiGambar: map['bukti_gambar'],
      status: map['status'] ?? 'menunggu',
      periode: map['periode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'iuran_id': iuranId,
      'user_id': userId,
      'user_name': userName,
      'uang': uang,
      'tipe': tipe,
      'timestamp': Timestamp.fromDate(timestamp),
      'deskripsi': deskripsi,
      'bukti_gambar': buktiGambar,
      'status': status,
      'periode': periode,
    };
  }
}

class PengumumanModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final List<String> imageUrls;

  PengumumanModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.imageUrls = const [],
  });

  factory PengumumanModel.fromMap(Map<String, dynamic> map, String id) {
    return PengumumanModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      imageUrls: List<String>.from(map['image_urls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'image_urls': imageUrls,
    };
  }
}
