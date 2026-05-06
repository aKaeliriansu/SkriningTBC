import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class TbInfoScreen extends StatelessWidget {
  const TbInfoScreen({super.key, this.onStartScreening});

  final VoidCallback? onStartScreening;

  static final _kemenkesUri =
      Uri.parse('https://www.kemkes.go.id/');

  Future<void> _openKemenkes(BuildContext context) async {
    try {
      final ok =
          await launchUrl(_kemenkesUri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroSection(onStartScreening: onStartScreening),
          _StatsSection(),
          _WhatIsTbcSection(),
          _SymptomsSection(),
          _TransmissionSection(),
          _RiskGroupsSection(),
          _DiagnosisSection(),
          _PreventionSection(),
          _LivingWithTbcSection(),
          _DisclaimerSection(),
          _CtaSection(onStartScreening: onStartScreening),
          _Footer(onKemenkesTap: () => _openKemenkes(context)),
        ],
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({this.onStartScreening});
  final VoidCallback? onStartScreening;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1E3D), Color(0xFF1B3A6B), Color(0xFF1E4D8C)],
        ),
      ),
      child: Stack(
        children: [
          // Dekorasi latar
          const Positioned(
            right: -40,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.medical_information_rounded,
                size: 260,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.blueBright.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'WAWASAN MEDIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memahami\nTuberkulosis:\nPanduan Modern.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Deteksi dini adalah kunci pengobatan yang efektif. '
                  'Pelajari bagaimana skrining TBC dapat memberdayakan '
                  'perjalanan kesehatan Anda melalui wawasan profesional.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onStartScreening,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Mulai Skrining'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.navy,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 560;
          if (wide) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _JangkauanText()),
                SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(value: '95%', caption: 'TINGKAT KESEMBUHAN DENGAN INTERVENSI DINI', highlighted: true)),
                      SizedBox(width: 10),
                      Expanded(child: _StatCard(value: '15 mnt', caption: 'WAKTU PENILAIAN DIGITAL', highlighted: false)),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Column(
            children: [
              _JangkauanText(),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatCard(value: '95%', caption: 'TINGKAT KESEMBUHAN\nDENGAN INTERVENSI DINI', highlighted: true)),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(value: '15 mnt', caption: 'WAKTU PENILAIAN\nDIGITAL', highlighted: false)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JangkauanText extends StatelessWidget {
  const _JangkauanText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jangkauan Global',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tuberkulosis tetap menjadi prioritas kesehatan global yang '
          'signifikan. Tujuan kami adalah menyediakan skrining yang '
          'dapat diakses oleh setiap rumah tangga.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: '10JT+',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy,
                ),
              ),
              TextSpan(
                text: '  KASUS PER TAHUN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.caption,
    required this.highlighted,
  });

  final String value;
  final String caption;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.blueBright : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted)
            const Icon(Icons.verified_outlined, size: 18, color: Colors.white)
          else
            const Icon(Icons.schedule_outlined, size: 18, color: Color(0xFF64748B)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: highlighted ? Colors.white : AppTheme.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: highlighted
                  ? Colors.white.withValues(alpha: 0.85)
                  : const Color(0xFF94A3B8),
              letterSpacing: 0.3,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Symptoms info ─────────────────────────────────────────────────────────────

class _SymptomsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mengenali Gejala.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
          ),
          const SizedBox(height: 16),
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _SymptomInfoText()),
                    const SizedBox(width: 20),
                    const Expanded(flex: 4, child: _SymptomCards()),
                  ],
                )
              : Column(
                  children: [
                    _SymptomInfoText(),
                    const SizedBox(height: 16),
                    const _SymptomCards(),
                  ],
                ),
        ],
      ),
    );
  }
}

