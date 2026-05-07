import 'package:flutter/material.dart';

import '../data/knowledge_base.dart';
import '../services/download_helper.dart';
import '../services/local_settings.dart';
import '../services/symptom_repository.dart';
import '../theme/app_theme.dart';

class AdminSymptomsScreen extends StatefulWidget {
  const AdminSymptomsScreen({super.key});

  @override
  State<AdminSymptomsScreen> createState() => _AdminSymptomsScreenState();
}

class _AdminSymptomsScreenState extends State<AdminSymptomsScreen> {
  final _repo = SymptomRepository();
  final _settings = LocalSettings();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  List<Map<String, dynamic>> _results = [];
  bool _isLoggedIn = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final u = await _settings.getAdminUsername();
    final p = await _settings.getAdminPassword();
    if (mounted) {
      if (u != null) _usernameCtrl.text = u;
      if (p != null) _passwordCtrl.text = p;
    }
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMsg = 'Username wajib diisi.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMsg = 'Password wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final url = await _settings.getWebAppUrl();
      final list = await _repo.loadDiagnosaForAdmin(webAppUrl: url, password: password);
      await _settings.setAdminUsername(username);
      await _settings.setAdminPassword(password);
      if (!mounted) return;
      setState(() {
        _results = list;
        _isLoggedIn = true;
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

  Future<void> _logout() async {
    await _settings.setAdminUsername(null);
    await _settings.setAdminPassword(null);
    setState(() {
      _isLoggedIn = false;
      _results = [];
      _errorMsg = null;
      _usernameCtrl.clear();
      _passwordCtrl.clear();
    });
  }

  void _downloadCsv() {
    const headers =
        'No,Timestamp,Kode Hasil,Judul Diagnosa,Nilai CF,Gejala Aktif';
    final rows = _results.asMap().entries.map((e) {
      final i = e.key + 1;
      final d = e.value;
      String esc(String v) =>
          v.contains(',') || v.contains('"') || v.contains('\n')
              ? '"${v.replaceAll('"', '""')}"'
              : v;
      return [
        '$i',
        esc(d['timestamp'] as String? ?? ''),
        esc(d['id_user'] as String? ?? ''),
        esc(d['hasil_utama_kode'] as String? ?? ''),
        esc(d['hasil_utama_nilai_cf'] as String? ?? ''),
        esc(d['detail_jawaban_json'] as String? ?? ''),
      ].join(',');
    });
    final csv = '$headers\n${rows.join('\n')}';
    final ts = DateTime.now();
    final filename =
        'hasil_diagnosa_${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}.csv';
    downloadCsvFile(csv, filename);
  }

  Future<void> _refresh() async {
    final url = await _settings.getWebAppUrl();
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final list = await _repo.loadDiagnosaForAdmin(
        webAppUrl: url,
        password: _passwordCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _results = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Riwayat Diagnosa'),
        actions: _isLoggedIn
            ? [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loading ? null : _refresh,
                ),
                IconButton(
                  tooltip: 'Unduh CSV',
                  icon: const Icon(Icons.download_rounded),
                  onPressed: (_loading || _results.isEmpty) ? null : _downloadCsv,
                ),
                IconButton(
                  tooltip: 'Keluar',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _logout,
                ),
              ]
            : null,
      ),
      body: _isLoggedIn ? _buildResults() : _buildLoginForm(),
    );
  }

  // ── Login ────────────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.admin_panel_settings_outlined,
              color: AppTheme.navy, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          'Masuk Admin',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Masukkan password admin untuk melihat riwayat hasil diagnosa.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _usernameCtrl,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          autocorrect: false,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordCtrl,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          autocorrect: false,
          onSubmitted: (_) => _loading ? null : _login(),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMsg!,
                      style: const TextStyle(
                          color: Color(0xFFDC2626), fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _login,
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Masuk',
                  style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ── Hasil diagnosa ───────────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Container(
          color: AppTheme.navy.withValues(alpha: 0.04),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.circle,
                  size: 8,
                  color: _loading
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Text(
                _loading
                    ? 'Memperbarui...'
                    : '${_results.length} hasil diagnosa',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (_errorMsg != null)
          Container(
            color: const Color(0xFFFEF2F2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMsg!,
                      style: const TextStyle(
                          color: Color(0xFFDC2626), fontSize: 13)),
                ),
              ],
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada hasil diagnosa.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _DiagnosaCard(data: _results[i]),
                ),
        ),
      ],
    );
  }
}

// ── Diagnosa Card ─────────────────────────────────────────────────────────────

class _DiagnosaCard extends StatelessWidget {
  const _DiagnosaCard({required this.data});

  final Map<String, dynamic> data;

  Color _bg(String id) => switch (id) {
        'P01' => const Color(0xFFFEE2E2),
        'P02' => const Color(0xFFFEF3C7),
        _     => const Color(0xFFDCFCE7),
      };

  Color _textColor(String id) => switch (id) {
        'P01' => const Color(0xFFDC2626),
        'P02' => const Color(0xFFD97706),
        _     => const Color(0xFF16A34A),
      };

  Color _border(String id) => switch (id) {
        'P01' => const Color(0xFFFCA5A5),
        'P02' => const Color(0xFFFCD34D),
        _     => const Color(0xFF86EFAC),
      };

  String _formatTimestamp(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final h   = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$min';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id     = data['id_user']              as String? ?? 'P03';
    final title  = data['hasil_utama_kode']     as String? ?? '-';
    final cfStr  = data['hasil_utama_nilai_cf'] as String? ?? '0%';
    final tsRaw  = data['timestamp']            as String? ?? '';
    final symptomCodes = (data['detail_jawaban_json'] as String? ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final namaMap = {for (final s in kFallbackSymptoms) s.id: s.hint};

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _border(id)),
      ),
      color: _bg(id).withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: timestamp + badge ──────────────────────────────────
            Row(
              children: [
                Text(
                  _formatTimestamp(tsRaw),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _bg(id),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border(id)),
                  ),
                  child: Text(
                    id,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _textColor(id),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Judul + CF ─────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textColor(id),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  cfStr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textColor(id),
                  ),
                ),
              ],
            ),

            // ── Gejala aktif ───────────────────────────────────────────────
            if (symptomCodes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Gejala yang dipilih:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: symptomCodes
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.navy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${namaMap[s] ?? s} ($s)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.navy,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
