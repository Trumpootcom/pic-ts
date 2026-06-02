import 'dart:io';

import 'package:flutter/material.dart';

import '../services/project_storage.dart';
import '../theme/app_colors.dart';

class EditProjectsPage extends StatelessWidget {
  final Future<List<StoredProject>> projectsFuture;
  final Future<void> Function(StoredProject project) onOpenProject;
  final Future<void> Function(StoredProject project) onRenameProject;
  final Future<void> Function(StoredProject project) onDeleteProject;

  const EditProjectsPage({
    super.key,
    required this.projectsFuture,
    required this.onOpenProject,
    required this.onRenameProject,
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
  final Future<void> Function(StoredProject project) onDeleteProject;

  const _ProjectCard({
    required this.project,
    required this.onOpenProject,
    required this.onRenameProject,
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
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 44,
                height: 44,
              ),
              visualDensity: VisualDensity.compact,
              color: AppColors.darkUnsat,
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => onRenameProject(project),
            ),
            Container(
              width: 1,
              height: rowHeight,
              color: AppColors.darkUnsat,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 44,
                height: 44,
              ),
              visualDensity: VisualDensity.compact,
              color: AppColors.darkUnsat,
              icon: const Icon(Icons.delete_forever),
              onPressed: () => onDeleteProject(project),
            ),
          ],
        ),
      ),
    );
  }
}
