import 'package:flutter/material.dart';

import '../models/symptom_def.dart';
import '../services/forward_chaining_engine.dart';
import '../services/symptom_repository.dart';
import '../theme/app_theme.dart';

class TbDetectionScreen extends StatefulWidget {
  const TbDetectionScreen({
    super.key,
    this.reloadSignal,
    this.onResult,
  });

  final ValueNotifier<int>? reloadSignal;
  final void Function(InferenceResult)? onResult;

  @override
  State<TbDetectionScreen> createState() => _TbDetectionScreenState();
}

class _TbDetectionScreenState extends State<TbDetectionScreen> {
  final _repo = SymptomRepository();
  final _engine = ForwardChainingEngine();

  List<SymptomDef> _symptoms = [];
  final Map<String, double> _userCfs = {};
  bool _loading = true;
  bool _running = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    widget.reloadSignal?.addListener(_onReloadSignal);
    _loadSymptoms();
  }

  @override
  void dispose() {
    widget.reloadSignal?.removeListener(_onReloadSignal);
    super.dispose();
  }

  void _onReloadSignal() => _loadSymptoms(forceRefresh: true);

  Future<void> _loadSymptoms({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final list = await _repo.loadSymptomsForUser(forceRefresh: forceRefresh);
      if (!mounted) return;
      final ids = list.map((s) => s.id).toSet();
      _userCfs.removeWhere((id, _) => !ids.contains(id));
      setState(() {
        _symptoms = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = e.toString();
      });
    }
  }

  Future<void> _runScreening() async {
    setState(() => _running = true);

    final facts = Map<String, double>.from(_userCfs);
    final result = _engine.run(facts, symptoms: _symptoms);

    if (!mounted) return;
    setState(() => _running = false);

    // Simpan hasil ke sheet (fire-and-forget)
    final diagnosaData = {
      'timestamp': DateTime.now().toIso8601String(),
      'id_user': result.conclusionId,
      'hasil_utama_kode': result.conclusion.title,
      'hasil_utama_nilai_cf': '${(result.certainty * 100).toStringAsFixed(1)}%',
      'detail_jawaban_json': result.activeSymptomIds.join(','),
    };
    _repo.saveDiagnosaResult(diagnosaData).catchError((_) {});

    if (widget.onResult != null) {
      widget.onResult!(result);
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _ResultPage(result: result),
        ),
      );
    }
  }

  List<SymptomDef> get _utama =>
      _symptoms.where((s) => s.category == SymptomCategory.utama).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<SymptomDef> get _tambahan =>
      _symptoms.where((s) => s.category == SymptomCategory.tambahan).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadSymptoms(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Skrining Gejala TBC',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.blueBright.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.blueBright.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppTheme.blueBright),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pilih gejala yang Anda rasakan, lalu gulir roda keyakinan '
                          'untuk setiap gejala (Tidak → Sangat Yakin).',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.blueBright,
                                    height: 1.5,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ProgressBar(
                  selected: _userCfs.length,
                  total: _symptoms.length,
                ),
                const SizedBox(height: 24),
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                          color: Color(0xFFDC2626), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_utama.isNotEmpty) ...[
                  const _SectionHeader(
                    icon: Icons.warning_amber_rounded,
                    label: 'Gejala Utama',
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 12),
                  _SymptomGrid(
                    symptoms: _utama,
                    userCfs: _userCfs,
                    onToggle: (id) => setState(() {
                      if (_userCfs.containsKey(id)) {
                        _userCfs.remove(id);
                      } else {
                        _userCfs[id] = 0.8;
                      }
                    }),
                    onCfChanged: (id, cf) => setState(() => _userCfs[id] = cf),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_tambahan.isNotEmpty) ...[
                  const _SectionHeader(
                    icon: Icons.medical_services_outlined,
                    label: 'Gejala Tambahan & Riwayat',
                    color: AppTheme.navy,
                  ),
                  const SizedBox(height: 12),
                  _SymptomGrid(
                    symptoms: _tambahan,
                    userCfs: _userCfs,
                    onToggle: (id) => setState(() {
                      if (_userCfs.containsKey(id)) {
                        _userCfs.remove(id);
                      } else {
                        _userCfs[id] = 0.8;
                      }
                    }),
                    onCfChanged: (id, cf) => setState(() => _userCfs[id] = cf),
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Data Anda diproses secara lokal sesuai standar privasi medis.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Tombol aksi ────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _running
                    ? null
                    : () => setState(() => _userCfs.clear()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_running || _symptoms.isEmpty)
                      ? null
                      : _runScreening,
                  icon: _running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.fact_check_outlined, size: 18),
                  label: Text(_running ? 'Memproses...' : 'Lihat Hasil Skrining'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.selected, required this.total});

  final int selected;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : selected / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gejala dipilih',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF64748B)),
            ),
            Text(
              '$selected dari $total',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.blueBright),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
        ),
      ],
    );
  }
}

