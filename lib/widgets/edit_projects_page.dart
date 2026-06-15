import 'dart:io';

import 'package:flutter/material.dart';

import '../services/project_storage.dart';
import '../theme/app_colors.dart';

class EditProjectsPage extends StatelessWidget {
  final Future<List<StoredProject>> projectsFuture;
  final Future<void> Function(StoredProject project) onOpenProject;
  final Future<void> Function(StoredProject project) onRenameProject;
  final Future<void> Function(StoredProject project) onShareProject;
  final Future<void> Function(StoredProject project) onDeleteProject;

  const EditProjectsPage({
    super.key,
    required this.projectsFuture,
    required this.onOpenProject,
    required this.onRenameProject,
    required this.onShareProject,
    required this.onDeleteProject,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoredProject>>(
      future: projectsFuture,
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

        final projects = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            for (final project in projects)
              _ProjectCard(
                project: project,
                onOpenProject: onOpenProject,
                onRenameProject: onRenameProject,
                onShareProject: onShareProject,
                onDeleteProject: onDeleteProject,
              ),
          ],
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final StoredProject project;
  final Future<void> Function(StoredProject project) onOpenProject;
  final Future<void> Function(StoredProject project) onRenameProject;
  final Future<void> Function(StoredProject project) onShareProject;
  final Future<void> Function(StoredProject project) onDeleteProject;

  const _ProjectCard({
    required this.project,
    required this.onOpenProject,
    required this.onRenameProject,
    required this.onShareProject,
    required this.onDeleteProject,
  });

  @override
  Widget build(BuildContext context) {
    const rowHeight = 52.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.lightSat,
        border: Border.all(color: AppColors.darkUnsat),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onOpenProject(project),
              child: Container(
                width: rowHeight,
                height: rowHeight,
                color: AppColors.lightUnsat,
                padding: const EdgeInsets.all(8),
                child: Image.file(
                  File(project.iconPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Container(
              width: 1,
              height: rowHeight,
              color: AppColors.darkUnsat,
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onOpenProject(project),
                child: Container(
                  height: rowHeight,
                  color: const Color.fromARGB(50, 255, 255, 255),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: rowHeight,
              color: AppColors.darkUnsat,
            ),
            SizedBox(
              width: 44,
              height: rowHeight,
              child: PopupMenuButton<_ProjectAction>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, color: AppColors.darkUnsat),
                onSelected: (action) async {
                  switch (action) {
                    case _ProjectAction.rename:
                      await onRenameProject(project);
                      break;
                    case _ProjectAction.share:
                      await onShareProject(project);
                      break;
                    case _ProjectAction.delete:
                      await onDeleteProject(project);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ProjectAction.rename,
                    child: _ProjectMenuItem(
                      icon: Icons.edit_rounded,
                      label: 'Rename',
                    ),
                  ),
                  PopupMenuItem(
                    value: _ProjectAction.share,
                    child: _ProjectMenuItem(
                      icon: Icons.share,
                      label: 'Share',
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ProjectAction.delete,
                    child: _ProjectMenuItem(
                      icon: Icons.delete_forever,
                      label: 'Delete',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProjectAction { rename, share, delete }

class _ProjectMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProjectMenuItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.darkUnsat),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
