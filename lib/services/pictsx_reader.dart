import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

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

    for (final file in archive.files) {
      final outPath = '${projectDir.path}/${file.name}';

      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    return projectDir;
  }
}
