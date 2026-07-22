import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../models/vendor.dart';
import '../services/firebase_service.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _teleponController = TextEditingController();
  final _emailController = TextEditingController();
  final _fokusController = TextEditingController();

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _fokusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.vendor,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.tambah, style: GoogleFonts.poppins()),
      ),
      body: StreamBuilder<List<Vendor>>(
        stream: _firebaseService.getVendors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final vendors = snapshot.data ?? [];

          if (vendors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
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
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return _buildVendorCard(vendor);
            },
          );
        },
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vendor.kode,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (vendor.fokus.isNotEmpty)
                        Text(
                          vendor.fokus,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20, color: AppColors.primary),
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
                      _showEditDialog(vendor);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(vendor);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, vendor.alamat),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, vendor.telepon),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, vendor.email),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    _kodeController.clear();
    _namaController.clear();
    _alamatController.clear();
    _teleponController.clear();
    _emailController.clear();
    _fokusController.clear();

    showDialog(
      context: context,
      builder: (context) => _buildFormDialog(
        title: '${AppStrings.tambah} ${AppStrings.vendor}',
        onSave: () async {
          if (_formKey.currentState!.validate()) {
            final vendor = Vendor(
              id: '',
              kode: _kodeController.text,
              nama: _namaController.text,
              alamat: _alamatController.text,
              telepon: _teleponController.text,
              email: _emailController.text,
              fokus: _fokusController.text,
              createdAt: DateTime.now(),
            );
            await _firebaseService.addVendor(vendor);
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showEditDialog(Vendor vendor) {
    _kodeController.text = vendor.kode;
    _namaController.text = vendor.nama;
    _alamatController.text = vendor.alamat;
    _teleponController.text = vendor.telepon;
    _emailController.text = vendor.email;
    _fokusController.text = vendor.fokus;

    showDialog(
      context: context,
      builder: (context) => _buildFormDialog(
        title: '${AppStrings.edit} ${AppStrings.vendor}',
        onSave: () async {
          if (_formKey.currentState!.validate()) {
            final updatedVendor = Vendor(
              id: vendor.id,
              kode: _kodeController.text,
              nama: _namaController.text,
              alamat: _alamatController.text,
              telepon: _teleponController.text,
              email: _emailController.text,
              fokus: _fokusController.text,
              createdAt: vendor.createdAt,
            );
            await _firebaseService.updateVendor(updatedVendor);
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
    return AlertDialog(
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _kodeController,
                decoration: InputDecoration(
                  labelText: 'Kode (A1, A2, dst)',
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kode harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: AppStrings.namaVendor,
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama vendor harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fokusController,
                decoration: InputDecoration(
                  labelText: 'Fokus Solusi',
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alamatController,
                decoration: InputDecoration(
                  labelText: AppStrings.alamat,
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _teleponController,
                decoration: InputDecoration(
                  labelText: AppStrings.telepon,
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telepon harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppStrings.email,
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email harus diisi';
                  }
                  if (!value.contains('@')) {
                    return 'Email tidak valid';
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
  }

  void _showDeleteConfirmation(Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.konfirmasi, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Hapus vendor "${vendor.nama}"?',
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
              await _firebaseService.deleteVendor(vendor.id);
              await _firebaseService.deletePenilaianByVendor(vendor.id);
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
