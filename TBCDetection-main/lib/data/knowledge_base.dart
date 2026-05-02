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
// Engine menggunakan logika tier, bukan iterasi kRules. Daftar ini untuk
// referensi dan pengisian kolom rule_forward_chaining di database.

const List<ExpertRule> kRules = [
  ExpertRule(
    id: 'R1',
    requiredIds: [],
    conclusionId: 'P03',
    cfExpert: 0.0,
    description: 'TIDAK ADA KG1 (Batuk Berdahak) → P03 Bukan TBC. '
        'Batuk adalah gateway symptom; tanpa batuk proses berhenti.',
  ),
  ExpertRule(
    id: 'R2',
    requiredIds: ['KG1'],
    conclusionId: 'P03',
    cfExpert: 0.4,
    description: 'KG1 = YA, KG2 = TIDAK, KG3 = TIDAK, KG4–KG13 semua TIDAK → '
        'P03 Bukan TBC. Batuk tunggal tanpa gejala pendukung.',
  ),
  ExpertRule(
    id: 'R3',
    requiredIds: ['KG1', 'KG2'],
    conclusionId: 'P02',
    cfExpert: 0.0,
    description: 'KG1 AND KG2 → P02 Mungkin TBC. '
        'CF = CF_combine(KG1, KG2) = CF(KG1) + CF(KG2)×(1−CF(KG1)).',
  ),
  ExpertRule(
    id: 'R4',
    requiredIds: ['KG1', 'KG3'],
    conclusionId: 'P02',
    cfExpert: 0.0,
    description: 'KG1 AND KG3 → P02 Mungkin TBC. '
        'CF = CF_combine(KG1, KG3). Hemoptisis adalah tanda klinis serius.',
  ),
  ExpertRule(
    id: 'R5',
    requiredIds: ['KG1'],
    conclusionId: 'P02',
    cfExpert: 0.0,
    description: 'KG1 = YA, KG2/KG3 = TIDAK, setidaknya satu KG4–KG13 = YA → '
        'P02 Mungkin TBC. CF = CF_combine bertahap semua gejala aktif.',
  ),
  ExpertRule(
    id: 'R6',
    requiredIds: ['KG1', 'KG2/KG3'],
    conclusionId: 'P01',
    cfExpert: 0.0,
    description: 'R3 atau R4 terpenuhi DAN setidaknya satu KG4–KG13 = YA → '
        'P01 Positif TBC. CF_final = CF_combine(CF_level2, CF_supporting).',
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
