import 'dart:io';

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
      final jpgBytes = img.encodeJpg(image, quality: 95);

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
}
