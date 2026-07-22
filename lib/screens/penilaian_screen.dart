import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../models/vendor.dart';
import '../models/kriteria.dart';
import '../models/penilaian.dart';
import '../services/firebase_service.dart';

class PenilaianScreen extends StatefulWidget {
  const PenilaianScreen({super.key});

  @override
  State<PenilaianScreen> createState() => _PenilaianScreenState();
}

class _PenilaianScreenState extends State<PenilaianScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _nilaiController = TextEditingController();

  Vendor? _selectedVendor;
  Kriteria? _selectedKriteria;

  @override
  void dispose() {
    _nilaiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.penilaian,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.tambah, style: GoogleFonts.poppins()),
      ),
      body: StreamBuilder<List<Penilaian>>(
        stream: _firebaseService.getPenilaian(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final penilaianList = snapshot.data ?? [];

          if (penilaianList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.kosong,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: penilaianList.length,
            itemBuilder: (context, index) {
              final penilaian = penilaianList[index];
              return _buildPenilaianCard(penilaian);
            },
          );
        },
      ),
    );
  }

  Widget _buildPenilaianCard(Penilaian penilaian) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rate_review, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    penilaian.vendorName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    penilaian.kriteriaName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                penilaian.nilai.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showDeleteConfirmation(penilaian),
              icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    _selectedVendor = null;
    _selectedKriteria = null;
    _nilaiController.clear();

    showDialog(
      context: context,
      builder: (context) => _buildFormDialog(
        title: '${AppStrings.tambah} ${AppStrings.penilaian}',
        onSave: () async {
          if (_formKey.currentState!.validate() &&
              _selectedVendor != null &&
              _selectedKriteria != null) {
            final penilaian = Penilaian(
              id: '',
              vendorId: _selectedVendor!.id,
              vendorName: _selectedVendor!.nama,
              kriteriaId: _selectedKriteria!.id,
              kriteriaName: _selectedKriteria!.nama,
              nilai: double.parse(_nilaiController.text),
              createdAt: DateTime.now(),
            );
            await _firebaseService.addPenilaian(penilaian);
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildFormDialog({
    required String title,
    required VoidCallback onSave,
  }) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<List<Vendor>>(
                    stream: _firebaseService.getVendors(),
                    builder: (context, snapshot) {
                      final vendors = snapshot.data ?? [];
                      return DropdownButtonFormField<Vendor>(
                        initialValue: _selectedVendor,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.pilihVendor,
                          border: const OutlineInputBorder(),
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        items: vendors.map((vendor) {
                          return DropdownMenuItem(
                            value: vendor,
                            child: Text(vendor.nama, style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedVendor = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Pilih vendor terlebih dahulu';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Kriteria>>(
                    stream: _firebaseService.getKriteria(),
                    builder: (context, snapshot) {
                      final kriteriaList = snapshot.data ?? [];
                      return DropdownButtonFormField<Kriteria>(
                        initialValue: _selectedKriteria,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.pilihKriteria,
                          border: const OutlineInputBorder(),
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        items: kriteriaList.map((kriteria) {
                          return DropdownMenuItem(
                            value: kriteria,
                            child: Text(kriteria.nama, style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedKriteria = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Pilih kriteria terlebih dahulu';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nilaiController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${AppStrings.nilai} (1-10)',
                      border: const OutlineInputBorder(),
                      labelStyle: GoogleFonts.poppins(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nilai harus diisi';
                      }
                      final nilai = double.tryParse(value);
                      if (nilai == null || nilai < 1 || nilai > 10) {
                        return 'Nilai harus antara 1-10';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.batal, style: GoogleFonts.poppins()),
            ),
            FilledButton(
              onPressed: onSave,
              child: Text(AppStrings.simpan, style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Penilaian penilaian) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.konfirmasi, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Hapus penilaian ini?',
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
              await _firebaseService.deletePenilaian(penilaian.id);
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: Text(AppStrings.ya, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
