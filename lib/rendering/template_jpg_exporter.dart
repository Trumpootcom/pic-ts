import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../services/template_loader.dart';
import 'template_pdf_exporter.dart';

class TemplateJpgExporter {
  Future<File> exportAndShare({
    required LoadedTemplate loadedTemplate,
    required Map<String, dynamic> documentData,
    required List<Map<String, dynamic>> rosterRows,
    required String projectFolderPath,
    required String fileName,
  }) async {
    final document = Map<String, dynamic>.from(
      loadedTemplate.template.rawJson['document'] as Map? ?? {},
    );
    final dpi = (document['dpi'] as num?)?.toDouble() ?? 300;
    final pdfBytes = await TemplatePdfExporter().buildPdfBytes(
      loadedTemplate: loadedTemplate,
      documentData: documentData,
      rosterRows: rosterRows,
      projectFolderPath: projectFolderPath,
    );

    final exportDir = Directory(
      p.join((await getTemporaryDirectory()).path, 'pic_ts_exports'),
    );
    await exportDir.create(recursive: true);

    final file = File(p.join(exportDir.path, p.basename(fileName)));

    await for (final raster in Printing.raster(pdfBytes, dpi: dpi)) {
      final image = raster.asImage();
      final jpgBytes = _encodeJpgWithDpi(image: image, dpi: dpi.round());

      await file.writeAsBytes(jpgBytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/jpeg')],
          fileNameOverrides: [p.basename(file.path)],
          title: loadedTemplate.template.name,
          subject: loadedTemplate.template.name,
        ),
      );

      return file;
    }

    throw Exception('No JPG pages were generated.');
  }

  Uint8List _encodeJpgWithDpi({
    required img.Image image,
    required int dpi,
  }) {
    final jpgBytes = img.encodeJpg(image, quality: 95);

    if (jpgBytes.length >= 20 &&
        jpgBytes[0] == 0xff &&
        jpgBytes[1] == 0xd8 &&
        jpgBytes[2] == 0xff &&
        jpgBytes[3] == 0xe0 &&
        String.fromCharCodes(jpgBytes.sublist(6, 11)) == 'JFIF\u0000') {
      jpgBytes[13] = 1;
      jpgBytes[14] = (dpi >> 8) & 0xff;
      jpgBytes[15] = dpi & 0xff;
      jpgBytes[16] = (dpi >> 8) & 0xff;
      jpgBytes[17] = dpi & 0xff;
      return jpgBytes;
    }

    final patchedBytes = BytesBuilder(copy: false)
      ..add(jpgBytes.sublist(0, 2))
      ..add([
        0xff,
        0xe0,
        0x00,
        0x10,
        0x4a,
        0x46,
        0x49,
        0x46,
        0x00,
        0x01,
        0x01,
        0x01,
        (dpi >> 8) & 0xff,
        dpi & 0xff,
        (dpi >> 8) & 0xff,
        dpi & 0xff,
        0x00,
        0x00,
      ])
      ..add(jpgBytes.sublist(2));

    return patchedBytes.toBytes();
  }
}
