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
          _SymptomsSection(),
          _PreventionSection(),
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
                    color: AppTheme.blueBright.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.82),
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
                  ? Colors.white.withOpacity(0.85)
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: items.map((item) => _SymptomInfoCard(item: item)).toList(),
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
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
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              item.desc,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
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
      child: Stack(
        children: [
          const Positioned(
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
              const Text(
                'Strategi Pencegahan\nProaktif.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const _PreventionStep(
                  number: '1',
                  text: 'Jaga ventilasi optimal di ruang tamu dan ruang kerja.'),
              const _PreventionStep(
                  number: '2',
                  text: 'Selesaikan kursus lengkap vaksinasi BCG untuk anak-anak.'),
              const _PreventionStep(
                  number: '3',
                  text: 'Terapkan kebersihan pernapasan standar di tempat umum.'),
              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Unduh Panduan'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Tonton Seminar'),
                  ),
                ],
              ),
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
                color: Colors.white.withOpacity(0.88),
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
