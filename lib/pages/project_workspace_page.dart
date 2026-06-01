import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../widgets/edit_document_page.dart';
import '../widgets/edit_roster_page.dart';
import 'photo_crop_page.dart';

import '../build_info.dart';
import '../rendering/template_pdf_exporter.dart';
import '../widgets/template_preview_page.dart';
import '../services/project_storage.dart';
import '../services/template_loader.dart';
import '../theme/app_colors.dart';
import '../util/ts_print.dart';
import '../widgets/tsts_title_bar.dart';
import '../widgets/workspace_icon_button.dart';
import '../widgets/workspace_filmstrip.dart';
import '../widgets/workspace_page.dart';
import '../models/workspace_carousel_item.dart';
import '../services/roster_photo_service.dart';

int defaultProfileRotationQuarterTurns = 0;

class ProjectWorkspacePage extends StatefulWidget {
  final StoredProject project;

  const ProjectWorkspacePage({super.key, required this.project});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  late Future<void> _loadFuture;
  final PageController _pageController = PageController();

  int _currentPage = 0;
  double _currentPagePosition = 0.0;

  late Map<String, dynamic> projectData;
  late List<dynamic> documentSchema;
  late List<dynamic> rosterSchema;
  late Map<String, dynamic> documentData;
  late List<Map<String, dynamic>> roster;
  late List<LoadedTemplate> templates;

  @override
  void initState() {
    super.initState();
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
    projectData = await ProjectStorage().openProject(widget.project);

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
      projectFolderPath: widget.project.folderPath,
    );
  }

  Future<void> _saveProject() async {
    projectData['documentData'] = documentData;
    projectData['roster'] = roster;

    await ProjectStorage().saveProject(
      project: widget.project,
      data: projectData,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Project Saved')));
  }

  void _addRosterRow() {
    final row = <String, dynamic>{};

    for (final field in rosterSchema) {
      final key = field['key'] as String;
      row[key] = field['default'] ?? '';
    }

    setState(() {
      roster.add(row);
    });
  }

  void _deleteRosterRow(int index) {
    setState(() {
      roster.removeAt(index);
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
    final preparedPhoto = await RosterPhotoService().pickAndPreparePhoto(
      projectFolderPath: widget.project.folderPath,
    );

    if (preparedPhoto == null) return;

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

    setState(() {
      roster[i]['profilePicture'] = p.relative(
        cropResult.croppedImagePath,
        from: widget.project.folderPath,
      );

      roster[i]['profilePictureCrop'] = {
        'cropLeft': cropResult.cropLeft,
        'cropTop': cropResult.cropTop,
        'cropWidth': cropResult.cropWidth,
        'cropHeight': cropResult.cropHeight,
        'rotationQuarterTurns': cropResult.rotationQuarterTurns,
        'rawWidth': cropResult.rawWidth,
        'rawHeight': cropResult.rawHeight,
      };
    });
  }

  Future<void> _exportTemplate(LoadedTemplate loadedTemplate) async {
    final document = Map<String, dynamic>.from(
      loadedTemplate.template.rawJson['document'] as Map? ?? {},
    );

    final output = document['output']?.toString() ?? '';

    if (output != 'pdf') {
      return;
    }

    await TemplatePdfExporter().exportAndShare(
      loadedTemplate: loadedTemplate,
      documentData: documentData,
      rosterRows: roster,
      projectFolderPath: widget.project.folderPath,
      fileName: '${loadedTemplate.template.id}.pdf',
    );
  }

  List<WorkspaceCarouselItem> _buildCarouselItems() {
    return [
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
                icon: Icons.save_rounded,
                onPressed: _saveProject,
              ),
            ],
          ),
          child: EditDocumentPage(
            documentSchema: documentSchema,
            documentData: documentData,
            inputDecoration: _inputDecoration,
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
                onPressed: _addRosterRow,
              ),
              WorkspaceIconButton(
                icon: Icons.save_rounded,
                onPressed: _saveProject,
              ),
            ],
          ),
          child: EditRosterPage(
            roster: roster,
            rosterSchema: rosterSchema,
            projectData: projectData,
            projectFolderPath: widget.project.folderPath,
            inputDecoration: _inputDecoration,
            onAddRosterRow: _addRosterRow,
            onDeleteRosterRow: _deleteRosterRow,
            onReplacePhoto: _replacePhoto,
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
              projectFolderPath: widget.project.folderPath,
            ),
          ),
        ),
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
        SafeArea(
          top: false,
          child: WorkspaceFilmstrip(
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.medUnsat,
      appBar: TstsTitleBar(
        title: 'PIC Tool Suite $buildTime',
        subtitle: widget.project.name,
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

          return _buildContentPages();
        },
      ),
    );
  }
}
