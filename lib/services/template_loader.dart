import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/template_definition.dart';

class LoadedTemplate {
  final String folderPath;
  final String themeId;
  final String productFolder;
  final TemplateDefinition template;

  const LoadedTemplate({
    required this.folderPath,
    required this.themeId,
    required this.productFolder,
    required this.template,
  });

  String assetPath(String fileName) => '$folderPath/$fileName';
}

class TemplateLoader {
  static const String rootPath = 'assets/templates';

  Future<List<LoadedTemplate>> loadTemplates() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final templateFiles = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith(rootPath) && path.endsWith('/template.json'),
        )
        .toList()
      ..sort();

    final loaded = <LoadedTemplate>[];

    for (final templatePath in templateFiles) {
      final jsonText = await rootBundle.loadString(templatePath);
      final jsonMap = jsonDecode(jsonText) as Map<String, dynamic>;

      final folderPath = templatePath.substring(
        0,
        templatePath.length - '/template.json'.length,
      );

      final parts = folderPath.split('/');

      final themeId = parts.length > 2 ? parts[2] : '';
      final productFolder = parts.length > 3 ? parts[3] : '';

      loaded.add(
        LoadedTemplate(
          folderPath: folderPath,
          themeId: themeId,
          productFolder: productFolder,
          template: TemplateDefinition.fromJson(jsonMap),
        ),
      );
    }

    return loaded;
  }

  Future<List<LoadedTemplate>> loadProjectTemplates({
    required String projectFolderPath,
  }) async {
    final templatesRoot = Directory('$projectFolderPath/templates');

    if (!await templatesRoot.exists()) {
      return [];
    }

    final templateFiles = templatesRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('${Platform.pathSeparator}template.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final loaded = <LoadedTemplate>[];

    for (final templateFile in templateFiles) {
      final jsonText = await templateFile.readAsString();
      final jsonMap = jsonDecode(jsonText) as Map<String, dynamic>;

      final folderPath = templateFile.parent.path;
      final productFolder = folderPath.split(Platform.pathSeparator).last;

      loaded.add(
        LoadedTemplate(
          folderPath: folderPath,
          themeId: '',
          productFolder: productFolder,
          template: TemplateDefinition.fromJson(jsonMap),
        ),
      );
    }

    return loaded;
  }
}