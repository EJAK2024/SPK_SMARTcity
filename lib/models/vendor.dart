import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id;
  final String nama;
  final String alamat;
  final String telepon;
  final String email;
  final String kode;
  final String fokus;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.telepon,
    required this.email,
    required this.kode,
    required this.fokus,
    required this.createdAt,
  });

  factory Vendor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vendor(
      id: doc.id,
      nama: data['nama'] ?? '',
      alamat: data['alamat'] ?? '',
      telepon: data['telepon'] ?? '',
      email: data['email'] ?? '',
      kode: data['kode'] ?? '',
      fokus: data['fokus'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'alamat': alamat,
      'telepon': telepon,
      'email': email,
      'kode': kode,
      'fokus': fokus,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
