import '../data/knowledge_base.dart';
import '../models/symptom_def.dart';

class FiredRuleTrace {
  const FiredRuleTrace({
    required this.ruleId,
    required this.conclusionId,
    required this.cfPremise,
    required this.cfAfterExpert,
    this.description,
  });

  final String ruleId;
  final String conclusionId;
  final double cfPremise;
  final double cfAfterExpert;
  final String? description;
}

class InferenceResult {
  const InferenceResult({
    required this.conclusionId,
    required this.conclusion,
    required this.certainty,
    required this.traces,
    required this.allConclusionScores,
    this.activeSymptomIds = const [],
  });

  final String conclusionId;
  final ConclusionDef conclusion;
  final double certainty;
  final List<FiredRuleTrace> traces;
  final Map<String, double> allConclusionScores;
  final List<String> activeSymptomIds;
}

/// Mesin forward chaining 10-rule dengan certainty factor (MYCIN combine).
///
/// Semua gejala bersifat opsional. Tidak ada gateway wajib.
/// Gejala dikelompokkan berdasarkan CF Pakar:
///   Respirasi Khas  (CF 0.8): KG2 (batuk kronis), KG3 (batuk berdarah)
///   Sistemik Kuat   (CF 0.8): KG5 (demam malam), KG7 (keringat malam)
///   Riwayat/Kontak  (CF 0.8): KG11 (keluarga TBC), KG13 (kontak TBC)
///   Pendukung Sedang(CF 0.6): KG6 (nyeri dada), KG9 (BB turun), KG12 (riwayat TBC)
///   Gejala Ringan   (CF 0.4): KG1 (batuk), KG4 (sesak), KG8 (nafsu makan), KG10 (lelah)
///   Sangat Ringan   (CF 0.3): KG14 (imunisasi BCG)
///
/// Rumus CF evidence: CF_user × CF_pakar
/// Rumus combine    : CF(A,B) = CF(A) + CF(B) × (1 − CF(A))
class ForwardChainingEngine {
  ForwardChainingEngine({this.activationThreshold = 0.05});

  final double activationThreshold;

  static double combinePositive(double cf1, double cf2) =>
      cf1 + cf2 * (1.0 - cf1);

