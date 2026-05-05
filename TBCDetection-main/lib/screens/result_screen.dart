import 'package:flutter/material.dart';

import '../data/knowledge_base.dart';
import '../services/forward_chaining_engine.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.onRetry,
  });

  final InferenceResult result;
  final VoidCallback onRetry;

  // ── Helpers ────────────────────────────────────────────────────────────────

  _LevelStyle get _style {
    switch (result.conclusionId) {
      case 'P01':
        return const _LevelStyle(
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFDC2626),
          iconBg: Color(0xFFFEE2E2),
          chipLabel: 'HIGH CERTAINTY',
          chipColor: Color(0xFFDC2626),
          accentColor: Color(0xFFDC2626),
        );
      case 'P02':
        return const _LevelStyle(
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFF2563EB),
          iconBg: Color(0xFFDBEAFE),
          chipLabel: 'MODERATELY HIGH CERTAINTY',
          chipColor: Color(0xFF2563EB),
          accentColor: Color(0xFF2563EB),
        );
      default:
        return const _LevelStyle(
          icon: Icons.check_circle_outline_rounded,
          iconColor: Color(0xFF16A34A),
          iconBg: Color(0xFFDCFCE7),
          chipLabel: 'LOW RISK',
          chipColor: Color(0xFF16A34A),
          accentColor: Color(0xFF16A34A),
        );
    }
  }

  String get _certaintyLabel {
    final pct = (result.certainty * 100).round();
    if (pct == 0) return 'TIDAK ADA INDIKASI';
    if (pct < 30) return 'LOW CERTAINTY';
    if (pct < 50) return 'MODERATELY LOW CERTAINTY';
    if (pct < 70) return 'MODERATELY HIGH CERTAINTY';
    if (pct < 90) return 'HIGH CERTAINTY';
    return 'VERY HIGH CERTAINTY';
  }

  String _buildAnalysisText() {
    final pct = (result.certainty * 100).round();
    final ids = result.activeSymptomIds;
    if (ids.isEmpty) {
      return 'Tidak ada gejala yang dipilih. Sistem tidak dapat melakukan '
          'penilaian risiko. Silakan isi skrining terlebih dahulu.';
    }
    final namaMap = {for (final s in kFallbackSymptoms) s.id: s.hint};
    final namaList = ids.map((id) => namaMap[id] ?? id).toList();
    final gejalaTeks = namaList.length == 1
        ? namaList.first.toLowerCase()
        : '${namaList.sublist(0, namaList.length - 1).map((e) => e.toLowerCase()).join(', ')} dan ${namaList.last.toLowerCase()}';

    switch (result.conclusionId) {
      case 'P01':
        return 'Berdasarkan algoritma forward chaining dan perhitungan '
            'certainty factor, kombinasi gejala yang Anda input ($gejalaTeks) '
            'menunjukkan tingkat keyakinan klinis sebesar $pct% terhadap '
            'indikasi Tuberkulosis aktif. Kondisi ini memerlukan evaluasi '
            'medis segera untuk memastikan diagnosis akurat.';
      case 'P02':
        return 'Berdasarkan algoritma forward chaining dan perhitungan '
            'certainty factor, kombinasi gejala yang Anda input ($gejalaTeks) '
            'menunjukkan tingkat keyakinan klinis sebesar $pct% terhadap '
            'indikasi awal Tuberkulosis. Kondisi ini memerlukan evaluasi '
            'medis lebih lanjut untuk memastikan diagnosis akurat.';
      default:
        return 'Berdasarkan algoritma forward chaining dan certainty factor, '
            'gejala yang Anda laporkan ($gejalaTeks) tidak membentuk pola '
            'yang kuat untuk indikasi Tuberkulosis saat ini. '
            'Tetap pantau kondisi Anda.';
    }
  }

  List<_ActionItem> get _actions {
    switch (result.conclusionId) {
      case 'P01':
        return const [
          _ActionItem(
            icon: Icons.local_hospital_outlined,
            title: 'Kunjungi Puskesmas atau Dokter',
            desc: 'Lakukan konsultasi tatap muka dalam 1–2 hari ke depan '
                'untuk pemeriksaan fisik paru secara menyeluruh.',
          ),
          _ActionItem(
            icon: Icons.science_outlined,
            title: 'Tes Dahak (TCM)',
            desc: 'Minta pemeriksaan Tes Cepat Molekuler (TCM) sebagai '
                'standar emas pendeteksian bakteri Mycobacterium tuberculosis.',
          ),
          _ActionItem(
            icon: Icons.masks_outlined,
            title: 'Gunakan Masker di Area Publik',
            desc: 'Gunakan masker medis untuk mencegah potensi penularan '
                'droplet kepada keluarga atau orang di sekitar Anda.',
          ),
          _ActionItem(
            icon: Icons.home_outlined,
            title: 'Isolasi Sementara',
            desc: 'Batasi kontak erat dengan orang lain, terutama lansia '
                'dan anak-anak, hingga diagnosis dipastikan.',
          ),
        ];
      case 'P02':
        return const [
          _ActionItem(
            icon: Icons.medical_services_outlined,
            title: 'Kunjungi Puskesmas atau Dokter',
            desc: 'Lakukan konsultasi tatap muka dalam 2–3 hari ke depan '
                'untuk pemeriksaan fisik paru secara menyeluruh.',
          ),
          _ActionItem(
            icon: Icons.science_outlined,
            title: 'Tes Dahak (TCM)',
            desc: 'Minta pemeriksaan Tes Cepat Molekuler (TCM) sebagai '
                'standar emas pendeteksian bakteri Mycobacterium tuberculosis.',
          ),
          _ActionItem(
            icon: Icons.masks_outlined,
            title: 'Gunakan Masker di Area Publik',
            desc: 'Gunakan masker medis untuk mencegah potensi penularan '
                'droplet kepada keluarga atau orang di sekitar Anda.',
          ),
        ];
      default:
        return const [
          _ActionItem(
            icon: Icons.favorite_border_rounded,
            title: 'Jaga Pola Hidup Sehat',
            desc: 'Konsumsi gizi seimbang, olahraga teratur, dan pastikan '
                'ventilasi ruangan yang baik.',
          ),
          _ActionItem(
            icon: Icons.monitor_heart_outlined,
            title: 'Pantau Kondisi Tubuh',
            desc: 'Perhatikan perubahan gejala, terutama batuk yang bertambah '
                'lama atau gejala baru yang muncul.',
          ),
          _ActionItem(
            icon: Icons.medical_services_outlined,
            title: 'Konsultasi Jika Gejala Bertambah',
            desc: 'Segera ke fasilitas kesehatan jika gejala memburuk atau '
                'Anda memiliki kontak dengan penderita TBC.',
          ),
        ];
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final pct = (result.certainty * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: onRetry,
        ),
        title: const Text('Hasil Skrining'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: wide
                ? _WideLayout(
                    style: style,
                    pct: pct,
                    certaintyLabel: _certaintyLabel,
                    analysisText: _buildAnalysisText(),
                    actions: _actions,
                    result: result,
                    onRetry: onRetry,
                  )
                : _NarrowLayout(
                    style: style,
                    pct: pct,
                    certaintyLabel: _certaintyLabel,
                    analysisText: _buildAnalysisText(),
                    actions: _actions,
                    result: result,
                    onRetry: onRetry,
                  ),
          );
        },
      ),
    );
  }
}

