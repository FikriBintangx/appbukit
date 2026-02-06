import 'package:flutter/material.dart';
import 'package:tiara_fin/widgets/wavy_navbar.dart';
import 'package:flutter/services.dart';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';
import 'package:tiara_fin/screens/auth_screens.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui'; // For Glassmorphism

import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tiara_fin/screens/notification_screen.dart';
import 'package:tiara_fin/screens/forum_screen.dart';
import 'package:tiara_fin/screens/edit_profile_screen.dart';
import 'package:tiara_fin/widgets/animations.dart';
import 'package:tiara_fin/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tiara_fin/widgets/skeleton_loader.dart';
import 'package:tiara_fin/screens/feature_screens.dart';
import 'package:tiara_fin/widgets/empty_state.dart';
import 'package:tiara_fin/widgets/tappable_card.dart';
import 'package:tiara_fin/security_utils.dart';
import 'package:tiara_fin/screens/pengaduan_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tiara_fin/message_helper.dart';
import 'package:tiara_fin/screens/detail_keuangan_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

// ========== TETAPAN HAKIKI ==========
// ========== TETAPAN HAKIKI ==========

class WavyClipper extends CustomClipper<Path> {
  final double animationValue;

  WavyClipper({this.animationValue = 0.0});

  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    // Tambah efek ombak banyu
    final waveOffset = animationValue * 20; // Goyang dikit 20px
    
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
  bool shouldReclip(WavyClipper oldClipper) => oldClipper.animationValue != animationValue;
}

