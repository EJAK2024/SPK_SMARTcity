import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../models/vendor.dart';
import '../models/kriteria.dart';
import '../models/penilaian.dart';
import '../services/firebase_service.dart';
import 'hasil_screen.dart';

class PenilaianWizardScreen extends StatefulWidget {
  const PenilaianWizardScreen({super.key});

  @override
  State<PenilaianWizardScreen> createState() => _PenilaianWizardScreenState();
}

class _PenilaianWizardScreenState extends State<PenilaianWizardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  List<Vendor> _allVendors = [];
  final List<Vendor> _selectedVendors = [];
  List<Kriteria> _kriteriaList = [];
  final Map<String, Map<String, double>> _allScores = {};
  final Map<String, double> _weights = {};
  bool _isLoading = true;
  bool _isSaving = false;

  int _currentVendorIndex = 0;

  final Map<String, Map<String, double>> _templates = {
    'Smart City Standar': {
      'C1': 0.20, 'C2': 0.20, 'C3': 0.15,
      'C4': 0.15, 'C5': 0.15, 'C6': 0.10, 'C7': 0.05,
    },
    'Prioritas Keamanan': {
      'C1': 0.15, 'C2': 0.30, 'C3': 0.10,
      'C4': 0.10, 'C5': 0.15, 'C6': 0.10, 'C7': 0.10,
    },
    'Prioritas Biaya': {
      'C1': 0.10, 'C2': 0.10, 'C3': 0.30,
      'C4': 0.10, 'C5': 0.10, 'C6': 0.15, 'C7': 0.15,
    },
    'Prioritas Pengalaman': {
      'C1': 0.15, 'C2': 0.15, 'C3': 0.10,
      'C4': 0.25, 'C5': 0.15, 'C6': 0.10, 'C7': 0.10,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _firebaseService.getVendors().listen((vendors) {
      setState(() {
        _allVendors = vendors;
        _isLoading = false;
      });
    });

    _firebaseService.getKriteria().listen((kriteriaList) {
      setState(() {
        _kriteriaList = kriteriaList;
        for (final k in kriteriaList) {
          if (!_weights.containsKey(k.id)) {
            _weights[k.id] = k.bobot;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleVendor(Vendor vendor) {
    setState(() {
      if (_selectedVendors.any((v) => v.id == vendor.id)) {
        _selectedVendors.removeWhere((v) => v.id == vendor.id);
        _allScores.remove(vendor.id);
      } else {
        _selectedVendors.add(vendor);
        _initScoresForVendor(vendor.id);
      }
      if (_currentVendorIndex >= _selectedVendors.length) {
        _currentVendorIndex = (_selectedVendors.length - 1).clamp(0, _selectedVendors.length - 1);
      }
    });
  }

  void _selectAllVendors() {
    setState(() {
      if (_selectedVendors.length == _allVendors.length) {
        _selectedVendors.clear();
        _allScores.clear();
      } else {
        _selectedVendors.clear();
        _selectedVendors.addAll(_allVendors);
        for (final v in _allVendors) {
          _initScoresForVendor(v.id);
        }
      }
      _currentVendorIndex = 0;
    });
  }

  void _initScoresForVendor(String vendorId) {
    if (!_allScores.containsKey(vendorId)) {
      _allScores[vendorId] = {};
    }
    for (final k in _kriteriaList) {
      if (!_allScores[vendorId]!.containsKey(k.id)) {
        _allScores[vendorId]![k.id] = 3.0;
      }
    }
  }

  void _applyTemplate(String templateName) {
    final template = _templates[templateName];
    if (template == null) return;

    setState(() {
      for (final k in _kriteriaList) {
        if (template.containsKey(k.kode)) {
          _weights[k.id] = template[k.kode]!;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "$templateName" diterapkan!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _autoNormalizeWeights() {
    final totalWeight = _calculateTotalWeight();
    if (totalWeight == 0) return;

    setState(() {
      for (final k in _kriteriaList) {
        final current = _weights[k.id] ?? k.bobot;
        _weights[k.id] = current / totalWeight;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bobot sudah dinormalisasi ke total 1.0'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveScores() async {
    if (_selectedVendors.isEmpty || _kriteriaList.isEmpty) return;

    setState(() => _isSaving = true);

    for (final vendor in _selectedVendors) {
      await _firebaseService.deletePenilaianByVendor(vendor.id);

      final vendorScores = _allScores[vendor.id];
      if (vendorScores == null) continue;

      for (final kriteria in _kriteriaList) {
        final nilai = vendorScores[kriteria.id] ?? 3.0;
        final penilaian = Penilaian(
          id: '',
          vendorId: vendor.id,
          vendorName: vendor.nama,
          kriteriaId: kriteria.id,
          kriteriaName: kriteria.nama,
          nilai: nilai,
          createdAt: DateTime.now(),
        );
        await _firebaseService.addPenilaian(penilaian);
      }
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menyimpan penilaian ${_selectedVendors.length} vendor!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HasilScreen()),
      );
    }
  }

  double _calculateTotalWeight() {
    double total = 0;
    for (final k in _kriteriaList) {
      total += _weights[k.id] ?? k.bobot;
    }
    return total;
  }

  Vendor? get _activeVendor =>
      _selectedVendors.isNotEmpty ? _selectedVendors[_currentVendorIndex] : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Wizard Penilaian TOPSIS',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                      _buildStep4(),
                    ],
                  ),
                ),
                _buildBottomButtons(),
              ],
            ),
    );
  }

  // ==================== STEP INDICATOR ====================
  Widget _buildStepIndicator() {
    final steps = [
      {'icon': Icons.business, 'label': 'Vendor'},
      {'icon': Icons.star, 'label': 'Skor'},
      {'icon': Icons.tune, 'label': 'Bobot'},
      {'icon': Icons.check_circle, 'label': 'Selesai'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success
                              : isActive
                                  ? AppColors.warning
                                  : Colors.grey.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.warning.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : Icon(step['icon'] as IconData,
                                  size: 18,
                                  color: isActive ? Colors.white : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? AppColors.warning
                              : isCompleted
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 24,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: isCompleted ? AppColors.success : Colors.grey.withValues(alpha: 0.2),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ==================== STEP 1: PILIH VENDOR ====================
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Langkah 1 dari 4',
            'Pilih Vendor',
            'Pilih semua vendor yang akan dinilai sekaligus',
            Icons.business,
            AppColors.primary,
          ),
          const SizedBox(height: 12),

          // Select All Button
          if (_allVendors.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: _selectAllVendors,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _selectedVendors.length == _allVendors.length
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pilih Semua Vendor (${_allVendors.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_selectedVendors.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_selectedVendors.length} dipilih',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),

          if (_allVendors.isEmpty)
            _buildEmptyVendor()
          else
            ..._allVendors.map((vendor) => _buildVendorOption(vendor)),

          if (_selectedVendors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedVendors.length} vendor dipilih. Anda akan memberi skor untuk semua vendor di langkah berikutnya.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyVendor() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.business_center,
                  size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'Belum ada vendor',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tambahkan vendor terlebih dahulu di menu Vendor',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorOption(Vendor vendor) {
    final isSelected = _selectedVendors.any((v) => v.id == vendor.id);
    final hasScore = _allScores.containsKey(vendor.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.warning.withValues(alpha: 0.04) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.warning : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleVendor(vendor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.warning : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppColors.warning : Colors.grey.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    vendor.kode,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.warning : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.nama,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vendor.fokus,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasScore)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✓ Dinilai',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== STEP 2: STAR RATING ====================
  Widget _buildStep2() {
    if (_selectedVendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Pilih vendor terlebih dahulu',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final vendor = _selectedVendors[_currentVendorIndex];
    final vendorScores = _allScores[vendor.id] ?? {};

    return Column(
      children: [
        // Vendor Navigation Tabs
        if (_selectedVendors.length > 1)
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedVendors.length,
              itemBuilder: (context, index) {
                final v = _selectedVendors[index];
                final isActive = index == _currentVendorIndex;
                final isScored = _allScores.containsKey(v.id);

                return GestureDetector(
                  onTap: () {
                    setState(() => _currentVendorIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.warning
                          : AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.warning : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          v.kode,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : AppColors.warning,
                          ),
                        ),
                        if (isScored && !isActive) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Score Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  'Langkah 2 dari 4',
                  'Beri Skor',
                  '${_currentVendorIndex + 1}/${_selectedVendors.length} — ${vendor.nama}',
                  Icons.star,
                  AppColors.accent,
                ),
                const SizedBox(height: 12),

                // Vendor Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            vendor.kode,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.nama,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              vendor.fokus,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Star Rating Cards
                ..._kriteriaList.map((kriteria) {
                  final score = vendorScores[kriteria.id] ?? 3.0;
                  return _buildStarRatingCard(kriteria, score);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarRatingCard(Kriteria kriteria, double currentScore) {
    final isCost = !kriteria.isBenefit;
    final scoreInt = currentScore.toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    kriteria.kode,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kriteria.nama,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCost
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCost ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 10,
                        color: isCost ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isCost ? 'Cost' : 'Benefit',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isCost ? AppColors.warning : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              kriteria.deskripsi,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isFilled = starValue <= scoreInt;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      final vid = _activeVendor?.id;
                      if (vid != null) {
                        _allScores[vid] ??= {};
                        _allScores[vid]![kriteria.id] = starValue.toDouble();
                      }
                    });
                  },
                  child: AnimatedScale(
                    scale: isFilled ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 38,
                        color: isFilled
                            ? AppColors.warning
                            : Colors.grey.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),

            // Score Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1',
                    style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getScoreColor(scoreInt).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getScoreLabel(scoreInt),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(scoreInt),
                    ),
                  ),
                ),
                Text('5',
                    style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 1: return AppColors.error;
      case 2: return const Color(0xFFFF5722);
      case 3: return AppColors.warning;
      case 4: return const Color(0xFF8BC34A);
      case 5: return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  String _getScoreLabel(int score) {
    switch (score) {
      case 1: return '1 - Sangat Buruk';
      case 2: return '2 - Kurang';
      case 3: return '3 - Cukup';
      case 4: return '4 - Baik';
      case 5: return '5 - Sangat Baik';
      default: return '$score';
    }
  }

  // ==================== STEP 3: BOBOT + TEMPLATE ====================
  Widget _buildStep3() {
    final totalWeight = _calculateTotalWeight();
    final isWeightValid = (totalWeight - 1.0).abs() < 0.01;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Langkah 3 dari 4',
            'Atur Bobot Kriteria',
            'Pilih template atau atur bobot secara manual',
            Icons.tune,
            AppColors.primary,
          ),
          const SizedBox(height: 12),

          // Template Selection
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Template Bobot',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih template sesuai prioritas pengambilan keputusan',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _templates.entries.map((entry) {
                      return _buildTemplateChip(entry.key, entry.value);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Weight Total Indicator + Auto Normalize
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isWeightValid
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isWeightValid ? AppColors.success : AppColors.error,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isWeightValid ? Icons.check_circle : Icons.warning,
                        color: isWeightValid ? AppColors.success : AppColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Bobot',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            totalWeight.toStringAsFixed(2),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isWeightValid ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _autoNormalizeWeights,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.balance, size: 22, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text(
                        'Normalisasi',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weight Sliders
          ..._kriteriaList.map((kriteria) => _buildWeightCard(kriteria)),

          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _resetWeights,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Reset ke Default', style: GoogleFonts.poppins(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String name, Map<String, double> template) {
    return GestureDetector(
      onTap: () => _applyTemplate(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              template.entries.take(3).map((e) => '${e.key}:${(e.value * 100).toInt()}%').join(' · '),
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(Kriteria kriteria) {
    final weight = _weights[kriteria.id] ?? kriteria.bobot;
    final percentage = (weight * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    kriteria.kode,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kriteria.nama,
                    style: GoogleFonts.poppins(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$percentage%',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                thumbColor: AppColors.primary,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                  elevation: 4,
                ),
                overlayColor: AppColors.primary.withValues(alpha: 0.1),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                trackHeight: 6,
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: weight,
                min: 0.01,
                max: 0.50,
                divisions: 49,
                onChanged: (value) {
                  setState(() {
                    _weights[kriteria.id] = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetWeights() {
    setState(() {
      for (final k in _kriteriaList) {
        _weights[k.id] = k.bobot;
      }
    });
  }

  // ==================== STEP 4: RINGKASAN ====================
  Widget _buildStep4() {
    if (_selectedVendors.isEmpty) {
      return Center(
        child: Text(
          'Pilih vendor terlebih dahulu',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Langkah 4 dari 4',
            'Ringkasan',
            'Periksa semua data sebelum menyimpan',
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(height: 12),

          // Vendor Scores Summary
          ..._selectedVendors.map((vendor) => _buildVendorSummaryCard(vendor)),

          const SizedBox(height: 12),

          // Weight Summary
          _buildWeightSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildVendorSummaryCard(Vendor vendor) {
    final vendorScores = _allScores[vendor.id] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      vendor.kode,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.nama,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        vendor.fokus,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ..._kriteriaList.map((kriteria) {
              final score = vendorScores[kriteria.id] ?? 3.0;
              final scoreInt = score.toInt();
              final weight = _weights[kriteria.id] ?? kriteria.bobot;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      kriteria.kode,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        kriteria.nama,
                        style: GoogleFonts.poppins(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < scoreInt ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: index < scoreInt
                              ? AppColors.warning
                              : Colors.grey.withValues(alpha: 0.3),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(weight * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Bobot Kriteria',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_calculateTotalWeight() - 1.0).abs() < 0.01
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total: ${_calculateTotalWeight().toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: (_calculateTotalWeight() - 1.0).abs() < 0.01
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._kriteriaList.map((kriteria) {
              final weight = _weights[kriteria.id] ?? kriteria.bobot;
              final percentage = (weight * 100).toInt();

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      kriteria.kode,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: weight,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percentage%',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==================== COMMON WIDGETS ====================
  Widget _buildStepHeader(String step, String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final totalWeight = _calculateTotalWeight();
    final isWeightValid = (totalWeight - 1.0).abs() < 0.01;
    final canProceed = _currentStep == 0
        ? _selectedVendors.isNotEmpty
        : _currentStep == 1
            ? _selectedVendors.isNotEmpty
            : _currentStep == 2
                ? isWeightValid
                : true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('Kembali', style: GoogleFonts.poppins()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.warning),
                  foregroundColor: AppColors.warning,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 3 ? 1 : 1,
            child: _currentStep == 3
                ? FilledButton.icon(
                    onPressed: (_selectedVendors.isEmpty || _isSaving || !isWeightValid)
                        ? null
                        : _saveScores,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan & Lihat Hasil',
                      style: GoogleFonts.poppins(),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: canProceed ? _nextStep : null,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      _currentStep == 2 ? 'Lihat Ringkasan' : 'Lanjut',
                      style: GoogleFonts.poppins(),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