// ── Layout variants ───────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.style,
    required this.pct,
    required this.certaintyLabel,
    required this.analysisText,
    required this.actions,
    required this.result,
    required this.onRetry,
  });

  final _LevelStyle style;
  final int pct;
  final String certaintyLabel;
  final String analysisText;
  final List<_ActionItem> actions;
  final InferenceResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(style: style, pct: pct, certaintyLabel: certaintyLabel, result: result),
        const SizedBox(height: 24),
        _MainContent(
          style: style,
          analysisText: analysisText,
          actions: actions,
          result: result,
        ),
        const SizedBox(height: 24),
        _BottomButtons(onRetry: onRetry),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.style,
    required this.pct,
    required this.certaintyLabel,
    required this.analysisText,
    required this.actions,
    required this.result,
    required this.onRetry,
  });

  final _LevelStyle style;
  final int pct;
  final String certaintyLabel;
  final String analysisText;
  final List<_ActionItem> actions;
  final InferenceResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(style: style, pct: pct, certaintyLabel: certaintyLabel, result: result),
        const SizedBox(height: 20),
        _MainContent(
          style: style,
          analysisText: analysisText,
          actions: actions,
          result: result,
        ),
        const SizedBox(height: 24),
        _BottomButtons(onRetry: onRetry),
      ],
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.style,
    required this.pct,
    required this.certaintyLabel,
    required this.result,
  });

  final _LevelStyle style;
  final int pct;
  final String certaintyLabel;
  final InferenceResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: style.iconBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(style.icon, color: style.iconColor, size: 38),
        ),
        const SizedBox(height: 16),
        Text(
          result.conclusion.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: style.chipColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            pct > 0 ? '$certaintyLabel  •  $pct%' : certaintyLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: style.chipColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.style,
    required this.analysisText,
    required this.actions,
    required this.result,
  });

  final _LevelStyle style;
  final String analysisText;
  final List<_ActionItem> actions;
  final InferenceResult result;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Analisis Sistem Pakar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 20, color: style.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Analisis Sistem Pakar',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _HighlightText(
                text: analysisText,
                accentColor: style.accentColor,
                pct: (result.certainty * 100).round(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rekomendasi Tindakan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 20, color: style.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Rekomendasi Tindakan',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...actions.map((a) => _ActionTile(item: a, accentColor: style.accentColor)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Jejak aturan (collapsed)
        if (result.traces.isNotEmpty)
          _TraceExpansion(result: result),
        const SizedBox(height: 16),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catatan: Hasil ini adalah alat bantu skrining awal berbasis '
                  'kecerdasan buatan dan bukan merupakan diagnosis medis final. '
                  'Segera hubungi tenaga kesehatan profesional untuk verifikasi klinis.',
                  style: t.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomButtons extends StatelessWidget {
  const _BottomButtons({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Ulangi Skrining'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item, required this.accentColor});

  final _ActionItem item;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceExpansion extends StatelessWidget {
  const _TraceExpansion({required this.result});
  final InferenceResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          'Jejak Aturan Forward Chaining',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: result.traces.map((t) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.ruleId,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.description ?? '${t.ruleId} → ${t.conclusionId} '
                        '(CF=${t.cfAfterExpert.toStringAsFixed(2)})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Render teks dengan persentase di-highlight
class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.text,
    required this.accentColor,
    required this.pct,
  });

  final String text;
  final Color accentColor;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final highlight = '$pct%';
    final idx = text.indexOf(highlight);
    if (idx < 0 || pct == 0) {
      return Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(height: 1.6, color: const Color(0xFF374151)),
      );
    }
    return RichText(
      text: TextSpan(
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(height: 1.6, color: const Color(0xFF374151)),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: highlight,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: accentColor,
              decoration: TextDecoration.underline,
              decorationColor: accentColor,
            ),
          ),
          TextSpan(text: text.substring(idx + highlight.length)),
        ],
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────

class _LevelStyle {
  const _LevelStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.chipLabel,
    required this.chipColor,
    required this.accentColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String chipLabel;
  final Color chipColor;
  final Color accentColor;
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;
}
