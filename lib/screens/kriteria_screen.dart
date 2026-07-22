import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../models/kriteria.dart';
import '../services/firebase_service.dart';

class KriteriaScreen extends StatefulWidget {
  const KriteriaScreen({super.key});

  @override
  State<KriteriaScreen> createState() => _KriteriaScreenState();
}

class _KriteriaScreenState extends State<KriteriaScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _bobotController = TextEditingController();
  bool _isBenefit = true;

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _deskripsiController.dispose();
    _bobotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.kriteria,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.tambah, style: GoogleFonts.poppins()),
      ),
      body: StreamBuilder<List<Kriteria>>(
        stream: _firebaseService.getKriteria(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final kriteriaList = snapshot.data ?? [];

          if (kriteriaList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
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
            itemCount: kriteriaList.length,
            itemBuilder: (context, index) {
              final kriteria = kriteriaList[index];
              return _buildKriteriaCard(kriteria);
            },
          );
        },
      ),
    );
  }

  Widget _buildKriteriaCard(Kriteria kriteria) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kriteria.kode,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    kriteria.nama,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(AppStrings.edit, style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(AppStrings.hapus, style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(kriteria);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(kriteria);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              kriteria.deskripsi,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip('Bobot: ${kriteria.bobot.toStringAsFixed(2)}', AppColors.accent),
                const SizedBox(width: 8),
                _buildChip(
                  kriteria.isBenefit ? 'Benefit' : 'Cost',
                  kriteria.isBenefit ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showAddDialog() {
    _kodeController.clear();
    _namaController.clear();
    _deskripsiController.clear();
    _bobotController.clear();
    _isBenefit = true;
    _openFormDialog(isEdit: false);
  }

  void _showEditDialog(Kriteria kriteria) {
    _kodeController.text = kriteria.kode;
    _namaController.text = kriteria.nama;
    _deskripsiController.text = kriteria.deskripsi;
    _bobotController.text = kriteria.bobot.toString();
    _isBenefit = kriteria.isBenefit;
    _openFormDialog(isEdit: true, kriteria: kriteria);
  }

  void _openFormDialog({required bool isEdit, Kriteria? kriteria}) {
    final formKey = GlobalKey<FormState>();
    bool tempIsBenefit = _isBenefit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEdit ? '${AppStrings.edit} ${AppStrings.kriteria}' : '${AppStrings.tambah} ${AppStrings.kriteria}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kodeController,
                        decoration: InputDecoration(
                          labelText: 'Kode (C1, C2, dst)',
                          border: const OutlineInputBorder(),
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Kode harus diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: AppStrings.namaKriteria,
                          border: const OutlineInputBorder(),
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Nama kriteria harus diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deskripsiController,
                        decoration: InputDecoration(
                          labelText: AppStrings.deskripsi,
                          border: const OutlineInputBorder(),
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Deskripsi harus diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bobotController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${AppStrings.bobot} (0-1)',
                          border: const OutlineInputBorder(),
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Bobot harus diisi';
                          final bobot = double.tryParse(value);
                          if (bobot == null || bobot < 0 || bobot > 1) {
                            return 'Bobot harus antara 0-1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<bool>(
                        initialValue: tempIsBenefit,
                        decoration: InputDecoration(
                          labelText: AppStrings.isBenefit,
                          border: const OutlineInputBorder(),
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: true,
                            child: Text(AppStrings.benefit, style: GoogleFonts.poppins()),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text(AppStrings.cost, style: GoogleFonts.poppins()),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            tempIsBenefit = value ?? true;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(AppStrings.batal, style: GoogleFonts.poppins()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                final newKriteria = Kriteria(
                                  id: isEdit ? kriteria!.id : '',
                                  kode: _kodeController.text,
                                  nama: _namaController.text,
                                  deskripsi: _deskripsiController.text,
                                  bobot: double.parse(_bobotController.text),
                                  isBenefit: tempIsBenefit,
                                  createdAt: isEdit ? kriteria!.createdAt : DateTime.now(),
                                );

                                if (isEdit) {
                                  await _firebaseService.updateKriteria(newKriteria);
                                } else {
                                  await _firebaseService.addKriteria(newKriteria);
                                }

                                if (!mounted) return;
                                Navigator.pop(sheetContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit
                                          ? 'Kriteria "${newKriteria.nama}" berhasil diperbarui!'
                                          : 'Kriteria "${newKriteria.nama}" berhasil ditambahkan!',
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(AppStrings.simpan, style: GoogleFonts.poppins()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(Kriteria kriteria) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.konfirmasi, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Hapus kriteria "${kriteria.nama}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.tidak, style: GoogleFonts.poppins()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await _firebaseService.deleteKriteria(kriteria.id);
              await _firebaseService.deletePenilaianByKriteria(kriteria.id);
              if (!mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kriteria "${kriteria.nama}" berhasil dihapus!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text(AppStrings.ya, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
