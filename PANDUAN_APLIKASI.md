# PANDUAN APLIKASI SPK Smart City

## Alur Aplikasi (Flow)

```
Splash Screen (3 detik)
       │
       ▼
  ┌─────────────────────────────────────┐
  │           HOME SCREEN               │
  │  ┌─────────────────────────────┐    │
  │  │ Header: Logo + Judul Aplikasi│    │
  │  └─────────────────────────────┘    │
  │  ┌─────────────────────────────┐    │
  │  │ Bobot Kriteria (Card)       │    │
  │  │ C1-C7 + Bobot + Tipe       │    │
  │  └─────────────────────────────┘    │
  │  ┌──────┐ ┌──────┐                 │
  │  │Vendor│ │Krite-│                 │
  │  │      │ │ria   │                 │
  │  └──────┘ └──────┘                 │
  │  ┌──────┐ ┌──────┐                 │
  │  │Wizar-│ │Hasil │                 │
  │  │d     │ │TOPSIS│                 │
  │  └──────┘ └──────┘                 │
  └─────────────────────────────────────┘
       │       │        │        │
       ▼       ▼        ▼        ▼
   Vendor   Kriteria  Wizard   Hasil
   Screen   Screen    Penilai  Screen
                         an
```

---

## 1. SPLASH SCREEN (Layar Pembuka)

**File:** `lib/screens/splash_screen.dart`

### Tampilan:
- **Background:** Gradasi warna biru (primary → primaryDark)
- **Logo:** Logo aplikasi di tengah dengan efek animasi fade-in + scale-up
- **Judul:** "SPK Smart City" (font besar, putih)
- **Sub-judul:** "Pemilihan Vendor Infrastruktur" (font lebih kecil, putih transparan)
- **Loading:** Progress indicator lingkaran kecil di bawah teks

### Perilaku:
- Tampil selama **3 detik**
- Otomatis pindah ke **Home Screen** setelah 3 detik
- Terdapat animasi:
  - Logo muncul dengan efek fade + scale (0 → 1 detik)
  - Teks muncul dengan efek slide-up (0.3 → 0.7 detik)
  - Teks sub-judul muncul dengan fade (0.5 → 1 detik)

---

## 2. HOME SCREEN (Halaman Utama)

**File:** `lib/screens/home_screen.dart`

### Elemen UI:

#### a. AppBar (Header Atas)
| Elemen | Keterangan |
|--------|------------|
| Judul | "SPK Smart City" (font bold, putih) |
| Warna | Biru (AppColors.primary) |
| Menu (⋮) | Tombol tiga titik di pojok kanan atas |

#### b. Menu Popup (⋮) - Di pojok kanan atas
| Opsi | Icon | Fungsi |
|------|------|--------|
| Isi Data Contoh | 📦 (storage) | Mengisi data vendor, kriteria, dan penilaian contoh ke Firestore |
| Reset Semua Data | 🗑️ (delete_forever) | Menghapus SEMUA data di Firestore |

#### c. Header Card (Kartu Gradasi Biru)
- Logo kecil di pojok kiri atas
- **Judul:** "Pemilihan Vendor Infrastruktur"
- **Sub-judul:** "Metode TOPSIS - 7 Kriteria, 6 Vendor"

#### d. Card Bobot Kriteria (Ringkasan)
Menampilkan daftar 7 kriteria beserta bobot dan tipenya:

| Kode | Nama Kriteria | Bobot | Tipe |
|------|---------------|-------|------|
| C1 | Kemampuan Teknis & Interoperabilitas | 0.20 | Benefit |
| C2 | Keamanan Siber | 0.20 | Benefit |
| C3 | Total Cost of Ownership (TCO) | 0.15 | Cost |
| C4 | Rekam Jejak & Pengalaman Proyek | 0.15 | Benefit |
| C5 | Kualitas Layanan Purna Jual (SLA) | 0.15 | Benefit |
| C6 | Skalabilitas & Fleksibilitas | 0.10 | Benefit |
| C7 | Kepatuhan Regulasi | 0.05 | Benefit |

