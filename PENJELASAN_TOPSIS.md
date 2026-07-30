# Penjelasan Metode TOPSIS — Aplikasi SPK Smart City

## Apa Itu TOPSIS?

TOPSIS (Technique for Order Preference by Similarity to Ideal Solution) adalah metode
pengambilan keputusan untuk memilih alternatif terbaik dari beberapa pilihan.

**Konsep intinya sederhana:** Alternatif terbaik adalah yang paling dekat dengan solusi ideal
terbaik dan paling jauh dari solusi ideal terburuk.

> **Analogi sederhana:** Bayangkan kamu mau beli HP. Kamu punya 6 pilihan HP (A1–A6).
> Kamu nilai masing-masing HP berdasarkan 7 kriteria (harga, kamera, baterai, dll).
> TOPSIS akan menghitung HP mana yang "paling mendekati HP impian" dan "paling jauh dari HP
> paling jelek". Itulah rekomendasi terbaiknya.

---

## Data yang Dipakai

Aplikasi ini punya **6 vendor** yang dinilai dengan **7 kriteria**:

### 7 Kriteria (C1–C7)

| Kode | Nama Kriteria | Bobot | Jenis |
|------|--------------|-------|-------|
| C1 | Kemampuan Teknis & Interoperabilitas | 20% | Benefit (makin besar makin baik) |
| C2 | Keamanan Siber | 20% | Benefit |
| C3 | Total Cost of Ownership (TCO) | 15% | **Cost** (makin kecil makin baik) |
| C4 | Rekam Jejak & Pengalaman Proyek | 15% | Benefit |
| C5 | Kualitas Layanan Purna Jual (SLA) | 15% | Benefit |
| C6 | Skalabilitas & Fleksibilitas | 10% | Benefit |
| C7 | Kepatuhan Regulasi | 5% | Benefit |

> **Catatan:** Bobot total = 100%. C3 (biaya) satu-satunya yang bersifat **Cost** — artinya
> semakin rendah nilainya, semakin bagus. Sisanya **Benefit** — semakin tinggi nilainya,
> semakin bagus.

### 6 Vendor (A1–A6)

A1 = Huawei, A2 = Cisco, A3 = Siemens, A4 = Telkom, A5 = NEC, A6 = IBM.

### Penilaian

Masing-masing vendor diberi nilai 1–5 untuk setiap kriteria. Misalnya:

| | C1 | C2 | C3 | C4 | C5 | C6 | C7 |
|---|---|---|---|---|---|---|---|
| A1 (Huawei) | 4 | 5 | 3 | 4 | 4 | 3 | 5 |
| A2 (Cisco) | 5 | 4 | 4 | 4 | 3 | 4 | 5 |
| A3 (Siemens) | 3 | 4 | 2 | 5 | 5 | 4 | 4 |
| A4 (Telkom) | 4 | 3 | 5 | 3 | 5 | 3 | 5 |
| A5 (NEC) | 3 | 5 | 4 | 4 | 4 | 4 | 4 |
| A6 (IBM) | 5 | 5 | 3 | 3 | 3 | 3 | 5 |

---

## 6 Langkah Perhitungan TOPSIS

### Langkah 1: Matriks Keputusan

Menyusun tabel penilaian seperti di atas. Baris = vendor, kolom = kriteria. Nilainya
langsung dari data penilaian (skala 1–5). Di aplikasi, tabel ini ada di layar hasil
bagian "Langkah 1: Matriks Keputusan".

### Langkah 2: Normalisasi Matriks

Setiap nilai dinormalisasi agar adil antar kriteria. Rumusnya:

```
Nilai normal = Nilai asli / akar(jumlah kuadrat semua nilai di kolom yang sama)
```

**Maksudnya:** Membandingkan nilai tiap vendor dalam satu kriteria secara proporsional.
Hasilnya berupa angka antara 0–1.

**Contoh untuk C1:** Nilai asli vendor = [4, 5, 3, 4, 3, 5].
- Jumlah kuadrat = 4² + 5² + 3² + 4² + 3² + 5² = 16 + 25 + 9 + 16 + 9 + 25 = 100
- Akar dari 100 = 10
- Maka Huawei (A1) yang nilainya 4, setelah dinormalisasi jadi 4/10 = 0,4
- Cisco (A2) yang nilainya 5, jadi 5/10 = 0,5
- Dan seterusnya

Di aplikasi, hasilnya bisa dilihat di "Langkah 2: Matriks Normalisasi".

### Langkah 3: Matriks Ternormalisasi Terbobot

Nilai normal dikalikan dengan bobot masing-masing kriteria. Ini untuk memberikan
prioritas sesuai kepentingan kriteria.

**Contoh:** C1 punya bobot 0,20 (20%). Maka:
- Huawei: 0,4 × 0,20 = 0,08
- Cisco: 0,5 × 0,20 = 0,10

Kriteria dengan bobot lebih besar (C1, C2) akan lebih berpengaruh ke hasil akhir.
Di aplikasi ada di "Langkah 3: Matriks Terbobot".

### Langkah 4: Solusi Ideal (A+ dan A-)

