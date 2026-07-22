import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/firebase_service.dart';
import 'vendor_screen.dart';
import 'kriteria_screen.dart';
import 'penilaian_wizard_screen.dart';
import 'hasil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _checkAndSeedData();
  }

  Future<void> _checkAndSeedData() async {
    final isSeeded = await _firebaseService.isDataSeeded();
    if (!isSeeded && mounted) {
      _showSeedDialog();
    }
  }

  void _showSeedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Inisialisasi Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Belum ada data kriteria dan vendor. Ingin mengisi data contoh?\n\n'
          '• 7 Kriteria (Teknis, Keamanan, TCO, dll)\n'
          '• 6 Vendor (Huawei, Cisco, Siemens, dll)',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.tidak, style: GoogleFonts.poppins()),
          ),
          FilledButton(
            onPressed: () async {
              setState(() => _isSeeding = true);
              Navigator.pop(context);
              await _firebaseService.seedAllData();
              setState(() => _isSeeding = false);
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data contoh berhasil diisi!')),
              );
            },
            child: _isSeeding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Ya, Isi Data', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    const Icon(Icons.storage, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Isi Data Contoh', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, size: 20, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('Reset Semua Data', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'seed') {
                _showSeedDialog();
              } else if (value == 'reset') {
                _showResetDialog();
              }
            },
          ),
        ],
      ),
      body: _isSeeding
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengisi data contoh...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildKriteriaInfo(),
                  const SizedBox(height: 24),
                  _buildMenuGrid(context),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Metode TOPSIS - 7 Kriteria, 6 Vendor',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKriteriaInfo() {
    final kriteria = [
      {'kode': 'C1', 'nama': 'Teknis & Interoperabilitas', 'bobot': '0.20', 'tipe': 'Benefit'},
      {'kode': 'C2', 'nama': 'Keamanan Siber', 'bobot': '0.20', 'tipe': 'Benefit'},
      {'kode': 'C3', 'nama': 'Total Cost of Ownership', 'bobot': '0.15', 'tipe': 'Cost'},
      {'kode': 'C4', 'nama': 'Rekam Jejak & Pengalaman', 'bobot': '0.15', 'tipe': 'Benefit'},
      {'kode': 'C5', 'nama': 'Layanan Purna Jual (SLA)', 'bobot': '0.15', 'tipe': 'Benefit'},
      {'kode': 'C6', 'nama': 'Skalabilitas & Fleksibilitas', 'bobot': '0.10', 'tipe': 'Benefit'},
      {'kode': 'C7', 'nama': 'Kepatuhan Regulasi', 'bobot': '0.05', 'tipe': 'Benefit'},
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bobot Kriteria',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...kriteria.map((k) => _buildKriteriaRow(k)),
            const SizedBox(height: 8),
            Text(
              'Total Bobot: 1.00',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKriteriaRow(Map<String, String> kriteria) {
    final isCost = kriteria['tipe'] == 'Cost';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              kriteria['kode']!,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kriteria['nama']!,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCost ? AppColors.warning.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${kriteria['bobot']} ${kriteria['tipe']}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isCost ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      _MenuItem(
        icon: Icons.business,
        title: AppStrings.vendor,
        subtitle: 'Kelola data vendor',
        color: AppColors.primary,
        screen: const VendorScreen(),
      ),
      _MenuItem(
        icon: Icons.assignment,
        title: AppStrings.kriteria,
        subtitle: 'Kelola kriteria penilaian',
        color: AppColors.accent,
        screen: const KriteriaScreen(),
      ),
      _MenuItem(
        icon: Icons.auto_awesome,
        title: 'Wizard Penilaian',
        subtitle: 'Step-by-step penilaian',
        color: AppColors.warning,
        screen: const PenilaianWizardScreen(),
      ),
      _MenuItem(
        icon: Icons.bar_chart,
        title: AppStrings.hasil,
        subtitle: 'Lihat hasil TOPSIS',
        color: AppColors.success,
        screen: const HasilScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return _buildMenuCard(context, menu);
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuItem menu) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => menu.screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: menu.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(menu.icon, size: 32, color: menu.color),
            ),
            const SizedBox(height: 12),
            Text(
              menu.title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              menu.subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Semua Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Semua data vendor, kriteria, dan penilaian akan dihapus. Lanjutkan?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.tidak, style: GoogleFonts.poppins()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await _firebaseService.deleteAllData();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua data berhasil dihapus!')),
              );
            },
            child: Text('Ya, Hapus Semua', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget screen;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.screen,
  });
}
