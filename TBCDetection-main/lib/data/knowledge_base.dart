import '../models/symptom_def.dart';

class ExpertRule {
  const ExpertRule({
    required this.id,
    required this.requiredIds,
    required this.conclusionId,
    required this.cfExpert,
    this.description,
  });

  final String id;
  final List<String> requiredIds;
  final String conclusionId;
  final double cfExpert;
  final String? description;
}

class ConclusionDef {
  const ConclusionDef({
    required this.id,
    required this.title,
    required this.body,
    required this.action,
  });

  final String id;
  final String title;
  final String body;
  final String action;
}

// ─── Fallback gejala (dipakai jika Spreadsheet belum dikonfigurasi) ───────────
// Data sesuai tabel: kode_gejala, nama_gejala, pertanyaan, CF Pakar, aktif

const List<SymptomDef> kFallbackSymptoms = [
  // ── Gejala Utama (KG1–KG3) ──────────────────────────────────────────────
  SymptomDef(
    id: 'KG1',
    question: 'Apakah Anda mengalami batuk berdahak?',
    hint: 'Batuk Berdahak',
    sortOrder: 1,
    cfPakar: 0.4,
    category: SymptomCategory.utama,
  ),
  SymptomDef(
    id: 'KG2',
    question: 'Apakah batuk yang Anda alami berlangsung lebih dari 2 minggu?',
    hint: 'Batuk > 2 Minggu',
    sortOrder: 2,
    cfPakar: 0.8,
    category: SymptomCategory.utama,
  ),
  SymptomDef(
    id: 'KG3',
    question: 'Apakah Anda pernah batuk berdarah atau dahak bercampur darah?',
    hint: 'Batuk Berdarah',
    sortOrder: 3,
    cfPakar: 0.8,
    category: SymptomCategory.utama,
  ),

  // ── Gejala Tambahan (KG4–KG14) ──────────────────────────────────────────
  SymptomDef(
    id: 'KG4',
    question: 'Apakah Anda mengalami sesak napas atau kesulitan bernapas?',
    hint: 'Sesak Napas',
    sortOrder: 4,
    cfPakar: 0.4,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG5',
    question: 'Apakah Anda mengalami demam ringan yang sering terasa di malam hari?',
    hint: 'Demam Malam Hari',
    sortOrder: 5,
    cfPakar: 0.8,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG6',
    question: 'Apakah Anda merasakan nyeri atau rasa tidak nyaman di area dada?',
    hint: 'Nyeri Dada',
    sortOrder: 6,
    cfPakar: 0.6,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG7',
    question: 'Apakah Anda sering berkeringat di malam hari tanpa aktivitas fisik?',
    hint: 'Keringat Malam',
    sortOrder: 7,
    cfPakar: 0.8,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG8',
    question: 'Apakah nafsu makan Anda menurun secara signifikan akhir-akhir ini?',
    hint: 'Nafsu Makan Menurun',
    sortOrder: 8,
    cfPakar: 0.4,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG9',
    question: 'Apakah terjadi penurunan berat badan tanpa alasan yang jelas?',
    hint: 'Penurunan Berat Badan',
    sortOrder: 9,
    cfPakar: 0.6,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG10',
    question: 'Apakah Anda sering merasa lelah atau lemas berkepanjangan (malaise)?',
    hint: 'Malaise / Kelelahan',
    sortOrder: 10,
    cfPakar: 0.4,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG11',
    question: 'Apakah ada anggota keluarga yang pernah atau sedang menderita TBC?',
    hint: 'Riwayat TBC Keluarga',
    sortOrder: 11,
    cfPakar: 0.8,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG12',
    question: 'Apakah Anda pernah didiagnosa atau menjalani pengobatan TBC sebelumnya?',
    hint: 'Riwayat Terkena TBC',
    sortOrder: 12,
    cfPakar: 0.6,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG13',
    question: 'Apakah Anda memiliki kontak erat dengan penderita TBC yang terkonfirmasi?',
    hint: 'Kontak Positif TBC',
    sortOrder: 13,
    cfPakar: 0.8,
    category: SymptomCategory.tambahan,
  ),
  SymptomDef(
    id: 'KG14',
    question: 'Apakah Anda memiliki riwayat imunisasi BCG (biasanya saat bayi)?',
    hint: 'Riwayat Imunisasi BCG',
    sortOrder: 14,
    cfPakar: 0.3,
    category: SymptomCategory.tambahan,
  ),
];

