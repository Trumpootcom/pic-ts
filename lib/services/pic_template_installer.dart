import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../util/ts_print.dart';

class PicTemplateInstaller {
  static const List<String> bundledTemplates = [
    'assets/pic_templates/ParadigmCNA.pictsx',
  ];

  Future<Directory> templatesRoot() async {
    final docs = await getApplicationDocumentsDirectory();

    final dir = Directory(
      '${docs.path}/pic_templates',
    );

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  Future<void> installBundledTemplates() async {
    final root = await templatesRoot();

    for (final assetPath in bundledTemplates) {
      final fileName = assetPath.split('/').last;

      final destination = File(
        '${root.path}/$fileName',
      );

      if (await destination.exists()) {
        continue;
      }

      final data = await rootBundle.load(assetPath);

      await destination.writeAsBytes(
        data.buffer.asUint8List(),
        flush: true,
      );

      tsPrint(
        'Installed template: $fileName',
      );
    }
  }
}