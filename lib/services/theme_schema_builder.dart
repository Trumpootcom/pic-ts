import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/theme_pack.dart';
import '../util/ts_print.dart';

class ThemeSchema {
  final List<Map<String, dynamic>> documentFields;
  final List<Map<String, dynamic>> rosterFields;
  final ThemeMetrics metrics;

  const ThemeSchema({
    required this.documentFields,
    required this.rosterFields,
    required this.metrics,
  });
}

class ThemeMetrics {
  final double profilePicturePreviewAspectRatio;
  final List<ThemeProfilePictureCrop> profilePictureCrops;

  const ThemeMetrics({
    required this.profilePicturePreviewAspectRatio,
    required this.profilePictureCrops,
  });
}

class ThemeProfilePictureCrop {
  final double aspectRatio;
  final String shape;

  const ThemeProfilePictureCrop({
    required this.aspectRatio,
    required this.shape,
  });

  Map<String, dynamic> toJson() {
    return {
      'aspectRatio': aspectRatio,
      'shape': shape,
    };
  }
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

    tsPrint('');
    tsPrint('========================================');
    tsPrint('THEME SCHEMA BUILD');
    tsPrint('THEME PATH: ${themePack.folderPath}');
    tsPrint('TEMPLATE COUNT: ${templateFiles.length}');
    tsPrint('========================================');

    final documentFields = <String, Map<String, dynamic>>{};
    final rosterFields = <String, Map<String, dynamic>>{};
    final profilePictureCrops = <ThemeProfilePictureCrop>[];

    for (final templatePath in templateFiles) {
      tsPrint('');
      tsPrint('----------------------------------------');
      tsPrint('PROCESSING TEMPLATE: $templatePath');
      tsPrint('----------------------------------------');

      final jsonText = await rootBundle.loadString(templatePath);
      final jsonMap = jsonDecode(jsonText) as Map<String, dynamic>;

      final data = jsonMap['data'] as Map<String, dynamic>? ?? {};

      _mergeFields(
        target: documentFields,
        fields: data['document'] as List<dynamic>? ?? [],
      );

      final rosterData = data['roster'];

      if (rosterData is Map<String, dynamic>) {
        _mergeFields(
          target: rosterFields,
          fields: rosterData['fields'] as List<dynamic>? ?? [],
        );
      } else {
        _mergeFields(
          target: rosterFields,
          fields: rosterData as List<dynamic>? ?? [],
        );
      }

      _collectProfilePictureCrops(
        templatePath: templatePath,
        jsonMap: jsonMap,
        crops: profilePictureCrops,
      );
    }

    final previewAspectRatio = profilePictureCrops.isEmpty
        ? 1.0
        : profilePictureCrops
            .map((crop) => crop.aspectRatio)
            .reduce((a, b) => a > b ? a : b);

    tsPrint('');
    tsPrint('========================================');
    tsPrint('FINAL PROFILE PREVIEW ASPECT RATIO');
    tsPrint(previewAspectRatio);
    tsPrint('PROFILE PICTURE CROP COUNT');
    tsPrint(profilePictureCrops.length);
    tsPrint('========================================');
    tsPrint('');

    return ThemeSchema(
      documentFields: documentFields.values.toList(),
      rosterFields: rosterFields.values.toList(),
      metrics: ThemeMetrics(
        profilePicturePreviewAspectRatio: previewAspectRatio,
        profilePictureCrops: profilePictureCrops,
      ),
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

  void _collectProfilePictureCrops({
    required String templatePath,
    required Map<String, dynamic> jsonMap,
    required List<ThemeProfilePictureCrop> crops,
  }) {
    final roster = jsonMap['roster'] as Map<String, dynamic>? ?? {};
    final elements = roster['elements'] as List<dynamic>? ?? [];

    tsPrint('ROSTER ELEMENT COUNT: ${elements.length}');

    for (final element in elements) {
      final elementMap = Map<String, dynamic>.from(element as Map);

      final source = elementMap['source'];
      final type = elementMap['type'];

      tsPrint('ELEMENT TYPE=$type SOURCE=$source');

      if (source != 'profilePicture') {
        continue;
      }

      final w = (elementMap['w'] as num?)?.toDouble();
      final h = (elementMap['h'] as num?)?.toDouble();

      if (w == null || h == null || h == 0) {
        tsPrint('PROFILE PICTURE CROP SKIPPED INVALID SIZE');
        continue;
      }

      final shape = elementMap['shape']?.toString() ?? 'rect';
      final aspectRatio = w / h;

      tsPrint('');
      tsPrint('PROFILE PICTURE CROP FOUND');
      tsPrint('TEMPLATE: $templatePath');
      tsPrint('WIDTH: $w');
      tsPrint('HEIGHT: $h');
      tsPrint('ASPECT RATIO: $aspectRatio');
      tsPrint('SHAPE: $shape');
      tsPrint('');

      crops.add(
        ThemeProfilePictureCrop(
          aspectRatio: aspectRatio,
          shape: shape,
        ),
      );
    }
  }
}