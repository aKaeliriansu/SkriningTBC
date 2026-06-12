import '../models/symptom_def.dart';

// ─── Fact hierarchy ───────────────────────────────────────────────────────────

enum FactType { symptom, cluster, pattern, diagnosis }

// ─── Production rule ──────────────────────────────────────────────────────────

class FCRule {
  const FCRule({
    required this.id,
    required this.conditions,
    required this.conclusionId,
    required this.conclusionType,
    this.description,
  });

  /// Semua kondisi harus ada di Working Memory (AND semantics).
  /// OR dimodelkan sebagai rule terpisah per gejala yang mengarah ke fakta yang sama.
  final String id;
  final List<String> conditions;
  final String conclusionId;
  final FactType conclusionType;
  final String? description;
}

// ─── Aturan forward chaining 3-layer ─────────────────────────────────────────
//
// Layer 1  Gejala (symptom) → Klaster (cluster)
//   Satu gejala → satu klaster. Beberapa rule bisa menulis ke klaster yang sama;
//   engine menggabungkan CF-nya dengan rumus MYCIN combine.
//
// Layer 2  Klaster → Pola (pattern)
//   Dua atau tiga klaster aktif → pola baru ditambahkan ke WM.
//   CF pola = min(CF_klaster_a, CF_klaster_b)  [AND semantics].
//
// Layer 3  Pola / Klaster → Diagnosa (diagnosis)
//   Rule mengarah ke P01 atau P02.
//   Jika tidak ada P01/P02 di WM → mesin mengembalikan P03 sebagai default.