// ─── Aturan forward chaining (dokumentasi) ────────────────────────────────────
// Engine menggunakan if-else berprioritas, bukan iterasi kRules. Daftar ini
// untuk referensi dokumentasi dan pengisian rule_forward_chaining di database.
//
// Semua gejala bersifat opsional — tidak ada gateway wajib.
// CF_evidence(KGn) = CF_user × CF_pakar_n
// CF_combine(A,B)  = CF(A) + CF(B) × (1 − CF(A))
// CF_total         = combine berurutan seluruh gejala aktif
//
// Kelompok gejala berdasarkan CF Pakar:
//   Respirasi Khas   (0.8) : KG2 batuk kronis, KG3 batuk berdarah
//   Sistemik Kuat    (0.8) : KG5 demam malam, KG7 keringat malam
//   Riwayat/Kontak   (0.8) : KG11 keluarga TBC, KG13 kontak TBC
//   Pendukung Sedang (0.6) : KG6 nyeri dada, KG9 penurunan BB, KG12 riwayat TBC
//   Gejala Ringan    (0.4) : KG1 batuk, KG4 sesak, KG8 nafsu makan, KG10 lelah
//   Sangat Ringan    (0.3) : KG14 imunisasi BCG

const List<ExpertRule> kRules = [
  // ── P03: Bukan TBC ─────────────────────────────────────────────────────────
  ExpertRule(
    id: 'R1',
    requiredIds: [],
    conclusionId: 'P03',
    cfExpert: 0.0,
    description: 'Tidak ada gejala aktif → P03 Bukan TBC. CF = 0.',
  ),
  ExpertRule(
    id: 'R2',
    requiredIds: [],
    conclusionId: 'P03',
    cfExpert: 0.0,
    description: 'Hanya gejala ringan (CF_pakar ≤ 0.4) aktif: subset {KG1, KG4, KG8, KG10, KG14} '
        '→ P03 Bukan TBC. CF = combine(gejala ringan aktif).',
  ),

  // ── P02: Mungkin TBC ───────────────────────────────────────────────────────
  ExpertRule(
    id: 'R3',
    requiredIds: ['KG6/KG9/KG12'],
    conclusionId: 'P02',
    cfExpert: 0.0,
    description: 'Gejala pendukung sedang (KG6/KG9/KG12, CF_pakar 0.6) aktif '
        'tanpa tanda khas TBC → P02 Mungkin TBC. CF = combine(gejala sedang aktif).',
  ),
  ExpertRule(
    id: 'R4',
    requiredIds: ['KG11/KG13'],
    conclusionId: 'P02',
    cfExpert: 0.0,
    description: 'Riwayat/kontak kuat (KG11 atau KG13, CF_pakar 0.8) aktif '
        'tanpa respirasi khas dan tanpa sistemik kuat → P02 Mungkin TBC.',
  ),
  ExpertRule(
    id: 'R5',
    requiredIds: ['KG5/KG7'],
    conclusionId: 'P02',
    cfExpert: 0.0,
    description: 'Sistemik kuat (KG5 atau KG7, CF_pakar 0.8) aktif '
        'tanpa respirasi khas → P02 Mungkin TBC. CF = combine(gejala aktif).',
  ),
  ExpertRule(
    id: 'R6',
    requiredIds: ['KG2/KG3'],
    conclusionId: 'P02',
    cfExpert: 0.0,
    description: 'Respirasi khas (KG2 atau KG3, CF_pakar 0.8) aktif '
        'tanpa sistemik kuat/pendukung signifikan → P02 Mungkin TBC.',
  ),

  // ── P01: Positif TBC ───────────────────────────────────────────────────────
  ExpertRule(
    id: 'R7',
    requiredIds: ['KG5/KG7', 'KG11/KG13'],
    conclusionId: 'P01',
    cfExpert: 0.0,
    description: 'Sistemik kuat (KG5/KG7) DAN riwayat/kontak kuat (KG11/KG13) '
        'aktif tanpa respirasi khas → P01 Positif TBC. CF = combine(semua aktif).',
  ),
  ExpertRule(
    id: 'R8',
    requiredIds: ['KG2/KG3', 'KG6/KG9/KG12_atau_KG11/KG13'],
    conclusionId: 'P01',
    cfExpert: 0.0,
    description: 'Respirasi khas (KG2/KG3) DAN pendukung sedang (KG6/KG9/KG12) '
        'atau riwayat/kontak kuat → P01 Positif TBC. CF = combine(semua aktif).',
  ),
  ExpertRule(
    id: 'R9',
    requiredIds: ['KG2/KG3', 'KG5/KG7'],
    conclusionId: 'P01',
    cfExpert: 0.0,
    description: 'Respirasi khas (KG2/KG3) DAN sistemik kuat (KG5/KG7) '
        '→ P01 Positif TBC. CF = combine(semua aktif).',
  ),
  ExpertRule(
    id: 'R10',
    requiredIds: ['KG2/KG3', 'KG5/KG7', 'KG11/KG13'],
    conclusionId: 'P01',
    cfExpert: 0.0,
    description: 'Respirasi khas DAN sistemik kuat DAN riwayat/kontak kuat '
        '→ P01 Positif TBC dengan keyakinan tertinggi. CF = combine(semua aktif).',
  ),
];