  InferenceResult run(
    Map<String, double> userSymptomCf, {
    List<SymptomDef>? symptoms,
  }) {
    final effectiveSymptoms = symptoms ?? kFallbackSymptoms;
    final traces = <FiredRuleTrace>[];

    // CF_evidence = CF_user × CF_pakar
    double evidenceCf(String id) {
      final userCf = userSymptomCf[id] ?? 0.0;
      if (userCf < activationThreshold) return 0.0;
      final sym = effectiveSymptoms.where((s) => s.id == id).firstOrNull;
      return (userCf * (sym?.cfPakar ?? 0.5)).clamp(0.0, 1.0);
    }

    // Kumpulkan semua gejala aktif
    final active = <String, double>{};
    for (final s in effectiveSymptoms) {
      final cf = evidenceCf(s.id);
      if (cf >= activationThreshold) active[s.id] = cf;
    }
    final activeIds = active.keys.toList();

    // CF gabungan seluruh gejala aktif (MYCIN sequential combine)
    double cfTotal = 0.0;
    for (final cf in active.values) {
      cfTotal = combinePositive(cfTotal, cf);
    }

    // Helper: tambah trace dan kembalikan hasil
    InferenceResult decide(String ruleId, String conclusionId, String desc) {
      traces.add(FiredRuleTrace(
        ruleId: ruleId,
        conclusionId: conclusionId,
        cfPremise: cfTotal,
        cfAfterExpert: cfTotal,
        description: desc,
      ));
      return _build(conclusionId, cfTotal, traces, {conclusionId: cfTotal}, activeIds);
    }

    bool has(String id) => active.containsKey(id);
    bool hasAnyOf(List<String> ids) => ids.any(has);

    // Klasifikasi kelompok berdasarkan CF Pakar
    final hasRespStrong = hasAnyOf(['KG2', 'KG3']);         // Batuk kronis / berdarah
    final hasSysStrong  = hasAnyOf(['KG5', 'KG7']);         // Demam malam / keringat malam
    final hasExpStrong  = hasAnyOf(['KG11', 'KG13']);        // Riwayat keluarga / kontak TBC
    final hasMedium     = hasAnyOf(['KG6', 'KG9', 'KG12']); // Nyeri dada / BB turun / riwayat TBC
    final weakSet       = {'KG1', 'KG4', 'KG8', 'KG10', 'KG14'};
    final hasWeakOnly   = active.keys.every(weakSet.contains);

    // ── R1: Tidak ada gejala aktif ──────────────────────────────────────────
    if (active.isEmpty) {
      return decide('R1', 'P03', 'R1: Tidak ada gejala aktif → Bukan TBC');
    }

    // ── R2: Hanya gejala ringan (CF_pakar ≤ 0.4) ───────────────────────────
    if (hasWeakOnly) {
      return decide('R2', 'P03',
          'R2: Hanya gejala umum ringan aktif (${activeIds.join(", ")}) → Bukan TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // ── P01: Rules prioritas tinggi ─────────────────────────────────────────

    // R10: Respirasi khas + Sistemik kuat + Riwayat/Kontak kuat
    if (hasRespStrong && hasSysStrong && hasExpStrong) {
      return decide('R10', 'P01',
          'R10: Respirasi khas + sistemik kuat + riwayat/kontak → Positif TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // R9: Respirasi khas + Sistemik kuat
    if (hasRespStrong && hasSysStrong) {
      return decide('R9', 'P01',
          'R9: Respirasi khas (KG2/KG3) + sistemik kuat (KG5/KG7) → Positif TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // R8: Respirasi khas + gejala pendukung sedang atau riwayat/kontak kuat
    if (hasRespStrong && (hasMedium || hasExpStrong)) {
      return decide('R8', 'P01',
          'R8: Respirasi khas + pendukung sedang/riwayat → Positif TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // R7: Sistemik kuat + Riwayat/Kontak kuat (tanpa respirasi khas)
    if (hasSysStrong && hasExpStrong) {
      return decide('R7', 'P01',
          'R7: Sistemik kuat + riwayat/kontak kuat (tanpa respirasi khas) → Positif TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // ── P02: Rules mungkin TBC ──────────────────────────────────────────────

    // R6: Respirasi khas saja (tanpa pendukung kuat lain)
    if (hasRespStrong) {
      return decide('R6', 'P02',
          'R6: Respirasi khas tanpa pendukung kuat → Mungkin TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // R5: Sistemik kuat tanpa respirasi khas
    if (hasSysStrong) {
      return decide('R5', 'P02',
          'R5: Sistemik kuat tanpa respirasi khas → Mungkin TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // R4: Riwayat/kontak kuat tanpa tanda klinis khas
    if (hasExpStrong) {
      return decide('R4', 'P02',
          'R4: Riwayat/kontak kuat tanpa tanda klinis khas → Mungkin TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // R3: Gejala pendukung sedang saja (KG6/KG9/KG12)
    if (hasMedium) {
      return decide('R3', 'P02',
          'R3: Gejala pendukung sedang tanpa tanda khas → Mungkin TBC, CF=${cfTotal.toStringAsFixed(2)}');
    }

    // Fallback (logically unreachable setelah R2 menangkap hasWeakOnly)
    return decide('R2', 'P03', 'R2: Gejala tidak memenuhi kriteria skrining → Bukan TBC');
  }

  InferenceResult _build(
    String id,
    double cf,
    List<FiredRuleTrace> traces,
    Map<String, double> scores,
    List<String> activeIds,
  ) {
    final conclusion = kConclusions[id] ?? kDefaultConclusion;
    return InferenceResult(
      conclusionId: id,
      conclusion: conclusion,
      certainty: cf.clamp(0.0, 1.0),
      traces: List.unmodifiable(traces),
      allConclusionScores: Map.unmodifiable(scores),
      activeSymptomIds: List.unmodifiable(activeIds),
    );
  }
}