Menentukan dua "kondisi bayangan":
- **A+ (Solusi Ideal Positif):** Nilai terbaik untuk setiap kriteria
- **A- (Solusi Ideal Negatif):** Nilai terburuk untuk setiap kriteria

**Aturannya:**
- Untuk kriteria **Benefit** (C1, C2, C4, C5, C6, C7):
  - A+ = nilai **tertinggi** → karena makin tinggi makin baik
  - A- = nilai **terendah**
- Untuk kriteria **Cost** (C3 / TCO):
  - A+ = nilai **terendah** → karena biaya makin rendah makin baik
  - A- = nilai **tertinggi**

Bayangkan A+ sebagai "vendor sempurna" dan A- sebagai "vendor terburuk" dalam
bayangan. Di aplikasi ada di "Langkah 4: Solusi Ideal".

### Langkah 5: Jarak ke Solusi Ideal

Menghitung seberapa jauh setiap vendor dari A+ dan A- menggunakan rumus
jarak Euclidean (seperti mengukur jarak garis lurus antara dua titik).

- **D+** = jarak vendor ke solusi ideal positif (A+)
- **D-** = jarak vendor ke solusi ideal negatif (A-)

**Artinya:**
- D+ kecil → vendor mendekati yang ideal/sempurna
- D- besar → vendor jauh dari yang jelek

Di aplikasi ada di "Langkah 5: Jarak ke Solusi Ideal".

### Langkah 6: Nilai Preferensi & Ranking

Menghitung skor akhir (disebut V atau nilai preferensi):

```
V = D- / (D+ + D-)
```

**Penjelasan dengan kata-kata:**
- V = Seberapa dekat vendor ke yang sempurna, dibandingkan total jarak
- V = 1 → vendor itu sempurna (D- besar, D+ kecil)
- V = 0 → vendor itu sangat jelek (D- kecil, D+ besar)
- V di antaranya 0 sampai 1

**Yang dihitung:**
1. Hitung V untuk tiap vendor
2. Urutkan dari V terbesar ke terkecil
3. Ranking 1 diberikan ke V tertinggi

---

## Hasil Akhir

Di aplikasi, hasil akhir ditampilkan seperti ini:

### 1. Kartu Pemenang (Winner Card)

Vendor dengan ranking 1 tampil paling mencolok dengan:
- Ikon trofi
- Nama vendor yang jadi rekomendasi terbaik
- Skor V (nilai preferensi)
- Selisih skor dengan vendor peringkat 2

### 2. Statistik Cepat

- Total vendor yang dinilai
- Rata-rata skor semua vendor
- Selisih skor antara tertinggi dan terendah

### 3. Grafik Batang

Semua vendor diurutkan dari skor tertinggi ke terendah dalam bentuk diagram
batang. Warna emas untuk juara 1, biru untuk 3 besar, abu-abu untuk sisanya.

### 4. Daftar Ranking

Tabel lengkap peringkat semua vendor dari 1 sampai terakhir, lengkap dengan
skor V masing-masing.

### 5. Detail Perhitungan (Bisa Dibuka/Tutup)

Di bagian bawah, ada toggle "Detail Perhitungan TOPSIS" yang berisi:
- **Langkah 1:** Matriks Keputusan — nilai asli 1–5
- **Langkah 2:** Matriks Normalisasi — nilai yang sudah dinormalisasi
- **Langkah 3:** Matriks Terbobot — nilai normal × bobot
- **Langkah 4:** Solusi Ideal A+ dan A- — nilai ideal terbaik/terburuk per kriteria
- **Langkah 5:** Jarak D+ dan D- — jarak ke ideal positif dan negatif

> Semua langkah bisa diklik satu per satu untuk melihat detail angkanya.

### 6. Tabel Detail Lengkap

Tabel besar yang menggabungkan semua informasi: nilai asli, D+, D-, V, dan ranking
dalam satu tampilan.

---

## Contoh Hasil (Dari Data Seed)

Berdasarkan data contoh yang sudah disediakan aplikasi:

| Ranking | Vendor | Skor (V) |
|---------|--------|---------|
| 1 | Cisco (A2) | 0.6540 |
| 2 | NEC (A5) | 0.5951 |
| 3 | Huawei (A1) | 0.5853 |
| 4 | Siemens (A3) | 0.5816 |
| 5 | IBM (A6) | 0.4806 |
| 6 | Telkom (A4) | 0.2950 |

> **Kesimpulan:** Dari 6 vendor smart city, **Cisco (A2)** keluar sebagai rekomendasi
> terbaik dengan skor 0.654, unggul tipis dari NEC dan Huawei.

---

## Ringkasan - Alur di Aplikasi

```
User memasukkan data (Vendor, Kriteria, Penilaian)
         ↓
Langkah 1 → Matriks Keputusan (nilai 1-5)
         ↓
Langkah 2 → Normalisasi (0-1)
         ↓
Langkah 3 × Bobot → Matriks Terbobot
         ↓
Langkah 4 → Cari A+ (ideal) dan A- (terjelek)
         ↓
Langkah 5 → Hitung D+ dan D- tiap vendor
         ↓
Langkah 6 → Hitung V = D-/(D++D-)
         ↓
Ranking: V tertinggi = Peringkat 1
         ↓
Tampilkan: Juara + Grafik + Tabel + Detail
```