class _SymptomInfoText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gejala TB bisa sangat halus. Mengidentifikasi indikator '
          'awal ini sangat penting untuk diagnosis dan pemulihan yang efektif.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Segera Cari Konsultasi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jika Anda mengalami batuk terus-menerus selama lebih dari 3 minggu.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFB45309),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SymptomCards extends StatelessWidget {
  const _SymptomCards();

  @override
  Widget build(BuildContext context) {
    const items = [
      _SymptomItem(
        icon: Icons.air_rounded,
        title: 'Batuk Terus-menerus',
        desc: 'Batuk berkepanjangan yang mungkin menghasilkan dahak atau darah adalah indikator yang paling umum.',
        color: Color(0xFF2563EB),
      ),
      _SymptomItem(
        icon: Icons.thermostat_outlined,
        title: 'Demam Berulang',
        desc: 'Demam ringan yang tidak dapat dijelaskan, terutama di malam hari atau saat tidur.',
        color: Color(0xFFDC2626),
      ),
      _SymptomItem(
        icon: Icons.nightlight_outlined,
        title: 'Keringat Malam',
        desc: 'Keringat berlebih di malam hari, seringkali cukup parah hingga membasahi tempat tidur.',
        color: Color(0xFF7C3AED),
      ),
      _SymptomItem(
        icon: Icons.monitor_weight_outlined,
        title: 'Penurunan Berat Badan',
        desc: 'Penurunan nafsu makan dan berat badan yang cepat dan tidak dapat dijelaskan dalam waktu singkat.',
        color: Color(0xFFD97706),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => SizedBox(
                    width: itemWidth,
                    child: _SymptomInfoCard(item: item),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _SymptomItem {
  const _SymptomItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
}

class _SymptomInfoCard extends StatelessWidget {
  const _SymptomInfoCard({required this.item});
  final _SymptomItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.desc,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Prevention ────────────────────────────────────────────────────────────────

class _PreventionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1E3D), Color(0xFF1B3A6B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.shield_rounded, size: 180, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Strategi Pencegahan\nProaktif.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 20),
              _PreventionStep(
                  number: '1',
                  text: 'Jaga ventilasi optimal di ruang tamu dan ruang kerja.'),
              _PreventionStep(
                  number: '2',
                  text: 'Selesaikan kursus lengkap vaksinasi BCG untuk anak-anak.'),
              _PreventionStep(
                  number: '3',
                  text: 'Terapkan kebersihan pernapasan standar di tempat umum.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreventionStep extends StatelessWidget {
  const _PreventionStep({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.blueBright,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA ───────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection({this.onStartScreening});
  final VoidCallback? onStartScreening;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        children: [
          Text(
            'Siap untuk memeriksa\nstatus risiko Anda?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Alat skrining tingkat klinis kami memberikan analisis segera '
            'berdasarkan gejala dan riwayat Anda.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 20,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              _FeatureChip(label: 'Cepat, Aman & Privat.'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStartScreening,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: const Text('Mulai Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 14, color: Color(0xFF16A34A)),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
        ),
      );
}

class _InfoExpansion extends StatelessWidget {
  const _InfoExpansion({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {this.bold = false});
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child:
                Icon(Icons.circle, size: 5, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: const Color(0xFF475569),
                fontWeight:
                    bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MythCard extends StatelessWidget {
  const _MythCard({required this.myth, required this.fact});
  final String myth;
  final String fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFFDC2626)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(myth,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_rounded,
                size: 14, color: Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(fact,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF166534),
                      height: 1.4)),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Apa itu TBC ───────────────────────────────────────────────────────────────

class _WhatIsTbcSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Apa itu TBC?'),
          _InfoExpansion(
            icon: Icons.info_outline_rounded,
            title: 'Definisi & Fakta Dasar',
            color: Color(0xFF2563EB),
            children: [
              _Bullet(
                  'Tuberkulosis (TBC) adalah penyakit infeksi menular yang disebabkan oleh bakteri Mycobacterium tuberculosis.'),
              _Bullet(
                  'TBC adalah salah satu penyakit infeksi penyebab kematian terbanyak di dunia — lebih dari 10 juta orang terinfeksi setiap tahun.'),
              _Bullet(
                  'Indonesia termasuk negara dengan beban TBC tertinggi ke-2 di dunia.'),
              _Bullet(
                  'TBC dapat disembuhkan jika diobati tuntas dengan paduan OAT (Obat Anti Tuberkulosis) selama 6 bulan.'),
            ],
          ),
          _InfoExpansion(
            icon: Icons.category_outlined,
            title: 'Jenis-jenis TBC',
            color: Color(0xFF7C3AED),
            children: [
              _Bullet('TBC Paru — menyerang jaringan paru-paru, paling umum dan menular.',
                  bold: true),
              _Bullet(
                  'TBC Ekstra Paru — menyerang organ lain seperti kelenjar getah bening, tulang, otak, ginjal, atau kulit.'),
              _Bullet('TBC Laten — bakteri ada di tubuh tetapi tidak aktif, tidak menular, dan tidak bergejala.'),
              _Bullet('TBC Aktif — bakteri aktif berkembang, menimbulkan gejala, dan dapat menularkan ke orang lain.'),
              _Bullet('TBC Resistan Obat (TB-RO / MDR-TB) — terjadi akibat pengobatan yang tidak tuntas atau tidak teratur.'),
            ],
          ),
        ],
      );
}

// ── Cara Penularan ────────────────────────────────────────────────────────────

class _TransmissionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Cara Penularan'),
          _InfoExpansion(
            icon: Icons.air_rounded,
            title: 'Bagaimana TBC menular?',
            color: Color(0xFFDC2626),
            children: [
              _Bullet(
                  'TBC menular melalui udara — saat penderita batuk, bersin, atau berbicara, droplet berisi bakteri terhirup orang lain.'),
              _Bullet(
                  'Penularan lebih mudah terjadi di ruangan tertutup, sempit, dan tidak berventilasi baik.'),
              _Bullet(
                  'Paparan berulang jangka panjang dengan penderita TBC aktif meningkatkan risiko tertular.'),
              _Bullet(
                  'Tidak semua yang terpapar langsung tertular — sistem imun tubuh berperan penting.'),
            ],
          ),
          _InfoExpansion(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Mitos vs Fakta Penularan',
            color: Color(0xFFD97706),
            children: [
              _MythCard(
                myth: 'TBC menular lewat sentuhan tangan atau berbagi peralatan makan.',
                fact: 'TBC hanya menular lewat udara (droplet pernapasan), bukan kontak fisik atau berbagi alat makan.',
              ),
              _MythCard(
                myth: 'Penderita TBC harus diisolasi total dari keluarga.',
                fact: 'Setelah 2 minggu pengobatan teratur, penderita umumnya tidak lagi menularkan dan bisa beraktivitas normal.',
              ),
              _MythCard(
                myth: 'TBC adalah penyakit turunan/keturunan.',
                fact: 'TBC adalah penyakit infeksi bakteri, bukan penyakit genetik. Siapa pun bisa tertular.',
              ),
              _MythCard(
                myth: 'Batuk darah pasti TBC.',
                fact: 'Batuk darah bisa disebabkan banyak kondisi lain. Diagnosis TBC harus dikonfirmasi oleh tenaga kesehatan.',
              ),
            ],
          ),
        ],
      );
}

// ── Kelompok Berisiko ─────────────────────────────────────────────────────────

class _RiskGroupsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Kelompok Berisiko Tinggi'),
          _InfoExpansion(
            icon: Icons.group_outlined,
            title: 'Siapa yang lebih rentan?',
            color: Color(0xFFD97706),
            children: [
              _Bullet('Kontak erat dengan penderita TBC aktif (anggota keluarga serumah).'),
              _Bullet('Orang dengan sistem imun lemah: penderita HIV/AIDS, diabetes, kanker, atau yang menjalani kemoterapi.'),
              _Bullet('Anak-anak di bawah 5 tahun dan lansia di atas 65 tahun.'),
              _Bullet('Petugas kesehatan yang sering terpapar pasien TBC.'),
              _Bullet('Penghuni fasilitas padat: penjara, asrama, panti jompo.'),
              _Bullet('Perokok aktif dan pecandu alkohol.'),
              _Bullet('Orang yang mengalami malnutrisi atau kekurangan gizi.'),
              _Bullet('Penduduk daerah dengan prevalensi TBC tinggi.'),
            ],
          ),
        ],
      );
}

