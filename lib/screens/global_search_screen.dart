import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import '../services.dart';
import 'admin_screens.dart';
import 'user_detail_screen.dart';

/// Global Search Screen - Cari semua (Transaksi, Iuran, Warga)
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0.5,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari transaksi, iuran, atau warga...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.black38),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(color: Colors.black87),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.toLowerCase();
              _isSearching = val.isNotEmpty;
            });
          },
        ),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black54),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _isSearching = false;
                });
              },
            ),
        ],
      ),
      body: _isSearching
          ? _buildSearchResults()
          : _buildSearchSuggestions(),
    );
  }

  Widget _buildSearchSuggestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Cari Apa Saja',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaksi • Iuran • Warga',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final fs = FirestoreService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Transaksi
          StreamBuilder<List<TransaksiModel>>(
            stream: fs.getTransaksiList(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final results = snapshot.data!.where((t) {
                return t.userName.toLowerCase().contains(_searchQuery) ||
                    t.deskripsi.toLowerCase().contains(_searchQuery) ||
                    t.uang.toString().contains(_searchQuery);
              }).toList();

              if (results.isEmpty) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Transaksi', results.length),
                  const SizedBox(height: 8),
                  ...results.take(5).map((t) => _buildTransaksiItem(t)),
                  if (results.length > 5)
                    TextButton(
                      onPressed: () {
                        // Navigate to full transaksi list with filter
                        Navigator.pop(context);
                        // TODO: Navigate to AdminTransaksiScreen with search query
                      },
                      child: Text('Lihat semua ${results.length} transaksi'),
                    ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // Search Iuran
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('iuran').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final results = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['nama'] ?? '').toString().toLowerCase();
                final desc = (data['deskripsi'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || desc.contains(_searchQuery);
              }).toList();

              if (results.isEmpty) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Iuran', results.length),
                  const SizedBox(height: 8),
                  ...results.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildIuranItem(data, doc.id);
                  }),
                  if (results.length > 5)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to AdminIuranScreen
                      },
                      child: Text('Lihat semua ${results.length} iuran'),
                    ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // Search Warga
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'user')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final results = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['nama'] ?? '').toString().toLowerCase();
                final blok = (data['blok'] ?? '').toString().toLowerCase();
                final noRumah = (data['no_rumah'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) ||
                    blok.contains(_searchQuery) ||
                    noRumah.contains(_searchQuery);
              }).toList();

              if (results.isEmpty) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Warga', results.length),
                  const SizedBox(height: 8),
                  ...results.take(5).map((doc) {
                    final user = UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                    return _buildWargaItem(user);
                  }),
                  if (results.length > 5)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to AdminUserScreen
                      },
                      child: Text('Lihat semua ${results.length} warga'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransaksiItem(TransaksiModel transaksi) {
    Color statusColor = Colors.grey;
    if (transaksi.status == 'sukses') statusColor = Colors.green;
    if (transaksi.status == 'gagal') statusColor = Colors.red;
    if (transaksi.status == 'menunggu') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            transaksi.tipe == 'pemasukan'
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          transaksi.userName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${transaksi.deskripsi} • ${Utils.formatDateTime(transaksi.timestamp)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Utils.formatCurrency(transaksi.uang),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaksi.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailTransaksiScreen(transaksi: transaksi),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIuranItem(Map<String, dynamic> data, String id) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.receipt_long,
            color: Color(0xFF6C63FF),
            size: 20,
          ),
        ),
        title: Text(
          data['nama'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          data['deskripsi'] ?? '',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          Utils.formatCurrency(data['harga'] ?? 0),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6C63FF),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to iuran detail or edit
        },
      ),
    );
  }

  Widget _buildWargaItem(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
          child: Text(
            user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
        title: Text(
          user.nama,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Blok ${user.blok} No.${user.noRumah}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailScreen(user: user),
            ),
          );
        },
      ),
    );
  }
}
