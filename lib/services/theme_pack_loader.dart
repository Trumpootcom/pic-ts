import 'package:flutter/services.dart';

import '../models/theme_pack.dart';

class ThemePackLoader {
  static const String rootPath = 'assets/templates';

  Future<List<ThemePack>> loadThemePacks() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final iconFiles = manifest
        .listAssets()
        .where(
          (path) => path.startsWith(rootPath) && path.endsWith('/icon.png'),
        )
        .toList()
      ..sort();

    final packs = <ThemePack>[];

    for (final iconPath in iconFiles) {
      final folderPath = iconPath.substring(
        0,
        iconPath.length - '/icon.png'.length,
      );

      final parts = folderPath.split('/');
      final id = parts.isNotEmpty ? parts.last : folderPath;

      packs.add(
        ThemePack(
          id: id,
          name: _prettyName(id),
          folderPath: folderPath,
          iconPath: iconPath,
        ),
      );
    }

    return packs;
  }

  String _prettyName(String id) {
    return id
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}