> **Total Bobot: 1.00**

#### e. Grid Menu (4 Menu Utama)
Ditampilkan dalam grid 2×2:

| Menu | Icon | Warna | Fungsi | Screen |
|------|------|-------|--------|--------|
| **Vendor** | 🏢 (business) | Biru | Kelola data vendor | VendorScreen |
| **Kriteria** | 📋 (assignment) | Cyan | Kelola kriteria penilaian | KriteriaScreen |
| **Wizard Penilaian** | ⭐ (auto_awesome) | Oranye | Step-by-step penilaian TOPSIS | PenilaianWizardScreen |
| **Hasil TOPSIS** | 📊 (bar_chart) | Hijau | Lihat hasil perhitungan TOPSIS | HasilScreen |

### Inisialisasi Data:
- Saat pertama kali dibuka, jika **belum ada data** di Firestore:
  - Muncul dialog otomatis: "Belum ada data kriteria dan vendor"
  - Pilihan: "Ya, Isi Data" atau "Tidak"
  - Jika memilih "Ya", akan mengisi:
    - 7 Kriteria (C1-C7)
    - 6 Vendor (Huawei, Cisco, Siemens, Telkom, NEC, IBM)
    - 42 Data Penilaian (6 vendor × 7 kriteria)

---

## 3. VENDOR SCREEN (Kelola Vendor)

**File:** `lib/screens/vendor_screen.dart`

### Elemen UI:

#### a. AppBar
| Elemen | Keterangan |
|--------|------------|
| Judul | "Vendor" (font bold, putih) |
| Warna | Biru (AppColors.primary) |
| Tombol "+ Tambah" | FAB di pojok kanan bawah |

#### b. Daftar Vendor (ListView)
Setiap vendor ditampilkan dalam **Card** dengan:

**Baris Pertama:**
- Badge kode vendor (contoh: A1) dengan latar biru transparan
- Nama vendor (font bold)
- Fokus solusi vendor (sub-judul)
- Menu tiga titik (⋮) untuk aksi

**Baris Kedua - Keempat (Info Vendor):**
- 📍 Alamat vendor
- 📞 Telepon vendor
- 📧 Email vendor

#### c. Menu Aksi Vendor (⋮)
| Opsi | Fungsi |
|------|--------|
| Edit | Mengubah data vendor (muncul dialog form) |
| Hapus | Menghapus vendor beserta semua penilaian terkait |

#### d. Form Tambah/Edit Vendor
Muncul dalam dialog (AlertDialog) dengan field:
| Field | Tipe | Validasi |
|-------|------|----------|
| Kode | Text | Wajib diisi (contoh: A1, A2) |
| Nama Vendor | Text | Wajib diisi |
| Fokus Solusi | Text | Opsional |
| Alamat | Text | Wajib diisi |
| Telepon | Text | Wajib diisi |
| Email | Text | Wajib diisi, harus mengandung "@" |

**Tombol:** Simpan | Batal

---

## 4. KRITERIA SCREEN (Kelola Kriteria)

**File:** `lib/screens/kriteria_screen.dart`

### Elemen UI:

#### a. AppBar
| Elemen | Keterangan |
|--------|------------|
| Judul | "Kriteria" (font bold, putih) |
| Warna | Cyan (AppColors.accent) |
| Tombol "+ Tambah" | FAB di pojok kanan bawah |

#### b. Daftar Kriteria (ListView)
Setiap kriteria ditampilkan dalam **Card** dengan:

**Baris Pertama:**
- Badge kode kriteria (contoh: C1) dengan latar cyan transparan
- Nama kriteria (font bold)
- Menu tiga titik (⋮) untuk aksi

**Baris Kedua:**
- Deskripsi kriteria

