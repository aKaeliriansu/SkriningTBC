import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/symptom_def.dart';

class SheetSymptomApi {
  SheetSymptomApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 25);

  /// GET: hanya gejala aktif (untuk pengguna deteksi).
  Future<List<SymptomDef>> fetchActiveSymptoms(String webAppUrl) async {
    final uri = Uri.parse(webAppUrl.trim());
    final res = await _client.get(uri).timeout(_timeout);
    _checkStatus(res);
    final map = _decodeJson(res.body);
    _checkOk(map);
    final list = map['symptoms'] as List<dynamic>? ?? [];
    return _parseList(list).where((s) => s.id.isNotEmpty && s.active).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// POST admin: daftar semua baris (termasuk tidak aktif).
  Future<List<SymptomDef>> listAllSymptoms({
    required String webAppUrl,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse(webAppUrl.trim());
    final res = await _post(
      uri,
      jsonEncode({'username': username, 'password': password, 'action': 'listSymptoms'}),
    );
    _checkStatus(res);
    final map = _decodeJson(res.body);
    _checkOk(map);
    final list = map['symptoms'] as List<dynamic>? ?? [];
    return _parseList(list).where((s) => s.id.isNotEmpty).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> saveSymptom({
    required String webAppUrl,
    required String username,
    required String password,
    required SymptomDef symptom,
  }) async {
    final uri = Uri.parse(webAppUrl.trim());
    final res = await _post(
      uri,
      jsonEncode({'username': username, 'password': password, 'action': 'saveSymptom', 'symptom': symptom.toJson()}),
    );
    _checkStatus(res);
    final map = _decodeJson(res.body);
    _checkOk(map, fallbackError: 'Gagal menyimpan gejala');
  }

  Future<void> deleteSymptom({
    required String webAppUrl,
    required String username,
    required String password,
    required String symptomId,
  }) async {
    final uri = Uri.parse(webAppUrl.trim());
    final res = await _post(
      uri,
      jsonEncode({'username': username, 'password': password, 'action': 'deleteSymptom', 'symptomId': symptomId}),
    );
    _checkStatus(res);
    final map = _decodeJson(res.body);
    _checkOk(map, fallbackError: 'Gagal menghapus gejala');
  }

  Future<List<Map<String, dynamic>>> listDiagnosaResults({
    required String webAppUrl,
    required String password,
  }) async {
    final uri = Uri.parse(webAppUrl.trim());
    final res = await _post(
      uri,
      jsonEncode({'password': password, 'action': 'listDiagnosa'}),
    );
    _checkStatus(res);
    final map = _decodeJson(res.body);
    _checkOk(map);
    final list = map['data'] as List<dynamic>? ?? [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveDiagnosaResult({
    required String webAppUrl,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse(webAppUrl.trim());
    final res = await _post(
      uri,
      jsonEncode({'action': 'saveDiagnosa', 'diagnosa': data}),
    );
    _checkStatus(res);
    final map = _decodeJson(res.body);
    _checkOk(map, fallbackError: 'Gagal menyimpan hasil diagnosa');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// POST ke GAS dengan penanganan redirect.
  /// - Web: biarkan browser menangani redirect secara native.
  /// - Non-web: follow manual karena dart:io mengubah POST→GET pada 302,
  ///   sedangkan echo URL GAS hanya menerima GET setelah redirect pertama.
  Future<http.Response> _post(Uri uri, String jsonBody) async {
    const headers = {'Content-Type': 'text/plain; charset=utf-8'};
    if (kIsWeb) {
      return _client
          .post(uri, headers: headers, body: jsonBody)
          .timeout(_timeout);
    }
    Uri current = uri;
    String method = 'POST';
    for (int hop = 0; hop < 5; hop++) {
      final req = http.Request(method, current)..followRedirects = false;
      if (method == 'POST') {
        req.headers.addAll(headers);
        req.body = jsonBody;
      }
      final streamed = await _client.send(req).timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode >= 300 && res.statusCode < 400) {
        final loc = res.headers['location'];
        if (loc == null || loc.isEmpty) break;
        current = current.resolve(loc);
        method = (res.statusCode == 307 || res.statusCode == 308) ? 'POST' : 'GET';
        continue;
      }
      return res;
    }
    throw SheetApiException('Terlalu banyak redirect');
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SheetApiException('HTTP ${res.statusCode}',
          statusCode: res.statusCode);
    }
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw SheetApiException('Format respons tidak valid (bukan objek JSON).');
    } catch (e) {
      if (e is SheetApiException) rethrow;
      throw SheetApiException('Gagal memparse JSON: $e');
    }
  }

  void _checkOk(Map<String, dynamic> map, {String? fallbackError}) {
    if (map['ok'] != true) {
      throw SheetApiException(
        map['error']?.toString() ?? fallbackError ?? 'Server error',
      );
    }
  }

  List<SymptomDef> _parseList(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((e) => SymptomDef.fromJson(_normalizeKeys(e)))
        .toList();
  }

  Map<String, dynamic> _normalizeKeys(Map raw) {
    final m = Map<String, dynamic>.from(raw);

    if (!m.containsKey('id') && m.containsKey('kode_gejala')) {
      m['id'] = m['kode_gejala'];
    }
    if (!m.containsKey('question') && m.containsKey('pertanyaan')) {
      m['question'] = m['pertanyaan'];
    }
    if (!m.containsKey('hint') && m.containsKey('nama_gejala')) {
      m['hint'] = m['nama_gejala'];
    }
    if (!m.containsKey('cfPakar')) {
      m['cfPakar'] = m['cf_pakar'] ?? m['CF Pakar'] ?? m['CF_pakar'] ??
          m['cfpakar'] ?? m['cf pakar'];
    }
    if (!m.containsKey('active') && m.containsKey('aktif')) {
      m['active'] = m['aktif'];
    }
    if (!m.containsKey('sortOrder') && m.containsKey('no')) {
      m['sortOrder'] = m['no'];
    }

    return m;
  }
}

class SheetApiException implements Exception {
  SheetApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