// ========== BUNGKUSAN UTAMA ==========
class UserMainScreen extends StatefulWidget {
  final int initialIndex;
  const UserMainScreen({super.key, this.initialIndex = 0});
  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late List<Widget> _screens;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Wave Animation Controller
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _screens = [
      BerandaScreen(waveController: _waveController),
      const RiwayatScreen(),
      const PembayaranScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoleTheme.wargaBackground,
      extendBody: true, // Important for floating effect over body content
      body: Stack(
        children: [
          // Main Body with PageView for smooth sliding
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
              HapticFeedback.selectionClick();
            },
            children: _screens,
          ),
          
          // Navbar Melayang Kek Harapan
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: WavyBottomBar(
                selectedIndex: _selectedIndex,
                items: const [
                  Icons.dashboard_rounded,
                  Icons.history_rounded,
                  Icons.payment_rounded,
                  Icons.person_rounded,
                ],
                onItemSelected: (i) {
                   HapticFeedback.lightImpact();
                   _onTabTapped(i);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class BerandaScreen extends StatefulWidget {
  final AnimationController? waveController;
  const BerandaScreen({super.key, this.waveController});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();
  final RefreshController _refreshController = RefreshController();
  
  UserModel? _currentUser;
  List<IuranModel> _allIuran = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    _currentUser = await _auth.getCurrentUser();
    _fs.getIuranList().listen((list) {
      if (mounted) setState(() => _allIuran = list);
    });
    if (mounted) setState(() {});
  }

  void _showAddForumDialog(BuildContext context) {
    if (_currentUser == null) return;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Buat Diskusi", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Topik", hintText: "Contoh: Keamanan"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Detail", hintText: "Deskripsi (Opsional)"),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text("Diskusi akan diverifikasi Ketua RT.", style: TextStyle(fontSize: 12, color: Colors.orange))),
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                MessageHelper.showLoading(context, message: "Mengirim...");
                await _fs.requestForum(_currentUser!.id, _currentUser!.nama, titleCtrl.text, descCtrl.text);
                if (mounted) {
                   MessageHelper.hideLoading(context);
                   MessageHelper.showSuccess(context, "Terkirim! Menunggu verifikasi.");
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Kirim"),
          )
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
             Icon(Icons.warning_rounded, color: Colors.red, size: 32),
             SizedBox(width: 10),
             Flexible(child: Text("Panggilan Darurat", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Apakah Anda dalam situasi darurat? Tekan tombol di bawah untuk bantuan segera.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            _buildEmergencyAction(
              "Panggil Satpam",
              "08123456789", // Nomor asal jeplak
              Icons.shield,
              const Color(0xFF00796B),
              () async {
                final Uri launchUri = Uri(scheme: 'tel', path: '08123456789');
                try {
                  await launchUrl(launchUri);
                } catch (e) {
                   debugPrint("Could not launch $launchUri");
                }
              }
            ),
             const SizedBox(height: 12),
            _buildEmergencyAction(
              "Ambulans",
              "118",
              Icons.medical_services,
              Colors.redAccent,
              () async {
                 final Uri launchUri = Uri(scheme: 'tel', path: '118');
                 try {
                   await launchUrl(launchUri);
                 } catch (e) {
                    debugPrint("Could not launch $launchUri");
                 }
              }
            ),
             const SizedBox(height: 12),
            _buildEmergencyAction(
              "Pemadam Kebakaran",
              "113",
              Icons.fire_truck,
              Colors.orange,
              () async {
                 final Uri launchUri = Uri(scheme: 'tel', path: '113');
                 try {
                   await launchUrl(launchUri);
                 } catch (e) {
                    debugPrint("Could not launch $launchUri");
                 }
              }
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAction(String label, String subLabel, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.call, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Prevent overlap with navbar
        child: FloatingActionButton(
          onPressed: () => _showAddForumDialog(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        header: WaterDropMaterialHeader(
          backgroundColor: AppColors.primary,
          color: Colors.white,
          distance: 60,
        ),
        onRefresh: () async {
           HapticFeedback.mediumImpact(); // Haptic feedback on refresh
           await Future.delayed(const Duration(seconds: 1));
           _loadData(); // Reload data
           _refreshController.refreshCompleted();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 160),
          child: Column(
            children: [

              // Header Section
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Gradient
                  AnimatedBuilder(
                    animation: widget.waveController ?? const AlwaysStoppedAnimation(0),
                    builder: (context, child) {
                      return ClipPath(
                        clipper: WavyClipper(animationValue: widget.waveController?.value ?? 0),
                        child: Container(
                          height: 260,
                          decoration: const BoxDecoration(
                            gradient: RoleTheme.wargaGradient,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -50, right: -30,
                                child: Container(
                                  width: 150, height: 150,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                                ),
                              ),
                              Positioned(
                                bottom: 20, left: -20,
                                child: Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  ),

                  // Header Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                               Container(
                                 decoration: BoxDecoration(
                                   shape: BoxShape.circle,
                                   border: Border.all(color: Colors.white, width: 2),
                                   boxShadow: AppTheme.softShadow,
                                 ),
                                 child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.white,
                                    backgroundImage: (_currentUser?.photoUrl != null && _currentUser!.photoUrl!.isNotEmpty)
                                        ? NetworkImage(_currentUser!.photoUrl!)
                                        : null,
                                    child: (_currentUser?.photoUrl == null || _currentUser!.photoUrl!.isEmpty)
                                        ? Text(
                                            _currentUser?.nama.isNotEmpty == true ? _currentUser!.nama[0].toUpperCase() : 'U',
                                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 20),
                                          )
                                        : null,
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     'Selamat Pagi,',
                                     style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                                   ),
                                   Text(
                                     _currentUser?.nama ?? 'Warga',
                                     style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                   ),
                                 ],
                               ),
                            ],
                          ),
                          Row(
                            children: [
                               // SOS Button
                               GestureDetector(
                                onTap: () {
                                  HapticFeedback.heavyImpact(); // Getaran kuat untuk emergency
                                  _showEmergencyDialog(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.9), // Emergency Red
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 4),
                                      Text(
                                        "SOS",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                          
                              // Notification Icon with Badge
                              StreamBuilder<List<NotificationModel>>(
                                stream: _fs.getNotifications(_currentUser?.role ?? 'warga'),
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
                          )
                        ],
                      ),
                    ),
                  ),
                  
                  // Balance Card
                  Padding(
                    padding: const EdgeInsets.only(top: 140, left: 16, right: 16),
                    child: _buildBalanceCard(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Main Menu Grid
              Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: FadeInSlide.delayed(
                   delay: const Duration(milliseconds: 200),
                   child: _buildMenuGrid(context),
                 ),
              ),
              
              const SizedBox(height: 24),
              
               // Announcements Section
              FadeInSlide.delayed(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    _buildSectionHeader('Pemberitahuan', null),
                    SizedBox(
                      height: 170,
                      child: StreamBuilder<List<PengumumanModel>>(
                        stream: _fs.getPengumuman(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final list = snapshot.data!;
                          if (list.isEmpty) return const Center(child: Text("Belum ada pengumuman"));
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: list.length,
                            itemBuilder: (context, index) => _buildRealAnnouncementCard(list[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Financial Statistics
              FadeInSlide.delayed(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    _buildSectionHeader('Statistik Keuangan', null),
                    Container(
                      height: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                          final List<FlSpot> incomeSpots = [];
                          final List<FlSpot> expenseSpots = [];

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
                            
                            incomeSpots.add(FlSpot((5-i).toDouble(), income));
                            expenseSpots.add(FlSpot((5-i).toDouble(), expense));
                          }

                          // Get max Y for dynamic scaling
                          double maxVal = 0;
                          for(var s in incomeSpots) if(s.y > maxVal) maxVal = s.y;
                          for(var s in expenseSpots) if(s.y > maxVal) maxVal = s.y;
                          if (maxVal == 0) maxVal = 100;

                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: maxVal / 5,
                                getDrawingHorizontalLine: (value) => 
                                  FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final monthIndex = DateTime.now().month - (5 - value.toInt());
                                      final safeMonthIndex = (monthIndex - 1) % 12; // 0-11
                                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(months[safeMonthIndex], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 5,
                              minY: 0,
                              maxY: maxVal * 1.2,
                              lineBarsData: [
                                // Income Line
                                LineChartBarData(
                                  spots: incomeSpots,
                                  isCurved: true,
                                  gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF69F0AE)]),
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [AppColors.success.withValues(alpha: 0.3), AppColors.success.withValues(alpha: 0.0)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                // Expense Line
                                LineChartBarData(
                                  spots: expenseSpots,
                                  isCurved: true,
                                  gradient: const LinearGradient(colors: [AppColors.danger, Color(0xFFFF8A80)]),
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: false,
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
              ),
              
              const SizedBox(height: 24),

              // Recent Activity
              FadeInSlide.delayed(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    _buildSectionHeader('Aktivitas Terakhir', null),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StreamBuilder<List<TransaksiModel>>(
                        stream: _fs.getUserTransaksi(_currentUser?.id ?? 'none'),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Column(
                              children: List.generate(3, (index) => const TransactionSkeletonCard()),
                            );
                          }
                          final recent = snapshot.data!.take(3).toList();
                          if (recent.isEmpty) {
                            return const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'Belum Ada Aktivitas',
                              message: 'Transaksi kamu akan muncul di sini',
                            );
                          }
                          
                          return AnimationLimiter(
                            child: Column(
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 375),
                                childAnimationBuilder: (widget) => SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: widget,
                                  ),
                                ),
                                children: recent.map((t) => _buildRecentTransactionItem(t)).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealAnnouncementCard(PengumumanModel item) {
    if (_currentUser == null) return const SizedBox.shrink();
    bool isNew = !item.viewers.contains(_currentUser!.id);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPengumumanScreen(pengumuman: item, currentUser: _currentUser!))),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: item.id,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    image: item.imageUrls.isNotEmpty ? DecorationImage(image: NetworkImage(item.imageUrls.first), fit: BoxFit.cover) : null,
                  ),
                  child: item.imageUrls.isEmpty ? const Center(child: Icon(Icons.campaign, color: AppColors.primary, size: 40)) : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (isNew) Container(margin: const EdgeInsets.only(left: 6), width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(Utils.formatDate(item.date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMenuGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildMenuIcon(Icons.history_edu, 'Riwayat', AppTheme.secondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatScreen())))),
        const SizedBox(width: 12),
        Expanded(child: _buildMenuIcon(Icons.payments_outlined, 'Tagihan', AppTheme.danger, () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UserMainScreen(initialIndex: 2)), (r) => false))),
        const SizedBox(width: 12),
        Expanded(child: _buildMenuIcon(Icons.forum_outlined, 'Diskusi', AppTheme.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumDiskusiScreen())))),
        const SizedBox(width: 12),
        Expanded(child: _buildMenuIcon(Icons.people_outline, 'Warga', AppTheme.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoWargaScreen())))),
      ],
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return TappableCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            // Dual-tone Icon
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.1,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
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

  Widget _buildAnnouncementCard(String title, String time, String imagePath) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
             child: Text(time, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const Text("Klik untuk detail", style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<List<TransaksiModel>>(
      stream: _fs.getUserTransaksi(_currentUser?.id ?? 'none'),
      builder: (context, snapshot) {
         int tagihanBelumLunas = 0;
         bool isLunas = false;
         
         if (snapshot.hasData) {
            final now = DateTime.now();
            int totalMustPay = _allIuran.fold(0, (sum, i) => sum + i.harga);
             final paidTrans = snapshot.data!.where((t) {
                 if (t.tipe != 'pemasukan' || t.status == 'gagal') return false;
                 final tDate = t.timestamp;
                 return tDate.month == now.month && tDate.year == now.year;
              });
             final paidIuranIds = paidTrans.map((t) => t.iuranId).toSet();
             int paidAmount = 0;
             for(var iuran in _allIuran) {
                 if(paidIuranIds.contains(iuran.id)) paidAmount += iuran.harga;
             }
             tagihanBelumLunas = totalMustPay - paidAmount;
             if (tagihanBelumLunas <= 0) {
                 tagihanBelumLunas = 0;
                 if (_allIuran.isNotEmpty) isLunas = true;
             }
         }
         
         // Calculate prepaid months
         int paidMonthsAhead = 0;
         if (isLunas && _allIuran.isNotEmpty) {
             final now = DateTime.now();
             DateTime checkDate = DateTime(now.year, now.month + 1);
             int totalMustPay = _allIuran.fold(0, (sum, i) => sum + i.harga);
             
             if (totalMustPay > 0 && snapshot.hasData) {
               for (int i = 0; i < 12; i++) {
                   String periodeStr = "${checkDate.month.toString().padLeft(2, '0')}-${checkDate.year}";
                   int amountPaidForMonth = snapshot.data!
                     .where((t) => t.periode == periodeStr && t.status == 'sukses' && t.tipe == 'pemasukan')
                     .fold(0, (sum, t) => sum + t.uang);
                   if (amountPaidForMonth >= totalMustPay) {
                     paidMonthsAhead++;
                     checkDate = DateTime(checkDate.year, checkDate.month + 1);
                   } else {
                     break; 
                   }
               }
             }
         }

          return Stack(
            children: [
              Container(
                 padding: const EdgeInsets.all(24),
                 constraints: const BoxConstraints(minHeight: 200),
                 decoration: BoxDecoration(
                   gradient: AppTheme.meshGradient,
                   borderRadius: BorderRadius.circular(24),
                   boxShadow: AppTheme.glowShadow(Colors.blue),
                 ),
                 child: Stack(
                   children: [
                      // Transparent decoration circles
                      Positioned(
                        top: -30, right: -30,
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                        ),
                      ),
                      Positioned(
                        bottom: -20, left: -20,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        ),
                      ),
                      
                      // Content
                      Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text("Sisa Tagihan Bulan Ini", style: TextStyle(color: Colors.white70, fontSize: 14)),
                             Icon(Icons.credit_card, color: Colors.white30),
                           ],
                         ),
                         const SizedBox(height: 12),
                         FittedBox(
                           fit: BoxFit.scaleDown,
                           alignment: Alignment.centerLeft,
                           child: Text(
                             isLunas 
                               ? (paidMonthsAhead > 0 ? "Lunas (+${paidMonthsAhead} Bln)" : "Lunas 🎉")
                               : Utils.formatCurrency(tagihanBelumLunas),
                             style: GoogleFonts.outfit(
                               fontSize: 32,
                               fontWeight: FontWeight.bold,
                               color: Colors.white,
                               letterSpacing: 1.0,
                             ),
                           ),
                         ),
                         const SizedBox(height: 24),
                         Row(
                           children: [
                             Expanded(
                               child: ElevatedButton(
                                 onPressed: () {
                                    if (isLunas) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailKeuanganScreen()));
                                    } else {
                                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UserMainScreen(initialIndex: 2)), (r) => false);
                                    }
                                 },
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.white,
                                   foregroundColor: const Color(0xFF6C5CE7),
                                   elevation: 0,
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                 ),
                                 child: Text(isLunas ? "Lihat Detail" : "Bayar Sekarang", style: const TextStyle(fontWeight: FontWeight.bold)),
                               ),
                             ),
                             const SizedBox(width: 12),
                             Container(
                               decoration: BoxDecoration(
                                 color: Colors.white.withValues(alpha: 0.2),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: IconButton(
                                 onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UserMainScreen(initialIndex: 1)), (r) => false),
                                 tooltip: "Riwayat Pembayaran",
                                 icon: const Icon(Icons.history, color: Colors.white),
                               ),
                             )
                           ],
                         )
                       ],
                      ),
                   ],
                 ),
              ),
              
              // Liquid Surface Overlay (Wet Look)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.5), // High Gloss Start
                            Colors.white.withValues(alpha: 0.0), // Clear Center
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.1), // Subtle Reflection End
                          ],
                          stops: const [0.0, 0.4, 0.6, 1.0],
                        ),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.white.withValues(alpha: 0.1),
                             offset: const Offset(-1, -1),
                             blurRadius: 2,
                             spreadRadius: 0
                           )
                        ]
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
      }
    );
  }
  
  Widget _buildRecentTransactionItem(TransaksiModel t) {
     final bool isSuccess = t.status == 'sukses';
     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10)]
        ),
        child: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Icon(
                 isSuccess ? Icons.check_circle : Icons.access_time_filled,
                 color: isSuccess ? Colors.green : Colors.orange,
                 size: 20,
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(t.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   Text(Utils.formatDate(t.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                 ],
               ),
             ),
             Text(
               Utils.formatCurrency(t.uang),
               style: TextStyle(fontWeight: FontWeight.bold, color: t.tipe == 'pengeluaran' ? Colors.red : Colors.black),
             )
          ],
        ),
     );
  }
}