**Baris Ketiga (Chip):**
- Badge "Bobot: 0.20" (warna cyan)
- Badge "Benefit" (hijau) atau "Cost" (oranye)

#### c. Menu Aksi Kriteria (⋮)
| Opsi | Fungsi |
|------|--------|
| Edit | Mengubah data kriteria (muncul dialog form) |
| Hapus | Menghapus kriteria beserta semua penilaian terkait |

#### d. Form Tambah/Edit Kriteria
Muncul dalam dialog (AlertDialog) dengan field:
| Field | Tipe | Validasi |
|-------|------|----------|
| Kode | Text | Wajib diisi (contoh: C1, C2) |
| Nama Kriteria | Text | Wajib diisi |
| Deskripsi | Text | Wajib diisi |
| Bobot | Number | Wajib diisi, antara 0-1 |
| Tipe Kriteria | Dropdown | Benefit atau Cost |

**Tombol:** Simpan | Batal

---

## 5. WIZARD PENILAIAN SCREEN (Penilaian Bertahap)

**File:** `lib/screens/penilaian_wizard_screen.dart`

### Alur Wizard (4 Langkah):

```
Step 1: Pilih Vendor ──→ Step 2: Beri Skor ──→ Step 3: Atur Bobot ──→ Step 4: Ringkasan
    │                      │                      │                      │
    ▼                      ▼                      ▼                      ▼
┌─────────┐          ┌─────────┐          ┌─────────┐          ┌─────────┐
│ Pilih   │          │ Star    │          │ Slider  │          │ Review  │
│ vendor  │          │ Rating  │          │ Bobot   │          │ Semua   │
│ mana    │          │ 1-5     │          │ per     │          │ data    │
│ saja    │          │ bintang │          │ kriteria│          │         │
└─────────┘          └─────────┘          └─────────┘          └─────────┘
```

### Step Indicator (Indikator Langkah)
Di bagian atas, terdapat 4 lingkaran yang menunjukkan langkah aktif:
1. 🏢 Vendor (abu-abu jika belum aktif)
2. ⭐ Skor (abu-abu jika belum aktif)
3. 🎛️ Bobot (abu-abu jika belum aktif)
4. ✅ Selesai (abu-abu jika belum aktif)

**Warna:**
- **Abu-abu:** Langkah belum/sudah dilewati
- **Oranye:** Langkah aktif saat ini
- **Hijau:** Langkah sudah selesai (centang)

---

### STEP 1: PILIH VENDOR

**Header:** "Langkah 1 dari 4" | "Pilih Vendor"

**Tampilan:**
- **Tombol "Pilih Semua Vendor"** di bagian atas (jika ada data vendor)
  - Centang semua / buang centang semua
  - Badge jumlah yang dipilih: "X dipilih"

- **Daftar Vendor:** Setiap vendor ditampilkan dalam Card dengan:
  - Checkbox (✓) untuk memilih
  - Badge kode vendor (contoh: A1)
  - Nama vendor
  - Fokus solusi
  - Badge "✓ Dinilai" (jika sudah ada skor)

- **Info Box Hijau:** "X vendor dipilih. Anda akan memberi skor untuk semua vendor di langkah berikutnya."

**Navigasi:**
- Tombol "Lanjut" (oranye) → Pindah ke Step 2
- Tombol "Kembali" (outline) → Kembali ke Home

---

### STEP 2: BERI SKOR (Star Rating)

**Header:** "Langkah 2 dari 4" | "Beri Skor" | "X/Y — Nama Vendor"

**Tampilan:**

#### Tab Vendor (Horizontal Scrolling)
- Jika lebih dari 1 vendor dipilih, ditampilkan tab horizontal di bagian atas
- Setiap tab: kode vendor + badge centang hijau jika sudah dinilai
- Tab aktif: latar oranye

