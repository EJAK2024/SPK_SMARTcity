import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor.dart';
import '../models/kriteria.dart';
import '../models/penilaian.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== VENDOR ====================
  Stream<List<Vendor>> getVendors() {
    return _firestore.collection('vendors').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Vendor.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addVendor(Vendor vendor) async {
    await _firestore.collection('vendors').add(vendor.toFirestore());
  }

  Future<void> updateVendor(Vendor vendor) async {
    await _firestore.collection('vendors').doc(vendor.id).update(vendor.toFirestore());
  }

  Future<void> deleteVendor(String id) async {
    await _firestore.collection('vendors').doc(id).delete();
  }

  // ==================== KRITERIA ====================
  Stream<List<Kriteria>> getKriteria() {
    return _firestore.collection('kriteria').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Kriteria.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addKriteria(Kriteria kriteria) async {
    await _firestore.collection('kriteria').add(kriteria.toFirestore());
  }

  Future<void> updateKriteria(Kriteria kriteria) async {
    await _firestore.collection('kriteria').doc(kriteria.id).update(kriteria.toFirestore());
  }

  Future<void> deleteKriteria(String id) async {
    await _firestore.collection('kriteria').doc(id).delete();
  }

  // ==================== PENILAIAN ====================
  Stream<List<Penilaian>> getPenilaian() {
    return _firestore.collection('penilaian').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Penilaian.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addPenilaian(Penilaian penilaian) async {
    await _firestore.collection('penilaian').add(penilaian.toFirestore());
  }

  Future<void> updatePenilaian(Penilaian penilaian) async {
    await _firestore.collection('penilaian').doc(penilaian.id).update(penilaian.toFirestore());
  }

  Future<void> deletePenilaian(String id) async {
    await _firestore.collection('penilaian').doc(id).delete();
  }

  Future<void> deletePenilaianByVendor(String vendorId) async {
    final snapshot = await _firestore
        .collection('penilaian')
        .where('vendorId', isEqualTo: vendorId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deletePenilaianByKriteria(String kriteriaId) async {
    final snapshot = await _firestore
        .collection('penilaian')
        .where('kriteriaId', isEqualTo: kriteriaId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ==================== SEED DATA ====================
  Future<bool> isDataSeeded() async {
    final kriteriaSnapshot = await _firestore.collection('kriteria').limit(1).get();
    return kriteriaSnapshot.docs.isNotEmpty;
  }

  Future<void> seedAllData() async {
    await _seedKriteria();
    await _seedVendors();
    await _seedPenilaian();
  }

  Future<void> _seedKriteria() async {
    final kriteriaData = [
      {
        'kode': 'C1',
        'nama': 'Kemampuan Teknis & Interoperabilitas',
        'deskripsi': 'Dukungan open API, kompatibilitas sistem',
        'bobot': 0.20,
        'isBenefit': true,
      },
      {
        'kode': 'C2',
        'nama': 'Keamanan Siber',
        'deskripsi': 'Enkripsi, sertifikasi ISO 27001',
        'bobot': 0.20,
        'isBenefit': true,
      },
      {
        'kode': 'C3',
        'nama': 'Total Cost of Ownership (TCO)',
        'deskripsi': 'Biaya awal + operasional jangka panjang',
        'bobot': 0.15,
        'isBenefit': false,
      },
      {
        'kode': 'C4',
        'nama': 'Rekam Jejak & Pengalaman Proyek',
        'deskripsi': 'Jumlah proyek sejenis, referensi kota lain',
        'bobot': 0.15,
        'isBenefit': true,
      },
      {
        'kode': 'C5',
        'nama': 'Kualitas Layanan Purna Jual (SLA)',
        'deskripsi': 'Waktu respons, ketersediaan tim lokal',
        'bobot': 0.15,
        'isBenefit': true,
      },
      {
        'kode': 'C6',
        'nama': 'Skalabilitas & Fleksibilitas',
        'deskripsi': 'Kemudahan pengembangan/upgrade ke depan',
        'bobot': 0.10,
        'isBenefit': true,
      },
      {
        'kode': 'C7',
        'nama': 'Kepatuhan Regulasi',
        'deskripsi': 'Kesesuaian dengan UU PDP, standar pemerintah',
        'bobot': 0.05,
        'isBenefit': true,
      },
    ];

    for (final data in kriteriaData) {
      await _firestore.collection('kriteria').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _seedVendors() async {
    final vendorData = [
      {
        'nama': 'Huawei (Smart City Solution)',
        'alamat': 'Huawei Indonesia, Jakarta',
        'telepon': '+62 21 5785 3888',
        'email': 'smartcity@huawei.com',
        'kode': 'A1',
        'fokus': 'Command center, ICT, keamanan berbasis AI',
      },
      {
        'nama': 'Cisco (Smart+Connected Communities)',
        'alamat': 'Cisco Systems Indonesia, Jakarta',
        'telepon': '+62 21 576 0911',
        'email': 'smartconnected@cisco.com',
        'kode': 'A2',
        'fokus': 'Jaringan & konektivitas kota',
      },
      {
        'nama': 'Siemens (Smart Infrastructure)',
        'alamat': 'Siemens Indonesia, Jakarta',
        'telepon': '+62 21 2567 888',
        'email': 'smartinfrastructure@siemens.com',
        'kode': 'A3',
        'fokus': 'Energi, transportasi, bangunan pintar',
      },
      {
        'nama': 'Telkom Indonesia (Smart City Nusantara)',
        'alamat': 'Telkom Indonesia, Bandung',
        'telepon': '+62 22 4531 100',
        'email': 'smartcity@telkom.co.id',
        'kode': 'A4',
        'fokus': 'Platform command center & IoT lokal',
      },
      {
        'nama': 'NEC Corporation',
        'alamat': 'NEC Indonesia, Jakarta',
        'telepon': '+62 21 5795 6060',
        'email': 'smartcity@nec.co.id',
        'kode': 'A5',
        'fokus': 'Keamanan publik, analitik AI',
      },
      {
        'nama': 'IBM (Intelligent Operations Center)',
        'alamat': 'IBM Indonesia, Jakarta',
        'telepon': '+62 21 2552 888',
        'email': 'ioc@ibm.com',
        'kode': 'A6',
        'fokus': 'Data analytics & integrasi sistem',
      },
    ];

    for (final data in vendorData) {
      await _firestore.collection('vendors').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _seedPenilaian() async {
    // Ambil data vendor dan kriteria yang sudah di-seed
    final vendorSnapshot = await _firestore.collection('vendors').get();
    final kriteriaSnapshot = await _firestore.collection('kriteria').get();

    final vendorMap = <String, String>{}; // kode -> id
    for (final doc in vendorSnapshot.docs) {
      vendorMap[doc['kode']] = doc.id;
    }

    final kriteriaMap = <String, String>{}; // kode -> id
    for (final doc in kriteriaSnapshot.docs) {
      kriteriaMap[doc['kode']] = doc.id;
    }

    final vendorNames = <String, String>{}; // kode -> nama
    for (final doc in vendorSnapshot.docs) {
      vendorNames[doc['kode']] = doc['nama'];
    }

    final kriteriaNames = <String, String>{}; // kode -> nama
    for (final doc in kriteriaSnapshot.docs) {
      kriteriaNames[doc['kode']] = doc['nama'];
    }

    // Matriks Keputusan (skala 1-5):
    //         C1  C2  C3  C4  C5  C6  C7
    // A1:      4   5   3   4   4   3   5  (Huawei)
    // A2:      5   4   4   4   3   4   5  (Cisco)
    // A3:      3   4   2   5   5   4   4  (Siemens)
    // A4:      4   3   5   3   5   3   5  (Telkom)
    // A5:      3   5   4   4   4   4   4  (NEC)
    // A6:      5   5   3   3   3   3   5  (IBM)
    final matriks = {
      'A1': [4, 5, 3, 4, 4, 3, 5],
      'A2': [5, 4, 4, 4, 3, 4, 5],
      'A3': [3, 4, 2, 5, 5, 4, 4],
      'A4': [4, 3, 5, 3, 5, 3, 5],
      'A5': [3, 5, 4, 4, 4, 4, 4],
      'A6': [5, 5, 3, 3, 3, 3, 5],
    };

    final kodesKriteria = ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7'];

    for (final entry in matriks.entries) {
      final vendorKode = entry.key;
      final nilaiArray = entry.value;

      for (int i = 0; i < kodesKriteria.length; i++) {
        final kriteriaKode = kodesKriteria[i];
        final vendorId = vendorMap[vendorKode] ?? '';
        final kriteriaId = kriteriaMap[kriteriaKode] ?? '';

        if (vendorId.isNotEmpty && kriteriaId.isNotEmpty) {
          await _firestore.collection('penilaian').add({
            'vendorId': vendorId,
            'vendorName': vendorNames[vendorKode] ?? '',
            'kriteriaId': kriteriaId,
            'kriteriaName': kriteriaNames[kriteriaKode] ?? '',
            'nilai': nilaiArray[i].toDouble(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  Future<void> deleteAllData() async {
    await _deleteCollection('vendors');
    await _deleteCollection('kriteria');
    await _deleteCollection('penilaian');
  }

  Future<void> _deleteCollection(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
