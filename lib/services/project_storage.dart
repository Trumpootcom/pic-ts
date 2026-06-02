import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'theme_schema_builder.dart';

class StoredProject {
  final String id;
  final String name;
  final String folderPath;

  const StoredProject({
    required this.id,
    required this.name,
    required this.folderPath,
  });

  factory StoredProject.fromJson({
    required Map<String, dynamic> json,
    required String folderPath,
  }) {
    return StoredProject(
      id: json['id'] as String,
      name: json['name'] as String,
      folderPath: folderPath,
    );
  }

  String get iconPath => '$folderPath/icon.png';
  String get dataJsonPath => '$folderPath/data/data.json';
  String get photosPath => '$folderPath/data/photos';
  String get templatesPath => '$folderPath/templates';
  String get historyTxtPath => '$folderPath/data/history.txt';
}

class ProjectStorage {
  Future<Directory> ensureProjectsRoot() async {
    return _projectsRoot();
  }

  Future<List<StoredProject>> listProjects() async {
    final root = await _projectsRoot();

    final dirs = root.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final projects = <StoredProject>[];

    for (final dir in dirs) {
      final file = _dataJsonFile(dir);

      if (!await file.exists()) {
        continue;
      }

      final jsonText = await file.readAsString();
      final jsonMap = jsonDecode(jsonText) as Map<String, dynamic>;

      projects.add(
        StoredProject.fromJson(
          json: jsonMap,
          folderPath: dir.path,
        ),
      );
    }

    return projects;
  }

  Future<Map<String, dynamic>> openProject(StoredProject project) async {
    final file = File(project.dataJsonPath);
    final jsonText = await file.readAsString();

    final jsonMap = jsonDecode(jsonText) as Map<String, dynamic>;

    await refreshProjectSchema(
      project: project,
      projectData: jsonMap,
    );

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonMap),
    );

    return jsonMap;
  }

  Future<void> refreshProjectSchema({
    required StoredProject project,
    required Map<String, dynamic> projectData,
  }) async {
    final existingDocumentSchema = List<Map<String, dynamic>>.from(
      (projectData['documentSchema'] as List<dynamic>? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final existingRosterSchema = List<Map<String, dynamic>>.from(
      (projectData['rosterSchema'] as List<dynamic>? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    final schema = await ThemeSchemaBuilder().buildFromProjectDirectory(
      Directory(project.folderPath),
    );
    final mergedDocumentSchema = _mergeSchemaFields(
      existingFields: existingDocumentSchema,
      discoveredFields: schema.documentFields,
    );
    final mergedRosterSchema = _mergeSchemaFields(
      existingFields: existingRosterSchema,
      discoveredFields: schema.rosterFields,
    );

    final documentData = Map<String, dynamic>.from(
      projectData['documentData'] as Map? ?? {},
    );

    for (final field in mergedDocumentSchema) {
      final key = field['key'] as String;
      documentData.putIfAbsent(key, () => field['default'] ?? '');
    }

    final rosterRows = List<Map<String, dynamic>>.from(
      (projectData['roster'] as List<dynamic>? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    for (final row in rosterRows) {
      for (final field in mergedRosterSchema) {
        final key = field['key'] as String;
        row.putIfAbsent(key, () => field['default'] ?? '');
      }
    }

    projectData['documentSchema'] = mergedDocumentSchema;
    projectData['rosterSchema'] = mergedRosterSchema;
    projectData['documentData'] = documentData;
    projectData['roster'] = rosterRows;
    projectData['templateMetrics'] = {
      'profilePicturePreviewAspectRatio':
          schema.metrics.profilePicturePreviewAspectRatio,
      'profilePictureMaxRenderWidthPx':
          schema.metrics.profilePictureMaxRenderWidthPx,
      'profilePictureMaxRenderHeightPx':
          schema.metrics.profilePictureMaxRenderHeightPx,
      'profilePictureCrops': schema.metrics.profilePictureCrops
          .map((e) => e.toJson())
          .toList(),
    };
  }

  List<Map<String, dynamic>> _mergeSchemaFields({
    required List<Map<String, dynamic>> existingFields,
    required List<Map<String, dynamic>> discoveredFields,
  }) {
    final merged = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    for (final field in existingFields) {
      final key = field['key'] as String?;

      if (key == null || seenKeys.contains(key)) {
        continue;
      }

      merged.add(field);
      seenKeys.add(key);
    }

    for (final field in discoveredFields) {
      final key = field['key'] as String?;

      if (key == null || seenKeys.contains(key)) {
        continue;
      }

      merged.add(field);
      seenKeys.add(key);
    }

    return merged;
  }

  Future<void> saveProject({
    required StoredProject project,
    required Map<String, dynamic> data,
  }) async {
    final file = File(project.dataJsonPath);

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  Future<void> renameProject({
    required StoredProject project,
    required String name,
  }) async {
    final file = File(project.dataJsonPath);
    final jsonText = await file.readAsString();
    final jsonMap = jsonDecode(jsonText) as Map<String, dynamic>;

    jsonMap['name'] = name;
    jsonMap['modifiedAt'] = DateTime.now().toIso8601String();

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonMap),
    );
  }

  Future<void> deleteProject(StoredProject project) async {
    final dir = Directory(project.folderPath);

    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<Directory> _projectsRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/projects');

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    return root;
  }

  File _dataJsonFile(Directory projectDir) {
    return File('${projectDir.path}/data/data.json');
  }
}