#### Kartu Info Vendor
- Gradasi warna cyan
- Badge kode vendor
- Nama vendor
- Fokus solusi

#### Kartu Penilaian per Kriteria (Star Rating)
Untuk setiap kriteria, ditampilkan kartu dengan:
- **Baris atas:** Badge kode kriteria + Nama kriteria + Badge "Benefit" (hijau) atau "Cost" (oranye)
- **Baris kedua:** Deskripsi kriteria
- **Star Rating:** 5 bintang yang bisa diklik
  - ⭐ = Skor terisi (oranye)
  - ☆ = Skor kosong (abu-abu)
  - **Skala:**
    - 1 bintang = Sangat Buruk
    - 2 bintang = Kurang
    - 3 bintang = Cukup
    - 4 bintang = Baik
    - 5 bintang = Sangat Baik

**Navigasi:**
- Tombol "Kembali" (outline) → Kembali ke Step 1
- Tombol "Lanjut" (oranye) → Pindah ke Step 3

---

### STEP 3: ATUR BOBOT KRITERIA

**Header:** "Langkah 3 dari 4" | "Atur Bobot Kriteria"

**Tampilan:**

#### Template Bobot (Card)
4 template yang bisa dipilih:
| Template | C1 | C2 | C3 | C4 | C5 | C6 | C7 |
|----------|----|----|----|----|----|----|----|
| Smart City Standar | 20% | 20% | 15% | 15% | 15% | 10% | 5% |
| Prioritas Keamanan | 15% | 30% | 10% | 10% | 15% | 10% | 10% |
| Prioritas Biaya | 10% | 10% | 30% | 10% | 10% | 15% | 15% |
| Prioritas Pengalaman | 15% | 15% | 10% | 25% | 15% | 10% | 10% |

#### Indikator Total Bobot
- **Hijau:** Total = 1.00 (valid)
- **Merah:** Total ≠ 1.00 (tidak valid)
- Tombol **"Normalisasi"** → Otomatis normalisasi bobot agar total = 1.00

#### Slider Bobot per Kriteria
Setiap kriteria memiliki slider untuk mengatur bobot:
- Badge kode kriteria
- Nama kriteria
- Persentase bobot (contoh: 20%)
- Slider dari 0.01 hingga 0.50 (rentang 1%-50%)

#### Tombol "Reset ke Default"
Mengembalikan semua bobot ke nilai awal dari Firestore

**Navigasi:**
- Tombol "Kembali" (outline) → Kembali ke Step 2
- Tombol "Lihat Ringkasan" (oranye) → Pindah ke Step 4

---

### STEP 4: RINGKASAN

**Header:** "Langkah 4 dari 4" | "Ringkasan"

**Tampilan:**

#### Kartu Ringkasan per Vendor
Untuk setiap vendor yang dipilih:
- Badge kode vendor dengan gradasi oranye
- Nama vendor + fokus solusi
- **Tabel ringkasan skor:**
  - Kode kriteria + Nama kriteria
  - Star rating (1-5)
  - Persentase bobot

#### Kartu Ringkasan Bobot
- Badge "Bobot Kriteria"
- Badge total bobot (hijau/merah)
- Bar progress per kriteria

**Navigasi:**
- Tombol "Kembali" (outline) → Kembali ke Step 3
- Tombol "Simpan & Lihat Hasil" (hijau) → Menyimpan data ke Firestore → Pindah ke HasilScreen

---

## 6. HASIL SCREEN (Hasil Perhitungan TOPSIS)

**File:** `lib/screens/hasil_screen.dart`

### Elemen UI:

#### a. AppBar
| Elemen | Keterangan |
|--------|------------|
| Judul | "Hasil TOPSIS" (font bold, putih) |
| Warna | Hijau (AppColors.success) |
| Tombol Refresh | 🔄 di pojok kanan atas (hitung ulang) |

