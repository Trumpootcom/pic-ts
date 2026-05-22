import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/theme_pack.dart';

class ThemeSchema {
  final List<Map<String, dynamic>> documentFields;
  final List<Map<String, dynamic>> rosterFields;

  const ThemeSchema({required this.documentFields, required this.rosterFields});
}

class ThemeSchemaBuilder {
  Future<ThemeSchema> build(ThemePack themePack) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final templateFiles =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith('${themePack.folderPath}/') &&
                  path.endsWith('/template.json'),
            )
            .toList()
          ..sort();

    print('THEME PATH: ${themePack.folderPath}');
    print('TEMPLATE FILES: $templateFiles');

    final documentFields = <String, Map<String, dynamic>>{};
    final rosterFields = <String, Map<String, dynamic>>{};

    for (final templatePath in templateFiles) {
      final jsonText = await rootBundle.loadString(templatePath);
      final jsonMap = jsonDecode(jsonText) as Map<String, dynamic>;

      final data = jsonMap['data'] as Map<String, dynamic>? ?? {};

      _mergeFields(
        target: documentFields,
        fields: data['document'] as List<dynamic>? ?? [],
      );

      _mergeFields(
        target: rosterFields,
        fields: data['roster'] as List<dynamic>? ?? [],
      );
    }

    return ThemeSchema(
      documentFields: documentFields.values.toList(),
      rosterFields: rosterFields.values.toList(),
    );
  }

  void _mergeFields({
    required Map<String, Map<String, dynamic>> target,
    required List<dynamic> fields,
  }) {
    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field as Map);
      final key = fieldMap['key'] as String;

      target.putIfAbsent(key, () => fieldMap);
    }
  }
}
