import 'dart:math';
import '../models/vendor.dart';
import '../models/kriteria.dart';
import '../models/penilaian.dart';
import '../models/hasil_topsis.dart';
import '../models/detail_topsis.dart';

class TopsisService {
  static DetailTopsis? _lastDetail;

  static DetailTopsis? get lastDetail => _lastDetail;

  static List<HasilTopsis> hitung({
    required List<Vendor> vendors,
    required List<Kriteria> kriteriaList,
    required List<Penilaian> penilaianList,
  }) {
    if (vendors.isEmpty || kriteriaList.isEmpty || penilaianList.isEmpty) {
      _lastDetail = null;
      return [];
    }

    final matriks = _bangunMatriksKeputusan(vendors, kriteriaList, penilaianList);
    final matriksNormal = _normalisasiMatriks(matriks, kriteriaList);
    final matriksTerbobot = _kalikanBobot(matriksNormal, kriteriaList);
    final solusiIdeal = _tentukanSolusiIdeal(matriksTerbobot, kriteriaList);
    final jarakIdeal = _hitungJarakIdeal(matriksTerbobot, solusiIdeal);

    _lastDetail = DetailTopsis(
      vendorNames: vendors.map((v) => '${v.kode} ${v.nama}').toList(),
      kriteriaNames: kriteriaList.map((k) => '${k.kode} ${k.nama}').toList(),
      matriksKeputusan: matriks,
      matriksNormal: matriksNormal,
      matriksTerbobot: matriksTerbobot,
      bobot: kriteriaList.map((k) => k.bobot).toList(),
      isBenefit: kriteriaList.map((k) => k.isBenefit).toList(),
      solusiIdealPlus: solusiIdeal['aPlus']!,
      solusiIdealMinus: solusiIdeal['aMinus']!,
      jarakIdealPlus: jarakIdeal['dPlus']!,
      jarakIdealMinus: jarakIdeal['dMinus']!,
      nilaiPreferensi: [],
    );

    return _hitungPreferensi(vendors, jarakIdeal);
  }

  static List<List<double>> _bangunMatriksKeputusan(
    List<Vendor> vendors,
    List<Kriteria> kriteriaList,
    List<Penilaian> penilaianList,
  ) {
    final matriks = List.generate(
      vendors.length,
      (i) => List<double>.filled(kriteriaList.length, 0),
    );

    for (final penilaian in penilaianList) {
      final vendorIndex = vendors.indexWhere((v) => v.id == penilaian.vendorId);
      final kriteriaIndex = kriteriaList.indexWhere((k) => k.id == penilaian.kriteriaId);

      if (vendorIndex != -1 && kriteriaIndex != -1) {
        matriks[vendorIndex][kriteriaIndex] = penilaian.nilai;
      }
    }

    return matriks;
  }

  static List<List<double>> _normalisasiMatriks(
    List<List<double>> matriks,
    List<Kriteria> kriteriaList,
  ) {
    final jumlahKuadrat = List<double>.filled(kriteriaList.length, 0);

    for (int j = 0; j < kriteriaList.length; j++) {
      for (int i = 0; i < matriks.length; i++) {
        jumlahKuadrat[j] += matriks[i][j] * matriks[i][j];
      }
      jumlahKuadrat[j] = sqrt(jumlahKuadrat[j]);
    }

    final matriksNormal = List.generate(
      matriks.length,
      (i) => List<double>.filled(kriteriaList.length, 0),
    );

    for (int i = 0; i < matriks.length; i++) {
      for (int j = 0; j < kriteriaList.length; j++) {
        if (jumlahKuadrat[j] != 0) {
          matriksNormal[i][j] = matriks[i][j] / jumlahKuadrat[j];
        }
      }
    }

    return matriksNormal;
  }

  static List<List<double>> _kalikanBobot(
    List<List<double>> matriksNormal,
    List<Kriteria> kriteriaList,
  ) {
    return List.generate(
      matriksNormal.length,
      (i) => List.generate(
        kriteriaList.length,
        (j) => matriksNormal[i][j] * kriteriaList[j].bobot,
      ),
    );
  }

  static Map<String, List<double>> _tentukanSolusiIdeal(
    List<List<double>> matriksTerbobot,
    List<Kriteria> kriteriaList,
  ) {
    final aPlus = List<double>.filled(kriteriaList.length, 0);
    final aMinus = List<double>.filled(kriteriaList.length, 0);

    for (int j = 0; j < kriteriaList.length; j++) {
      double maxVal = matriksTerbobot[0][j];
      double minVal = matriksTerbobot[0][j];

      for (int i = 1; i < matriksTerbobot.length; i++) {
        if (matriksTerbobot[i][j] > maxVal) {
          maxVal = matriksTerbobot[i][j];
        }
        if (matriksTerbobot[i][j] < minVal) {
          minVal = matriksTerbobot[i][j];
        }
      }

      if (kriteriaList[j].isBenefit) {
        aPlus[j] = maxVal;
        aMinus[j] = minVal;
      } else {
        aPlus[j] = minVal;
        aMinus[j] = maxVal;
      }
    }

    return {'aPlus': aPlus, 'aMinus': aMinus};
  }

  static Map<String, List<double>> _hitungJarakIdeal(
    List<List<double>> matriksTerbobot,
    Map<String, List<double>> solusiIdeal,
  ) {
    final aPlus = solusiIdeal['aPlus']!;
    final aMinus = solusiIdeal['aMinus']!;

    final dPlus = List<double>.filled(matriksTerbobot.length, 0);
    final dMinus = List<double>.filled(matriksTerbobot.length, 0);

    for (int i = 0; i < matriksTerbobot.length; i++) {
      double sumDPlus = 0;
      double sumDMinus = 0;

      for (int j = 0; j < matriksTerbobot[i].length; j++) {
        sumDPlus += pow(matriksTerbobot[i][j] - aPlus[j], 2);
        sumDMinus += pow(matriksTerbobot[i][j] - aMinus[j], 2);
      }

      dPlus[i] = sqrt(sumDPlus);
      dMinus[i] = sqrt(sumDMinus);
    }

    return {'dPlus': dPlus, 'dMinus': dMinus};
  }

  static List<HasilTopsis> _hitungPreferensi(
    List<Vendor> vendors,
    Map<String, List<double>> jarakIdeal,
  ) {
    final dPlus = jarakIdeal['dPlus']!;
    final dMinus = jarakIdeal['dMinus']!;

    final hasil = <HasilTopsis>[];

    for (int i = 0; i < vendors.length; i++) {
      double nilaiPreferensi = 0;
      final totalJarak = dPlus[i] + dMinus[i];

      if (totalJarak != 0) {
        nilaiPreferensi = dMinus[i] / totalJarak;
      }

      hasil.add(HasilTopsis(
        vendorId: vendors[i].id,
        vendorName: vendors[i].nama,
        nilaiPreferensi: nilaiPreferensi,
        ranking: 0,
      ));
    }

    hasil.sort((a, b) => b.nilaiPreferensi.compareTo(a.nilaiPreferensi));

    for (int i = 0; i < hasil.length; i++) {
      hasil[i] = HasilTopsis(
        vendorId: hasil[i].vendorId,
        vendorName: hasil[i].vendorName,
        nilaiPreferensi: hasil[i].nilaiPreferensi,
        ranking: i + 1,
      );
    }

    return hasil;
  }
}
