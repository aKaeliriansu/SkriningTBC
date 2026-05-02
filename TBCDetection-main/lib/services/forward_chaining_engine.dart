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

/// Mesin forward chaining 4-level dengan certainty factor (MYCIN combine).
///
/// Tier logic:
///   Level 1 — cek KG1 (gateway): jika tidak ada → P03
///   Level 2 — cek KG2/KG3 (batuk kronis/berdarah): jika ada → P02 awal
///   Level 3 — gejala pendukung KG4–KG13 tanpa Level 2 → P02
///   Level 4 — gejala pendukung KG4–KG13 setelah Level 2 → P01
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
    final activeIds = <String>[];

    // Hitung CF bukti: CF_user × CF_pakar
    double evidenceCf(String id) {
      final userCf = userSymptomCf[id] ?? 0.0;
      if (userCf < activationThreshold) return 0.0;
      final sym = effectiveSymptoms.where((s) => s.id == id).firstOrNull;
      final pakar = sym?.cfPakar ?? 0.5;
      return (userCf * pakar).clamp(0.0, 1.0);
    }

    // ── Level 1: Apakah ada batuk berdahak (KG1)? ───────────────────────────
    final kg1 = evidenceCf('KG1');
    if (kg1 < activationThreshold) {
      traces.add(const FiredRuleTrace(
        ruleId: 'R1',
        conclusionId: 'P03',
        cfPremise: 0,
        cfAfterExpert: 0,
        description: 'R1: Tidak ada batuk berdahak → Bukan TBC',
      ));
      return _build('P03', 0.0, traces, {'P03': 0.0}, activeIds);
    }
    activeIds.add('KG1');

    // ── Level 2: Batuk kronis (KG2) atau batuk berdarah (KG3) ───────────────
    final kg2 = evidenceCf('KG2');
    final kg3 = evidenceCf('KG3');
    final hasLevel2 = kg2 >= activationThreshold || kg3 >= activationThreshold;

    double mainCf = kg1;
    if (kg2 >= activationThreshold) {
      activeIds.add('KG2');
      mainCf = combinePositive(mainCf, kg2);
      traces.add(FiredRuleTrace(
        ruleId: 'R3',
        conclusionId: 'P02',
        cfPremise: kg2,
        cfAfterExpert: mainCf,
        description: 'R3: KG1 + KG2 (batuk > 2 minggu) → CF=${ mainCf.toStringAsFixed(2)}',
      ));
    }
    if (kg3 >= activationThreshold) {
      activeIds.add('KG3');
      mainCf = combinePositive(mainCf, kg3);
      traces.add(FiredRuleTrace(
        ruleId: 'R4',
        conclusionId: 'P02',
        cfPremise: kg3,
        cfAfterExpert: mainCf,
        description: 'R4: KG1 + KG3 (batuk berdarah) → CF=${mainCf.toStringAsFixed(2)}',
      ));
    }

    // ── Level 3/4: Gejala pendukung KG4–KG13 ─────────────────────────────────
    const supportingIds = [
      'KG4', 'KG5', 'KG6', 'KG7', 'KG8',
      'KG9', 'KG10', 'KG11', 'KG12', 'KG13',
    ];
    double supportingCf = 0.0;
    for (final id in supportingIds) {
      final cf = evidenceCf(id);
      if (cf >= activationThreshold) {
        activeIds.add(id);
        supportingCf = combinePositive(supportingCf, cf);
        traces.add(FiredRuleTrace(
          ruleId: hasLevel2 ? 'R6' : 'R5',
          conclusionId: hasLevel2 ? 'P01' : 'P02',
          cfPremise: cf,
          cfAfterExpert: supportingCf,
          description: '${hasLevel2 ? "R6" : "R5"}: $id → CF_supporting=${supportingCf.toStringAsFixed(2)}',
        ));
      }
    }

    // KG14 (Riwayat Imunisasi BCG) — faktor pendukung ringan
    final kg14 = evidenceCf('KG14');
    if (kg14 >= activationThreshold) {
      activeIds.add('KG14');
      supportingCf = combinePositive(supportingCf, kg14);
      traces.add(FiredRuleTrace(
        ruleId: hasLevel2 ? 'R6' : 'R5',
        conclusionId: hasLevel2 ? 'P01' : 'P02',
        cfPremise: kg14,
        cfAfterExpert: supportingCf,
        description: 'KG14: riwayat imunisasi → CF_supporting=${supportingCf.toStringAsFixed(2)}',
      ));
    }

    // ── Penentuan hasil akhir ──────────────────────────────────────────────────
    if (hasLevel2) {
      if (supportingCf >= activationThreshold) {
        // R6: Level2 + gejala pendukung → P01 Positif TBC
        final finalCf = combinePositive(mainCf, supportingCf);
        return _build('P01', finalCf, traces, {
          'P01': finalCf,
          'P02': mainCf,
        }, activeIds);
      } else {
        // R3/R4 tanpa pendukung → P02 Mungkin TBC
        return _build('P02', mainCf, traces, {'P02': mainCf}, activeIds);
      }
    } else {
      if (supportingCf >= activationThreshold) {
        // R5: KG1 + pendukung → P02 Mungkin TBC
        final finalCf = combinePositive(kg1, supportingCf);
        traces.add(FiredRuleTrace(
          ruleId: 'R5',
          conclusionId: 'P02',
          cfPremise: kg1,
          cfAfterExpert: finalCf,
          description: 'R5: KG1 + gejala pendukung → CF=${finalCf.toStringAsFixed(2)}',
        ));
        return _build('P02', finalCf, traces, {'P02': finalCf}, activeIds);
      } else {
        // R2: Hanya KG1 tanpa gejala lain → P03
        traces.add(FiredRuleTrace(
          ruleId: 'R2',
          conclusionId: 'P03',
          cfPremise: kg1,
          cfAfterExpert: kg1,
          description: 'R2: Hanya batuk biasa tanpa gejala lain → Bukan TBC',
        ));
        return _build('P03', kg1, traces, {'P03': kg1}, activeIds);
      }
    }
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
