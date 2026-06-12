import '../data/knowledge_base.dart';
import '../models/symptom_def.dart';

// ─── Output types (tidak berubah — kompatibel dengan result_screen.dart) ──────

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

// ─── Working Memory fact (internal) ──────────────────────────────────────────

class _WMFact {
  const _WMFact({required this.id, required this.type, required this.cf});

  final String id;
  final FactType type;
  final double cf;

  _WMFact withCf(double newCf) => _WMFact(id: id, type: type, cf: newCf);
}

// ─── Mesin Forward Chaining berbasis Working Memory ───────────────────────────
//
// Alur eksekusi:
//   1. WM diinisialisasi dengan fakta gejala: CF_evidence = CF_user × CF_pakar.
//   2. Agenda loop: iterasi seluruh kFCRules; setiap rule yang semua kondisinya
//      ada di WM akan menyala dan menambah / memperbarui fakta baru ke WM.
//      Setiap rule hanya menyala SATU KALI (dicatat di `fired`).
//      Loop berhenti saat tidak ada rule baru yang menyala (fixed-point).
//   3. Konklusi dipilih berdasarkan prioritas: P01 > P02 > P03.
//
// CF semantics:
//   • AND (multi-kondisi) : premis = min(CF kondisi-kondisi)
//   • OR                  : dimodelkan sebagai rule terpisah per gejala;
//                           engine menggunakan MYCIN combine saat menulis ke
//                           fakta yang sama lebih dari sekali.
//   • Combine (MYCIN)     : CF(A,B) = CF_A + CF_B × (1 − CF_A)
class ForwardChainingEngine {
  ForwardChainingEngine({this.activationThreshold = 0.05});

  final double activationThreshold;

  static double _combine(double a, double b) => a + b * (1.0 - a);

  static double _andCf(List<double> cfs) =>
      cfs.reduce((a, b) => a < b ? a : b);

  InferenceResult run(
    Map<String, double> userSymptomCf, {
    List<SymptomDef>? symptoms,
  }) {
    final effectiveSymptoms = symptoms ?? kFallbackSymptoms;

    // ── 1. Init WM dengan fakta gejala ──────────────────────────────────────
    final wm = <String, _WMFact>{};
    for (final sym in effectiveSymptoms) {
      final userCf = userSymptomCf[sym.id] ?? 0.0;
      if (userCf < activationThreshold) continue;
      final evidenceCf = (userCf * sym.cfPakar).clamp(0.0, 1.0);
      if (evidenceCf >= activationThreshold) {
        wm[sym.id] = _WMFact(id: sym.id, type: FactType.symptom, cf: evidenceCf);
      }
    }

    // ── 2. Agenda loop ───────────────────────────────────────────────────────
    final traces = <FiredRuleTrace>[];
    final fired = <String>{};
    bool changed = true;

    while (changed) {
      changed = false;
      for (final rule in kFCRules) {
        if (fired.contains(rule.id)) continue;

        // Kumpulkan CF kondisi; batalkan jika ada yang tidak terpenuhi
        final condCfs = <double>[];
        var allMet = true;
        for (final cond in rule.conditions) {
          final fact = wm[cond];
          if (fact == null || fact.cf < activationThreshold) {
            allMet = false;
            break;
          }
          condCfs.add(fact.cf);
        }
        if (!allMet) continue;

        // CF premis: min untuk AND; nilai tunggal untuk kondisi tunggal
        final premiseCf = condCfs.length == 1
            ? condCfs.first
            : _andCf(condCfs);

        // Tulis fakta ke WM: baru atau gabung MYCIN jika sudah ada
        final existing = wm[rule.conclusionId];
        final updatedCf = existing == null
            ? premiseCf
            : _combine(existing.cf, premiseCf);

        wm[rule.conclusionId] = _WMFact(
          id: rule.conclusionId,
          type: rule.conclusionType,
          cf: updatedCf,
        );

        fired.add(rule.id);
        changed = true;

        traces.add(FiredRuleTrace(
          ruleId: rule.id,
          conclusionId: rule.conclusionId,
          cfPremise: premiseCf,
          cfAfterExpert: updatedCf,
          description: rule.description ??
              'IF ${rule.conditions.join(' ∧ ')} THEN ${rule.conclusionId} '
              '(CF_premis=${premiseCf.toStringAsFixed(2)}, '
              'CF_hasil=${updatedCf.toStringAsFixed(2)})',
        ));
      }
    }

    // ── 3. Pilih konklusi berprioritas P01 > P02 > P03 ──────────────────────
    String conclusionId = 'P03';
    double certainty = 0.0;

    for (final p in const ['P01', 'P02']) {
      final fact = wm[p];
      if (fact != null && fact.cf >= activationThreshold) {
        conclusionId = p;
        certainty = fact.cf;
        break;
      }
    }

    if (conclusionId == 'P03') {
      // Tidak ada P01/P02 → P03 sebagai default.
      // CF P03: gabungan seluruh gejala aktif (menunjukkan seberapa banyak
      // gejala yang dilaporkan, meskipun tidak memenuhi pola TBC).
      double fallbackCf = 0.0;
      for (final f in wm.values.where((f) => f.type == FactType.symptom)) {
        fallbackCf = _combine(fallbackCf, f.cf);
      }
      certainty = wm['P03']?.cf ?? fallbackCf;
    }

    final activeIds = wm.values
        .where((f) => f.type == FactType.symptom)
        .map((f) => f.id)
        .toList();

    final allScores = <String, double>{
      'P01': wm['P01']?.cf ?? 0.0,
      'P02': wm['P02']?.cf ?? 0.0,
      'P03': conclusionId == 'P03' ? certainty : (wm['P03']?.cf ?? 0.0),
    };

    return InferenceResult(
      conclusionId: conclusionId,
      conclusion: kConclusions[conclusionId] ?? kDefaultConclusion,
      certainty: certainty.clamp(0.0, 1.0),
      traces: List.unmodifiable(traces),
      allConclusionScores: Map.unmodifiable(allScores),
      activeSymptomIds: List.unmodifiable(activeIds),
    );
  }
}
