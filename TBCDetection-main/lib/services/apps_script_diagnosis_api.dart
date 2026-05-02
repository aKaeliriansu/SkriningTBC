import 'dart:convert';

import 'package:http/http.dart' as http;

class AppsScriptDiagnosisApi {
  AppsScriptDiagnosisApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 25);

  Future<DiagnosisResult> diagnose({
    required String webAppUrl,
    required String idUser,
    required Map<String, double> jawaban,
  }) async {
    final uri = Uri.parse(webAppUrl.trim());
    final payload = jsonEncode({
      'id_user': idUser,
      'jawaban': jawaban,
    });

    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: payload,
        )
        .timeout(_timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw DiagnosisApiException('HTTP ${res.statusCode}', statusCode: res.statusCode);
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw DiagnosisApiException(map['error']?.toString() ?? 'Server error');
    }

    final data = map['data'];
    if (data is! Map<String, dynamic>) {
      throw DiagnosisApiException('Format respons data tidak valid.');
    }
    return DiagnosisResult.fromJson(data);
  }
}

class DiagnosisResult {
  const DiagnosisResult({
    required this.idHasil,
    required this.hasilUtamaKode,
    required this.hasilUtamaNilaiCf,
    required this.hasilUtamaNama,
    required this.solusiTindakLanjut,
    required this.ranking,
    required this.ruleTerpenuhi,
  });

  final String idHasil;
  final String hasilUtamaKode;
  final double hasilUtamaNilaiCf;
  final String hasilUtamaNama;
  final String solusiTindakLanjut;
  final List<DiagnosisRankingItem> ranking;
  final List<DiagnosisRuleHit> ruleTerpenuhi;

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    final rankingRaw = (json['ranking'] as List<dynamic>? ?? const []);
    final rulesRaw = (json['rule_terpenuhi'] as List<dynamic>? ?? const []);

    return DiagnosisResult(
      idHasil: (json['id_hasil'] as String? ?? '').trim(),
      hasilUtamaKode: (json['hasil_utama_kode'] as String? ?? '').trim(),
      hasilUtamaNilaiCf: (json['hasil_utama_nilai_cf'] as num?)?.toDouble() ?? 0,
      hasilUtamaNama: (json['hasil_utama_nama'] as String? ?? '').trim(),
      solusiTindakLanjut: (json['solusi_tindak_lanjut'] as String? ?? '').trim(),
      ranking: rankingRaw
          .whereType<Map>()
          .map((e) => DiagnosisRankingItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      ruleTerpenuhi: rulesRaw
          .whereType<Map>()
          .map((e) => DiagnosisRuleHit.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DiagnosisRankingItem {
  const DiagnosisRankingItem({
    required this.kode,
    required this.cf,
    required this.namaDiagnosa,
  });

  final String kode;
  final double cf;
  final String namaDiagnosa;

  factory DiagnosisRankingItem.fromJson(Map<String, dynamic> json) {
    return DiagnosisRankingItem(
      kode: (json['kode'] as String? ?? '').trim(),
      cf: (json['cf'] as num?)?.toDouble() ?? 0,
      namaDiagnosa: (json['nama_diagnosa'] as String? ?? '').trim(),
    );
  }
}

class DiagnosisRuleHit {
  const DiagnosisRuleHit({
    required this.kodeRule,
    required this.thenKodeDiagnosa,
    required this.cfRuleUser,
    required this.matchedGejala,
  });

  final String kodeRule;
  final String thenKodeDiagnosa;
  final double cfRuleUser;
  final List<String> matchedGejala;

  factory DiagnosisRuleHit.fromJson(Map<String, dynamic> json) {
    final matched = (json['matched_gejala'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return DiagnosisRuleHit(
      kodeRule: (json['kode_rule'] as String? ?? '').trim(),
      thenKodeDiagnosa: (json['then_kode_diagnosa'] as String? ?? '').trim(),
      cfRuleUser: (json['cf_rule_user'] as num?)?.toDouble() ?? 0,
      matchedGejala: matched,
    );
  }
}

class DiagnosisApiException implements Exception {
  DiagnosisApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
