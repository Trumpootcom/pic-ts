import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class PictsxReader {
  Future<Uint8List?> readIconBytes(File pictsxFile) async {
    final bytes = await pictsxFile.readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes);

    final iconFile = archive.findFile('icon.png');

    if (iconFile == null) {
      return null;
    }

    return Uint8List.fromList(
      iconFile.content as List<int>,
    );
  }
}