import 'package:cloud_firestore/cloud_firestore.dart';

class Penilaian {
  final String id;
  final String vendorId;
  final String vendorName;
  final String kriteriaId;
  final String kriteriaName;
  final double nilai;
  final DateTime createdAt;

  Penilaian({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.kriteriaId,
    required this.kriteriaName,
    required this.nilai,
    required this.createdAt,
  });

  factory Penilaian.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Penilaian(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? '',
      kriteriaId: data['kriteriaId'] ?? '',
      kriteriaName: data['kriteriaName'] ?? '',
      nilai: (data['nilai'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'kriteriaId': kriteriaId,
      'kriteriaName': kriteriaName,
      'nilai': nilai,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
