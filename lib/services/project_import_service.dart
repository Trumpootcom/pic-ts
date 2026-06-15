import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'project_storage.dart';

class ProjectImportPackageInfo {
  final File packageFile;
  final Archive archive;
  final Map<String, dynamic> projectData;
  final String projectId;
  final String projectName;
  final bool hasConflict;

  const ProjectImportPackageInfo({
    required this.packageFile,
    required this.archive,
    required this.projectData,
    required this.projectId,
    required this.projectName,
    required this.hasConflict,
  });
}

class ProjectImportService {
  Future<ProjectImportPackageInfo> inspectProjectPackage(File packageFile) async {
    final bytes = await packageFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final dataFile = archive.findFile('data/data.json');

    if (dataFile == null) {
      throw Exception('Project package is missing data/data.json.');
    }

    final projectData = jsonDecode(
      utf8.decode(dataFile.content as List<int>),
    ) as Map<String, dynamic>;

    final projectsRoot = await ProjectStorage().ensureProjectsRoot();
    final originalId = projectData['id']?.toString() ??
        _safeProjectId(p.basenameWithoutExtension(packageFile.path));
    final originalName = projectData['name']?.toString() ??
        p.basenameWithoutExtension(packageFile.path);
    final projectId = _safeProjectId(originalId);
    final hasConflict =
        await Directory(p.join(projectsRoot.path, projectId)).exists() ||
        await _projectNameExists(originalName);

    return ProjectImportPackageInfo(
      packageFile: packageFile,
      archive: archive,
      projectData: projectData,
      projectId: projectId,
      projectName: originalName,
      hasConflict: hasConflict,
    );
  }

  Future<StoredProject> importProjectPackage({
    required ProjectImportPackageInfo packageInfo,
    required String projectName,
  }) async {
    final projectsRoot = await ProjectStorage().ensureProjectsRoot();
    final projectId = await _availableProjectId(projectsRoot, projectName);

    if (await _projectNameExists(projectName)) {
      throw Exception('Project already exists: $projectName');
    }

    final projectDir = Directory(p.join(projectsRoot.path, projectId));

    await projectDir.create(recursive: true);

    try {
      await _extractArchive(
        archive: packageInfo.archive,
        projectDir: projectDir,
      );

      final projectData = Map<String, dynamic>.from(packageInfo.projectData);
      projectData['id'] = projectId;
      projectData['name'] = projectName;
      projectData['modifiedAt'] = DateTime.now().toIso8601String();

      await File(p.join(projectDir.path, 'data', 'data.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(projectData),
      );
    } catch (_) {
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
      }

      rethrow;
    }

    return StoredProject.fromJson(
      json: Map<String, dynamic>.from(packageInfo.projectData)
        ..['id'] = projectId
        ..['name'] = projectName,
      folderPath: projectDir.path,
    );
  }

  Future<void> _extractArchive({
    required Archive archive,
    required Directory projectDir,
  }) async {
    for (final file in archive.files) {
      final safeName = file.name.replaceAll('\\', '/');

      if (safeName.isEmpty ||
          safeName.startsWith('/') ||
          safeName.split('/').contains('..')) {
        continue;
      }

      final outPath = p.normalize(p.join(projectDir.path, safeName));

      if (file.isFile) {
        final outFile = File(outPath);

        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
  }

  Future<String> _availableProjectId(Directory projectsRoot, String value) async {
    final baseId = _safeProjectId(value);

    if (!await Directory(p.join(projectsRoot.path, baseId)).exists()) {
      return baseId;
    }

    throw Exception('Project already exists: $value');
  }

  Future<bool> _projectNameExists(String value) async {
    final projects = await ProjectStorage().listProjects();
    return projects.any((project) => project.name == value);
  }

  String _safeProjectId(String value) {
    final safeId = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return safeId.isEmpty ? 'imported_project' : safeId;
  }
}
