import 'package:tiara_fin/screens/notification_screen.dart';
import 'package:tiara_fin/widgets/wavy_navbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
// import 'package:tiara_fin/screens/auth_screens.dart'; // Utk logout nav
import 'package:tiara_fin/screens/user_screens.dart'; // Utk reuse ProfileScreen
import 'package:tiara_fin/screens/user_detail_screen.dart'; // New Import
// import 'package:printing/printing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tiara_fin/screens/forum_screen.dart';
import 'package:tiara_fin/screens/admin_features.dart';
import 'package:tiara_fin/screens/global_search_screen.dart';
import 'package:tiara_fin/screens/pengaduan_screen.dart';
import 'package:intl/intl.dart';
import 'package:tiara_fin/widgets/skeleton_loader.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart'; // Added for Pull-to-Refresh
import 'package:flutter/services.dart';
import 'package:tiara_fin/theme.dart';

// --- MARKAS BESAR ADMIN ---
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});
  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> with SingleTickerProviderStateMixin {
  int _idx = 0;
  UserModel? _currentUser;
  final AuthService _auth = AuthService();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUser();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadUser() async {
    final user = await _auth.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  void _onTabTapped(int index) {
    if (_idx != index) {
      setState(() {
        _idx = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      );
    }
  }

  List<Widget> get _screens {
    if (_currentUser?.role == 'ketua_rt') {
       // Ketua RT: Dashboard, Laporan Transaksi (ReadOnly), User List, Profile
       // Hide "Kelola Iuran"
       return [
         AdminDashboardScreen(currentUser: _currentUser!),
         const AdminTransaksiScreen(), // Ensure this screen handles readonly/actions inside if needed, or create separate if strict
         const AdminUserScreen(), // Laporan Warga
         const AdminProfileScreen(),
       ];
    }
    // Default Admin
    return [
      AdminDashboardScreen(currentUser: _currentUser!),
      const AdminTransaksiScreen(),
      const AdminIuranScreen(),
      const AdminUserScreen(),
      const AdminProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // Safety check idx if role changes/hot reload
    if (_idx >= _screens.length) _idx = 0;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _idx = index;
              });
              HapticFeedback.selectionClick();
            },
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: WavyBottomBar(
                selectedIndex: _idx,
                items: _getNavIcons(),
                onItemSelected: _onTabTapped,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<IconData> _getNavIcons() {
    if (_currentUser?.role == 'ketua_rt') {
      return [
        Icons.dashboard_rounded,
        Icons.list_alt_rounded,
        Icons.people_rounded,
        Icons.person_rounded,
      ];
    }
    // Admin Default
    return [
       Icons.dashboard_rounded,
       Icons.list_alt_rounded,
       Icons.payment_rounded,
       Icons.people_rounded,
       Icons.person_rounded,
    ];
  }
}

// ========== Wavy Clipper (Copied for Admin) ==========
class AdminWavyClipper extends CustomClipper<Path> {
  final double animationValue;

  AdminWavyClipper({this.animationValue = 0.0});

  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    // Kasih efek ombak goyang
    final waveOffset = animationValue * 20; // Goyang 20px aja cukup
    
    var firstControlPoint = Offset(
      size.width / 4, 
      size.height + waveOffset
    );
    var firstEndPoint = Offset(
      size.width / 2.25, 
      size.height - 30 - waveOffset
    );
    var secondControlPoint = Offset(
      size.width - (size.width / 3.25), 
      size.height - 80 + waveOffset
    );
    var secondEndPoint = Offset(
      size.width, 
      size.height - 40 - waveOffset
    );

    path.quadraticBezierTo(
      firstControlPoint.dx, 
      firstControlPoint.dy,
      firstEndPoint.dx, 
      firstEndPoint.dy
    );
    path.quadraticBezierTo(
      secondControlPoint.dx, 
      secondControlPoint.dy,
      secondEndPoint.dx, 
      secondEndPoint.dy
    );

    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(AdminWavyClipper oldClipper) => oldClipper.animationValue != animationValue;
}

// --- DASHBOARD ADMIN GANTENG ---
class AdminDashboardScreen extends StatefulWidget {
  final UserModel currentUser;
  const AdminDashboardScreen({super.key, required this.currentUser});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  final SupabaseService _supabase = SupabaseService();
  
  // Local state removed, use widget.currentUser

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    // Sesuain menu sama jabatan
    final bool isKetuaRT = widget.currentUser.role == 'ketua_rt';

    return Scaffold(
      backgroundColor: isKetuaRT ? RoleTheme.rtBackground : RoleTheme.adminBackground,
      floatingActionButton: isKetuaRT ? null : Padding(
        padding: const EdgeInsets.only(bottom: 100), // Fix overlap
        child: FloatingActionButton(
          onPressed: () => _showQuickActions(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 160), // Fix overlap with floating nav
        child: Column(
          children: [
            // Header Bergelombang Biar Estetik
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Background Ombak Mahal
                ClipPath(
                  clipper: AdminWavyClipper(),
                  child: Container(
                    height: 260,
                    decoration: BoxDecoration(
                      gradient: isKetuaRT ? RoleTheme.rtGradient : RoleTheme.adminGradient,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50, right: -50,
                          child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle)),
                        ),
                        Positioned(
                          bottom: 40, left: -30,
                          child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle)),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Nama & Sapaan Manis
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: StreamBuilder<UserModel>(
                        stream: _fs.streamUser(widget.currentUser.id),
                        builder: (context, snapshot) {
                          final user = snapshot.data ?? widget.currentUser;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white,
                                    backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                                        ? CachedNetworkImageProvider(user.photoUrl!)
                                        : null,
                                    child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                                        ? const Icon(Icons.person, color: AppColors.primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Halo, ${user.nama}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user.role == 'ketua_rt' ? 'Ketua RT' : 'Administrator',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                          // Search Button & Notification Bell
                          Row(
                            children: [
                              // Global Search Button
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const GlobalSearchScreen(),
                                    ),
                                  ),
                                  child: const Icon(Icons.search, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Notification Bell with Badge
                              StreamBuilder<List<NotificationModel>>(
                            stream: _fs.getNotifications('admin'),
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.hasData 
                                ? snapshot.data!.where((n) => !n.isRead).length 
                                : 0;
                              
                              return Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: InkWell(
                                      onTap: () => Navigator.push(
                                        context, 
                                        MaterialPageRoute(builder: (_) => const NotificationScreen())
                                      ),
                                      child: const Icon(Icons.notifications_outlined, color: Colors.white),
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          unreadCount > 9 ? '9+' : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

                
                // 3. Kartu Statistik Nindih Header
                Padding(
                  padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
                  child: StreamBuilder<List<TransaksiModel>>(
                    stream: _fs.getTransaksiList(),
                    builder: (context, snapshot) {
                      double totalKas = 0;
                      double pemasukan = 0;

                      if (snapshot.hasData) {
                        final list = snapshot.data!;
                        final masuk = list
                            .where((e) => e.tipe == 'pemasukan' && e.status == 'sukses')
                            .fold(0, (p, e) => p + e.uang);
                        final keluar = list
                            .where((e) => e.tipe == 'pengeluaran')
                            .fold(0, (p, e) => p + e.uang);
                        totalKas = (masuk - keluar).toDouble();
                        pemasukan = masuk.toDouble();
                      }

                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppTheme.meshGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.glowShadow(Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Total Kas", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 5),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          Utils.formatCurrency(totalKas.toInt()),
                                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20)
                                  ),
                                  child: Row(
                                    children: [
                                       const Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                                       const SizedBox(width: 4),
                                       Text(Utils.formatCurrency(pemasukan.toInt()), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            AspectRatio(
                              aspectRatio: 2.2,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: 11,
                                  minY: 0,
                                  maxY: 5,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: const [
                                        FlSpot(0, 1), FlSpot(2, 2.5), FlSpot(4, 2), 
                                        FlSpot(6, 3.5), FlSpot(8, 3), FlSpot(11, 4.5)
                                      ],
                                      isCurved: true,
                                      color: Colors.white,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true, 
                                        color: Colors.white.withValues(alpha: 0.1)
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // Menu Sat Set Wat Wet
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<TransaksiModel>>(
                stream: _fs.getTransaksiList(),
                builder: (context, transSnap) {
                  final pendingCount = transSnap.hasData 
                    ? transSnap.data!.where((t) => t.status == 'menunggu').length 
                    : 0;
                  
                  return StreamBuilder<List<UserModel>>(
                    stream: _fs.getUsers(),
                    builder: (context, userSnap) {
                      final totalWarga = userSnap.hasData 
                        ? userSnap.data!.where((u) => u.role != 'admin' && u.role != 'ketua_rt').length 
                        : 0;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aksi Cepat',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (!isKetuaRT) ...[
                                Expanded(
                                  child: _buildQuickActionCard(
                                    icon: Icons.check_circle_outline,
                                    label: 'Verifikasi',
                                    count: pendingCount,
                                    color: Colors.orange,
                                    onTap: () {
                                      final parent = context.findAncestorStateOfType<_AdminMainScreenState>();
                                      parent?._onTabTapped(1);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickActionCard(
                                    icon: Icons.analytics_outlined,
                                    label: 'Laporan',
                                    color: Colors.purple,
                                    onTap: () => _exportPdf(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.people_outline,
                                  label: 'Warga',
                                  count: totalWarga,
                                  color: Colors.green,
                                  onTap: () {
                                    final parent = context.findAncestorStateOfType<_AdminMainScreenState>();
                                    parent?._onTabTapped(isKetuaRT ? 2 : 3);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Menu Geser Geser (Horizontal Scroll)
            SizedBox(
              height: 140,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                   if (isKetuaRT) ...[
                      _buildMenuIcon(Icons.campaign_outlined, 'Info', AppTheme.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PengumumanListScreen(currentUser: widget.currentUser)))),
                      const SizedBox(width: 12),
                      _buildMenuIcon(Icons.forum_outlined, 'Forum', AppTheme.secondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumDiskusiScreen()))),
                      const SizedBox(width: 12),
                      _buildMenuIcon(Icons.analytics_outlined, 'Laporan', AppTheme.primary, () => _exportPdf(context)),
                      const SizedBox(width: 12),
                      _buildMenuIcon(Icons.report_problem_outlined, 'Aduan', AppTheme.danger, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PengaduanScreen(currentUser: widget.currentUser)))),
                   ] else ...[
                      _buildMenuIcon(Icons.analytics_outlined, 'Laporan', AppTheme.primary, () => _exportPdf(context)),
                      const SizedBox(width: 12),
                      _buildMenuIcon(Icons.attach_money_outlined, 'Iuran', AppTheme.primary, () => _showAddIuranDialog(context)),
                      const SizedBox(width: 12),
                      _buildMenuIcon(Icons.people_outline, 'Warga', AppTheme.success, () => _showAddUserDialog(context)),
                      const SizedBox(width: 12),
                      _buildMenuIcon(Icons.campaign_outlined, 'Info', AppTheme.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PengumumanListScreen(currentUser: widget.currentUser)))),
                      const SizedBox(width: 12),
                      _buildMenuIcon(Icons.forum_outlined, 'Forum', AppTheme.secondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumDiskusiScreen()))),
                      const SizedBox(width: 12),
                      _buildMenuIcon(Icons.report_problem_outlined, 'Aduan', AppTheme.danger, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PengaduanScreen(currentUser: widget.currentUser)))),
                   ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Aksi Cepat (Previously Grid, now maybe just a header or removed since we have the menu)
            // Let's keep "Aksi Cepat" as a secondary list or remove it if redundant?
            // The user asked to "samain sama menu dashboard warga" which implies the ICON GRID is the main menu.
            // So the above grid replaces the old "Aksi Cepat" buttons.
                       // Grafik Kepatuhan Warga (Real cuy datanya)
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<UserModel>>(
                stream: _fs.getUsers(),
                builder: (context, userSnap) {
                  return StreamBuilder<List<TransaksiModel>>(
                    stream: _fs.getTransaksiList(),
                    builder: (context, transSnap) {
                      if (!userSnap.hasData || !transSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = userSnap.data!
                          .where((u) => u.role != 'admin') // Exclude admin
                          .toList();
                      final totalWarga = users.length;
                      
                      final now = DateTime.now();
                      final currentMonthTrans = transSnap.data!.where((t) {
                        return t.timestamp.month == now.month &&
                               t.timestamp.year == now.year &&
                               t.tipe == 'pemasukan' &&
                               t.status == 'sukses';
                      }).toList();

                      final paidUserIds = currentMonthTrans.map((t) => t.userId).toSet();
                      final lunasCount = users.where((u) => paidUserIds.contains(u.id)).length;
                      final belumCount = totalWarga - lunasCount;

                      // Fix division by zero if no users
                      return Column(
                        children: [
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Status Iuran Warga (Bulan Ini)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              TextButton(onPressed: (){}, child: const Text('Detail', style: TextStyle(color: AppColors.primary)))
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,2))],
                            ),
                            child: Column(
                              children: [
                                // Progress Bar Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tingkat Pembayaran',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      totalWarga > 0 
                                        ? '${((lunasCount / totalWarga) * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: totalWarga == 0 ? 0 : (lunasCount / totalWarga),
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    minHeight: 10,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Pie Chart & Legend
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 100, width: 100,
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 0, centerSpaceRadius: 30,
                                          sections: [
                                            PieChartSectionData(
                                              color: AppColors.primary, 
                                              value: lunasCount.toDouble(), 
                                              radius: 15, 
                                              showTitle: false
                                            ),
                                            PieChartSectionData(
                                              color: AppColors.lightGrey, 
                                              value: belumCount.toDouble(), 
                                              radius: 15, 
                                              showTitle: false
                                            ),
                                          ]
                                        )
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildLegendItem(AppColors.primary, 'Lunas', '$lunasCount Warga'),
                                          const SizedBox(height: 12),
                                          _buildLegendItem(AppColors.lightGrey, 'Belum Bayar', '$belumCount Warga'),
                                        ],
                                      )
                                    )
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    }
                  );
                }
              ),
            ),
            
            const SizedBox(height: 24),

            // Diagram Duit Masuk vs Duit Keluar
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Statistik Keuangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Text("6 Bulan Terakhir", style: TextStyle(color: Colors.blue, fontSize: 10)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,2))],
                    ),
                    child: StreamBuilder<List<TransaksiModel>>(
                      stream: _fs.getTransaksiList(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        // Process Data
                        final trans = snapshot.data!;
                        final now = DateTime.now();
                        final List<Map<String, dynamic>> monthlyStats = [];

                        for (int i = 5; i >= 0; i--) {
                          final date = DateTime(now.year, now.month - i, 1);
                          final monthTrans = trans.where((t) => 
                            t.timestamp.year == date.year && t.timestamp.month == date.month && t.status == 'sukses'
                          ).toList();
                          
                          double income = 0;
                          double expense = 0;
                          
                          for (var t in monthTrans) {
                            if (t.tipe == 'pemasukan') income += t.uang;
                            if (t.tipe == 'pengeluaran') expense += t.uang;
                          }
                          
                          monthlyStats.add({
                            'month': date.month,
                            'income': income,
                            'expense': expense,
                          });
                        }

                        // Max Value for Y-Axis
                        double maxVal = 0;
                        for(var m in monthlyStats) {
                          if (m['income'] > maxVal) maxVal = m['income'];
                          if (m['expense'] > maxVal) maxVal = m['expense'];
                        }
                        if (maxVal == 0) maxVal = 100; // avoid zero

                        return BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxVal * 1.2,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Colors.blueGrey,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    Utils.formatCurrency(rod.toY.toInt()),
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < monthlyStats.length) {
                                      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          monthNames[monthlyStats[index]['month'] - 1],
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: monthlyStats.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: (data['income'] as double),
                                    color: AppColors.success,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  BarChartRodData(
                                    toY: (data['expense'] as double),
                                    color: AppColors.danger,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Aktivitas Terkini
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text(
                    'Aktivitas Terkini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<TransaksiModel>>(
                    stream: _fs.getTransaksiList(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final recent = snapshot.data!.take(5).toList();
                      return Column(
                        children: recent.map((t) => _buildModernTransactionItem(t)).toList(),
                      );
                    },
                  ),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color color, VoidCallback onTap, {double width = 100}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(20),
           boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.1, 
                  child: Container(width: 48, height: 48, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
                ),
                Icon(icon, color: color, size: 26),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (count != null && count > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (count != null && count > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildModernTransactionItem(TransaksiModel t) {
    final isIncome = t.tipe == 'pemasukan';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome ? AppColors.primary.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? AppColors.primary : AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  t.deskripsi,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${Utils.formatCurrency(t.uang)}',
            style: TextStyle(
              color: isIncome ? AppColors.primary : AppColors.danger,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aksi Cepat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.note_add, color: AppColors.primary),
                title: const Text('Catat Iuran Baru'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddIuranDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: AppColors.primary),
                title: const Text('Tambah Warga'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddUserDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign, color: AppColors.primary),
                title: const Text('Buat Pengumuman'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPengumumanDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                title: const Text('Catat Pemasukan Tunai'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPemasukanDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.money_off, color: AppColors.danger),
                title: const Text('Catat Pengeluaran'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPengeluaranDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showAddPemasukanDialog(BuildContext context) {
    final jumlahCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Catat Pemasukan Tunai"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jumlahCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Jumlah Terima (Rp)",
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: "Dari Siapa / Keterangan",
                  hintText: "Contoh: Bpk. Budi (Iuran Sampah)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              if (isUploading) ...[
                 const SizedBox(height: 16),
                 const LinearProgressIndicator(),
                 const Center(child: Text("Menyimpan...")),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                 if (jumlahCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi data")));
                   return;
                 }
                 
                 setState(() => isUploading = true);
                 
                 try {
                   final amount = int.parse(jumlahCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
                   // Add 'manual_income' transaction type or reuse 'pemasukan' with 'sukses' status immediately
                   await _fs.addTransaksiManual(
                     userId: 'admin_manual', // Special ID for manual entry
                     userName: descCtrl.text, // User Name or Description
                     amount: amount,
                     type: 'pemasukan',
                     description: descCtrl.text,
                   );
                   
                   if (context.mounted) {
                     Navigator.pop(ctx);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Pemasukan Tercatat!"), backgroundColor: Colors.green));
                   }
                 } catch (e) {
                    setState(() => isUploading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                 }
              },
              child: const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }

  void _showAddPengeluaranDialog(BuildContext context) {
    final jumlahCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    File? selectedImage;
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Catat Pengeluaran"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: jumlahCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Jumlah Pengeluaran (Rp)",
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: "Keterangan",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        selectedImage = File(image.path);
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Upload Struk/Bukti",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  const Text(
                    "Mengupload bukti...",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (jumlahCtrl.text.isNotEmpty &&
                          descCtrl.text.isNotEmpty) {
                        setState(() => isUploading = true);

                        try {
                          String? uploadedUrl;
                          if (selectedImage != null) {
                            uploadedUrl = await _supabase.uploadImage(
                              selectedImage!,
                            );
                          }

                          // Removed null check since widget.currentUser is required
                          await _fs.tambahPengeluaranAdmin(
                            widget.currentUser.id,
                            widget.currentUser.nama,
                            int.parse(jumlahCtrl.text),
                            descCtrl.text,
                            buktiUrl: uploadedUrl,
                          );

                            Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "✅ Pengeluaran berhasil dicatat!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                        } catch (e) {
                          setState(() => isUploading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ Gagal: $e")),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIuranDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPeriode = 'bulanan'; // Default

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Tambah Jenis Iuran"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nama Iuran",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Harga",
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: "Deskripsi",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPeriode,
                    decoration: const InputDecoration(
                      labelText: "Periode Pembayaran",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bulanan', child: Text("Rutin (Bulanan)")),
                      DropdownMenuItem(value: 'sekali', child: Text("Dadakan (Sekali Bayar)")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedPeriode = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (priceCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                    await _fs.tambahIuran(
                      nameCtrl.text,
                      int.parse(priceCtrl.text),
                      descCtrl.text,
                      periode: selectedPeriode,
                    );
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Iuran berhasil ditambahkan!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                child: const Text("Buat"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final noRumahCtrl = TextEditingController();
    final noHpCtrl = TextEditingController(); // Added
    String selectedBlok = 'Q1';
    final List<String> blokList = ['Q1', 'Q2', 'Q3', 'Q4', 'Q5'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Tambah Warga Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noHpCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "No. HP (WhatsApp)",
                    hintText: "Contoh: 628123456789",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedBlok,
                        decoration: const InputDecoration(
                          labelText: 'Blok',
                          border: OutlineInputBorder(),
                        ),
                        items: blokList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedBlok = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: noRumahCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "No. Rumah",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Password akan dibuat otomatis:\n'NamaDepan' + 'Blok' + 'NoRumah' + '!'\nContoh: FikriQ1No12!",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty &&
                    emailCtrl.text.isNotEmpty &&
                    noRumahCtrl.text.isNotEmpty) {
                  // Password otomatis biar ga mikir
                  final firstName = nameCtrl.text.split(
                    ' ',
                  )[0]; // Ambil kata pertama
                  final generatedPass =
                      "$firstName$selectedBlok${noRumahCtrl.text}!";

                  final error = await _auth.register(
                    nameCtrl.text,
                    emailCtrl.text,
                    generatedPass,
                    blok: selectedBlok,
                    noRumah: noRumahCtrl.text,
                    noHp: noHpCtrl.text,
                  );
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    if (error == null) {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("✅ Warga Ditambahkan"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Email: ${emailCtrl.text}"),
                              Text(
                                "Password: $generatedPass",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Harap simpan password ini atau minta warga segera menggantinya.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("❌ Gagal: $error"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Tambah"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPengumumanDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    List<XFile> selectedFiles = [];
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Buat Pengumuman"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Judul",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: "Isi Pengumuman",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final List<XFile> medias = await picker.pickMultipleMedia();
                    if (medias.isNotEmpty) {
                      setState(() {
                        if (medias.length > 10) {
                          selectedFiles = medias.sublist(0, 10);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Max 10 file, mengambil 10 pertama",
                              ),
                            ),
                          );
                        } else {
                          selectedFiles = medias;
                        }
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedFiles.isEmpty
                              ? "Tap untuk Upload (Foto/Video)"
                              : "${selectedFiles.length} file dipilih",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selectedFiles.isEmpty
                                ? Colors.grey
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedFiles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedFiles.take(5).map((e) {
                              return Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.insert_drive_file,
                                  color: Colors.grey,
                                ),
                              );
                            }).toList(),
                          ),
                          if (selectedFiles.length > 5)
                            Text(
                              "+ ${selectedFiles.length - 5} lainnya",
                              style: const TextStyle(fontSize: 10),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  const Text(
                    "Sedang mengupload...",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (titleCtrl.text.isNotEmpty &&
                          descCtrl.text.isNotEmpty) {
                        setState(() => isUploading = true);

                        List<String> urls = [];
                        try {
                          // Upload Files
                          for (var file in selectedFiles) {
                            final url = await _supabase.uploadImage(
                              File(file.path),
                            );
                            if (url != null) {
                              urls.add(url);
                            }
                          }

                          // Save to Firestore
                          await _fs.addPengumuman(
                            titleCtrl.text,
                            descCtrl.text,
                            widget.currentUser.role == 'ketua_rt' ? "Ketua RT" : widget.currentUser.nama,
                            urls,
                          );

                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ Pengumuman berhasil dipost!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isUploading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ Gagal: $e")),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    // Default Filters
    String selectedStatus = 'semua';
    String selectedType = 'semua';
    DateTimeRange? selectedDateRange;

    // Show Bottom Sheet instead of Dialog
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, 
              right: 20, 
              top: 10
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Filter Laporan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // 1. Filter Tanggal
                const Text("Periode Waktu", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 10),
                
                // Quick Date Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickDateChip("Semua", null, selectedDateRange, (r) => setState(() => selectedDateRange = r)),
                      const SizedBox(width: 8),
                      _buildQuickDateChip("Bulan Ini", 
                        DateTimeRange(start: DateTime(DateTime.now().year, DateTime.now().month, 1), end: DateTime.now()), 
                        selectedDateRange, (r) => setState(() => selectedDateRange = r)
                      ),
                      const SizedBox(width: 8),
                      _buildQuickDateChip("Bulan Lalu", 
                        DateTimeRange(
                          start: DateTime(DateTime.now().year, DateTime.now().month - 1, 1), 
                          end: DateTime(DateTime.now().year, DateTime.now().month, 0)
                        ), 
                        selectedDateRange, (r) => setState(() => selectedDateRange = r)
                      ),
                       const SizedBox(width: 8),
                      _buildQuickDateChip("Tahun Ini", 
                        DateTimeRange(start: DateTime(DateTime.now().year, 1, 1), end: DateTime.now()), 
                        selectedDateRange, (r) => setState(() => selectedDateRange = r)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Manual Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: selectedDateRange,
                      builder: (context, child) {
                          return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      }
                    );
                    if (picked != null) {
                      setState(() => selectedDateRange = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tanggal Dipilih",
                                style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.8), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedDateRange == null 
                                  ? "Semua Waktu" 
                                  : "${Utils.formatDate(selectedDateRange!.start)} - ${Utils.formatDate(selectedDateRange!.end)}",
                                style: const TextStyle(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2. Filter Tipe & Status Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            const Text("Tipe Transaksi", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                 _buildChoiceChip("Semua", selectedType == 'semua', (b) => setState(() => selectedType = 'semua')),
                                 _buildChoiceChip("Masuk", selectedType == 'pemasukan', (b) => setState(() => selectedType = 'pemasukan'), color: Colors.green),
                                 _buildChoiceChip("Keluar", selectedType == 'pengeluaran', (b) => setState(() => selectedType = 'pengeluaran'), color: Colors.red),
                              ],
                            )
                         ],
                       ),
                     ),
                  ],
                ),
                 const SizedBox(height: 20),
                 const Text("Status Pembayaran", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                 const SizedBox(height: 10),
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: Row(
                      children: [
                        _buildChoiceChip('Semua', selectedStatus == 'semua', (b) => setState(() => selectedStatus = 'semua')),
                        const SizedBox(width: 8),
                        _buildChoiceChip('Sukses', selectedStatus == 'sukses', (b) => setState(() => selectedStatus = 'sukses'), color: Colors.green),
                        const SizedBox(width: 8),
                        _buildChoiceChip('Menunggu', selectedStatus == 'menunggu', (b) => setState(() => selectedStatus = 'menunggu'), color: Colors.orange),
                        const SizedBox(width: 8),
                         _buildChoiceChip('Gagal', selectedStatus == 'gagal', (b) => setState(() => selectedStatus = 'gagal'), color: Colors.red),
                      ],
                   ),
                 ),

                const SizedBox(height: 40),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                       Navigator.pop(ctx); 
                       _generatePdf(context, selectedStatus, selectedType, selectedDateRange);
                    },
                    style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       foregroundColor: Colors.white,
                       elevation: 0,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: const Text("Terapkan & Cetak PDF", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTimeRange? range, DateTimeRange? currentRange, Function(DateTimeRange?) onSelect) {
    bool isSelected = false;
    if (range == null && currentRange == null) {
      isSelected = true;
    } else if (range != null && currentRange != null) {
      // Simple range equality check
      isSelected = range.start.year == currentRange.start.year && 
                   range.start.month == currentRange.start.month && 
                   range.end.day == currentRange.end.day; 
      // Approximate check is fine for UX
    }

    return InkWell(
      onTap: () => onSelect(range),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, Function(bool) onSelected, {Color color = AppColors.primary}) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87, 
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color,
      backgroundColor: Colors.white,
      side: selected ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _generatePdf(
    BuildContext context, 
    String status, 
    String type,
    DateTimeRange? dateRange,
  ) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menyiapkan PDF...")));
    }
    
    final snapshot = await _fs.getTransaksiList().first;
    try {
      await PdfService().exportLaporan(
        snapshot, 
        filterStatus: status,
        filterType: type,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal export: $e")));
      }
    }
  }
}

// --- TEMPAT CEK MUTASI CUAN ---
class AdminTransaksiScreen extends StatefulWidget {
  const AdminTransaksiScreen({super.key});

  @override
  State<AdminTransaksiScreen> createState() => _AdminTransaksiScreenState();
}

class _AdminTransaksiScreenState extends State<AdminTransaksiScreen> {
  String _searchQuery = '';
  String _filterStatus = 'semua';
  String _filterType = 'semua'; // 'semua', 'pemasukan', 'pengeluaran'
  DateTimeRange? _dateRange;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final RefreshController _refreshController = RefreshController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: _isSearching
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari transaksi...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black38),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: const TextStyle(color: Colors.black87),
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() => _searchQuery = val.toLowerCase());
                  });
                },
              ),
            )
            : const Text("Kelola Transaksi"),
        centerTitle: true,
        backgroundColor: _isSearching ? Colors.white : null,
        iconTheme: _isSearching ? const IconThemeData(color: Colors.black87) : null,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: _isSearching ? Colors.black87 : null),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export PDF',
              onPressed: () => _showPdfExportMenu(context),
            ),
          ],
        ],
      ),
      body: StreamBuilder<List<TransaksiModel>>(
        stream: fs.getTransaksiList(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, __) => const TransactionSkeletonCard(),
            );
          }

          var list = snapshot.data!;

          // Saring Status
          if (_filterStatus != 'semua') {
            list = list.where((t) => t.status == _filterStatus).toList();
          }

          // Apply Type Filter
          if (_filterType != 'semua') {
            list = list.where((t) => t.tipe == _filterType).toList();
          }


          // Apply Date Range Filter
          if (_dateRange != null) {
            list = list.where((t) {
              return t.timestamp.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                     t.timestamp.isBefore(_dateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }

          // Pencarian Cerdas (Cari apa aja ketemu)
          if (_searchQuery.isNotEmpty) {
            list = list.where((t) {
              final name = t.userName.toLowerCase();
              final desc = t.deskripsi.toLowerCase();
              final amount = t.uang.toString();
              final status = t.status.toLowerCase();
              final tipe = t.tipe.toLowerCase();
              final query = _searchQuery.toLowerCase();
              
              return name.contains(query) || 
                     desc.contains(query) || 
                     amount.contains(query) ||
                     status.contains(query) ||
                     tipe.contains(query);
            }).toList();
          }

          return Column(
            children: [
              // Filter Chips Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${list.length} Transaksi',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _filterStatus != 'semua') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Filtered',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Semua'),
                            selected: _filterStatus == 'semua',
                            onSelected: (_) => setState(() => _filterStatus = 'semua'),
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Menunggu'),
                            selected: _filterStatus == 'menunggu',
                            onSelected: (_) => setState(() => _filterStatus = 'menunggu'),
                            selectedColor: Colors.orange.withValues(alpha: 0.2),
                            checkmarkColor: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Sukses'),
                            selected: _filterStatus == 'sukses',
                            onSelected: (_) => setState(() => _filterStatus = 'sukses'),
                            selectedColor: Colors.green.withValues(alpha: 0.2),
                            checkmarkColor: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Gagal'),
                            selected: _filterStatus == 'gagal',
                            onSelected: (_) => setState(() => _filterStatus = 'gagal'),
                            selectedColor: Colors.red.withValues(alpha: 0.2),
                            checkmarkColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Type & Date Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text("Tipe: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: _filterType == 'semua',
                            onSelected: (_) => setState(() => _filterType = 'semua'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Masuk'),
                            selected: _filterType == 'pemasukan',
                            onSelected: (_) => setState(() => _filterType = 'pemasukan'),
                            selectedColor: Colors.green.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Keluar'),
                            selected: _filterType == 'pengeluaran',
                            onSelected: (_) => setState(() => _filterType = 'pengeluaran'),
                            selectedColor: Colors.red.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 16),
                          Container(width: 1, height: 24, color: Colors.grey.shade300),
                          const SizedBox(width: 16),
                          // Date Picker
                          InkWell(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                initialDateRange: _dateRange,
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      primaryColor: AppColors.primary,
                                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _dateRange = picked);
                              }
                            },
                            child: Chip(
                              avatar: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                _dateRange == null 
                                  ? 'Semua Waktu' 
                                  : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
                              ),
                              onDeleted: _dateRange != null 
                                ? () => setState(() => _dateRange = null) 
                                : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // List or Empty State
              if (list.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'Tidak ada hasil untuk "$_searchQuery"'
                            : 'Belum ada transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                            ? 'Coba kata kunci lain'
                            : 'Transaksi akan muncul di sini',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SmartRefresher( // Wrap ListView with SmartRefresher
                    controller: _refreshController,
                    enablePullDown: true,
                    header: WaterDropMaterialHeader(
                      backgroundColor: Theme.of(context).primaryColor,
                      color: Colors.white,
                    ),
                    onRefresh: () async {
                      // Haptic Feedback for better feel
                      HapticFeedback.mediumImpact();
                      // Simulate loading delay
                      await Future.delayed(const Duration(milliseconds: 1000));
                      if (mounted) setState(() {}); // Trigger rebuild
                      _refreshController.refreshCompleted();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        // ... existing item building logic ...
                        Color statusColor = Colors.grey;
                        if (item.status == 'sukses') statusColor = Colors.green;
                        if (item.status == 'gagal') statusColor = Colors.red;
                        if (item.status == 'menunggu') statusColor = Colors.orange;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailTransaksiScreen(transaksi: item),
                        ),
                      );
                    },
                  // ... rest of card content ...
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.2),
                          child: Icon(
                            item.tipe == 'pemasukan'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: item.tipe == 'pemasukan'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item.userName} - ${item.tipe.toUpperCase()}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Utils.formatCurrency(item.uang),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.deskripsi,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (item.status == 'sukses' &&
                                item.tipe == 'pemasukan')
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.green,
                                ),
                                tooltip: 'Kirim Kwitansi WA',
                                onPressed: () async {
                                  // Share receipt
                                  final text =
                                      "Kwitansi Digital Tiara Finance\n\n"
                                      "Telah terima dari: ${item.userName}\n"
                                      "Sejumlah: ${Utils.formatCurrency(item.uang)}\n"
                                      "Untuk: ${item.deskripsi}\n"
                                      "Tanggal: ${Utils.formatDateTime(item.timestamp)}\n"
                                      "Status: LUNAS\n\n"
                                      "Terima kasih.";

                                  // Encode for URL
                                  final url = Uri.parse(
                                    "https://wa.me/?text=${Uri.encodeComponent(text)}",
                                  );

                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tidak bisa membuka WhatsApp",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPdfExportMenu(BuildContext context) async {
    // Default Filters (Reset or match current screen's filter?) -> Let's use defaults for fresh export
    String selectedStatus = 'semua';
    String selectedType = 'semua';
    DateTimeRange? selectedDateRange;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, 
              right: 20, 
              top: 10
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Filter Laporan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                const Text("Periode Waktu", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 10),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickDateChip("Semua", null, selectedDateRange, (r) => setState(() => selectedDateRange = r)),
                      const SizedBox(width: 8),
                      _buildQuickDateChip("Bulan Ini", 
                        DateTimeRange(start: DateTime(DateTime.now().year, DateTime.now().month, 1), end: DateTime.now()), 
                        selectedDateRange, (r) => setState(() => selectedDateRange = r)
                      ),
                      const SizedBox(width: 8),
                      _buildQuickDateChip("Bulan Lalu", 
                        DateTimeRange(
                          start: DateTime(DateTime.now().year, DateTime.now().month - 1, 1), 
                          end: DateTime(DateTime.now().year, DateTime.now().month, 0)
                        ), 
                        selectedDateRange, (r) => setState(() => selectedDateRange = r)
                      ),
                       const SizedBox(width: 8),
                      _buildQuickDateChip("Tahun Ini", 
                        DateTimeRange(start: DateTime(DateTime.now().year, 1, 1), end: DateTime.now()), 
                        selectedDateRange, (r) => setState(() => selectedDateRange = r)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: selectedDateRange,
                      builder: (context, child) {
                          return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      }
                    );
                    if (picked != null) {
                      setState(() => selectedDateRange = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tanggal Dipilih",
                                style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.8), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedDateRange == null 
                                  ? "Semua Waktu" 
                                  : "${Utils.formatDate(selectedDateRange!.start)} - ${Utils.formatDate(selectedDateRange!.end)}",
                                style: const TextStyle(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            const Text("Tipe Transaksi", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                 _buildChoiceChip("Semua", selectedType == 'semua', (b) => setState(() => selectedType = 'semua')),
                                 _buildChoiceChip("Masuk", selectedType == 'pemasukan', (b) => setState(() => selectedType = 'pemasukan'), color: Colors.green),
                                 _buildChoiceChip("Keluar", selectedType == 'pengeluaran', (b) => setState(() => selectedType = 'pengeluaran'), color: Colors.red),
                              ],
                            )
                         ],
                       ),
                     ),
                  ],
                ),
                 const SizedBox(height: 20),
                 const Text("Status Pembayaran", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                 const SizedBox(height: 10),
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: Row(
                      children: [
                        _buildChoiceChip('Semua', selectedStatus == 'semua', (b) => setState(() => selectedStatus = 'semua')),
                        const SizedBox(width: 8),
                        _buildChoiceChip('Sukses', selectedStatus == 'sukses', (b) => setState(() => selectedStatus = 'sukses'), color: Colors.green),
                        const SizedBox(width: 8),
                        _buildChoiceChip('Menunggu', selectedStatus == 'menunggu', (b) => setState(() => selectedStatus = 'menunggu'), color: Colors.orange),
                        const SizedBox(width: 8),
                         _buildChoiceChip('Gagal', selectedStatus == 'gagal', (b) => setState(() => selectedStatus = 'gagal'), color: Colors.red),
                      ],
                   ),
                 ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                       Navigator.pop(ctx); 
                       _generatePdf(context, selectedStatus, selectedType, selectedDateRange);
                    },
                    style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       foregroundColor: Colors.white,
                       elevation: 0,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: const Text("Terapkan & Cetak PDF", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTimeRange? range, DateTimeRange? currentRange, Function(DateTimeRange?) onSelect) {
    bool isSelected = false;
    if (range == null && currentRange == null) {
      isSelected = true;
    } else if (range != null && currentRange != null) {
      isSelected = range.start.year == currentRange.start.year && 
                   range.start.month == currentRange.start.month && 
                   range.end.day == currentRange.end.day; 
    }

    return InkWell(
      onTap: () => onSelect(range),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, Function(bool) onSelected, {Color color = AppColors.primary}) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87, 
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color,
      backgroundColor: Colors.white,
      side: selected ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
  
  Future<void> _generatePdf(
    BuildContext context, 
    String status, 
    String type,
    DateTimeRange? dateRange,
  ) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menyiapkan PDF...")));
    }
    
    final snapshot = await FirestoreService().getTransaksiList().first;
    try {
      await PdfService().exportLaporan(
        snapshot, 
        filterStatus: status,
        filterType: type, // Ensure this parameter is handled in PdfService
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal export: $e")));
      }
    }
  }

}

class DetailTransaksiScreen extends StatelessWidget {
  final TransaksiModel transaksi;
  const DetailTransaksiScreen({super.key, required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();
    Color statusColor = Colors.grey;
    if (transaksi.status == 'sukses') statusColor = Colors.green;
    if (transaksi.status == 'gagal') statusColor = Colors.red;
    if (transaksi.status == 'menunggu') statusColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Transaksi"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow('Nama', transaksi.userName),
                    const Divider(),
                    _detailRow('Jumlah', Utils.formatCurrency(transaksi.uang)),
                    const Divider(),
                    _detailRow('Tipe', transaksi.tipe.toUpperCase()),
                    const Divider(),
                    _detailRow('Deskripsi', transaksi.deskripsi),
                    const Divider(),
                    _detailRow(
                      'Tanggal',
                      Utils.formatDateTime(transaksi.timestamp),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            transaksi.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            if (transaksi.buktiGambar != null && transaksi.buktiGambar!.isNotEmpty) ...[
              const Text(
                "Bukti Pembayaran:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                   showDialog(context: context, builder: (ctx) => Dialog(
                     child: CachedNetworkImage(imageUrl: transaksi.buktiGambar!),
                   ));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: transaksi.buktiGambar!,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 300,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (c, e, s) => Container(
                      height: 300,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            SizedBox(height: 8),
                            Text("Gagal memuat gambar"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Tidak ada bukti gambar",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (transaksi.status == 'menunggu')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Tolak Transaksi?'),
                            content: const Text(
                              'Apakah Anda yakin ingin menolak transaksi ini?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Tolak'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await fs.updateStatusTransaksi(transaksi.id, 'gagal');
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("❌ Transaksi ditolak"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Tolak"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await fs.updateStatusTransaksi(transaksi.id, 'sukses');
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Transaksi disetujui!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Terima"),
                    ),
                  ),
                ],
              ),
            
            // Tombol Download Kwitansi (kalo sukses)
            if (transaksi.status == 'sukses' && transaksi.tipe == 'pemasukan')
              Container(
                margin: const EdgeInsets.only(top: 16),
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      // Get iuran name
                      final iuranName = transaksi.deskripsi;
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📄 Membuat kwitansi...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      
                      await PdfService().generateKwitansiPDF(transaksi, iuranName);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Kwitansi berhasil dibuat!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Gagal membuat kwitansi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text("Download Kwitansi PDF"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// --- NGATUR DUIT PALAKAN (IURAN) ---
class AdminIuranScreen extends StatefulWidget {
  const AdminIuranScreen({super.key});

  @override
  State<AdminIuranScreen> createState() => _AdminIuranScreenState();
}

class _AdminIuranScreenState extends State<AdminIuranScreen> {
  
  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    bool isAmount = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isAmount ? 12 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Kelola Iuran", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Avoid navbar overlap
        child: FloatingActionButton.extended(
          onPressed: () => _showAddIuranDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Iuran'),
          backgroundColor: AppColors.primary,
        ),
      ),
      body: StreamBuilder<List<IuranModel>>(
        stream: fs.getIuranList(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final iurans = snap.data!;

          if (iurans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada iuran',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap tombol + untuk menambah iuran',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          // StreamBuilder beranak (Nested)
          return StreamBuilder<List<TransaksiModel>>(
            stream: fs.getTransaksiList(),
            builder: (ctx, transSnap) {
              final transactions = transSnap.hasData ? transSnap.data! : [];

              return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
            itemCount: iurans.length,
            itemBuilder: (c, i) {
              final iuran = iurans[i];
              
              // Itung statistik buat iuran ini
              final iuranTrans = transactions.where((t) => t.iuranId == iuran.id).toList();
              final paidCount = iuranTrans.where((t) => t.status == 'sukses').length;
              final pendingCount = iuranTrans.where((t) => t.status == 'menunggu').length;
              final totalAmount = iuranTrans
                  .where((t) => t.status == 'sukses')
                  .fold<int>(0, (sum, t) => (sum + t.uang).toInt());
              
              return Slidable(
                key: ValueKey(iuran.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) => _showEditIuranDialog(context, iuran),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                      borderRadius: BorderRadius.circular(12),
                    ),
                    SlidableAction(
                      onPressed: (context) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Iuran?'),
                            content: Text('Apakah Anda yakin ingin menghapus "${iuran.nama}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await fs.deleteIuran(iuran.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Iuran berhasil dihapus'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Hapus',
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.05),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.payment, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  iuran.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                Utils.formatCurrency(iuran.harga),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  iuran.deskripsi,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ),
                              // Label Periode
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: iuran.isRecurring ? Colors.blue[50] : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  iuran.periodeDisplay,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: iuran.isRecurring ? Colors.blue[700] : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Stats Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  label: 'Terbayar',
                                  value: '$paidCount',
                                  color: Colors.green,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey[300],
                                ),
                                _buildStatItem(
                                  label: 'Pending',
                                  value: '$pendingCount',
                                  color: Colors.orange,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey[300],
                                ),
                                _buildStatItem(
                                  label: 'Total',
                                  value: Utils.formatCurrency(totalAmount),
                                  color: AppColors.primary,
                                  isAmount: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => _showEditIuranDialog(context, iuran),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit, size: 16, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text("Edit", style: TextStyle(color: Colors.blue, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hapus Iuran?'),
                                      content: Text(
                                        'Apakah Anda yakin ingin menghapus "${iuran.nama}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await fs.deleteIuran(iuran.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("✅ Iuran berhasil dihapus"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete, size: 16, color: Colors.red),
                                      SizedBox(width: 4),
                                      Text("Hapus", style: TextStyle(color: Colors.red, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                );
            },
          );
            },
          );
        },
      ),
    );
  }

  void _showAddIuranDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final FirestoreService fs = FirestoreService();
    String selectedPeriode = 'bulanan'; // Default

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Tambah Jenis Iuran", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Nama Iuran",
                    hintText: "Contoh: Iuran Kebersihan",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Harga",
                    hintText: "0",
                    prefixText: 'Rp ',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                // Periode Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedPeriode,
                  isExpanded: true, // Fix overflow
                  decoration: InputDecoration(
                    labelText: "Periode Iuran",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'bulanan', child: Text('Bulanan (Rutin)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'tahunan', child: Text('Tahunan (Rutin)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'sekali', child: Text('Sekali/Dadakan (17an, dll)', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedPeriode = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: "Deskripsi",
                    hintText: "Keterangan tambahan...",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (priceCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                        try {
                          await fs.tambahIuran(
                            nameCtrl.text,
                            int.parse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')), // Safe parse
                            descCtrl.text,
                            periode: selectedPeriode,
                          );
                          if (!ctx.mounted) return;
                          
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text("Iuran berhasil ditambahkan!"),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                          );
                        }
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Mohon lengkapi data"), backgroundColor: Colors.orange),
                          );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text("Buat Iuran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditIuranDialog(BuildContext context, IuranModel iuran) {
    final nameCtrl = TextEditingController(text: iuran.nama);
    final priceCtrl = TextEditingController(text: iuran.harga.toString());
    final descCtrl = TextEditingController(text: iuran.deskripsi);
    final FirestoreService fs = FirestoreService();
    String selectedPeriode = iuran.periode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Iuran"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama Iuran",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Harga",
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                // Periode Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedPeriode,
                  decoration: const InputDecoration(
                    labelText: "Periode Iuran",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'bulanan', child: Text('Bulanan (Rutin)')),
                    DropdownMenuItem(value: 'tahunan', child: Text('Tahunan (Rutin)')),
                    DropdownMenuItem(value: 'sekali', child: Text('Sekali/Dadakan (17an, dll)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedPeriode = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: "Deskripsi",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (priceCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                  await fs.updateIuran(
                    iuran.id,
                    nameCtrl.text,
                    int.parse(priceCtrl.text),
                    descCtrl.text,
                    periode: selectedPeriode,
                  );
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Iuran berhasil diupdate!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DAFTAR PENDUDUK BUMI ---
// --- DAFTAR PENDUDUK BUMI ---
class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final FirestoreService _fs = FirestoreService();
  String _filterStatus = 'Semua'; // Semua, Lunas, Belum Lunas

  Set<String> _getPaidUserIds(List<TransaksiModel> allTrans) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Filter transactions: Type=pemasukan, Status=sukses, Month matches
    final paidTrans = allTrans.where((t) {
      if (t.tipe != 'pemasukan' || t.status != 'sukses') return false;
      // Check date
      final tDate = t.timestamp;
      return tDate.month == currentMonth && tDate.year == currentYear;
    }).toList();

    return paidTrans.map((t) => t.userId).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Warga"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _filterStatus = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Semua', child: Text('Semua')),
              const PopupMenuItem(value: 'Lunas', child: Text('Sudah Bayar')),
              const PopupMenuItem(value: 'Belum Lunas', child: Text('Belum Bayar')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _fs.getUsers(),
        builder: (ctx, snapUsers) {
          if (!snapUsers.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<TransaksiModel>>(
            stream: _fs.getTransaksiList(),
            builder: (ctx, snapTrans) {
              if (!snapTrans.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapUsers.data!;
              final trans = snapTrans.data!;
              final paidIds = _getPaidUserIds(trans);

              // Saring user sesuai selera
              final filteredUsers = users.where((u) {
                if (u.role == 'admin') return false; // Umpetin admin dari list (biar misterius)
                if (_filterStatus == 'Semua') return true;
                if (_filterStatus == 'Lunas') return paidIds.contains(u.id);
                if (_filterStatus == 'Belum Lunas') return !paidIds.contains(u.id);
                return true;
              }).toList();

              if (filteredUsers.isEmpty) {
                 return Center(child: Text("Tidak ada data user ($_filterStatus)"));
              }

              return Column(
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                     color: Colors.grey.shade100,
                     width: double.infinity,
                     child: Text(
                       "Menampilkan ${filteredUsers.length} warga ($_filterStatus)",
                       style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                     ),
                   ),
                   Expanded(
                     child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: filteredUsers.length,
                      itemBuilder: (c, i) {
                        final u = filteredUsers[i];
                        final isPaid = paidIds.contains(u.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  backgroundColor: isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                  child: Text(
                                    u.nama.isNotEmpty ? u.nama[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: isPaid ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Titik Status
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isPaid ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              u.nama,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.email),
                                if (u.blok.isNotEmpty) Text("Blok ${u.blok} No ${u.noRumah}"),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPaid ? 'LUNAS' : 'BELUM',
                                    style: TextStyle(
                                      color: isPaid ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    u.role,
                                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserDetailScreen(user: u),
                                ),
                              );
                            },
                          ),
                        );
                      },
                                       ),
                   ),
                ],
              );
            }
          );
        },
      ),
    );
  }
}

// --- PROFIL SANG PENGUASA ---
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
