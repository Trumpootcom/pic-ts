import 'dart:convert';
import 'dart:io';

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
