enum SymptomCategory { utama, tambahan }

class SymptomDef {
  const SymptomDef({
    required this.id,
    required this.question,
    required this.hint,
    this.sortOrder = 0,
    this.active = true,
    this.cfPakar = 0.5,
    this.category = SymptomCategory.tambahan,
  });

  final String id;
  final String question;
  final String hint;
  final int sortOrder;
  final bool active;
  final double cfPakar;
  final SymptomCategory category;

  SymptomDef copyWith({
    String? id,
    String? question,
    String? hint,
    int? sortOrder,
    bool? active,
    double? cfPakar,
    SymptomCategory? category,
  }) {
    return SymptomDef(
      id: id ?? this.id,
      question: question ?? this.question,
      hint: hint ?? this.hint,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
      cfPakar: cfPakar ?? this.cfPakar,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'hint': hint,
        'sortOrder': sortOrder,
        'active': active,
        'cfPakar': cfPakar,
        'category': category.name,
      };

  factory SymptomDef.fromJson(Map<String, dynamic> json) {
    final rawId =
        (json['id'] as String? ?? json['kode_gejala'] as String? ?? '').trim().toUpperCase();
    return SymptomDef(
      id: rawId,
      question:
          (json['question'] as String? ?? json['pertanyaan'] as String? ?? '').trim(),
      hint: (json['hint'] as String? ?? json['nama_gejala'] as String? ?? '').trim(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 999,
      active: _parseBool(json['active'] ?? json['aktif'], defaultValue: true),
      cfPakar: (json['cfPakar'] as num? ??
              json['cf_pakar'] as num? ??
              json['CF Pakar'] as num? ??
              json['CF_pakar'] as num?)
              ?.toDouble() ??
          0.5,
      category: _categoryFromId(rawId),
    );
  }

  static SymptomCategory _categoryFromId(String id) {
    const utamaIds = {'KG1', 'KG2', 'KG3'};
    return utamaIds.contains(id.toUpperCase())
        ? SymptomCategory.utama
        : SymptomCategory.tambahan;
  }

  static bool _parseBool(dynamic v, {required bool defaultValue}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'false' || s == '0' || s == 'no') return false;
    if (s == 'true' || s == '1' || s == 'yes') return true;
    return defaultValue;
  }
}
