import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/theme_pack.dart';

class StoredProject {
  final String id;
  final String name;
  final String themeId;
  final String themeName;
  final String themePath;
  final String folderPath;

  const StoredProject({
    required this.id,
    required this.name,
    required this.themeId,
    required this.themeName,
    required this.themePath,
    required this.folderPath,
  });

  factory StoredProject.fromJson({
    required Map<String, dynamic> json,
    required String folderPath,
  }) {
    return StoredProject(
      id: json['id'] as String,
      name: json['name'] as String,
      themeId: json['themeId'] as String,
      themeName: json['themeName'] as String,
      themePath: json['themePath'] as String,
      folderPath: folderPath,
    );
  }
}

class ProjectStorage {
  Future<Directory> _projectsRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/projects');

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    return root;
  }

  Future<Directory> createProject({
    required String projectName,
    required ThemePack themePack,
  }) async {
    final root = await _projectsRoot();
    final projectId = _slug(projectName);
    final projectDir = Directory('${root.path}/$projectId');
    print('CREATE PROJECT CALLED');
    if (await projectDir.exists()) {
      throw Exception('Project already exists: $projectName');
    }

    await projectDir.create(recursive: true);

    final projectJson = {
      'id': projectId,
      'name': projectName,
      'themeId': themePack.id,
      'themeName': themePack.name,
      'themePath': themePack.folderPath,
      'createdAt': DateTime.now().toIso8601String(),
      'documentData': <String, dynamic>{},
      'details': <Map<String, dynamic>>[],
    };

    final file = File('${projectDir.path}/project.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(projectJson),
    );

    return projectDir;
  }

  Future<List<StoredProject>> listProjects() async {
    final root = await _projectsRoot();

    final dirs = root.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final projects = <StoredProject>[];

    for (final dir in dirs) {
      final file = File('${dir.path}/project.json');

      if (!await file.exists()) {
        continue;
      }

      final jsonText = await file.readAsString();
      final jsonMap = jsonDecode(jsonText) as Map<String, dynamic>;

      projects.add(StoredProject.fromJson(json: jsonMap, folderPath: dir.path));
    }

    return projects;
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
