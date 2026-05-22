import 'package:flutter/material.dart';

import '../models/theme_pack.dart';
import '../services/project_storage.dart';
import '../services/theme_pack_loader.dart';
import '../theme/app_colors.dart';
import '../widgets/tsts_dialog.dart';
import '../widgets/tsts_title_bar.dart';
import 'project_workspace_page.dart';

class ThemeBrowserPage extends StatefulWidget {
  const ThemeBrowserPage({super.key});

  @override
  State<ThemeBrowserPage> createState() => _ThemeBrowserPageState();
}

class _ThemeBrowserPageState extends State<ThemeBrowserPage> {
  late final Future<List<ThemePack>> _themePacksFuture;

  @override
  void initState() {
    super.initState();
    _themePacksFuture = ThemePackLoader().loadThemePacks();
  }

  Future<void> _showNewProjectDialog(ThemePack pack) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return TstsDialog(
          title: 'Create New Project',
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: BorderSide(color: AppColors.darkUnsat, width: 2),
                backgroundColor: AppColors.lightUnsat,
              ),
              onPressed: () => Navigator.of(context).pop(),
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
                  final projectDir = await ProjectStorage().createProject(
                    projectName: projectName,
                    themePack: pack,
                  );

                  Navigator.of(context).pop();

                  final storedProjects = await ProjectStorage().listProjects();

                  final createdProject = storedProjects.firstWhere(
                    (p) => p.id == projectDir.path.split('/').last,
                  );

                  if (!this.context.mounted) return;

                  await Navigator.of(this.context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectWorkspacePage(project: createdProject),
                    ),
                  );

                  if (!this.context.mounted) return;

                  Navigator.of(this.context).pop();
                } catch (error) {
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: const Text('CREATE'),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(pack.iconPath, width: 64, height: 64),
              const SizedBox(height: 8),
              Text(
                pack.name,
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
        title: 'PIC Tool Suite',
        subtitle: 'Create New Project',
      ),
      body: FutureBuilder<List<ThemePack>>(
        future: _themePacksFuture,
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

          final packs = snapshot.data ?? [];

          if (packs.isEmpty) {
            return Center(
              child: Text(
                'No theme packs found.',
                style: TextStyle(color: AppColors.textDark),
              ),
            );
          }

          return ColoredBox(
            color: AppColors.lightUnsat,
            child: GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.9,
              ),
              itemCount: packs.length,
              itemBuilder: (context, index) {
                return _ThemePackTile(
                  pack: packs[index],
                  onTap: () => _showNewProjectDialog(packs[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ThemePackTile extends StatelessWidget {
  final ThemePack pack;
  final VoidCallback onTap;

  static const double folderWidth = 120;

  const _ThemePackTile({required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightUnsat,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: folderWidth,
              height: 90 * folderWidth / 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.folder,
                    size: 100 * folderWidth / 120,
                    color: AppColors.medSat,
                  ),
                  Positioned(
                    right: (folderWidth - 42 * folderWidth / 120) / 2,
                    bottom: 14 * folderWidth / 120,
                    child: Image.asset(
                      pack.iconPath,
                      width: 42 * folderWidth / 120,
                      height: 42 * folderWidth / 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              pack.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}