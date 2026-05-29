import 'package:flutter/material.dart';

import '../services/project_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/tsts_dialog.dart';
import '../widgets/tsts_title_bar.dart';
import 'project_workspace_page.dart';
import 'pic_template_browser_page.dart';

class ProjectBrowserPage extends StatefulWidget {
  const ProjectBrowserPage({super.key});

  @override
  State<ProjectBrowserPage> createState() => _ProjectBrowserPageState();
}

class _ProjectBrowserPageState extends State<ProjectBrowserPage> {
  late Future<List<StoredProject>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = ProjectStorage().listProjects();
  }

  Future<void> _showProjectActions(StoredProject project) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return TstsDialog(
          title: 'Edit Project',
          actions: null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                project.name,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();

                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProjectWorkspacePage(project: project),
                      ),
                    );

                    setState(() {
                      _projectsFuture = ProjectStorage().listProjects();
                    });
                  },
                  child: const Text('EDIT'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();

                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (confirmContext) {
                        return TstsDialog(
                          title: 'Delete Project',
                          actions: null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Delete "${project.name}"?',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textDark),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(confirmContext).pop(false);
                                  },
                                  child: const Text('CANCEL'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.of(confirmContext).pop(true);
                                  },
                                  child: const Text('DELETE'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (confirmed != true) return;

                    await ProjectStorage().deleteProject(project);

                    setState(() {
                      _projectsFuture = ProjectStorage().listProjects();
                    });
                  },
                  child: const Text('DELETE'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('CANCEL'),
                ),
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
        subtitle: 'Select Project',
      ),
      body: ColoredBox(
        color: AppColors.lightUnsat,
        child: FutureBuilder<List<StoredProject>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkUnsat,
                ),
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

            final projects = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProjectTile(
                  projectName: 'New Project',
                  themeIconPath: null,
                  isNewProject: true,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PicTemplateBrowserPage(),
                      ),
                    );

                    setState(() {
                      _projectsFuture = ProjectStorage().listProjects();
                    });
                  },
                ),
                for (final project in projects)
                  _ProjectTile(
                    projectName: project.name,
                    themeIconPath: '${project.themePath}/icon.png',
                    isNewProject: false,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProjectWorkspacePage(project: project),
                        ),
                      );

                      setState(() {
                        _projectsFuture = ProjectStorage().listProjects();
                      });
                    },
                    onLongPress: () => _showProjectActions(project),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final String projectName;
  final String? themeIconPath;
  final bool isNewProject;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ProjectTile({
    required this.projectName,
    required this.themeIconPath,
    required this.isNewProject,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const double folderSize = 64;
    const double tileHeight = folderSize + 0;
    const double iconSize = 28 * folderSize / 64;

    return Material(
      color: AppColors.lightUnsat,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: tileHeight,
          child: Row(
            children: [
              SizedBox(
                width: folderSize + 15,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isNewProject ? Icons.create_new_folder : Icons.folder,
                      size: folderSize,
                      color: isNewProject ? AppColors.darkSat : AppColors.medSat,
                    ),
                    if (themeIconPath != null)
                      Positioned(
                        right: (folderSize + 15 - iconSize) / 2,
                        top: folderSize / 3,
                        child: Image.asset(
                          themeIconPath!,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  projectName,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}