// ─── Kesimpulan diagnosa ──────────────────────────────────────────────────────

const Map<String, ConclusionDef> kConclusions = {
  'P01': ConclusionDef(
    id: 'P01',
    title: 'Positif TBC — Prioritas Tinggi',
    body:
        'Kombinasi gejala utama (batuk kronis/berdarah) ditambah gejala sistemik '
        'yang Anda laporkan menghasilkan tingkat keyakinan klinis yang tinggi '
        'terhadap indikasi Tuberkulosis. Ini bukan diagnosis pasti — '
        'pemeriksaan lanjutan oleh tenaga kesehatan wajib dilakukan.',
    action:
        'Segera kunjungi fasilitas kesehatan (Puskesmas/RSUD) dalam 1–2 hari '
        'ke depan. Minta pemeriksaan dahak TCM (Tes Cepat Molekuler) sebagai '
        'standar emas deteksi bakteri Mycobacterium tuberculosis. '
        'Gunakan masker medis untuk mencegah penularan kepada orang sekitar.',
  ),
  'P02': ConclusionDef(
    id: 'P02',
    title: 'Mungkin TBC — Perlu Konsultasi',
    body:
        'Pola gejala yang Anda laporkan cocok dengan beberapa indikator klinis '
        'Tuberkulosis. Sistem skrining menemukan kombinasi yang cukup untuk '
        'merekomendasikan evaluasi medis lebih lanjut.',
    action:
        'Konsultasikan kondisi Anda ke dokter atau Puskesmas dalam 2–3 hari '
        'ke depan untuk pemeriksaan fisik paru secara menyeluruh. '
        'Pantau perkembangan gejala dan hindari kontak erat dengan kelompok rentan.',
  ),
  'P03': ConclusionDef(
    id: 'P03',
    title: 'Bukan TBC — Tetap Waspada',
    body:
        'Berdasarkan jawaban Anda, tidak ditemukan kombinasi gejala yang memenuhi '
        'kriteria skrining TBC. Ini bukan jaminan kesehatan mutlak — '
        'kondisi dapat berubah seiring waktu.',
    action:
        'Tetap jaga pola hidup sehat: gizi seimbang, olahraga teratur, dan '
        'ventilasi udara baik di ruangan. Lakukan skrining ulang jika gejala '
        'baru muncul atau memburuk.',
  ),
};

const ConclusionDef kDefaultConclusion = ConclusionDef(
  id: 'P03',
  title: 'Tidak Ada Indikasi Kuat',
  body:
      'Sistem tidak menemukan kombinasi gejala yang memicu aturan skrining '
      'dengan keyakinan di atas ambang yang ditetapkan.',
  action:
      'Jika Anda tetap merasa tidak sehat, konsultasikan ke tenaga kesehatan. '
      'Ulangi skrining jika gejala baru muncul.',
);
