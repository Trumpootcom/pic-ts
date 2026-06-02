import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import 'theme_schema_builder.dart';

class PictsxReader {
  Future<Uint8List?> readIconBytes(File pictsxFile) async {
    final bytes = await pictsxFile.readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes);

    final iconFile = archive.findFile('icon.png');

    if (iconFile == null) {
      return null;
    }

    return Uint8List.fromList(iconFile.content as List<int>);
  }

  Future<Directory> extractToProject({
    required File pictsxFile,
    required String projectName,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final projectsRoot = Directory('${docs.path}/projects');

    if (!await projectsRoot.exists()) {
      await projectsRoot.create(recursive: true);
    }

    final projectId = projectName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final projectDir = Directory('${projectsRoot.path}/$projectId');

    if (await projectDir.exists()) {
      throw Exception('Project already exists: $projectName');
    }

    await projectDir.create(recursive: true);

    final bytes = await pictsxFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    await _extractArchiveEntries(
      archive: archive,
      outputRootPath: projectDir.path,
    );

    await _initializeProjectDataJson(
      projectDir: projectDir,
      projectId: projectId,
      projectName: projectName,
    );
    return projectDir;
  }

  Future<void> importTemplatesToProject({
    required File pictsxFile,
    required String projectFolderPath,
  }) async {
    final bytes = await pictsxFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    var importedTemplateFile = false;

    for (final file in archive.files) {
      final safeName = file.name.replaceAll('\\', '/');

      if (!safeName.startsWith('templates/')) {
        continue;
      }

      importedTemplateFile = true;
    }

    if (!importedTemplateFile) {
      throw Exception('No templates found in ${pictsxFile.path}');
    }

    await _extractArchiveEntries(
      archive: archive,
      outputRootPath: projectFolderPath,
      pathPrefix: 'templates/',
    );
  }

  Future<void> _initializeProjectDataJson({
    required Directory projectDir,
    required String projectId,
    required String projectName,
  }) async {
    final schema = await ThemeSchemaBuilder().buildFromProjectDirectory(
      projectDir,
    );

    final documentData = <String, dynamic>{};

    for (final field in schema.documentFields) {
      final key = field['key'] as String;
      documentData[key] = field['default'] ?? '';
    }

    final now = DateTime.now().toIso8601String();

    final dataJson = {
      'id': projectId,
      'name': projectName,
      'createdAt': now,
      'modifiedAt': now,
      'documentSchema': schema.documentFields,
      'rosterSchema': schema.rosterFields,
      'documentData': documentData,
      'roster': <Map<String, dynamic>>[],
      'templateMetrics': {
        'profilePicturePreviewAspectRatio':
            schema.metrics.profilePicturePreviewAspectRatio,
        'profilePictureMaxRenderWidthPx':
            schema.metrics.profilePictureMaxRenderWidthPx,
        'profilePictureMaxRenderHeightPx':
            schema.metrics.profilePictureMaxRenderHeightPx,
        'profilePictureCrops': schema.metrics.profilePictureCrops
            .map((crop) => crop.toJson())
            .toList(),
      },
    };

    final dataDir = Directory('${projectDir.path}/data');

    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    final dataFile = File('${dataDir.path}/data.json');

    await dataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(dataJson),
    );
  }

  Future<void> _extractArchiveEntries({
    required Archive archive,
    required String outputRootPath,
    String? pathPrefix,
  }) async {
    for (final file in archive.files) {
      final safeName = file.name.replaceAll('\\', '/');

      if (pathPrefix != null && !safeName.startsWith(pathPrefix)) {
        continue;
      }

      final outPath = '$outputRootPath/$safeName';

      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
  }
}
