import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../widgets/edit_document_page.dart';
import '../widgets/edit_projects_page.dart';
import '../widgets/edit_roster_page.dart';
import 'photo_crop_page.dart';

import '../rendering/template_jpg_exporter.dart';
import '../rendering/template_pdf_exporter.dart';
import '../widgets/template_preview_page.dart';
import '../services/project_import_service.dart';
import '../services/project_storage.dart';
import '../services/project_share_service.dart';
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
  bool _previewNavigationLocked = false;

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
    final trimmedDocumentData = _trimTrailingStringValues(documentData);
    projectData['documentData'] = trimmedDocumentData;
    projectData['roster'] = sortedRoster;

    await ProjectStorage().saveProject(
      project: project,
      data: projectData,
    );

    if (!mounted) return;

    setState(() {
      documentData = trimmedDocumentData;
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
      final row = _trimTrailingStringValues(roster[i])..remove('_rowId');
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

  Map<String, dynamic> _trimTrailingStringValues(Map<String, dynamic> values) {
    return values.map((key, value) {
      if (value is String) {
        return MapEntry(key, value.trimRight());
      }

      return MapEntry(key, value);
    });
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
          fileName: _exportFileName(
            templateName: loadedTemplate.template.name,
            projectName: project.name,
            extension: 'pdf',
          ),
        );
        return;
      }

      if (output == 'jpg' || output == 'jpeg') {
        await TemplateJpgExporter().exportAndShare(
          loadedTemplate: loadedTemplate,
          documentData: documentData,
          rosterRows: roster,
          projectFolderPath: project.folderPath,
          fileName: _exportFileName(
            templateName: loadedTemplate.template.name,
            projectName: project.name,
            extension: 'jpg',
          ),
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

  String _exportFileName({
    required String templateName,
    required String projectName,
    required String extension,
  }) {
    final safeTemplateName = _safeFileNamePart(templateName);
    final safeProjectName = _safeFileNamePart(projectName);
    final safeName = [
      if (safeTemplateName.isNotEmpty) safeTemplateName,
      if (safeProjectName.isNotEmpty) safeProjectName,
    ].join('_');

    if (safeName.isEmpty) {
      return 'export.$extension';
    }

    return '$safeName.$extension';
  }

  String _safeFileNamePart(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<void> _createProject() async {
    final templateFile = await _pickTemplateForNewProject();

    if (templateFile == null) {
      return;
    }

    final projectName = await _promptForNewProjectName(templateFile);
    final trimmedName = projectName?.trim() ?? '';

    if (trimmedName.isEmpty) {
      return;
    }

    try {
      await PictsxReader().extractToProject(
        pictsxFile: templateFile,
        projectName: trimmedName,
      );

      if (!mounted) return;

      setState(() {
        _projectsFuture = ProjectStorage().listProjects();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<File?> _pickTemplateForNewProject() async {
    return showDialog<File>(
      context: context,
      builder: (dialogContext) {
        return TstsDialog(
          title: 'New from Template',
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

                    return FutureBuilder<Uint8List?>(
                      future: PictsxReader().readIconBytes(file),
                      builder: (context, snapshot) {
                        final iconBytes = snapshot.data;

                        return ListTile(
                          leading: iconBytes == null
                              ? Icon(
                                  Icons.folder_zip_rounded,
                                  color: AppColors.darkSat,
                                )
                              : Image.memory(
                                  iconBytes,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<String?> _promptForNewProjectName(File templateFile) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _NewProjectDialog(
        templateName: _templatePackName(templateFile),
        templateFile: templateFile,
      ),
    );
  }

  Future<void> _importProject() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final file = File(result.files.single.path!);

    if (p.extension(file.path).toLowerCase() != '.picts') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a .picts project file.')),
      );
      return;
    }

    try {
      final importService = ProjectImportService();
      final packageInfo = await importService.inspectProjectPackage(file);
      var projectName = packageInfo.projectName;

      if (packageInfo.hasConflict) {
        final newName = await showDialog<String>(
          context: context,
          builder: (_) => _ImportProjectConflictDialog(
            initialName: packageInfo.projectName,
          ),
        );

        projectName = newName?.trim() ?? '';

        if (projectName.isEmpty) {
          return;
        }
      }

      final importedProject = await importService.importProjectPackage(
        packageInfo: packageInfo,
        projectName: projectName,
      );

      if (!mounted) return;

      setState(() {
        _projectsFuture = ProjectStorage().listProjects();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${importedProject.name}')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<String> _importedTemplatePackageName(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final wrapperName = _archiveWrapperFolderName(archive);

    if (wrapperName != null) {
      return wrapperName;
    }

    final dataFile = archive.findFile('data/data.json');

    if (dataFile != null) {
      final data = jsonDecode(
        utf8.decode(dataFile.content as List<int>),
      ) as Map<String, dynamic>;
      final name = data['name']?.toString().trim();
      final id = data['id']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }

      if (id != null && id.isNotEmpty) {
        return id;
      }
    }

    return p.basenameWithoutExtension(
      file.path,
    ).replaceFirst(RegExp(r'\s+\(\d+\)$'), '');
  }

  String? _archiveWrapperFolderName(Archive archive) {
    final rootNames = <String>{};

    for (final file in archive.files) {
      final safeName = file.name.replaceAll('\\', '/');

      if (safeName.isEmpty ||
          safeName.startsWith('/') ||
          safeName.split('/').contains('..')) {
        continue;
      }

      final parts = safeName.split('/').where((part) => part.isNotEmpty);
      final rootName = parts.isEmpty ? null : parts.first;

      if (rootName == null || rootName == '__MACOSX') {
        continue;
      }

      rootNames.add(rootName);
    }

    if (rootNames.length != 1) {
      return null;
    }

    final rootName = rootNames.single;

    if (rootName == 'data' ||
        rootName == 'templates' ||
        rootName == 'icon.png') {
      return null;
    }

    return rootName;
  }

  String _safeTemplateFileName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\.pictsx$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _importNewTemplate() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final file = File(result.files.single.path!);

    if (p.extension(file.path).toLowerCase() != '.pictsx') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a .pictsx template file.')),
      );
      return;
    }

    try {
      final templatesRoot = await PicTemplateInstaller().templatesRoot();
      final packageName = _safeTemplateFileName(
        await _importedTemplatePackageName(file),
      );

      if (packageName.isEmpty) {
        throw Exception('Template package name could not be found.');
      }

      var destination = File(p.join(templatesRoot.path, '$packageName.pictsx'));
      final selectedPath = p.normalize(p.absolute(file.path)).toLowerCase();
      final destinationPath =
          p.normalize(p.absolute(destination.path)).toLowerCase();

      if (selectedPath == destinationPath) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template is already installed.')),
        );
        return;
      }

      if (await destination.exists()) {
        if (!mounted) return;

        final choice = await showDialog<_ImportTemplateConflictChoice>(
          context: context,
          builder: (_) => _ImportTemplateConflictDialog(
            templateName: packageName,
          ),
        );

        if (choice == null) {
          return;
        }

        if (!choice.replaceExisting) {
          final newName = _safeTemplateFileName(choice.templateName ?? '');

          if (newName.isEmpty) {
            return;
          }

          destination = File(p.join(templatesRoot.path, '$newName.pictsx'));

          if (await destination.exists()) {
            throw Exception('Template already exists: $newName');
          }
        }
      }

      await file.copy(destination.path);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${_templatePackName(destination)}')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
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

    if (widget.project?.id == project.id) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ProjectWorkspacePage(),
        ),
      );
      return;
    }

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

  Future<void> _shareProject(StoredProject project) async {
    try {
      await ProjectShareService().shareProject(project);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
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
            color: const Color(0xFFB79852),
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
              PopupMenuButton<_ProjectsAction>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.add_rounded, color: AppColors.textLight),
                tooltip: 'Add Project',
                onSelected: (action) async {
                  switch (action) {
                    case _ProjectsAction.newFromTemplate:
                      await _createProject();
                      break;
                    case _ProjectsAction.importProject:
                      await _importProject();
                      break;
                    case _ProjectsAction.importNewTemplate:
                      await _importNewTemplate();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ProjectsAction.newFromTemplate,
                    child: _ProjectActionMenuItem(
                      icon: Icons.create_new_folder_rounded,
                      label: 'New from Template',
                    ),
                  ),
                  PopupMenuItem(
                    value: _ProjectsAction.importProject,
                    child: _ProjectActionMenuItem(
                      icon: Icons.drive_folder_upload_rounded,
                      label: 'Import Project',
                    ),
                  ),
                  PopupMenuItem(
                    value: _ProjectsAction.importNewTemplate,
                    child: _ProjectActionMenuItem(
                      icon: Icons.upload_file_rounded,
                      label: 'Import New Template',
                    ),
                  ),
                ],
              ),
            ],
          ),
          child: EditProjectsPage(
            projectsFuture: _projectsFuture,
            onOpenProject: _openProject,
            onRenameProject: _renameProject,
            onShareProject: _shareProject,
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
          title: 'Roster (${roster.length})',
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
                  icon: Icons.share,
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
              onZoomNavigationLockChanged: _setPreviewNavigationLocked,
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
            physics: _previewNavigationLocked
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
                _currentPagePosition = value.toDouble();
                _previewNavigationLocked = false;
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
            displayStyle: WorkspaceFilmstripStyle.cloud,
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

  void _setPreviewNavigationLocked(bool locked) {
    if (_previewNavigationLocked == locked) {
      return;
    }

    setState(() {
      _previewNavigationLocked = locked;
    });
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

class _NewProjectDialog extends StatefulWidget {
  final String templateName;
  final File templateFile;

  const _NewProjectDialog({
    required this.templateName,
    required this.templateFile,
  });

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _controller = TextEditingController();
  late final Future<Uint8List?> _iconBytesFuture;

  @override
  void initState() {
    super.initState();
    _iconBytesFuture = PictsxReader().readIconBytes(widget.templateFile);
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
      title: 'New from Template',
      actions: null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<Uint8List?>(
            future: _iconBytesFuture,
            builder: (context, snapshot) {
              final iconBytes = snapshot.data;

              if (iconBytes == null) {
                return Icon(
                  Icons.folder_zip_rounded,
                  size: 64,
                  color: AppColors.medSat,
                );
              }

              return Image.memory(
                iconBytes,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            widget.templateName,
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
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
              child: const Text('CREATE'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportProjectConflictDialog extends StatefulWidget {
  final String initialName;

  const _ImportProjectConflictDialog({
    required this.initialName,
  });

  @override
  State<_ImportProjectConflictDialog> createState() =>
      _ImportProjectConflictDialogState();
}

class _ImportProjectConflictDialogState
    extends State<_ImportProjectConflictDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialName} Copy');
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
      title: 'Project Exists',
      actions: null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter a new project name to continue importing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDark),
          ),
          const SizedBox(height: 18),
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
              child: const Text('CANCEL IMPORT'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('IMPORT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportTemplateConflictChoice {
  final bool replaceExisting;
  final String? templateName;

  const _ImportTemplateConflictChoice({
    required this.replaceExisting,
    this.templateName,
  });
}

class _ImportTemplateConflictDialog extends StatefulWidget {
  final String templateName;

  const _ImportTemplateConflictDialog({
    required this.templateName,
  });

  @override
  State<_ImportTemplateConflictDialog> createState() =>
      _ImportTemplateConflictDialogState();
}

class _ImportTemplateConflictDialogState
    extends State<_ImportTemplateConflictDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.templateName} Copy');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rename() {
    Navigator.of(context).pop(
      _ImportTemplateConflictChoice(
        replaceExisting: false,
        templateName: _controller.text,
      ),
    );
  }

  void _replace() {
    Navigator.of(context).pop(
      const _ImportTemplateConflictChoice(replaceExisting: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TstsDialog(
      title: 'Template Exists',
      actions: null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '"${widget.templateName}" is already installed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDark),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Template Name'),
            onSubmitted: (_) => _rename(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('CANCEL IMPORT'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _replace,
              child: const Text('REPLACE EXISTING'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rename,
              child: const Text('IMPORT WITH NEW NAME'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProjectsAction { newFromTemplate, importProject, importNewTemplate }

class _ProjectActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProjectActionMenuItem({
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
