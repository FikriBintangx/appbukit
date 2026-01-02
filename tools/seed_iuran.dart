import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tiara_fin/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> iuranList = [
    {
      "nama": "Iuran Rutin Bulanan",
      "harga": 100000,
      "deskripsi": "Iuran wajib setiap bulan untuk kas bersama.",
    },
    {
      "nama": "Iuran Keamanan",
      "harga": 50000,
      "deskripsi": "Biaya penjagaan lingkungan & keamanan RT.",
    },
    {
      "nama": "Iuran Kesehatan",
      "harga": 30000,
      "deskripsi": "Dana untuk kegiatan kesehatan & P3K.",
    },
    {
      "nama": "Iuran Kebersihan",
      "harga": 20000,
      "deskripsi": "Biaya kebersihan lingkungan & pengangkutan sampah.",
    },
  ];

  for (var item in iuranList) {
    await db.collection('iuran').add(item);
  }

  print("SEED IURAN SUKSES!");
}
