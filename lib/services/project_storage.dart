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

    final schema = await ThemeSchemaBuilder().buildFromProjectDirectory(
      Directory(project.folderPath),
    );

    jsonMap['documentSchema'] = schema.documentFields;
    jsonMap['rosterSchema'] = schema.rosterFields;

    jsonMap['templateMetrics'] = {
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

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonMap),
    );

    return jsonMap;
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
