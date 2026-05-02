import 'dart:convert';

import '../data/knowledge_base.dart';
import '../models/symptom_def.dart';
import 'local_settings.dart';
import 'sheet_symptom_api.dart';

class SymptomRepository {
  SymptomRepository({
    SheetSymptomApi? api,
    LocalSettings? settings,
  })  : _api = api ?? SheetSymptomApi(),
        _settings = settings ?? LocalSettings();

  final SheetSymptomApi _api;
  final LocalSettings _settings;

  List<SymptomDef> _sortedActive(List<SymptomDef> list) {
    final copy = list.where((s) => s.active && s.id.isNotEmpty).toList();
    copy.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }

  Future<List<SymptomDef>> loadSymptomsForUser({bool forceRefresh = false}) async {
    final url = await _settings.getWebAppUrl();

    if (!forceRefresh) {
      final cached = await _settings.getCachedSymptomsJson();
      if (cached != null && cached.isNotEmpty) {
        try {
          final list = _decodeList(cached);
          if (list.isNotEmpty) return _sortedActive(list);
        } catch (_) {}
      }
    }

    try {
      final fresh = await _api.fetchActiveSymptoms(url);
      if (fresh.isNotEmpty) {
        await _settings.setCachedSymptomsJson(
          jsonEncode(fresh.map((e) => e.toJson()).toList()),
        );
        return fresh;
      }
    } catch (_) {
      final cached = await _settings.getCachedSymptomsJson();
      if (cached != null && cached.isNotEmpty) {
        try {
          final list = _decodeList(cached);
          if (list.isNotEmpty) return _sortedActive(list);
        } catch (_) {}
      }
    }

    return _sortedActive(List.from(kFallbackSymptoms));
  }

  List<SymptomDef> _decodeList(String json) {
    final raw = jsonDecode(json) as List<dynamic>;
    return raw
        .map((e) => SymptomDef.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SymptomDef>> loadAllForAdmin({
    required String webAppUrl,
    required String username,
    required String password,
  }) {
    return _api.listAllSymptoms(
      webAppUrl: webAppUrl,
      username: username,
      password: password,
    );
  }

  Future<void> saveSymptomAdmin({
    required String webAppUrl,
    required String username,
    required String password,
    required SymptomDef symptom,
  }) async {
    await _api.saveSymptom(
      webAppUrl: webAppUrl,
      username: username,
      password: password,
      symptom: symptom,
    );
    await _invalidateUserCache();
  }

  Future<void> deleteSymptomAdmin({
    required String webAppUrl,
    required String username,
    required String password,
    required String symptomId,
  }) async {
    await _api.deleteSymptom(
      webAppUrl: webAppUrl,
      username: username,
      password: password,
      symptomId: symptomId,
    );
    await _invalidateUserCache();
  }

  Future<void> saveDiagnosaResult(Map<String, dynamic> diagnosaData) async {
    final url = await _settings.getWebAppUrl();
    await _api.saveDiagnosaResult(webAppUrl: url, data: diagnosaData);
  }

  Future<void> _invalidateUserCache() async {
    await _settings.setCachedSymptomsJson(null);
  }
}