class _SymptomGrid extends StatelessWidget {
  const _SymptomGrid({
    required this.symptoms,
    required this.userCfs,
    required this.onToggle,
    required this.onCfChanged,
  });

  final List<SymptomDef> symptoms;
  final Map<String, double> userCfs;
  final void Function(String) onToggle;
  final void Function(String, double) onCfChanged;

  static IconData _iconFor(String id) {
    switch (id) {
      case 'KG1':  return Icons.air_rounded;
      case 'KG2':  return Icons.calendar_month_outlined;
      case 'KG3':  return Icons.bloodtype_outlined;
      case 'KG4':  return Icons.wind_power_outlined;
      case 'KG5':  return Icons.nightlight_outlined;
      case 'KG6':  return Icons.favorite_border_rounded;
      case 'KG7':  return Icons.water_drop_outlined;
      case 'KG8':  return Icons.no_meals_outlined;
      case 'KG9':  return Icons.monitor_weight_outlined;
      case 'KG10': return Icons.battery_0_bar_rounded;
      case 'KG11': return Icons.family_restroom_rounded;
      case 'KG12': return Icons.history_rounded;
      case 'KG13': return Icons.people_outline_rounded;
      case 'KG14': return Icons.vaccines_outlined;
      default:     return Icons.medical_services_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 500 ? 3 : 2;
        final itemWidth = (constraints.maxWidth - 10 * (cols - 1)) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: symptoms.map((s) {
            final cfUser = userCfs[s.id];
            return SizedBox(
              width: itemWidth,
              child: _SymptomCard(
                symptom: s,
                icon: _iconFor(s.id),
                cfUser: cfUser,
                onTap: () => onToggle(s.id),
                onCfChanged: (cf) => onCfChanged(s.id, cf),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({
    required this.symptom,
    required this.icon,
    required this.cfUser,
    required this.onTap,
    required this.onCfChanged,
  });

  final SymptomDef symptom;
  final IconData icon;
  final double? cfUser;
  final VoidCallback onTap;
  final void Function(double) onCfChanged;

  static const _options = [
    (label: 'Sangat Yakin', value: 1.00),
    (label: 'Yakin', value: 0.80),
    (label: 'Cukup Yakin', value: 0.60),
    (label: 'Kurang Yakin', value: 0.40),
    (label: 'Tidak Yakin', value: 0.20),
    (label: 'Tidak', value: 0.00),
  ];

  bool get isSelected => cfUser != null;

  String get _currentLabel {
    if (cfUser == null) return 'Pilih';
    final opt = _options.firstWhere(
      (e) => (e.value - cfUser!).abs() < 0.01,
      orElse: () => _options[1],
    );
    return opt.label;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? AppTheme.navy.withValues(alpha: 0.06)
        : const Color(0xFFF8FAFC);
    final borderColor = isSelected ? AppTheme.navy : const Color(0xFFE2E8F0);
    final iconColor = isSelected ? AppTheme.navy : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.navy.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.navy : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.navy
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              symptom.hint.isNotEmpty ? symptom.hint : symptom.id,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.navy : const Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              symptom.question,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Visibility(
              visible: isSelected,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    height: 8,
                    thickness: 0.5,
                    color: AppTheme.navy.withValues(alpha: 0.15),
                  ),
                  PopupMenuButton<double>(
                    onSelected: onCfChanged,
                    padding: EdgeInsets.zero,
                    tooltip: '',
                    itemBuilder: (_) => _options.map((opt) {
                      final active = cfUser != null &&
                          (opt.value - cfUser!).abs() < 0.01;
                      return PopupMenuItem<double>(
                        value: opt.value,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check,
                              size: 14,
                              color: active
                                  ? AppTheme.navy
                                  : Colors.transparent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${opt.label}  (${opt.value.toStringAsFixed(2)})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: active ? AppTheme.navy : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.navy,
                            ),
                          ),
                          const Icon(
                            Icons.more_horiz,
                            size: 14,
                            color: AppTheme.navy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fallback result page ───────────────────────────────────────────────────────
class _ResultPage extends StatelessWidget {
  const _ResultPage({required this.result});
  final InferenceResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Skrining')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${result.conclusion.title}\n\n'
            'CF: ${(result.certainty * 100).toStringAsFixed(1)}%\n\n'
            '${result.conclusion.action}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
