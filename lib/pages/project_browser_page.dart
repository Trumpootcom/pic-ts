import 'package:flutter/material.dart';

import '../widgets/tsts_title_bar.dart';
import 'theme_browser_page.dart';

class ProjectBrowserPage extends StatelessWidget {
  const ProjectBrowserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TstsTitleBar(title: 'Pic-ts'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProjectTile(
            projectName: 'New Project',
            themeIconPath: null,
            isNewProject: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ThemeBrowserPage(),
                ),
              );
            },
          ),
        ],
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
    const double tileHeight = 110;
    const double folderSize = 64;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: tileHeight,
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isNewProject ? Icons.create_new_folder : Icons.folder,
                    size: folderSize,
                    color: isNewProject ? Colors.green : Colors.amber,
                  ),
                  if (themeIconPath != null)
                    Positioned(
                      right: 10,
                      bottom: 18,
                      child: Image.asset(
                        themeIconPath!,
                        width: 28,
                        height: 28,
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