import 'package:flutter/material.dart';

import '../services/project_storage.dart';
import '../widgets/tsts_title_bar.dart';
import 'theme_browser_page.dart';

class ProjectBrowserPage extends StatefulWidget {
  const ProjectBrowserPage({super.key});

  @override
  State<ProjectBrowserPage> createState() => _ProjectBrowserPageState();
}

class _ProjectBrowserPageState extends State<ProjectBrowserPage> {
  late final Future<List<StoredProject>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = ProjectStorage().listProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TstsTitleBar(title: 'PIC Tool Suite', subtitle: 'Select Project'),
      body: FutureBuilder<List<StoredProject>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
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
                      builder: (_) => const ThemeBrowserPage(),
                    ),
                  );

                  setState(() {
                    _projectsFuture =
                        ProjectStorage().listProjects();
                  });
                },
              ),

              for (final project in projects)
                _ProjectTile(
                  projectName: project.name,
                  themeIconPath:
                      '${project.themePath}/icon.png',
                  isNewProject: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Open ${project.name}',
                        ),
                      ),
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

class _ProjectTile extends StatelessWidget {
  final String projectName;
  final String? themeIconPath;
  final bool isNewProject;
  final VoidCallback onTap;

  const _ProjectTile({
    required this.projectName,
    required this.themeIconPath,
    required this.isNewProject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double folderSize = 64;
    const double tileHeight = folderSize+0;
    const double iconSize = 28*folderSize/64;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: tileHeight,
        child: Row(
          children: [
            SizedBox(
              width: folderSize+15,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isNewProject
                        ? Icons.create_new_folder
                        : Icons.folder,
                    size: folderSize,
                    color: isNewProject
                        ? Colors.green
                        : Colors.amber,
                  ),
                  if (themeIconPath != null)
                    Positioned(
                      right: (folderSize+15-iconSize)/2,
                      top: (folderSize)/3,
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}