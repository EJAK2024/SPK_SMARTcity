class DetailTopsis {
  final List<String> vendorNames;
  final List<String> kriteriaNames;
  final List<List<double>> matriksKeputusan;
  final List<List<double>> matriksNormal;
  final List<List<double>> matriksTerbobot;
  final List<double> bobot;
  final List<bool> isBenefit;
  final List<double> solusiIdealPlus;
  final List<double> solusiIdealMinus;
  final List<double> jarakIdealPlus;
  final List<double> jarakIdealMinus;
  final List<double> nilaiPreferensi;

  DetailTopsis({
    required this.vendorNames,
    required this.kriteriaNames,
    required this.matriksKeputusan,
    required this.matriksNormal,
    required this.matriksTerbobot,
    required this.bobot,
    required this.isBenefit,
    required this.solusiIdealPlus,
    required this.solusiIdealMinus,
    required this.jarakIdealPlus,
    required this.jarakIdealMinus,
    required this.nilaiPreferensi,
  });
}