// ── Diagnosis & Pemeriksaan ───────────────────────────────────────────────────

class _DiagnosisSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Diagnosis & Pemeriksaan'),
          const _InfoExpansion(
            icon: Icons.biotech_outlined,
            title: 'Cara dokter mendiagnosis TBC',
            color: Color(0xFF0891B2),
            children: [
              _Bullet('Anamnesis (wawancara gejala) — dokter menanyakan keluhan, riwayat kontak, dan riwayat pengobatan sebelumnya.'),
              _Bullet('Pemeriksaan dahak (sputum BTA) — gold standard untuk TBC paru, dilakukan 2 kali pada hari berbeda.'),
              _Bullet('Foto Rontgen dada (X-ray thorax) — mendeteksi kelainan pada paru-paru.'),
              _Bullet('Tes cepat molekuler (TCM/GeneXpert) — lebih akurat dan cepat, juga mendeteksi resistansi obat.'),
              _Bullet('Uji tuberkulin (Mantoux test) — digunakan terutama pada anak dan untuk mendeteksi TBC laten.'),
              _Bullet('Pemeriksaan darah lengkap — sebagai data pendukung.'),
            ],
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_hospital_outlined,
                    size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pemeriksaan TBC tersedia GRATIS di Puskesmas dan fasilitas kesehatan pemerintah di seluruh Indonesia melalui program TOSS-TBC.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1D4ED8),
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