// ========== JEJAK MANTAN (RIWAYAT) ==========
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  UserModel? _currentUser;
  String _selectedFilter = 'Semua'; // Status Filter
  String _selectedCategory = 'Semua'; // Category Filter
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    _currentUser = await _auth.getCurrentUser();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<List<TransaksiModel>>(
        stream: _fs.getUserTransaksi(_currentUser?.id ?? 'none'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(5, (index) => const TransactionSkeletonCard()),
            );
          }

          final allTrans = snapshot.data!;


          // Filter transactions for better visibility
          var filteredTrans = allTrans;
          
          // Search Logic
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filteredTrans = filteredTrans.where((t) {
               return t.deskripsi.toLowerCase().contains(query) || 
                      t.uang.toString().contains(query);
            }).toList();
          }

          // Statusnya Gimana?
          if (_selectedFilter == 'Lunas') {
            filteredTrans = filteredTrans.where((t) => t.status == 'sukses').toList();
          } else if (_selectedFilter == 'Menunggu') {
            filteredTrans = filteredTrans.where((t) => t.status == 'menunggu').toList();
          }
          
          // Pilih Kategori
          if (_selectedCategory != 'Semua') {
             filteredTrans = filteredTrans.where((t) => t.deskripsi.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
          }

          // Pilih Tanggal Jadian
          if (_selectedDateRange != null) {
            filteredTrans = filteredTrans.where((t) {
              return t.timestamp.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                     t.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }
          
          // Itung Totalnya Bos
          final int totalCount = filteredTrans.length;
          final int totalAmount = filteredTrans.fold(0, (sum, t) => sum + t.uang);

          // Group by date
          Map<String, List<TransaksiModel>> groupedByDate = {};
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));
          final weekAgo = today.subtract(const Duration(days: 7));

          for (var t in filteredTrans) {
            final transDate = DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day);
            String label;
            
            if (transDate == today) {
              label = 'Hari Ini';
            } else if (transDate == yesterday) {
              label = 'Kemarin';
            } else if (transDate.isAfter(weekAgo)) {
              label = 'Minggu Ini';
            } else {
              label = '${_getMonthName(t.timestamp.month)} ${t.timestamp.year}';
            }
            
            if (!groupedByDate.containsKey(label)) {
              groupedByDate[label] = [];
            }
            groupedByDate[label]!.add(t);
          }
          
          // Sort for readability
          final sortedKeys = groupedByDate.keys.toList();
          sortedKeys.sort((a, b) {
            const order = ['Hari Ini', 'Kemarin', 'Minggu Ini'];
            final aIndex = order.indexOf(a);
            final bIndex = order.indexOf(b);
            if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
            if (aIndex != -1) return -1;
            if (bIndex != -1) return 1;
            return b.compareTo(a); // Reverse chronological for months
          });

          return Column(
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey), 
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ) 
                      : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (val) {
                     setState(() => _searchQuery = val.toLowerCase());
                  },
                ),
              ),

              // Kartu Ringkasan (Baru nih)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), // Light green background (Green 50 equivalent)
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32), // Darker green text
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Utils.formatCurrency(totalAmount),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFA5D6A7)), // Green 200
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(
                           children: [
                             const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF2E7D32)),
                             const SizedBox(width: 8),
                             Text(
                               '$totalCount Transaksi',
                               style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32), fontSize: 12),
                             ),
                           ],
                         ),
                         InkWell(
                            onTap: () async {
                               final picked = await showDateRangePicker(
                                 context: context, 
                                 firstDate: DateTime(2020), 
                                 lastDate: DateTime(2030),
                                 initialDateRange: _selectedDateRange,
                                 builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
                                    ),
                                    child: child!,
                                  );
                                 }
                               );
                               if (picked != null) {
                                 setState(() => _selectedDateRange = picked);
                               }
                            },
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(20),
                               border: Border.all(color: const Color(0xFFA5D6A7)),
                             ),
                             child: Row(
                               children: [
                                 Icon(Icons.calendar_today_rounded, size: 12, color: _selectedDateRange != null ? AppColors.primary : Colors.grey[600]),
                                 const SizedBox(width: 6),
                                 Text(
                                   _selectedDateRange != null 
                                      ? "${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}" 
                                      : "Semua Tanggal",
                                   style: TextStyle(
                                     fontSize: 11,
                                     fontWeight: FontWeight.bold,
                                     color: _selectedDateRange != null ? AppColors.primary : Colors.grey[600],
                                   ),
                                 ),
                                 if (_selectedDateRange != null) ...[
                                   const SizedBox(width: 4),
                                   InkWell(
                                     onTap: () => setState(() => _selectedDateRange = null),
                                     child: const Icon(Icons.close, size: 12, color: AppColors.primary)
                                   )
                                 ]
                               ],
                             ),
                           ),
                         ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Saring (Bisa digeser)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Lunas'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Menunggu'),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    // Category Filters
                    _buildCategoryChip('Keamanan'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Kebersihan'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Sampah'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Sosial'),
                  ],
                ),
              ),

              // Garis Waktu Kehidupan
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                  children: sortedKeys.map((key) {
                    final transactions = groupedByDate[key]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            key,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.dark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...transactions.map((t) => _buildTransactionItem(t)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent, // Light Green or Transparent
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransaksiModel t) {
    Color statusBgColor = Colors.grey.shade100;
    Color statusTextColor = Colors.grey;
    String statusText = 'Menunggu';
    IconData statusIcon = Icons.access_time_rounded;

    if (t.status == 'sukses') {
      statusBgColor = const Color(0xFFE8F5E9); // Light Green
      statusTextColor = const Color(0xFF2E7D32); // Dark Green
      statusText = 'Lunas';
      statusIcon = Icons.check_circle_rounded;
    } else if (t.status == 'gagal') {
      statusBgColor = const Color(0xFFFFEBEE); // Light Red
      statusTextColor = const Color(0xFFC62828); // Dark Red
      statusText = 'Gagal';
      statusIcon = Icons.cancel_rounded;
    } else {
       // Menunggu
       statusBgColor = const Color(0xFFFFF3E0); // Light Orange
       statusTextColor = const Color(0xFFEF6C00); // Dark Orange
       statusText = 'Menunggu';
       statusIcon = Icons.access_time_filled_rounded;
    }

    return InkWell(
      onTap: () => _showTransactionDetail(t),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // Reduced margin
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Optimized Padding to prevent overflow
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            ),
             BoxShadow(
              color: Colors.grey.withValues(alpha: 0.02), 
              blurRadius: 2, 
              offset: const Offset(0, 1)
            )
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Icon Category
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorForIuran(t.deskripsi).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getIconForIuran(t.deskripsi),
                color: _getColorForIuran(t.deskripsi),
                size: 24,
              ),
            ),
            const SizedBox(width: 12), // Slightly reduced gap
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.deskripsi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Slightly smaller font
                      color: AppColors.dark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Wrap( // Changed Row to Wrap to handle smaller screens better
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${t.timestamp.day} ${_getMonthName(t.timestamp.month)} ${t.timestamp.year}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${t.timestamp.hour.toString().padLeft(2, '0')}:${t.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // Jumlah Duit & Statusnya
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Utils.formatCurrency(t.uang),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14, // Adjusted size
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusTextColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = isSelected ? 'Semua' : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue[900] : AppColors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(TransaksiModel t) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text("Detail Pembayaran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 20),
                     Center(
                       child: Column(
                         children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (t.status == 'sukses' ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                t.status == 'sukses' ? Icons.check_circle : Icons.pending,
                                size: 40,
                                color: t.status == 'sukses' ? Colors.green : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              Utils.formatCurrency(t.uang),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              t.status == 'sukses' ? "Pembayaran Berhasil" : "Menunggu Verifikasi",
                              style: TextStyle(
                                color: t.status == 'sukses' ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 32),
                     _detailRow("Tanggal", '${t.timestamp.day} ${_getMonthName(t.timestamp.month)} ${t.timestamp.year} ${t.timestamp.hour}:${t.timestamp.minute}'),
                     _detailRow("Kategori", t.deskripsi),
                     // _detailRow("Metode", t.metode ?? 'Transfer'), 
                     const Divider(height: 32),
                     const Text("Bukti Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: t.buktiGambar != null && t.buktiGambar!.isNotEmpty
                     ? ClipRRect(
                         borderRadius: BorderRadius.circular(12),
                         child: Image.network(t.buktiGambar!, fit: BoxFit.contain),
                       )
                     : const Center(child: Text("Tidak ada bukti lampiran", style: TextStyle(color: Colors.grey))),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: const TextStyle(color: Colors.grey)),
           Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getIconForIuran(String desc) {
    if (desc.toLowerCase().contains('keamanan')) return Icons.security;
    if (desc.toLowerCase().contains('kebersihan')) {
      return Icons.cleaning_services;
    }
    if (desc.toLowerCase().contains('sampah')) return Icons.delete;
    if (desc.toLowerCase().contains('lingkungan')) return Icons.nature;
    if (desc.toLowerCase().contains('air')) return Icons.water_drop;
    if (desc.toLowerCase().contains('renovasi')) return Icons.construction;
    return Icons.receipt;
  }

  Color _getColorForIuran(String desc) {
    if (desc.toLowerCase().contains('keamanan')) return AppColors.info;
    if (desc.toLowerCase().contains('kebersihan')) return AppColors.warning;
    if (desc.toLowerCase().contains('sampah')) return AppColors.danger;
    if (desc.toLowerCase().contains('lingkungan')) return AppColors.success;
    if (desc.toLowerCase().contains('renovasi')) return const Color(0xFFFF6B6B);
    return AppColors.primary;
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}

// ========== BAYAR HUTANG (PEMBAYARAN) ==========
class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  UserModel? _currentUser;
  
  // State buat milih-milih
  final Set<String> _selectedIuranIds = {};
  List<IuranModel> _allIuran = [];
  bool _isLoading = false;
  // String _selectedMethod = 'va'; // Removed as per request
  
  // BARU: Bulan apa aja yang mau dibayar
  final Map<String, Set<String>> _selectedMonthsByIuran = {}; // iuranId -> Set of periode strings
  
  Set<String> _paidIuranIds = {};
  Map<String, Set<String>> _paidMonthsByIuran = {}; // iuranId -> Set of paid/pending periode strings
  Map<String, Map<String, String>> _statusMonthsByIuran = {}; // iuranId -> (periode -> status)

  late Stream<List<IuranModel>> _iuranStream;

  @override
  void initState() {
    super.initState();
    _iuranStream = _fs.getIuranList();
    _loadUser();
  }

  void _loadUser() async {
    _currentUser = await _auth.getCurrentUser();
    if (mounted) {
      setState(() {});
      _checkPaidStatus();
    }
  }

  void _checkPaidStatus() async {
    if (_currentUser == null) return;
    
    final now = DateTime.now();
    final currentYear = now.year;

    // Get transactions for current year
    final trans = await _fs.getUserTransaksi(_currentUser!.id).first;
    
    final paidIds = <String>{};
    final paidMonths = <String, Set<String>>{};
    final statusMonths = <String, Map<String, String>>{};
    
    for (var t in trans) {
      // Must be pemasukan
      if (t.tipe != 'pemasukan') continue;
      if (t.status == 'gagal') continue;
      
      // Check if transaction is for current year
      if (t.timestamp.year == currentYear && t.iuranId != null) {
        paidIds.add(t.iuranId!);
        
        // Track paid months by iuran
        if (t.periode.isNotEmpty) {
          paidMonths.putIfAbsent(t.iuranId!, () => {});
          paidMonths[t.iuranId!]!.add(t.periode);
          
          statusMonths.putIfAbsent(t.iuranId!, () => {});
          statusMonths[t.iuranId!]![t.periode] = t.status;
        }
      }
    }

    if (mounted) {
      setState(() {
        _paidIuranIds = paidIds;
        _paidMonthsByIuran = paidMonths;
        _statusMonthsByIuran = statusMonths;
      });
    }
  }
  
  void _toggleSelection(String id) {
    if (_paidIuranIds.contains(id)) return; // Prevent selection if paid
    setState(() {
      if (_selectedIuranIds.contains(id)) {
        _selectedIuranIds.remove(id);
        _selectedMonthsByIuran.remove(id); // Clean up
      } else {
        _selectedIuranIds.add(id);
      }
    });
  }

  // _updateMonthSelection removed as we are back to Calendar Dialog




  int get _totalAmount {
    int total = 0;
    for (var iuran in _allIuran) {
      if (_selectedIuranIds.contains(iuran.id)) {
        // Recurring items: count selected months
        // Non-recurring items: only count once
        if (iuran.isRecurring) {
          final selectedMonths = _selectedMonthsByIuran[iuran.id] ?? {};
          total += iuran.harga * selectedMonths.length;
        } else {
          total += iuran.harga;
        }
      }
    }
    return total;
  }

  File? _buktiBayarFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _buktiBayarFile = File(image.path);
      });
    }
  }

  void _processPayment() async {
    if (_currentUser == null || _selectedIuranIds.isEmpty) return;

    // Check if recurring iuran have months selected
    for (var iuranId in _selectedIuranIds) {
      final iuran = _allIuran.firstWhere((i) => i.id == iuranId);
      if (iuran.isRecurring) {
        final selectedMonths = _selectedMonthsByIuran[iuranId] ?? {};
        if (selectedMonths.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ Pilih bulan untuk ${iuran.nama}"), backgroundColor: Colors.orange),
          );
          return;
        }
      }
    }

    if (_buktiBayarFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Harap upload bukti pembayaran"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload Proof of Payment
      String? buktiUrl;
      final supabase = SupabaseService();
      
      buktiUrl = await supabase.uploadImage(_buktiBayarFile!);
      
      if (buktiUrl == null) {
        throw "Gagal upload image. Pastikan koneksi stabil.";
      }

      // Proses pembayaran satu-satu
      for (var iuranId in _selectedIuranIds) {
        final iuran = _allIuran.firstWhere((i) => i.id == iuranId);
        
        if (iuran.isRecurring) {
          // Buat yang rutin: bikin transaksi tiap bulan
          final selectedMonths = _selectedMonthsByIuran[iuranId] ?? {};
          for (var periode in selectedMonths) {
            await _fs.addTransaksi(
              iuranId: iuran.id,
              userId: _currentUser!.id,
              userName: _currentUser!.nama,
              amount: iuran.harga,
              type: 'pemasukan',
              description: 'Bayar: ${iuran.nama} ($periode)',
              buktiUrl: buktiUrl,
              status: 'menunggu',
              periode: periode,
              metode: 'Transfer Bank',
            );
          }
        } else {
          // Buat yang sekali bayar: sikat langsung
          final now = DateTime.now();
          final periode = "${now.month.toString().padLeft(2, '0')}-${now.year}";
          await _fs.addTransaksi(
            iuranId: iuran.id,
            userId: _currentUser!.id,
            userName: _currentUser!.nama,
            amount: iuran.harga,
            type: 'pemasukan',
            description: 'Bayar: ${iuran.nama}',
            buktiUrl: buktiUrl,
            status: 'menunggu',
            periode: periode,
            metode: 'Transfer Bank',
          );
        }
      }

      // Kabarin Admin duit udah meluncur
      await _fs.sendNotification(
        title: "Pembayaran Baru",
        body: "${_currentUser!.nama} mengirim pembayaran ${_selectedIuranIds.length} jenis iuran. Total: ${Utils.formatCurrency(_totalAmount)}",
        type: "payment",
        targetRole: "admin",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pembayaran Berhasil Dikirim!"), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UserMainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("❌ Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Pembayaran Iuran'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Daftar Tagihan
          Expanded(
            child: StreamBuilder<List<IuranModel>>(
              stream: _iuranStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            "Gagal memuat data.\n${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text("Coba Lagi"),
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada tagihan iuran saat ini."));
                }

                _allIuran = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 150), // Increased bottom padding for Navbar overlap
                  children: [
                    // Header Option: Select All
                    // Header Removed
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Checkbox(
                    //         value: _selectedIuranIds.length == _allIuran.length && _allIuran.isNotEmpty,
                    //         onChanged: (val) => _selectAll(),
                    //         activeColor: AppColors.primary,
                    //       ),
                    //       const Text("Pilih Semua Tagihan", style: TextStyle(fontWeight: FontWeight.bold)),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 16),
                    ..._allIuran.map((iuran) => _buildIuranItem(iuran)),
                    
                    const SizedBox(height: 20),
                    // Extra Month Selection Info Removed (Now integrated in Card)

                    // Bukti Pembayaran
                    const Text(
                      'Bukti Pembayaran',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _buktiBayarFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_buktiBayarFile!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text("Tap untuk upload bukti", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    // Metode Pembayaran (Simplified)
                    const SizedBox(height: 20),
                    // Metode Pembayaran (Simplified to Transfer Info)
                    const Text(
                        'Metode Pembayaran',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      // Kartu Transfer Bank
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance, color: Colors.blue),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Transfer Bank BCA",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "1234 5678 90",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 18,
                                          color: AppColors.primary,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "a.n Bendahara RT",
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.grey),
                                  onPressed: () {
                                    Clipboard.setData(const ClipboardData(text: "1234567890"));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("No. Rekening Disalin!")),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                     Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                                     SizedBox(width: 8),
                                     Expanded(
                                       child: Text(
                                          "Mohon transfer sesuai nominal tagihan.",
                                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                       ),
                                     )
                                  ],
                                ),
                            )
                          ],
                        ),
                      ),
                      
                      // Extra padding at bottom to handle overlay
                      const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
          
          // Ringkasan Bawah
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 130), // Increased to 130 to clear floating navbar
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea( // Safe Area top/left/right mainly
              top: false, 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_selectedIuranIds.length} Item Dipilih", style: const TextStyle(color: Colors.grey)),
                      Text(
                        Utils.formatCurrency(_totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedIuranIds.isEmpty || _isLoading ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Bayar Sekarang", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIuranItem(IuranModel iuran) {
    final paidMonths = _paidMonthsByIuran[iuran.id] ?? {};
    final isPaidFull = iuran.isRecurring && paidMonths.length >= 12;
    final isPaidOnce = !iuran.isRecurring && _paidIuranIds.contains(iuran.id);
    final isPaid = isPaidFull || isPaidOnce;
    
    final isSelected = _selectedIuranIds.contains(iuran.id);
    final selectedMonths = _selectedMonthsByIuran[iuran.id] ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPaid ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.transparent, width: 2),
      ),
      child: ListTile(
        leading: isPaid 
           ? const Icon(Icons.check_circle, color: Colors.green)
           : Checkbox(
              value: isSelected,
              onChanged: (val) => _toggleSelection(iuran.id),
              activeColor: AppColors.primary,
            ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                iuran.nama, 
                style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isPaid ? Colors.grey : Colors.black
                )
              ),
            ),
            // Periode Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: iuran.isRecurring ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                iuran.periodeDisplay,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: iuran.isRecurring ? Colors.blue[700] : Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPaid)
              Text(
                iuran.isRecurring ? "Lunas semua bulan" : "Lunas bulan ini", 
                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
              )
            else ...[
              Text(iuran.deskripsi, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (iuran.isRecurring && paidMonths.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${paidMonths.length} bulan sudah dibayar',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (iuran.isRecurring && isSelected && selectedMonths.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${selectedMonths.length} bulan dipilih',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ],
        ),
        trailing: Text(
          Utils.formatCurrency(iuran.harga),
          style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isPaid ? Colors.grey : AppColors.dark
          ),
        ),
        onTap: isPaid ? null : () {
          if (iuran.isRecurring) {
            // Show new CALENDAR dialog
            _showMonthPickerDialog(iuran, paidMonths);
          } else {
            // For non-recurring, just toggle selection
            _toggleSelection(iuran.id);
          }
        },
      ),
    );
  }

  // Balikin Dialog Pilih Bulan (Versi Bagus)
  void _showMonthPickerDialog(IuranModel iuran, Set<String> paidMonths) {
    final now = DateTime.now();
    final currentYear = now.year;
    final selectedMonths = Set<String>.from(_selectedMonthsByIuran[iuran.id] ?? {});
    final statusMap = _statusMonthsByIuran[iuran.id] ?? {};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Pilih Bulan - ${iuran.nama}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text('Tahun $currentYear', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final monthStr = month.toString().padLeft(2, '0');
                    final periode = '$monthStr-$currentYear';
                    final isPaid = paidMonths.contains(periode); // actually paid or pending
                    final status = statusMap[periode] ?? 'sukses';
                    final isMenunggu = isPaid && status == 'menunggu';
                    
                    final isSelected = selectedMonths.contains(periode);
                    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                    
                    final boxColor = isPaid 
                        ? (isMenunggu ? Colors.orange[50] : Colors.green[50])
                        : (isSelected ? AppColors.primary : Colors.white);
                        
                    final borderColor = isPaid
                        ? (isMenunggu ? Colors.orange.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3))
                        : (isSelected ? AppColors.primary : Colors.grey[300]!);
                    
                    final textColor = isPaid
                        ? (isMenunggu ? Colors.orange[800] : Colors.green[800])
                        : (isSelected ? Colors.white : Colors.black87);
                    
                    return InkWell(
                      onTap: isPaid ? null : () {
                        setDialogState(() {
                          if (isSelected) {
                            selectedMonths.remove(periode);
                          } else {
                            selectedMonths.add(periode);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 4)] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              monthNames[index],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (isPaid)
                              Text(
                                isMenunggu ? 'Menunggu Verif' : 'Lunas', 
                                style: TextStyle(
                                  fontSize: 8, 
                                  color: isMenunggu ? Colors.orange[800] : Colors.green[700],
                                  fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.center,
                              )
                            else if (isSelected)
                              const Icon(Icons.check, size: 12, color: Colors.white)
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (selectedMonths.isNotEmpty)
                  Text(
                    '${selectedMonths.length} bulan dipilih • Total: ${Utils.formatCurrency(iuran.harga * selectedMonths.length)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedMonths.isEmpty ? null : () {
                setState(() {
                  _selectedMonthsByIuran[iuran.id] = selectedMonths;
                  if (!_selectedIuranIds.contains(iuran.id)) {
                    _selectedIuranIds.add(iuran.id);
                  }
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }







}




// ========== JATI DIRI (PROFILE) ==========
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    _currentUser = await _auth.getCurrentUser();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
               if (_currentUser == null) return;
               final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: _currentUser!)));
               if (refresh == true) {
                 _loadUser();
               }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 160), // Support Floating Navbar
        child: Column(
          children: [
            // Header Section
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Header Background Wavy
                ClipPath(
                  clipper: ProfileWaveClipper(),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: _currentUser?.role == 'admin' 
                        ? RoleTheme.adminGradient
                        : _currentUser?.role == 'ketua_rt'
                            ? RoleTheme.rtGradient
                            : const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF00796B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                    ),
                  ),
                ),
                
                // Content
                Positioned(
                  top: 100,
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10, 
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: (_currentUser?.photoUrl != null && _currentUser!.photoUrl!.isNotEmpty)
                              ? NetworkImage(_currentUser!.photoUrl!)
                              : null,
                          child: (_currentUser?.photoUrl == null || _currentUser!.photoUrl!.isEmpty)
                              ? Text(
                                  _currentUser?.nama.isNotEmpty == true ? _currentUser!.nama[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentUser?.nama ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87, // Changed for better visibility on white card if overlap, but here it is below header
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentUser?.role == 'admin' ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (_currentUser?.role ?? 'warga').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                             color: _currentUser?.role == 'admin' ? Colors.blue : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 80), // Space for the overlapping content
            
            // Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   // Personal Info Card
                   _buildSectionTitle('INFORMASI PRIBADI'),
                   Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Column(
                       children: [
                          _buildModernInfoRow(Icons.email_outlined, 'Email', _currentUser?.email ?? '-'),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildModernInfoRow(Icons.phone_outlined, 'No. Handphone', _currentUser?.noHp.isNotEmpty == true ? _currentUser!.noHp : '-'),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildModernInfoRow(Icons.home_work_outlined, 'Blok / Rumah', 
                              (_currentUser?.blok.isNotEmpty == true || _currentUser?.noRumah.isNotEmpty == true) 
                              ? '${_currentUser?.blok} / ${_currentUser?.noRumah}' 
                              : '-'),
                        ],
                     ),
                   ),
                   
                   const SizedBox(height: 24),
                   
                   // Settings Card
                   _buildSectionTitle('PENGATURAN'),
                   Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Column(
                       children: [
                         _buildModernMenuTile(Icons.lock_outline, 'Ubah Kata Sandi', Colors.orange, () => _showChangePasswordDialog(context)),
                         const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildModernMenuTile(Icons.notifications_outlined, 'Notifikasi', Colors.blue, 
                             () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildModernMenuTile(Icons.help_outline, 'Bantuan', Colors.purple, () => _showHelpDialog(context)),
                       ],
                     ),
                   ),

                   const SizedBox(height: 30),
                   
                   // Logout
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Keluar Aplikasi?'),
                              content: const Text('Anda harus login kembali untuk mengakses akun ini.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Keluar", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          
                          if (confirm == true && mounted) {
                             await _auth.logout();
                             Navigator.of(context).pushAndRemoveUntil(
                               MaterialPageRoute(builder: (_) => const LoginScreen()),
                               (route) => false,
                             );
                          }
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                         foregroundColor: Colors.red,
                         elevation: 0,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(16),
                           side: const BorderSide(color: Colors.red, width: 1),
                         ),
                       ),
                       child: const Text('Keluar Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernMenuTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  // Tempat buat ganti password
  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ubah Kata Sandi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Kata Sandi Lama"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Kata Sandi Baru"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (oldPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) return;
              
              // Cek password baru kuat ga
              final error = SecurityUtils.validatePassword(newPassCtrl.text);
              if (error != null) {
                MessageHelper.showWarning(context, error);
                return;
              }

              // Cek password lama bener ga
              final oldHash = SecurityUtils.hashPassword(oldPassCtrl.text);
              
              // Support old plain passwords too for legacy
              bool isMatch = false;
              if (_currentUser!.password == oldPassCtrl.text) {
                isMatch = true; 
              } else if (_currentUser!.password == oldHash) {
                isMatch = true;
              }

              if (isMatch) {
                 MessageHelper.showLoading(context, message: 'Mengupdate password...');
                 
                 final newHash = SecurityUtils.hashPassword(newPassCtrl.text);
                 await _fs.updateUserProfile(_currentUser!.id, nama: _currentUser!.nama, email: _currentUser!.email, password: newHash);
                 
                 if (mounted) {
                   MessageHelper.hideLoading(context);
                   Navigator.pop(ctx);
                   MessageHelper.showSuccess(context, "✅ Password berhasil diubah!");
                 }
              } else {
                 MessageHelper.showError(context, "❌ Password lama salah!");
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.help_outline, color: Colors.blue), SizedBox(width: 8), Text('Bantuan')]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jika mengalami kendala, hubungi pengurus RT:'),
            SizedBox(height: 16),
            Row(children: [Icon(Icons.person, size: 16), SizedBox(width: 8), Text('Pak RT (0812-3456-7890)')]),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.person, size: 16), SizedBox(width: 8), Text('Bendahara (0812-9876-5432)')]),
            SizedBox(height: 16),
            Text('Email Admin: admin@bukit.com', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tutup")),
        ],
      ),
    );
  }
}

class InfoWargaScreen extends StatefulWidget {
  const InfoWargaScreen({super.key});

  @override
  State<InfoWargaScreen> createState() => _InfoWargaScreenState();
}

class _InfoWargaScreenState extends State<InfoWargaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Info Warga'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            'Jadwal Pengambilan Sampah',
            'Setiap hari Selasa & Jumat, pukul 08:00 WIB.',
            Icons.delete_outline,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Jadwal Ronda Malam',
            'Silakan cek jadwal ronda di pos satpam atau grup WhatsApp warga.',
            Icons.security,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Kontak Darurat',
            'Satpam: 0812-3456-7890\nKetua RT: 0812-9876-5432',
            Icons.phone_in_talk,
            Colors.red,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final currentUser = await AuthService().getCurrentUser();
          if (currentUser != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PengaduanScreen(currentUser: currentUser),
              ),
            );
          }
        },
        label: const Text('Buat Pengaduan'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    
    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