#### b. Kartu Pemenang (Winner Card)
**Background:** Gradasi emas (gold → orange)
**Isi:**
- 🏆 Ikon trofi besar
- Teks "REKOMENDASI TERBAIK" (huruf besar, spacing lebar)
- Nama vendor terbaik (font besar, bold)
- Badge skor: "Skor: 0.XXXX"
- Badge margin: "+0.XXXX" (selisih dengan runner-up)

#### c. Quick Stats (3 Kartu Statistik)
| Statistik | Icon | Keterangan |
|-----------|------|------------|
| Total Vendor | 🏢 | Jumlah vendor yang dinilai |
| Rata-rata Skor | 📊 | Rata-rata nilai preferensi |
| Selisih Max-Min | ↔️ | Selisih skor tertinggi dan terendah |

#### d. Grafik Batang (Bar Chart)
**Judul:** "Perbandingan Skor Vendor"
- **X-axis:** Nama vendor (dipotong jika panjang)
- **Y-axis:** Skor preferensi (0-1)
- **Bar emas:** Pemenang (ranking 1)
- **Bar biru:** Top 3
- **Bar abu-abu:** Lainnya
- **Tooltip:** Menampilkan nama vendor + skor + ranking

#### e. Daftar Ranking (Ranking List)
**Judul:** "Ranking Vendor"
Setiap vendor ditampilkan dalam Card:
- **Medali:** 🥇 (emas), 🥈 (perak), 🥉 (perunggu) untuk top 3
- **Badge angka:** Untuk ranking selain top 3
- **Nama vendor:** Font bold untuk pemenang
- **Progress bar:** Menunjukkan proporsi skor
- **Skor:** Angka preferensi (contoh: 0.XXXX)

#### f. Tabel Detail Lengkap (Collapsible)
**Judul:** "Tabel Detail Lengkap"
Ketika diklik, menampilkan tabel dengan kolom:
| Vendor | C1 | C2 | C3 | C4 | C5 | C6 | C7 | D+ | D- | V | Rank |
|--------|----|----|----|----|----|----|----|----|----|---|------|

#### g. Detail Perhitungan TOPSIS (Collapsible)
**Judul:** "Detail Perhitungan TOPSIS"

Ketika diklik, menampilkan 5 langkah perhitungan:

**Langkah 1: Matriks Keputusan (X)**
- Tabel matriks keputusan (6 vendor × 7 kriteria)
- Nilai asli dari penilaian

**Langkah 2: Matriks Normalisasi (R)**
- Tabel matriks normalisasi
- Nilai dibagi dengan akar kuadrat jumlah kuadrat per kolom

**Langkah 3: Matriks Terbobot (Y)**
- Tabel matriks terbobot
- Nilai normalisasi × bobot kriteria

**Langkah 4: Solusi Ideal (A+ dan A-)**
- A+ (Ideal Positif): Nilai maksimum untuk Benefit, minimum untuk Cost
- A- (Ideal Negatif): Nilai minimum untuk Benefit, maksimum untuk Cost
- Info box: "C3 (TCO) bersifat Cost: A+ = nilai minimum, A- = nilai maksimum"

**Langkah 5: Jarak ke Solusi Ideal**
- D+ (Jarak ke Positif): Jarak Euclidean ke A+
- D- (Jarak ke Negatif): Jarak Euclidean ke A-
- Info box: "V = D- / (D+ + D-). Semakin mendekati 1, semakin baik."

---

## 7. PENILAIAN SCREEN (Penilaian Manual)

**File:** `lib/screens/penilaian_screen.dart`

> **Catatan:** Screen ini tidak diakses dari menu utama. Hanya bisa diakses jika ada referensi lain.

### Elemen UI:

#### a. AppBar
| Elemen | Keterangan |
|--------|------------|
| Judul | "Penilaian" (font bold, putih) |
| Warna | Oranye (AppColors.warning) |
| Tombol "+ Tambah" | FAB di pojok kanan bawah |

