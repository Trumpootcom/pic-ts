import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'project_storage.dart';

class ProjectShareService {
  Future<File> shareProject(StoredProject project) async {
    final file = await _buildProjectArchive(project);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
        fileNameOverrides: [p.basename(file.path)],
        title: project.name,
        subject: project.name,
      ),
    );

    return file;
  }

  Future<File> _buildProjectArchive(StoredProject project) async {
    final projectDir = Directory(project.folderPath);

    if (!await projectDir.exists()) {
      throw Exception('Project folder not found: ${project.folderPath}');
    }

    final archive = Archive();
    final files = projectDir
        .listSync(recursive: true)
        .whereType<File>()
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final relativePath = p
          .relative(file.path, from: projectDir.path)
          .replaceAll('\\', '/');
      final bytes = await file.readAsBytes();

      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }

    final exportDir = Directory(
      p.join((await getTemporaryDirectory()).path, 'pic_ts_exports'),
    );
    await exportDir.create(recursive: true);

    final exportFile = File(
      p.join(exportDir.path, '${_safeFileNamePart(project.name)}.picts'),
    );
    final encoded = ZipEncoder().encode(archive);

    if (encoded == null) {
      throw Exception('Could not create project export.');
    }

    await exportFile.writeAsBytes(encoded, flush: true);

    return exportFile;
  }

  String _safeFileNamePart(String value) {
    final safeName = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return safeName.isEmpty ? 'project' : safeName;
  }
}