// ── Hidup dengan TBC ──────────────────────────────────────────────────────────

class _LivingWithTbcSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Menghadapi & Hidup dengan TBC'),
          _InfoExpansion(
            icon: Icons.favorite_border_rounded,
            title: 'Sisi Fisik — Selama Pengobatan',
            color: Color(0xFFDC2626),
            children: [
              _Bullet('Minum OAT setiap hari tanpa putus selama 6 bulan sesuai petunjuk dokter — ini sangat penting untuk sembuh dan mencegah resistansi obat.'),
              _Bullet('Gunakan masker saat berinteraksi dengan orang lain, terutama pada 2 minggu pertama pengobatan.'),
              _Bullet('Buka jendela dan ventilasi rumah setiap hari agar udara segar bersirkulasi.'),
              _Bullet('Makan bergizi seimbang — protein cukup (telur, ikan, kacang) membantu pemulihan.'),
              _Bullet('Istirahat cukup dan hindari kelelahan berlebihan.'),
              _Bullet('Rutin kontrol ke fasilitas kesehatan sesuai jadwal untuk memantau kemajuan pengobatan.'),
            ],
          ),
          _InfoExpansion(
            icon: Icons.psychology_outlined,
            title: 'Sisi Mental & Emosional',
            color: Color(0xFF7C3AED),
            children: [
              _Bullet('Perasaan cemas, sedih, atau takut adalah hal yang wajar — jangan sembunyikan perasaan tersebut.'),
              _Bullet('Ceritakan kondisi Anda kepada orang yang dipercaya; dukungan keluarga sangat berpengaruh pada keberhasilan pengobatan.'),
              _Bullet('Bergabung dengan komunitas pasien TBC dapat membantu mengurangi rasa sendirian dalam menghadapi penyakit.'),
              _Bullet('Jaga rutinitas harian sejauh kemampuan fisik memungkinkan — tetap produktif membantu kondisi mental.'),
            ],
          ),
          _InfoExpansion(
            icon: Icons.handshake_outlined,
            title: 'Melawan Stigma',
            color: Color(0xFF16A34A),
            children: [
              _Bullet('TBC bukan aib — ini adalah penyakit menular biasa yang dapat dialami siapa saja dan BISA disembuhkan.'),
              _Bullet('Pasien TBC yang sudah minum obat 2 minggu umumnya tidak lagi menularkan penyakit.'),
              _Bullet('Jangan mengucilkan penderita TBC — dukungan sosial justru mempercepat pemulihan.'),
              _Bullet('Edukasi keluarga dan lingkungan sekitar bahwa TBC tidak menular lewat sentuhan, berbagi makanan, atau sekadar berdekatan.'),
              _Bullet('Hak penderita TBC tetap terlindungi — mereka berhak bekerja, bersekolah, dan bersosialisasi selama mematuhi aturan pengobatan.'),
            ],
          ),
        ],
      );
}

// ── Disclaimer ────────────────────────────────────────────────────────────────

class _DisclaimerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_rounded, size: 18, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text(
                'Disclaimer Penting',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Hasil skrining pada aplikasi ini BUKAN merupakan diagnosis medis. '
            'Skrining ini hanya bersifat informatif sebagai deteksi awal berdasarkan gejala yang Anda laporkan sendiri.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF92400E),
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apapun hasil skrining Anda — baik berisiko tinggi maupun rendah — segera konsultasikan ke tenaga kesehatan '
            '(dokter, Puskesmas, atau rumah sakit) untuk pemeriksaan dan diagnosis lebih lanjut.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF92400E),
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.onKemenkesTap});
  final VoidCallback onKemenkesTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 16, color: AppTheme.blueBright),
              SizedBox(width: 8),
              Text(
                'TBC Screening App',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '© aKaeliriansu',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Kebijakan Privasi',
                    style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Syarat Layanan',
                    style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: onKemenkesTap,
                child: const Text('Dukungan',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
