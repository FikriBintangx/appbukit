import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models.dart';
import '../services.dart';
import 'package:tiara_fin/theme.dart';

/// Ini Screen buat Aduan Warga alias Laporan
class PengaduanScreen extends StatefulWidget {
  final UserModel currentUser;

  const PengaduanScreen({super.key, required this.currentUser});

  @override
  State<PengaduanScreen> createState() => _PengaduanScreenState();
}

class _PengaduanScreenState extends State<PengaduanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pengaduan Warga'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePengaduanDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Buat Pengaduan'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (widget.currentUser.role == 'admin' || widget.currentUser.role == 'ketua_rt')
            ? FirebaseFirestore.instance
                .collection('pengaduan')
                .orderBy('created_at', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('pengaduan')
                .where('userId', isEqualTo: widget.currentUser.id)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          // Sort locally to avoid extra Firebase Indexing configuration
          docs.sort((a, b) {
            Timestamp tA = a['created_at'] as Timestamp;
            Timestamp tB = b['created_at'] as Timestamp;
            return tB.compareTo(tA); // Yang baru ditaro diatas
          });

          final pengaduanList = docs
              .map((doc) => PengaduanModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

          if (pengaduanList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada pengaduan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap tombol + untuk membuat pengaduan',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pengaduanList.length,
            itemBuilder: (context, index) {
              final pengaduan = pengaduanList[index];
              return _buildPengaduanCard(pengaduan);
            },
          );
        },
      ),
    );
  }

  Widget _buildPengaduanCard(PengaduanModel pengaduan) {
    Color statusColor = AppTheme.warning;
    String statusText = "Menunggu";
    
    if (pengaduan.status == 'proses') {
      statusColor = AppTheme.secondary;
      statusText = "Diproses";
    } else if (pengaduan.status == 'selesai') {
      statusColor = AppTheme.success;
      statusText = "Selesai";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showPengaduanDetail(pengaduan),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(pengaduan.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(pengaduan.category),
                        color: _getCategoryColor(pengaduan.category),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pengaduan.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCategoryLabel(pengaduan.category),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  pengaduan.description,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.divider),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      Utils.formatDateTime(pengaduan.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    if (pengaduan.photoUrl != null)
                      const Row(
                        children: [
                           Icon(Icons.attachment, size: 14, color: AppTheme.primary),
                           SizedBox(width: 4),
                           Text("Lampiran", style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreatePengaduanDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'lainnya';
    File? selectedImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Buat Pengaduan Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul Pengaduan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kategori:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Kebersihan'),
                        selected: selectedCategory == 'kebersihan',
                        onSelected: (selected) {
                          setState(() => selectedCategory = 'kebersihan');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Keamanan'),
                        selected: selectedCategory == 'keamanan',
                        onSelected: (selected) {
                          setState(() => selectedCategory = 'keamanan');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Fasilitas'),
                        selected: selectedCategory == 'fasilitas',
                        onSelected: (selected) {
                          setState(() => selectedCategory = 'fasilitas');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Lainnya'),
                        selected: selectedCategory == 'lainnya',
                        onSelected: (selected) {
                          setState(() => selectedCategory = 'lainnya');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (pickedFile != null) {
                        setState(() {
                          selectedImage = File(pickedFile.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: Text(selectedImage != null
                        ? 'Foto dipilih ✓'
                        : 'Tambah Foto (Opsional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul dan deskripsi harus diisi')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  
                  // Munculin loading biar user sabar
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    String? photoUrl;
                    
                    // Kalo ada fotonya, upload dulu skuy
                    if (selectedImage != null) {
                      try {
                        photoUrl = await SupabaseService().uploadImage(selectedImage!);
                      } catch (e) {
                         // Yaudah ignore aja kalo gagal upload, lanjut tanpa foto
                         print("Upload failed: $e");
                      }
                    }

                    // Masukin datanya ke database
                    final pengaduan = PengaduanModel(
                      id: '',
                      userId: widget.currentUser.id,
                      userName: widget.currentUser.nama,
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      category: selectedCategory,
                      photoUrl: photoUrl,
                      createdAt: DateTime.now(),
                      status: 'pending',
                    );

                    await FirebaseFirestore.instance
                        .collection('pengaduan')
                        .add(pengaduan.toMap());

                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop(); // Tutup loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Pengaduan berhasil dibuat!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop(); // Tutup loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Gagal membuat pengaduan: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Kirim'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPengaduanDetail(PengaduanModel pengaduan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {



        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Badge
                  // Timeline (Horizontal aja biar simple)
                  Row(
                    children: [
                      _buildTimelineItem("Terkirim", true, true),
                      _buildTimelineLine(pengaduan.status != 'pending'),
                      _buildTimelineItem("Diproses", pengaduan.status != 'pending', pengaduan.status == 'proses'),
                      _buildTimelineLine(pengaduan.status == 'selesai'),
                      _buildTimelineItem("Selesai", pengaduan.status == 'selesai', pengaduan.status == 'selesai'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    pengaduan.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category & Date
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(pengaduan.category),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCategoryLabel(pengaduan.category),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        Utils.formatDateTime(pengaduan.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Deskripsi:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pengaduan.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Photo
                  if (pengaduan.photoUrl != null) ...[
                    const Text(
                      'Foto:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        pengaduan.photoUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Admin Response
                  if (pengaduan.adminResponse != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Tanggapan Admin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pengaduan.adminResponse!,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                          if (pengaduan.respondedAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              Utils.formatDateTime(pengaduan.respondedAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Action Button for Admin/Ketua RT
                  if ((widget.currentUser.role == 'admin' || widget.currentUser.role == 'ketua_rt') && 
                      pengaduan.status != 'selesai') ...[
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                           // Show confirmation call
                           showDialog(
                             context: context, 
                             builder: (c) => AlertDialog(
                               title: const Text("Konfirmasi"),
                               content: const Text("Tandai pengaduan ini sebagai sudah ditindaklanjuti?"),
                               actions: [
                                 TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
                                 ElevatedButton(
                                   onPressed: () async {
                                     Navigator.pop(c); // Close dialog
                                     Navigator.pop(context); // Close detail sheet
                                     
                                     await FirebaseFirestore.instance.collection('pengaduan').doc(pengaduan.id).update({
                                       'status': 'selesai',
                                       'admin_response': 'Laporan telah ditindaklanjuti.',
                                       'responded_at': Timestamp.now(),
                                     });
                                     
                                     if(mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text("✅ Status diperbarui: Sudah Ditindaklanjuti")),
                                       );
                                     }
                                   }, 
                                   child: const Text("Ya, Sudah")
                                 ),
                               ],
                             )
                           );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          "Sudah Ditindaklanjuti", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineItem(String label, bool isActive, bool isCurrent) {
     return Expanded(
       child: Column(
         children: [
           Container(
             width: 24, height: 24,
             decoration: BoxDecoration(
               color: isActive ? AppTheme.primary : Colors.grey[200],
               shape: BoxShape.circle,
               border: isCurrent ? Border.all(color: AppTheme.primary.withOpacity(0.3), width: 4) : null,
             ),
             child: isActive ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
           ),
           const SizedBox(height: 8),
           Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppTheme.textMain : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
         ],
       ),
     );
  }

  Widget _buildTimelineLine(bool isActive) {
    return Container(
      width: 40, height: 2, 
      color: isActive ? AppTheme.primary : Colors.grey[200],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'kebersihan':
        return Colors.green;
      case 'keamanan':
        return Colors.red;
      case 'fasilitas':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'kebersihan':
        return Icons.cleaning_services;
      case 'keamanan':
        return Icons.security;
      case 'fasilitas':
        return Icons.build;
      default:
        return Icons.report;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'kebersihan':
        return 'Kebersihan';
      case 'keamanan':
        return 'Keamanan';
      case 'fasilitas':
        return 'Fasilitas';
      default:
        return 'Lainnya';
    }
  }
}
