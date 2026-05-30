import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../services/pic_template_installer.dart';
import '../theme/app_colors.dart';
import '../widgets/tsts_dialog.dart';
import '../widgets/tsts_title_bar.dart';
import '../widgets/folder_list_tile.dart';
import '../services/pictsx_reader.dart';
import '../util/ts_print.dart';
import '../build_info.dart';

class PicTemplateBrowserPage extends StatefulWidget {
  const PicTemplateBrowserPage({super.key});

  @override
  State<PicTemplateBrowserPage> createState() => _PicTemplateBrowserPageState();
}

class _PicTemplateBrowserPageState extends State<PicTemplateBrowserPage> {
  late final Future<List<File>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = _loadTemplates();
  }

  Future<List<File>> _loadTemplates() async {
    final root = await PicTemplateInstaller().templatesRoot();

    if (!await root.exists()) {
      return [];
    }

    final files =
        root
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.pictsx'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    return files;
  }

  String _templateName(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    return name.replaceAll(RegExp(r'\.pictsx$', caseSensitive: false), '');
  }

  Future<void> _showNewProjectDialog(File templateFile) async {
    final controller = TextEditingController();
    final templateName = _templateName(templateFile);
    final previewIconBytes = await PictsxReader().readIconBytes(templateFile);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return TstsDialog(
          title: 'Create New Project',
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: BorderSide(color: AppColors.darkUnsat, width: 2),
                backgroundColor: AppColors.lightUnsat,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.textLight,
                backgroundColor: AppColors.darkUnsat,
              ),
              onPressed: () async {
                final projectName = controller.text.trim();

                if (projectName.isEmpty) return;

                try {
                  await PictsxReader().extractToProject(
                    pictsxFile: templateFile,
                    projectName: projectName,
                  );

                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();

                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                } catch (error) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: const Text('CREATE'),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Icon(Icons.folder_zip, size: 64, color: AppColors.medSat),
              _buildTemplateIcon(previewIconBytes, size: 64),
              const SizedBox(height: 8),
              Text(
                templateName,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  filled: true,
                  fillColor: AppColors.lightUnsat,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.darkUnsat),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightUnsat,
      appBar: const TstsTitleBar(
        title: 'PIC Tool Suite $buildTime',
        subtitle: 'Create New Project',
      ),
      body: FutureBuilder<List<File>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.darkUnsat),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: AppColors.textDark),
              ),
            );
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Center(
              child: Text(
                'No PIC templates found.',
                style: TextStyle(color: AppColors.textDark),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final templateFile in templates)
                FutureBuilder<Uint8List?>(
                  future: PictsxReader().readIconBytes(templateFile),
                  builder: (context, snapshot) {
                    return FolderListTile(
                      title: _templateName(templateFile),
                      size: 64,
                      overlayIcon: snapshot.data == null
                          ? null
                          : Image.memory(snapshot.data!, fit: BoxFit.contain),
                      isCreateTile: false,
                      onTap: () => _showNewProjectDialog(templateFile),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}


Widget _buildTemplateIcon(Uint8List? bytes, {double size = 64}) {
  if (bytes == null) {
    tsPrint("ICON Bytes were NULL");
    return Icon(Icons.folder_zip, size: size, color: AppColors.medSat);
  }

  return Image.memory(bytes, width: size, height: size, fit: BoxFit.contain);
}