const List<FCRule> kFCRules = [
  // ── Layer 1: Gejala → Klaster ─────────────────────────────────────────────

  // Respirasi Khas (CF Pakar 0.8)
  FCRule(
    id: 'L1_RESP_1',
    conditions: ['KG2'],
    conclusionId: 'RESP_STRONG',
    conclusionType: FactType.cluster,
    description: 'IF KG2 (Batuk >2 Minggu) THEN RESP_STRONG',
  ),
  FCRule(
    id: 'L1_RESP_2',
    conditions: ['KG3'],
    conclusionId: 'RESP_STRONG',
    conclusionType: FactType.cluster,
    description: 'IF KG3 (Batuk Berdarah) THEN RESP_STRONG',
  ),

  // Sistemik Kuat (CF Pakar 0.8)
  FCRule(
    id: 'L1_SYS_1',
    conditions: ['KG5'],
    conclusionId: 'SYS_STRONG',
    conclusionType: FactType.cluster,
    description: 'IF KG5 (Demam Malam) THEN SYS_STRONG',
  ),
  FCRule(
    id: 'L1_SYS_2',
    conditions: ['KG7'],
    conclusionId: 'SYS_STRONG',
    conclusionType: FactType.cluster,
    description: 'IF KG7 (Keringat Malam) THEN SYS_STRONG',
  ),

  // Riwayat / Kontak (CF Pakar 0.8)
  FCRule(
    id: 'L1_EXP_1',
    conditions: ['KG11'],
    conclusionId: 'EXP_STRONG',
    conclusionType: FactType.cluster,
    description: 'IF KG11 (Riwayat TBC Keluarga) THEN EXP_STRONG',
  ),
  FCRule(
    id: 'L1_EXP_2',
    conditions: ['KG13'],
    conclusionId: 'EXP_STRONG',
    conclusionType: FactType.cluster,
    description: 'IF KG13 (Kontak Positif TBC) THEN EXP_STRONG',
  ),

  // Pendukung Sedang (CF Pakar 0.6)
  FCRule(
    id: 'L1_MED_1',
    conditions: ['KG6'],
    conclusionId: 'SUPPORT_MED',
    conclusionType: FactType.cluster,
    description: 'IF KG6 (Nyeri Dada) THEN SUPPORT_MED',
  ),
  FCRule(
    id: 'L1_MED_2',
    conditions: ['KG9'],
    conclusionId: 'SUPPORT_MED',
    conclusionType: FactType.cluster,
    description: 'IF KG9 (Penurunan Berat Badan) THEN SUPPORT_MED',
  ),
  FCRule(
    id: 'L1_MED_3',
    conditions: ['KG12'],
    conclusionId: 'SUPPORT_MED',
    conclusionType: FactType.cluster,
    description: 'IF KG12 (Riwayat Terkena TBC) THEN SUPPORT_MED',
  ),

  // Gejala Ringan (CF Pakar 0.3–0.4)
  FCRule(
    id: 'L1_WEAK_1',
    conditions: ['KG1'],
    conclusionId: 'WEAK_SYM',
    conclusionType: FactType.cluster,
    description: 'IF KG1 (Batuk Berdahak) THEN WEAK_SYM',
  ),
  FCRule(
    id: 'L1_WEAK_2',
    conditions: ['KG4'],
    conclusionId: 'WEAK_SYM',
    conclusionType: FactType.cluster,
    description: 'IF KG4 (Sesak Napas) THEN WEAK_SYM',
  ),
  FCRule(
    id: 'L1_WEAK_3',
    conditions: ['KG8'],
    conclusionId: 'WEAK_SYM',
    conclusionType: FactType.cluster,
    description: 'IF KG8 (Nafsu Makan Menurun) THEN WEAK_SYM',
  ),
  FCRule(
    id: 'L1_WEAK_4',
    conditions: ['KG10'],
    conclusionId: 'WEAK_SYM',
    conclusionType: FactType.cluster,
    description: 'IF KG10 (Malaise/Kelelahan) THEN WEAK_SYM',
  ),
  FCRule(
    id: 'L1_WEAK_5',
    conditions: ['KG14'],
    conclusionId: 'WEAK_SYM',
    conclusionType: FactType.cluster,
    description: 'IF KG14 (Riwayat BCG) THEN WEAK_SYM',
  ),

  // ── Layer 2: Klaster → Pola ───────────────────────────────────────────────

  FCRule(
    id: 'L2_PAT_1',
    conditions: ['RESP_STRONG', 'SYS_STRONG'],
    conclusionId: 'PAT_RESP_SYS',
    conclusionType: FactType.pattern,
    description: 'IF RESP_STRONG ∧ SYS_STRONG THEN PAT_RESP_SYS (Respirasi + Sistemik)',
  ),
  FCRule(
    id: 'L2_PAT_2',
    conditions: ['RESP_STRONG', 'EXP_STRONG'],
    conclusionId: 'PAT_RESP_EXP',
    conclusionType: FactType.pattern,
    description: 'IF RESP_STRONG ∧ EXP_STRONG THEN PAT_RESP_EXP (Respirasi + Riwayat)',
  ),
  FCRule(
    id: 'L2_PAT_3',
    conditions: ['RESP_STRONG', 'SUPPORT_MED'],
    conclusionId: 'PAT_RESP_MED',
    conclusionType: FactType.pattern,
    description: 'IF RESP_STRONG ∧ SUPPORT_MED THEN PAT_RESP_MED (Respirasi + Pendukung)',
  ),
  FCRule(
    id: 'L2_PAT_4',
    conditions: ['SYS_STRONG', 'EXP_STRONG'],
    conclusionId: 'PAT_SYS_EXP',
    conclusionType: FactType.pattern,
    description: 'IF SYS_STRONG ∧ EXP_STRONG THEN PAT_SYS_EXP (Sistemik + Riwayat)',
  ),

  // Pola komposit: RESP + SYS + EXP (fakta PAT_RESP_SYS sudah harus ada)
  FCRule(
    id: 'L2_PAT_5',
    conditions: ['PAT_RESP_SYS', 'EXP_STRONG'],
    conclusionId: 'PAT_FULL',
    conclusionType: FactType.pattern,
    description: 'IF PAT_RESP_SYS ∧ EXP_STRONG THEN PAT_FULL (Respirasi + Sistemik + Riwayat)',
  ),

  // ── Layer 3: Pola / Klaster → Diagnosa ───────────────────────────────────

  // P01 — Positif TBC
  FCRule(
    id: 'L3_P01_1',
    conditions: ['PAT_FULL'],
    conclusionId: 'P01',
    conclusionType: FactType.diagnosis,
    description: 'IF PAT_FULL (3 klaster kuat) THEN P01 — Positif TBC (keyakinan tertinggi)',
  ),
  FCRule(
    id: 'L3_P01_2',
    conditions: ['PAT_RESP_SYS'],
    conclusionId: 'P01',
    conclusionType: FactType.diagnosis,
    description: 'IF PAT_RESP_SYS (Respirasi + Sistemik) THEN P01 — Positif TBC',
  ),
  FCRule(
    id: 'L3_P01_3',
    conditions: ['PAT_RESP_EXP'],
    conclusionId: 'P01',
    conclusionType: FactType.diagnosis,
    description: 'IF PAT_RESP_EXP (Respirasi + Riwayat/Kontak) THEN P01 — Positif TBC',
  ),
  FCRule(
    id: 'L3_P01_4',
    conditions: ['PAT_RESP_MED'],
    conclusionId: 'P01',
    conclusionType: FactType.diagnosis,
    description: 'IF PAT_RESP_MED (Respirasi + Pendukung Sedang) THEN P01 — Positif TBC',
  ),
  FCRule(
    id: 'L3_P01_5',
    conditions: ['PAT_SYS_EXP'],
    conclusionId: 'P01',
    conclusionType: FactType.diagnosis,
    description: 'IF PAT_SYS_EXP (Sistemik + Riwayat/Kontak) THEN P01 — Positif TBC',
  ),

  // P02 — Mungkin TBC
  FCRule(
    id: 'L3_P02_1',
    conditions: ['RESP_STRONG'],
    conclusionId: 'P02',
    conclusionType: FactType.diagnosis,
    description: 'IF RESP_STRONG (Respirasi Khas saja) THEN P02 — Mungkin TBC',
  ),
  FCRule(
    id: 'L3_P02_2',
    conditions: ['SYS_STRONG'],
    conclusionId: 'P02',
    conclusionType: FactType.diagnosis,
    description: 'IF SYS_STRONG (Sistemik Kuat saja) THEN P02 — Mungkin TBC',
  ),
  FCRule(
    id: 'L3_P02_3',
    conditions: ['EXP_STRONG'],
    conclusionId: 'P02',
    conclusionType: FactType.diagnosis,
    description: 'IF EXP_STRONG (Riwayat/Kontak saja) THEN P02 — Mungkin TBC',
  ),
  FCRule(
    id: 'L3_P02_4',
    conditions: ['SUPPORT_MED'],
    conclusionId: 'P02',
    conclusionType: FactType.diagnosis,
    description: 'IF SUPPORT_MED (Pendukung Sedang saja) THEN P02 — Mungkin TBC',
  ),
];

// ─── Fallback gejala (dipakai jika Spreadsheet belum dikonfigurasi) ───────────

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

// ─── Kesimpulan diagnosa ──────────────────────────────────────────────────────

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