#### b. Daftar Penilaian (ListView)
Setiap penilaian ditampilkan dalam Card dengan:
- Icon penilaian (warna oranye)
- Nama vendor (font bold)
- Nama kriteria (sub-judul)
- Badge nilai (contoh: 4.00)
- Tombol hapus (🗑️)

#### c. Form Tambah Penilaian
Muncul dalam dialog dengan dropdown:
| Field | Tipe | Keterangan |
|-------|------|------------|
| Pilih Vendor | Dropdown | Daftar vendor dari Firestore |
| Pilih Kriteria | Dropdown | Daftar kriteria dari Firestore |
| Nilai (1-10) | Number | Input angka 1-10 |

**Tombol:** Simpan | Batal

---

## MODEL DATA

### Vendor
```dart
{
  id: String,           // ID Firestore
  kode: String,         // Contoh: A1, A2
  nama: String,         // Contoh: Huawei
  alamat: String,       // Alamat kantor
  telepon: String,      // Nomor telepon
  email: String,        // Alamat email
  fokus: String,        // Fokus solusi
  createdAt: DateTime,  // Waktu pembuatan
}
```

### Kriteria
```dart
{
  id: String,           // ID Firestore
  kode: String,         // Contoh: C1, C2
  nama: String,         // Nama kriteria
  deskripsi: String,    // Deskripsi kriteria
  bobot: double,        // Bobot 0-1
  isBenefit: bool,      // true=benefit, false=cost
  createdAt: DateTime,  // Waktu pembuatan
}
```

### Penilaian
```dart
{
  id: String,           // ID Firestore
  vendorId: String,     // ID vendor terkait
  vendorName: String,   // Nama vendor (denormalisasi)
  kriteriaId: String,   // ID kriteria terkait
  kriteriaName: String, // Nama kriteria (denormalisasi)
  nilai: double,        // Nilai skor 1-10
  createdAt: DateTime,  // Waktu pembuatan
}
```

---

## KONVENSI WARNA

| Nama | Kode | Penggunaan |
|------|------|------------|
| primary | #1A73E8 | Tombol utama, header VendorScreen |
| primaryDark | #1557B0 | Gradasi header |
| accent | #00BCD4 | Header KriteriaScreen, badge kriteria |
| background | #F5F5F5 | Background seluruh halaman |
| card | #FFFFFF | Background kartu |
| textPrimary | #212121 | Teks utama |
| textSecondary | #757575 | Teks sekunder |
| success | #4CAF50 | Badge Benefit, header HasilScreen, pemenang |
| warning | #FF9800 | Badge Cost, header PenilaianScreen, star rating |
| error | #F44336 | Tombol hapus, validasi error |

---

## ALUR PENGGUNAAN (User Flow)

### Pertama Kali:
1. Buka aplikasi → Splash Screen (3 detik)
2. Home Screen muncul → Dialog "Inisialisasi Data" muncul
3. Klik "Ya, Isi Data" → Data contoh terisi
4. Siap digunakan

### Penilaian Vendor:
1. Klik **"Wizard Penilaian"** di Home
2. **Step 1:** Centang vendor yang akan dinilai → Klik "Lanjut"
3. **Step 2:** Beri skor 1-5 bintang untuk setiap kriteria per vendor → Klik "Lanjut"
4. **Step 3:** Atur bobot kriteria (pilih template atau manual) → Klik "Lihat Ringkasan"
5. **Step 4:** Review ringkasan → Klik "Simpan & Lihat Hasil"
6. **HasilScreen** menampilkan rekomendasi vendor terbaik

### Lihat Hasil:
1. Klik **"Hasil TOPSIS"** di Home
2. Lihat kartu pemenang, grafik, dan ranking
3. Klik "Detail Perhitungan TOPSIS" untuk melihat langkah perhitungan
4. Klik tombol refresh (🔄) untuk menghitung ulang
