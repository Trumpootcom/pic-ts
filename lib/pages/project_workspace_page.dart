import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../widgets/edit_document_page.dart';
import '../widgets/edit_projects_page.dart';
import '../widgets/edit_roster_page.dart';
import 'pic_template_browser_page.dart';
import 'photo_crop_page.dart';

import '../rendering/template_jpg_exporter.dart';
import '../rendering/template_pdf_exporter.dart';
import '../widgets/template_preview_page.dart';
import '../services/project_storage.dart';
import '../services/template_loader.dart';
import '../theme/app_colors.dart';
import '../widgets/tsts_dialog.dart';
import '../widgets/tsts_title_bar.dart';
import '../widgets/workspace_icon_button.dart';
import '../widgets/workspace_filmstrip.dart';
import '../widgets/workspace_page.dart';
import '../models/workspace_carousel_item.dart';
import '../services/roster_photo_service.dart';
import '../services/pic_template_installer.dart';
import '../services/pictsx_reader.dart';
import '../models/history_manager.dart';
import '../services/history_storage.dart';
import '../widgets/history_bar.dart';

int defaultProfileRotationQuarterTurns = 0;
late HistoryManager historyManager;

class ProjectWorkspacePage extends StatefulWidget {
  final StoredProject? project;

  const ProjectWorkspacePage({super.key, this.project});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  late Future<void> _loadFuture;
  late final PageController _pageController;

  late int _currentPage;
  late double _currentPagePosition;

  late Map<String, dynamic> projectData;
  late List<dynamic> documentSchema;
  late List<dynamic> rosterSchema;
  late Map<String, dynamic> documentData;
  late List<Map<String, dynamic>> roster;
  late List<LoadedTemplate> templates;
  late Future<List<StoredProject>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.project == null ? 0 : 2;

    _currentPage = initialPage;
    _currentPagePosition = initialPage.toDouble();
    _pageController = PageController(initialPage: initialPage);
    _pageController.addListener(_handlePageScroll);
    _loadFuture = _loadProject();
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageScroll() {
    final page = _pageController.page;
    if (page == null) return;

    setState(() {
      _currentPagePosition = page;
    });
  }

