// lib/services/roster_photo_service.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../util/ts_print.dart';

class PreparedRosterPhoto {
  final String tempImagePath;
  final String croppedImagePath;

  const PreparedRosterPhoto({
    required this.tempImagePath,
    required this.croppedImagePath,
  });
}

class RosterPhotoService {
  Future<PreparedRosterPhoto?> pickAndPreparePhoto({
    required String projectFolderPath,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final sourceFile = File(result.files.single.path!);

    final photosDir = Directory('$projectFolderPath/data/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final safeName = DateTime.now().millisecondsSinceEpoch.toString();
    final extension = p.extension(sourceFile.path);
    final tempFile = File('${photosDir.path}/tmp_$safeName$extension');
    final croppedImagePath = '${photosDir.path}/$safeName.jpg';

    tsPrint('SOURCE FILE: ${sourceFile.path}');

    final bytes = await sourceFile.readAsBytes();
    tsPrint('SOURCE BYTES: ${bytes.length}');

    final decoded = img.decodeImage(bytes);
    tsPrint('DECODED NULL? ${decoded == null}');

    if (decoded != null) {
      tsPrint('DECODED SIZE: ${decoded.width} x ${decoded.height}');
    }

    if (decoded == null) {
      await sourceFile.copy(tempFile.path);
    } else {
      final normalized = img.bakeOrientation(decoded);
      tsPrint('NORMALIZED SIZE: ${normalized.width} x ${normalized.height}');

      await tempFile.writeAsBytes(img.encodeJpg(normalized, quality: 95));
      tsPrint('WROTE NORMALIZED JPG: ${tempFile.path}');
    }

    return PreparedRosterPhoto(
      tempImagePath: tempFile.path,
      croppedImagePath: croppedImagePath,
    );
  }

  Future<void> deleteTempPhoto(String tempImagePath) async {
    try {
      await File(tempImagePath).delete();
      tsPrint('DELETED TEMP NORMALIZED JPG');
    } catch (_) {}
  }
}