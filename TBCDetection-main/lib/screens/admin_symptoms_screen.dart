import 'package:flutter/material.dart';

import '../models/symptom_def.dart';
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

  List<SymptomDef> _items = [];
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
    final username = await _settings.getAdminUsername();
    final password = await _settings.getAdminPassword();
    if (!mounted) return;
    setState(() {
      if (username != null) _usernameCtrl.text = username;
      if (password != null) _passwordCtrl.text = password;
    });
  }

  Future<String> _getUrl() => _settings.getWebAppUrl();

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Username dan password wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final url = await _getUrl();
      final list = await _repo.loadAllForAdmin(
        webAppUrl: url,
        username: username,
        password: password,
      );
      await _settings.setAdminUsername(username);
      await _settings.setAdminPassword(password);

      if (!mounted) return;
      setState(() {
        _items = list;
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
      _items = [];
      _errorMsg = null;
      _passwordCtrl.clear();
    });
  }

  Future<void> _refreshList() async {
    final url = await _getUrl();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final list = await _repo.loadAllForAdmin(
        webAppUrl: url,
        username: username,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _items = list;
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

  String _normalizeId(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]'), '');
  }

  Future<void> _openEditor({SymptomDef? existing}) async {
    final url = await _getUrl();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final isNew = existing == null;

    final idCtrl = TextEditingController(text: existing?.id ?? '');
    final qCtrl = TextEditingController(text: existing?.question ?? '');
    final hCtrl = TextEditingController(text: existing?.hint ?? '');
    final orderCtrl = TextEditingController(
      text: existing != null ? '${existing.sortOrder}' : '10',
    );
    var active = existing?.active ?? true;
    var cfPakar = existing?.cfPakar ?? 0.5;

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(isNew ? 'Tambah Gejala' : 'Edit Gejala'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: idCtrl,
                  enabled: isNew,
                  decoration: const InputDecoration(
                    labelText: 'Kode (contoh: KG15)',
                    hintText: 'KG15',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Gejala',
                    hintText: 'contoh: Nyeri Sendi',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pertanyaan skrining',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CF Pakar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.navy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cfPakar.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: cfPakar,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: cfPakar.toStringAsFixed(1),
                  onChanged: (v) => setLocal(() => cfPakar = v),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0.1',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                    Text('rendah → sedang → tinggi',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                    Text('1.0',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Urutan tampil (angka)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif (tampil di skrining)'),
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final nid = isNew ? _normalizeId(idCtrl.text) : existing.id;
    if (nid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode gejala tidak valid')),
      );
      return;
    }

    final order = int.tryParse(orderCtrl.text.trim()) ?? 999;
    final symptom = SymptomDef(
      id: nid,
      question: qCtrl.text.trim(),
      hint: hCtrl.text.trim(),
      sortOrder: order,
      active: active,
      cfPakar: double.parse(cfPakar.toStringAsFixed(1)),
    );

    setState(() => _loading = true);
    try {
      await _repo.saveSymptomAdmin(
        webAppUrl: url,
        username: username,
        password: password,
        symptom: symptom,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tersimpan ke Spreadsheet')),
        );
        await _refreshList();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmDelete(SymptomDef s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Gejala?'),
        content: Text(
          'Yakin ingin menghapus "${s.hint.isNotEmpty ? s.hint : s.id}"?\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final url = await _getUrl();
    setState(() => _loading = true);
    try {
      await _repo.deleteSymptomAdmin(
        webAppUrl: url,
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        symptomId: s.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.id} berhasil dihapus')),
        );
        await _refreshList();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Kelola Gejala'),
        actions: _isLoggedIn
            ? [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loading ? null : _refreshList,
                ),
                IconButton(
                  tooltip: 'Keluar',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _logout,
                ),
              ]
            : null,
      ),
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: _loading ? null : () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Gejala'),
            )
          : null,
      body: _isLoggedIn ? _buildManagement() : _buildLoginForm(),
    );
  }

  // ── Login form ─────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.navy.withOpacity(0.08),
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
          'Gunakan username & password dari sheet "admin" di Spreadsheet.',
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
        const SizedBox(height: 14),
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
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                        color: Color(0xFFDC2626), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _login,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
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

  // ── Management view ────────────────────────────────────────────────────────

  Widget _buildManagement() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          color: AppTheme.navy.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: _loading
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Text(
                _loading
                    ? 'Memperbarui...'
                    : '${_items.length} gejala terdaftar',
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          child: _items.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada data gejala.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFF94A3B8)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = _items[i];
                    return _SymptomAdminCard(
                      symptom: s,
                      onEdit: () => _openEditor(existing: s),
                      onDelete: () => _confirmDelete(s),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Symptom Admin Card ─────────────────────────────────────────────────────────

class _SymptomAdminCard extends StatelessWidget {
  const _SymptomAdminCard({
    required this.symptom,
    required this.onEdit,
    required this.onDelete,
  });

  final SymptomDef symptom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUtama = symptom.category == SymptomCategory.utama;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUtama
              ? const Color(0xFFDC2626).withOpacity(0.25)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.navy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          symptom.id,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isUtama)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'utama',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'CF ${symptom.cfPakar.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: symptom.active
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    symptom.hint.isNotEmpty ? symptom.hint : symptom.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    symptom.question,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  color: AppTheme.navy,
                ),
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: onDelete,
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