  Future<void> _loadProject() async {
    _projectsFuture = ProjectStorage().listProjects();

    final project = widget.project;
    if (project == null) {
      return;
    }

    projectData = await ProjectStorage().openProject(project);

    documentSchema = projectData['documentSchema'] as List<dynamic>? ?? [];
    rosterSchema = projectData['rosterSchema'] as List<dynamic>? ?? [];

    documentData = Map<String, dynamic>.from(
      projectData['documentData'] as Map? ?? {},
    );

    roster = List<Map<String, dynamic>>.from(
      (projectData['roster'] as List<dynamic>? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    templates = await TemplateLoader().loadProjectTemplates(
      projectFolderPath: project.folderPath,
    );
    historyManager = HistoryManager(
      storage: HistoryStorage(project: project),
    );

    await historyManager.load();
  }

  Future<void> _saveProject() async {
    final project = widget.project;
    if (project == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return TstsDialog(
          title: 'Save Project',
          actions: null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Save Changes and Clear UNDO/REDO History?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDark),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('SAVE'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || confirmed != true) return;

    await historyManager.clear(projectData);

    final sortedRoster = _rosterSortedForSave();
    projectData['documentData'] = documentData;
    projectData['roster'] = sortedRoster;

    await ProjectStorage().saveProject(
      project: project,
      data: projectData,
    );

    if (!mounted) return;

    setState(() {
      roster = sortedRoster;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Project Saved')));
  }

  List<Map<String, dynamic>> _rosterSortedForSave() {
    final defaultFullName = _rosterFieldDefault('fullName').trim();
    final sortedRoster = <Map<String, dynamic>>[];
    final originalOrder = <Map<String, dynamic>, int>{};

    for (int i = 0; i < roster.length; i++) {
      final row = Map<String, dynamic>.from(roster[i])..remove('_rowId');
      sortedRoster.add(row);
      originalOrder[row] = i;
    }

    sortedRoster.sort((a, b) {
      final aName = a['fullName']?.toString().trim() ?? '';
      final bName = b['fullName']?.toString().trim() ?? '';
      final aIsDefault = aName.isEmpty || aName == defaultFullName;
      final bIsDefault = bName.isEmpty || bName == defaultFullName;

      if (aIsDefault != bIsDefault) {
        return aIsDefault ? -1 : 1;
      }

      if (aIsDefault && bIsDefault) {
        return (originalOrder[a] ?? 0).compareTo(originalOrder[b] ?? 0);
      }

      final nameCompare = _lastNameSortKey(aName).compareTo(
        _lastNameSortKey(bName),
      );

      if (nameCompare != 0) {
        return nameCompare;
      }

      return (originalOrder[a] ?? 0).compareTo(originalOrder[b] ?? 0);
    });

    return sortedRoster;
  }

  String _lastNameSortKey(String fullName) {
    final parts = fullName
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      return parts.first;
    }

    final lastName = parts.removeLast();
    return '$lastName ${parts.join(' ')}';
  }

  String _rosterFieldDefault(String key) {
    for (final field in rosterSchema) {
      if (field is! Map) {
        continue;
      }

      if (field['key'] == key) {
        return field['default']?.toString() ?? '';
      }
    }

    return '';
  }

  Future<void> _addRosterRow() async {
    final row = <String, dynamic>{};

    for (final field in rosterSchema) {
      final key = field['key'] as String;
      row[key] = field['default'] ?? '';
    }

    await historyManager.insertRosterRow(
      projectData: projectData,
      index: 0,
      row: row,
    );

    if (!mounted) return;

    setState(() {
      roster = List<Map<String, dynamic>>.from(
        (projectData['roster'] as List<dynamic>).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
    });
  }

  Future<void> _deleteRosterRow(int index) async {
    if (index < 0 || index >= roster.length) {
      return;
    }

    final fullName = roster[index]['fullName']?.toString().trim() ?? '';
    final rosterLabel = 'Roster ${index + 1}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return TstsDialog(
          title: 'Delete Roster',
          actions: null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '¿¿DELETE??',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: '\n$rosterLabel'),
                    if (fullName.isNotEmpty)
                      TextSpan(
                        text: '\n$fullName',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDark),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('DELETE'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || confirmed != true) return;

    await historyManager.deleteRosterRow(
      projectData: projectData,
      index: index,
    );

    if (!mounted) return;

    setState(() {
      roster = List<Map<String, dynamic>>.from(
        (projectData['roster'] as List<dynamic>).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color.fromARGB(50, 255, 255, 255),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.darkUnsat),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.darkSat, width: 2),
      ),
    );
  }

  Future<void> _replacePhoto(int i) async {
    final project = widget.project;
    if (project == null) return;

    final preparedPhoto = await RosterPhotoService().pickAndPreparePhoto(
      projectFolderPath: project.folderPath,
    );

    if (preparedPhoto == null) return;
    if (!mounted) return;

    final cropResult = await Navigator.of(context).push<PhotoCropResult>(
      MaterialPageRoute(
        builder: (_) => PhotoCropPage(
          imagePath: preparedPhoto.tempImagePath,
          targetWidthPx:
              projectData['templateMetrics']?['profilePictureMaxRenderWidthPx'] ??
              600,
          targetHeightPx:
              projectData['templateMetrics']?['profilePictureMaxRenderHeightPx'] ??
              900,
          croppedImagePath: preparedPhoto.croppedImagePath,
          initialRotationQuarterTurns: defaultProfileRotationQuarterTurns,
          profilePictureCrops:
              (projectData['templateMetrics']?['profilePictureCrops'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [],
        ),
      ),
    );

    await RosterPhotoService().deleteTempPhoto(preparedPhoto.tempImagePath);

    if (cropResult == null) return;

    defaultProfileRotationQuarterTurns = cropResult.rotationQuarterTurns;
    final relativePath = p.relative(
      cropResult.croppedImagePath,
      from: project.folderPath,
    );

    await historyManager.setRosterField(
      projectData: projectData,
      index: i,
      key: 'profilePicture',
      newValue: relativePath,
    );

    if (!mounted) return;

    setState(() {
      roster = List<Map<String, dynamic>>.from(
        (projectData['roster'] as List<dynamic>).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
    });
  }

  Future<List<File>> _loadInstalledTemplateFiles() async {
    final root = await PicTemplateInstaller().templatesRoot();

    if (!await root.exists()) {
      return [];
    }

    final files = root
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.pictsx'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    return files;
  }

  String _templatePackName(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    return name.replaceAll(RegExp(r'\.pictsx$', caseSensitive: false), '');
  }

  Future<File?> _pickInstalledTemplatePack() async {
    return showDialog<File>(
      context: context,
      builder: (dialogContext) {
        return TstsDialog(
          title: 'Add Templates',
          actions: null,
          child: SizedBox(
            width: 420,
            height: 360,
            child: FutureBuilder<List<File>>(
              future: _loadInstalledTemplateFiles(),
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
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  );
                }

                final files = snapshot.data ?? [];

                if (files.isEmpty) {
                  return Center(
                    child: Text(
                      'No PIC templates found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: files.length,
                  separatorBuilder: (context, index) => Divider(
                    color: AppColors.darkUnsat.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final file = files[index];

                    return ListTile(
                      leading: Icon(
                        Icons.folder_zip_rounded,
                        color: AppColors.darkSat,
                      ),
                      title: Text(
                        _templatePackName(file),
                        style: TextStyle(color: AppColors.textDark),
                      ),
                      onTap: () => Navigator.of(dialogContext).pop(file),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _addTemplatesToProject() async {
    final project = widget.project;
    if (project == null) return;

    final templatePack = await _pickInstalledTemplatePack();

    if (templatePack == null) {
      return;
    }

    try {
      await PictsxReader().importTemplatesToProject(
        pictsxFile: templatePack,
        projectFolderPath: project.folderPath,
      );

      await ProjectStorage().refreshProjectSchema(
        project: project,
        projectData: projectData,
      );

      await ProjectStorage().saveProject(
        project: project,
        data: projectData,
      );

      templates = await TemplateLoader().loadProjectTemplates(
        projectFolderPath: project.folderPath,
      );

      documentSchema = projectData['documentSchema'] as List<dynamic>? ?? [];
      rosterSchema = projectData['rosterSchema'] as List<dynamic>? ?? [];
      documentData = Map<String, dynamic>.from(
        projectData['documentData'] as Map? ?? {},
      );
      roster = List<Map<String, dynamic>>.from(
        (projectData['roster'] as List<dynamic>? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Templates Added')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _exportTemplate(LoadedTemplate loadedTemplate) async {
    final project = widget.project;
    if (project == null) return;

    final document = Map<String, dynamic>.from(
      loadedTemplate.template.rawJson['document'] as Map? ?? {},
    );

    final output = (document['output']?.toString() ?? '').toLowerCase();

    try {
      if (output == 'pdf') {
        await TemplatePdfExporter().exportAndShare(
          loadedTemplate: loadedTemplate,
          documentData: documentData,
          rosterRows: roster,
          projectFolderPath: project.folderPath,
          fileName: '${loadedTemplate.template.id}.pdf',
        );
        return;
      }

      if (output == 'jpg' || output == 'jpeg') {
        await TemplateJpgExporter().exportAndShare(
          loadedTemplate: loadedTemplate,
          documentData: documentData,
          rosterRows: roster,
          projectFolderPath: project.folderPath,
          fileName: '${loadedTemplate.template.id}.jpg',
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unsupported export type: $output')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _createProject() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PicTemplateBrowserPage(),
      ),
    );

    if (!mounted || created != true) return;

    setState(() {
      _projectsFuture = ProjectStorage().listProjects();
    });
  }

  Future<void> _openProject(StoredProject project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectWorkspacePage(project: project),
      ),
    );

    if (!mounted) return;

    setState(() {
      _projectsFuture = ProjectStorage().listProjects();
    });
  }

  Future<void> _confirmDeleteProject(StoredProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('DELETE'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || confirmed != true) return;

    await ProjectStorage().deleteProject(project);

    if (!mounted) return;

    setState(() {
      _projectsFuture = ProjectStorage().listProjects();
    });
  }

  Future<void> _renameProject(StoredProject project) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameProjectDialog(initialName: project.name),
    );

    final trimmedName = newName?.trim() ?? '';

    if (!mounted || trimmedName.isEmpty || trimmedName == project.name) {
      return;
    }

    await ProjectStorage().renameProject(project: project, name: trimmedName);

    if (!mounted) return;

    setState(() {
      _projectsFuture = ProjectStorage().listProjects();
    });
  }

  List<WorkspaceCarouselItem> _buildCarouselItems() {
    final project = widget.project;

    return [
      WorkspaceCarouselItem(
        title: 'Projects',
        thumbnail: SizedBox(
          width: 110,
          height: 85,
          child: Container(
            color: AppColors.lightUnsat,
            alignment: Alignment.center,
            child: Icon(
              Icons.folder_rounded,
              color: AppColors.darkSat,
              size: 84,
            ),
          ),
        ),
        page: WorkspacePage(
          title: 'Projects',
          actions: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WorkspaceIconButton(
                icon: Icons.create_new_folder_rounded,
                onPressed: _createProject,
              ),
            ],
          ),
          child: EditProjectsPage(
            projectsFuture: _projectsFuture,
            onOpenProject: _openProject,
            onRenameProject: _renameProject,
            onDeleteProject: _confirmDeleteProject,
          ),
        ),
      ),
      if (project != null) ...[
      WorkspaceCarouselItem(
        title: 'Properties',
        thumbnail: Image.asset(
          'assets/icons/properties.png',
          fit: BoxFit.cover,
        ),
        page: WorkspacePage(
          title: 'Properties',
          actions: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WorkspaceIconButton(
                icon: Icons.library_add_rounded,
                tooltip: 'Add Templates to Project',
                onPressed: _addTemplatesToProject,
              ),
            ],
          ),
          child: EditDocumentPage(
            documentSchema: documentSchema,
            documentData: documentData,
            inputDecoration: _inputDecoration,
            onSetDocumentField: (key, value) async {
              await historyManager.setDocumentField(
                projectData: projectData,
                key: key,
                newValue: value,
              );

              setState(() {
                documentData = Map<String, dynamic>.from(
                  projectData['documentData'] as Map,
                );
              });
            },
          ),
        ),
      ),
      WorkspaceCarouselItem(
        title: 'Roster',
        thumbnail: Image.asset('assets/icons/roster.png', fit: BoxFit.cover),
        page: WorkspacePage(
          title: 'Roster',
          actions: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WorkspaceIconButton(
                icon: Icons.person_add_alt_1_rounded,
                tooltip: 'Add Roster',
                onPressed: () => _addRosterRow(),
              ),
            ],
          ),
          child: EditRosterPage(
            roster: roster,
            rosterSchema: rosterSchema,
            projectData: projectData,
            projectFolderPath: project.folderPath,
            inputDecoration: _inputDecoration,
            onAddRosterRow: () => _addRosterRow(),
            onDeleteRosterRow: (index) => _deleteRosterRow(index),
            onReplacePhoto: _replacePhoto,
            onSetRosterField: (index, key, value) async {
              await historyManager.setRosterField(
                projectData: projectData,
                index: index,
                key: key,
                newValue: value,
              );

              setState(() {
                roster = List<Map<String, dynamic>>.from(
                  (projectData['roster'] as List<dynamic>).map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ),
                );
              });
            },
          ),
        ),
      ),
      for (final loadedTemplate in templates)
        WorkspaceCarouselItem(
          title: loadedTemplate.template.name,
          thumbnail: Image.file(
            File(loadedTemplate.assetPath('preview.jpg')),
            fit: BoxFit.cover,
          ),
          page: WorkspacePage(
            title: loadedTemplate.template.name,
            actions: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WorkspaceIconButton(
                  icon: Icons.file_present,
                  onPressed: () => _exportTemplate(loadedTemplate),
                ),
              ],
            ),
            child: TemplatePreviewPage(
              key: PageStorageKey(
                'template-preview-${loadedTemplate.template.id}',
              ),
              loadedTemplate: loadedTemplate,
              documentData: documentData,
              roster: roster,
              projectFolderPath: project.folderPath,
            ),
          ),
        ),
      ],
    ];
  }

  Widget _buildContentPages() {
    final pages = _buildCarouselItems();

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
                _currentPagePosition = value.toDouble();
              });
            },
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return pages[index].page;
            },
          ),
        ),
        if (pages.length > 1)
          WorkspaceFilmstrip(
            items: pages.map((page) => page.filmstripItem).toList(),
            currentIndex: _currentPage,
            currentPagePosition: _currentPagePosition,
            onPagePositionChanged: (pagePosition) {
              if (!_pageController.hasClients) return;

              _pageController.jumpTo(
                pagePosition * _pageController.position.viewportDimension,
              );
            },
            /*
              onTap: (index) {
                _pageController.jumpToPage(index);
              },*/
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            },
          ),
      ],
    );
  }

  Widget _buildHistoryBar() {
    if (widget.project == null) {
      return const SizedBox.shrink();
    }

    return HistoryBar(
      verbose: true,
      canUndo: historyManager.canUndo,
      canRedo: historyManager.canRedo,
      undoText: historyManager.undoDescription(
        documentSchema: documentSchema,
        rosterSchema: rosterSchema,
      ),
      redoText: historyManager.redoDescription(
        documentSchema: documentSchema,
        rosterSchema: rosterSchema,
      ),
      onUndo: () async {
        await historyManager.undo(projectData);

        setState(() {
          documentData = Map<String, dynamic>.from(
            projectData['documentData'] as Map,
          );

          roster = List<Map<String, dynamic>>.from(
            (projectData['roster'] as List<dynamic>).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
        });
      },
      onRedo: () async {
        await historyManager.redo(projectData);

        setState(() {
          documentData = Map<String, dynamic>.from(
            projectData['documentData'] as Map,
          );

          roster = List<Map<String, dynamic>>.from(
            (projectData['roster'] as List<dynamic>).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
        });
      },
      onSave: _saveProject,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.medUnsat,
      appBar: TstsTitleBar(
        title: 'PIC Tool Suite',
        subtitle: widget.project?.name ?? 'Select Project',
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
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
          return SafeArea(
            top: false,
            child: Column(
              children: [
                _buildHistoryBar(),
                Expanded(child: _buildContentPages()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RenameProjectDialog extends StatefulWidget {
  final String initialName;

  const _RenameProjectDialog({required this.initialName});

  @override
  State<_RenameProjectDialog> createState() => _RenameProjectDialogState();
}

class _RenameProjectDialogState extends State<_RenameProjectDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return TstsDialog(
      title: 'Rename Project',
      actions: null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Project Name'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('CANCEL'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('RENAME'),
            ),
          ),
        ],
      ),
    );
  }
}
