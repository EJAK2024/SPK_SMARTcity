import 'package:cloud_firestore/cloud_firestore.dart';

class Kriteria {
  final String id;
  final String kode;
  final String nama;
  final String deskripsi;
  final double bobot;
  final bool isBenefit;
  final DateTime createdAt;

  Kriteria({
    required this.id,
    required this.kode,
    required this.nama,
    required this.deskripsi,
    required this.bobot,
    required this.isBenefit,
    required this.createdAt,
  });

  factory Kriteria.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Kriteria(
      id: doc.id,
      kode: data['kode'] ?? '',
      nama: data['nama'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      bobot: (data['bobot'] ?? 0).toDouble(),
      isBenefit: data['isBenefit'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kode': kode,
      'nama': nama,
      'deskripsi': deskripsi,
      'bobot': bobot,
      'isBenefit': isBenefit,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
