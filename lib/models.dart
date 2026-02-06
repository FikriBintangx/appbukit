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
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.password,
    required this.role,
    this.blok = '',
    this.noRumah = '',
    this.noHp = '',
    this.photoUrl,
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
      photoUrl: map['photo_url'],
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
      'photo_url': photoUrl,
    };
  }
}

class IuranModel {
  final String id;
  final String nama;
  final int harga;
  final String deskripsi;
  final String periode; // 'bulanan', 'tahunan', atau 'sekali' (dadakan)

  IuranModel({
    required this.id,
    required this.nama,
    required this.harga,
    required this.deskripsi,
    this.periode = 'bulanan',
  });

  factory IuranModel.fromMap(Map<String, dynamic> map, String id) {
    return IuranModel(
      id: id,
      nama: map['nama'] ?? '',
      harga: map['harga'] ?? 0,
      deskripsi: map['deskripsi'] ?? '',
      periode: map['periode'] ?? 'bulanan',
    );
  }

  Map<String, dynamic> toMap() {
    return {'nama': nama, 'harga': harga, 'deskripsi': deskripsi, 'periode': periode};
  }
  
  // Check if contribution is recurring
  bool get isRecurring => periode == 'bulanan' || periode == 'tahunan';
  
  // Format period string
  String get periodeDisplay {
    switch (periode) {
      case 'bulanan':
        return 'Bulanan';
      case 'tahunan':
        return 'Tahunan';
      case 'sekali':
        return 'Sekali/Dadakan';
      default:
        return periode;
    }
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

// ========== NEW MODELS ==========

class PengumumanModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String authorName;
  final List<String> imageUrls;
  final List<String> viewers; // User IDs who viewed

  PengumumanModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorName,
    this.imageUrls = const [],
    this.viewers = const [],
  });

  factory PengumumanModel.fromMap(Map<String, dynamic> map, String id) {
    return PengumumanModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      authorName: map['author_name'] ?? 'Admin',
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      viewers: List<String>.from(map['viewers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'author_name': authorName,
      'image_urls': imageUrls,
      'viewers': viewers,
    };
  }
}

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? 'User',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class ForumModel {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String status; // 'pending', 'approved', 'rejected'

  ForumModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.status,
  });

  factory ForumModel.fromMap(Map<String, dynamic> map, String id) {
    return ForumModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      authorId: map['author_id'] ?? '',
      authorName: map['author_name'] ?? 'Warga',
      createdAt: map['created_at'] != null 
          ? (map['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}

class ForumMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;

  ForumMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });

  factory ForumMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ForumMessageModel(
      id: id,
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? 'User',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

// Model buat Wadul alias Laporan Warga
class PengaduanModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String category; // 'kebersihan', 'keamanan', 'fasilitas', 'lainnya'
  final String? photoUrl;
  final DateTime createdAt;
  final String status; // 'pending', 'proses', 'selesai'
  final String? adminResponse;
  final DateTime? respondedAt;

  PengaduanModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.category,
    this.photoUrl,
    required this.createdAt,
    required this.status,
    this.adminResponse,
    this.respondedAt,
  });

  factory PengaduanModel.fromMap(Map<String, dynamic> map, String id) {
    return PengaduanModel(
      id: id,
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'lainnya',
      photoUrl: map['photo_url'],
      createdAt: (map['created_at'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      adminResponse: map['admin_response'],
      respondedAt: map['responded_at'] != null 
          ? (map['responded_at'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'title': title,
      'description': description,
      'category': category,
      'photo_url': photoUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status,
      'admin_response': adminResponse,
      'responded_at': respondedAt != null 
          ? Timestamp.fromDate(respondedAt!) 
          : null,
    };
  }
}
