import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../models/vendor.dart';
import '../models/kriteria.dart';
import '../models/penilaian.dart';
import '../models/hasil_topsis.dart';
import '../models/detail_topsis.dart';
import '../services/firebase_service.dart';
import '../services/topsis_service.dart';

class HasilScreen extends StatefulWidget {
  const HasilScreen({super.key});

  @override
  State<HasilScreen> createState() => _HasilScreenState();
}

class _HasilScreenState extends State<HasilScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  List<Vendor> _vendors = [];
  List<Kriteria> _kriteriaList = [];
  List<Penilaian> _penilaianList = [];
  List<HasilTopsis> _hasilList = [];
  DetailTopsis? _detail;

  bool _isLoading = true;
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _firebaseService.getVendors().listen((vendors) {
      _vendors = vendors;
      _hitungTopsis();
    });

    _firebaseService.getKriteria().listen((kriteriaList) {
      _kriteriaList = kriteriaList;
      _hitungTopsis();
    });

    _firebaseService.getPenilaian().listen((penilaianList) {
      _penilaianList = penilaianList;
      _hitungTopsis();
    });
  }

  void _hitungTopsis() {
    setState(() {
      _isLoading = true;
    });

    _hasilList = TopsisService.hitung(
      vendors: _vendors,
      kriteriaList: _kriteriaList,
      penilaianList: _penilaianList,
    );
    _detail = TopsisService.lastDetail;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.hasil,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hitungTopsis,
            tooltip: 'Hitung Ulang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasilList.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Winner Card
                      _buildWinnerCard(),
                      const SizedBox(height: 16),

                      // Quick Stats
                      _buildQuickStats(),
                      const SizedBox(height: 16),

                      // Bar Chart Ranking
                      _buildRankingChart(),
                      const SizedBox(height: 16),

                      // Ranking List
                      _buildRankingList(),
                      const SizedBox(height: 16),

                      // Detail Table (Collapsible)
                      _buildDetailTable(),
                      const SizedBox(height: 16),

                      // Progressive Disclosure: Detail Perhitungan
                      _buildDetailToggle(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Belum ada data untuk dihitung',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan sudah mengisi data vendor, kriteria, dan penilaian',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== WINNER CARD ====================
  Widget _buildWinnerCard() {
    if (_hasilList.isEmpty) return const SizedBox();

    final winner = _hasilList.first;
    final runnerUp = _hasilList.length > 1 ? _hasilList[1] : null;
    final margin = runnerUp != null
        ? (winner.nilaiPreferensi - runnerUp.nilaiPreferensi)
        : winner.nilaiPreferensi;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Trophy Icon with Pulse Effect
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'REKOMENDASI TERBAIK',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),

          // Vendor Name
          Text(
            winner.vendorName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Score & Margin
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skor: ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFFFFA000),
                      ),
                    ),
                    Text(
                      winner.nilaiPreferensi.toStringAsFixed(4),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFA000),
                      ),
                    ),
                  ],
                ),
              ),
              if (runnerUp != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(width: 4),
                      Text(
                        '+${margin.toStringAsFixed(4)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==================== QUICK STATS ====================
  Widget _buildQuickStats() {
    if (_hasilList.isEmpty) return const SizedBox();

    final avgScore = _hasilList.fold<double>(0, (sum, h) => sum + h.nilaiPreferensi) /
        _hasilList.length;
    final spread = _hasilList.first.nilaiPreferensi - _hasilList.last.nilaiPreferensi;

    return Row(
      children: [
        _buildStatCard(
          Icons.business,
          'Total Vendor',
          '${_hasilList.length}',
          AppColors.primary,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          Icons.analytics,
          'Rata-rata Skor',
          avgScore.toStringAsFixed(3),
          AppColors.accent,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          Icons.compare_arrows,
          'Selisih Max-Min',
          spread.toStringAsFixed(3),
          spread > 0.1 ? AppColors.success : AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== RANKING CHART ====================
  Widget _buildRankingChart() {
    if (_hasilList.isEmpty) return const SizedBox();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Perbandingan Skor Vendor',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final hasil = _hasilList[group.x];
                        return BarTooltipItem(
                          '${hasil.vendorName.split(' ').first}\n',
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: 'Skor: ${rod.toY.toStringAsFixed(4)}\n',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            TextSpan(
                              text: 'Rank: #${hasil.ranking}',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  barGroups: _hasilList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final hasil = entry.value;
                    final isWinner = index == 0;
                    final isTop3 = index < 3;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: hasil.nilaiPreferensi,
                          gradient: LinearGradient(
                            colors: isWinner
                                ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
                                : isTop3
                                    ? [AppColors.primary, AppColors.primaryDark]
                                    : [Colors.grey.shade400, Colors.grey.shade500],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: MediaQuery.of(context).size.width / (_hasilList.length + 2),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 1,
                            color: Colors.grey.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < _hasilList.length) {
                            final name = _hasilList[index].vendorName;
                            final shortName = name.length > 12 ? name.substring(0, 12) : name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                shortName,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: GoogleFonts.poppins(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.15),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== RANKING LIST ====================
  Widget _buildRankingList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.leaderboard, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ranking Vendor',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._hasilList.asMap().entries.map((entry) {
              final index = entry.key;
              final hasil = entry.value;
              return _buildRankingItem(hasil, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(HasilTopsis hasil, int index) {
    final isWinner = index == 0;
    final isTop3 = index < 3;

    Color rankColor;
    String medalEmoji;

    switch (hasil.ranking) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        medalEmoji = '🥇';
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        medalEmoji = '🥈';
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        medalEmoji = '🥉';
        break;
      default:
        rankColor = AppColors.textSecondary;
        medalEmoji = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner
            ? const Color(0xFFFFD700).withValues(alpha: 0.06)
            : isTop3
                ? rankColor.withValues(alpha: 0.04)
                : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFFFD700)
              : isTop3
                  ? rankColor.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.15),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Medal/Rank
          SizedBox(
            width: 40,
            child: isTop3
                ? Text(
                    medalEmoji,
                    style: const TextStyle(fontSize: 28),
                    textAlign: TextAlign.center,
                  )
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${hasil.ranking}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Vendor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasil.vendorName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isWinner ? FontWeight.w700 : FontWeight.w600,
                    color: isWinner ? const Color(0xFFFFA000) : null,
                  ),
                ),
                const SizedBox(height: 6),
                // Progress Bar with Score
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: hasil.nilaiPreferensi,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isWinner ? const Color(0xFFFFD700) : AppColors.primary,
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hasil.nilaiPreferensi.toStringAsFixed(4),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isWinner ? const Color(0xFFFFA000) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DETAIL TABLE (COLLAPSIBLE) ====================
  Widget _buildDetailTable() {
    if (_detail == null) return const SizedBox();

    return _CollapsibleDetailTable(
      detail: _detail!,
      kriteriaList: _kriteriaList,
    );
  }

  // ==================== PROGRESSIVE DISCLOSURE ====================
  Widget _buildDetailToggle() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showDetail = !_showDetail;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showDetail
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calculate,
                      color: _showDetail ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Perhitungan TOPSIS',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _showDetail ? AppColors.primary : null,
                          ),
                        ),
                        Text(
                          'Matriks keputusan, normalisasi, solusi ideal, dan jarak',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showDetail ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _showDetail
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: _showDetail ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Detail Content (Progressive Disclosure)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetailContent(),
            crossFadeState:
                _showDetail ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_detail == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // Step 1: Matriks Keputusan
          _buildCollapsibleSection(
            'Langkah 1: Matriks Keputusan (X)',
            Icons.table_chart,
            _buildMatrixTable(
              _detail!.kriteriaNames.map((n) => n.split(' ').first).toList(),
              _detail!.vendorNames,
              _detail!.matriksKeputusan,
            ),
          ),
          const SizedBox(height: 10),

          // Step 2: Normalisasi
          _buildCollapsibleSection(
            'Langkah 2: Matriks Normalisasi (R)',
            Icons.grid_view,
            _buildMatrixTable(
              _detail!.kriteriaNames.map((n) => n.split(' ').first).toList(),
              _detail!.vendorNames,
              _detail!.matriksNormal,
            ),
          ),
          const SizedBox(height: 10),

          // Step 3: Terbobot
          _buildCollapsibleSection(
            'Langkah 3: Matriks Terbobot (Y)',
            Icons.grid_on,
            _buildMatrixTable(
              _detail!.kriteriaNames.map((n) => n.split(' ').first).toList(),
              _detail!.vendorNames,
              _detail!.matriksTerbobot,
            ),
          ),
          const SizedBox(height: 10),

          // Step 4: Solusi Ideal
          _buildCollapsibleSection(
            'Langkah 4: Solusi Ideal (A+ dan A-)',
            Icons.star,
            Column(
              children: [
                _buildIdealRow('A+ (Ideal Positif)', _detail!.solusiIdealPlus, AppColors.success),
                const SizedBox(height: 8),
                _buildIdealRow('A- (Ideal Negatif)', _detail!.solusiIdealMinus, AppColors.error),
                const SizedBox(height: 8),
                _buildInfoBox(
                  'C3 (TCO) bersifat Cost: A+ = nilai minimum, A- = nilai maksimum',
                  AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Step 5: Jarak Ideal
          _buildCollapsibleSection(
            'Langkah 5: Jarak ke Solusi Ideal',
            Icons.straighten,
            Column(
              children: [
                _buildIdealRow('D+ (Jarak ke Positif)', _detail!.jarakIdealPlus, AppColors.warning),
                const SizedBox(height: 8),
                _buildIdealRow('D- (Jarak ke Negatif)', _detail!.jarakIdealMinus, AppColors.primary),
                const SizedBox(height: 8),
                _buildInfoBox(
                  'V = D- / (D+ + D-). Semakin mendekati 1, semakin baik.',
                  AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection(String title, IconData icon, Widget content) {
    return _CollapsibleSection(title: title, icon: icon, content: content);
  }

  Widget _buildMatrixTable(
    List<String> colHeaders,
    List<String> rowHeaders,
    List<List<double>> matrix,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DataTable(
          columnSpacing: 12,
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
          columns: [
            const DataColumn(label: Text('')),
            ...colHeaders.map((h) => DataColumn(
                  label: Text(
                    h,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )),
          ],
          rows: List.generate(matrix.length, (i) {
            final isWinnerRow = i == 0;
            return DataRow(
              color: isWinnerRow
                  ? WidgetStateProperty.all(const Color(0xFFFFD700).withValues(alpha: 0.06))
                  : null,
              cells: [
                DataCell(
                  Text(
                    rowHeaders[i].length > 18 ? rowHeaders[i].substring(0, 18) : rowHeaders[i],
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...matrix[i].map((val) => DataCell(
                      Text(
                        val == val.roundToDouble()
                            ? val.toInt().toString()
                            : val.toStringAsFixed(3),
                        style: GoogleFonts.poppins(fontSize: 9),
                      ),
                    )),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildIdealRow(String label, List<double> values, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              values.map((v) => v.toStringAsFixed(4)).join(', '),
              style: GoogleFonts.poppins(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== COLLAPSIBLE SECTION WIDGET ====================
class _CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget content;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: _isExpanded ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isExpanded ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: widget.content,
            ),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ==================== COLLAPSIBLE DETAIL TABLE ====================
class _CollapsibleDetailTable extends StatefulWidget {
  final DetailTopsis detail;
  final List<Kriteria> kriteriaList;

  const _CollapsibleDetailTable({
    required this.detail,
    required this.kriteriaList,
  });

  @override
  State<_CollapsibleDetailTable> createState() => _CollapsibleDetailTableState();
}

class _CollapsibleDetailTableState extends State<_CollapsibleDetailTable> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isExpanded
                          ? AppColors.accent.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.table_chart,
                      color: _isExpanded ? AppColors.accent : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tabel Detail Lengkap',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isExpanded ? AppColors.accent : null,
                          ),
                        ),
                        Text(
                          'Matriks keputusan, normalisasi, terbobot, dan preferensi',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: _isExpanded ? AppColors.accent : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildTableContent(),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent() {
    final detail = widget.detail;
    final kriteriaShortNames = detail.kriteriaNames.map((n) => n.split(' ').first).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DataTable(
                columnSpacing: 10,
                headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
                columns: [
                  const DataColumn(label: Text('Vendor')),
                  ...kriteriaShortNames.map((h) => DataColumn(
                        label: Text(h, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600)),
                      )),
                  DataColumn(label: Text('D+', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('D-', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('V', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Rank', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600))),
                ],
                rows: List.generate(detail.matriksKeputusan.length, (i) {
                  final isWinner = i == 0;
                  return DataRow(
                    color: isWinner
                        ? WidgetStateProperty.all(const Color(0xFFFFD700).withValues(alpha: 0.06))
                        : null,
                    cells: [
                      DataCell(
                        Text(
                          detail.vendorNames[i].length > 15
                              ? detail.vendorNames[i].substring(0, 15)
                              : detail.vendorNames[i],
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      ...detail.matriksKeputusan[i].map((val) => DataCell(
                            Text(val.toInt().toString(), style: GoogleFonts.poppins(fontSize: 9)),
                          )),
                      DataCell(
                        Text(
                          detail.jarakIdealPlus[i].toStringAsFixed(3),
                          style: GoogleFonts.poppins(fontSize: 9, color: AppColors.warning),
                        ),
                      ),
                      DataCell(
                        Text(
                          detail.jarakIdealMinus[i].toStringAsFixed(3),
                          style: GoogleFonts.poppins(fontSize: 9, color: AppColors.primary),
                        ),
                      ),
                      DataCell(
                        Text(
                          detail.nilaiPreferensi.isNotEmpty
                              ? detail.nilaiPreferensi[i].toStringAsFixed(4)
                              : '-',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isWinner ? const Color(0xFFFFA000) : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isWinner
                                ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${i + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isWinner ? const Color(0xFFFFA000) : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
