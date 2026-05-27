import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'photo_crop_page.dart';

import '../models/template_definition.dart';
import '../rendering/template_pdf_exporter.dart';
import '../rendering/template_preview.dart';
import '../services/project_storage.dart';
import '../services/template_loader.dart';
import '../util/ts_print.dart';
import '../theme/app_colors.dart';
import '../widgets/tsts_title_bar.dart';

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
  int _selectedRosterIndex = 0;
  late Map<String, dynamic> projectData;
  late List<dynamic> documentSchema;
  late List<dynamic> rosterSchema;
  late Map<String, dynamic> documentData;
  late List<Map<String, dynamic>> roster;
  late List<LoadedTemplate> templates;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadProject();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    final allTemplates = await TemplateLoader().loadTemplates();

    templates = allTemplates
        .where((template) => template.themeId == widget.project.themeId)
        .toList();
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
      fillColor: AppColors.lightUnsat,
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

  String _workspaceSubtitle() {
    if (_currentPage == 0) {
      return 'Data Entry';
    }

    final templateIndex = _currentPage - 1;
    if (templateIndex < 0 || templateIndex >= templates.length) {
      return '';
    }

    return templates[templateIndex].template.name;
  }

  Widget _buildSubtitleActionButton({
    String? label,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.only(right: 0, top: 0),
        child: icon != null
            ? Icon(icon, size: 34)
            : Text(
                label ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSubtitleBar() {
    final pageCount = templates.length + 1;
    final title = _workspaceSubtitle();
    const subtitleBarHt = 40.0;
    final leftImageW = 90 * 1.0;

    final Widget action = _currentPage == 0
        ? _buildSubtitleActionButton(icon: Icons.save, onPressed: _saveProject)
        : _buildSubtitleActionButton(
            icon: Icons.file_present,
            onPressed: _exportCurrentTemplate,
          );

    return SizedBox(
      height: 35,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/backgrounds/trumpoot_titlebar_d.png',
            fit: BoxFit.fill,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: leftImageW,
              height: subtitleBarHt,
              child: Image.asset(
                'assets/backgrounds/trumpoot_titlebar_c.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: leftImageW + 5),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontFeatures: [FontFeature.enable('smcp')],
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: action,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _replacePhoto(int i) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    final sourceFile = File(result.files.single.path!);

    final photosDir = Directory('${widget.project.folderPath}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final safeName = DateTime.now().millisecondsSinceEpoch.toString();
    final extension = p.extension(sourceFile.path);
    final destination = File('${photosDir.path}/$safeName$extension');

    tsPrint('SOURCE FILE: ${sourceFile.path}');

    final bytes = await sourceFile.readAsBytes();
    tsPrint('SOURCE BYTES: ${bytes.length}');

    final decoded = img.decodeImage(bytes);
    tsPrint('DECODED NULL? ${decoded == null}');
    if (decoded != null) {
      tsPrint('DECODED SIZE: ${decoded.width} x ${decoded.height}');
    }
    if (decoded == null) {
      await sourceFile.copy(destination.path);
    } else {
      final normalized = img.bakeOrientation(decoded);
      tsPrint('NORMALIZED SIZE: ${normalized.width} x ${normalized.height}');

      await destination.writeAsBytes(img.encodeJpg(normalized, quality: 95));
      tsPrint('WROTE NORMALIZED JPG: ${destination.path}');
    }

    final cropResult = await Navigator.of(context).push<PhotoCropResult>(
      MaterialPageRoute(
        builder: (_) => PhotoCropPage(
          imagePath: destination.path,
          croppedImagePath:
              '${widget.project.folderPath}/photos/cropped_$safeName.jpg',
          initialRotationQuarterTurns: defaultProfileRotationQuarterTurns,
          profilePictureCrops:
              (projectData['templateMetrics']?['profilePictureCrops'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [],
        ),
      ),
    );

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

  Widget _buildRosterCard(int i) {
    final previewAspect =
        (projectData['templateMetrics']?['profilePicturePreviewAspectRatio']
                as num?)
            ?.toDouble() ??
        1.0;

    const previewHeight = 44.0;
    final previewWidth = previewHeight * previewAspect;

    final profilePicture = roster[i]['profilePicture']?.toString();

    final imageWidget =
        profilePicture == null || profilePicture.startsWith('assets/')
        ? Image.asset(
            profilePicture ?? 'assets/resources/portrait.png',
            width: previewWidth,
            height: previewHeight,
            fit: BoxFit.cover,
          )
        : Image.file(
            File('${widget.project.folderPath}/$profilePicture'),
            width: previewWidth,
            height: previewHeight,
            fit: BoxFit.cover,
          );

    return Card(
      key: ValueKey(roster[i]),
      color: AppColors.medSat,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 5),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _replacePhoto(i),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.darkUnsat),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: imageWidget,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: ValueKey('fullName_${i}_${roster[i].hashCode}'),
                initialValue: roster[i]['fullName']?.toString() ?? '',
                decoration: _inputDecoration(''), //'Full Name'
                onChanged: (value) {
                  roster[i]['fullName'] = value;
                },
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              color: AppColors.darkUnsat,
              icon: const Icon(Icons.close),
              onPressed: () => _deleteRosterRow(i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawDataPage() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height / 5,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.lightSat,
                  border: Border.all(color: AppColors.darkUnsat),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(right: 0),
                    children: [
                      for (final field in documentSchema)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: TextFormField(
                            initialValue:
                                documentData[field['key']]?.toString() ?? '',
                            decoration: _inputDecoration(
                              field['label'] as String,
                            ),
                            onChanged: (value) {
                              documentData[field['key']] = value;
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Roster (${roster.length})',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSubtitleActionButton(
                  icon: Icons.add_reaction,
                  onPressed: _addRosterRow,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightSat,
                  border: Border.all(color: AppColors.darkUnsat),
                ),
                child: ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(AppColors.darkUnsat),
                    trackColor: WidgetStateProperty.all(AppColors.lightUnsat),
                    trackVisibility: WidgetStateProperty.all(true),
                    radius: const Radius.circular(4),
                    thickness: WidgetStateProperty.all(8),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView(
                      padding: const EdgeInsets.only(right: 0),
                      children: [
                        for (int i = 0; i < roster.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 0),
                            child: _buildRosterCard(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePage(LoadedTemplate loadedTemplate) {
    final TemplateDefinition template = loadedTemplate.template;
    final hasRoster = roster.isNotEmpty;

    if (_selectedRosterIndex >= roster.length && roster.isNotEmpty) {
      _selectedRosterIndex = roster.length - 1;
    }
    final placement = Map<String, dynamic>.from(
      loadedTemplate.template.rawJson['document']['placement'] as Map? ?? {},
    );

    final maxRosterPerPage = placement['maxRosterPerPage'] as int? ?? 1;
    final pageStart = _selectedRosterIndex + 1;

    final pageEnd = (_selectedRosterIndex + maxRosterPerPage).clamp(
      1,
      roster.length,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  color: AppColors.darkUnsat,
                  onPressed: hasRoster && _selectedRosterIndex > 0
                      ? () {
                          setState(() {
                            _selectedRosterIndex -= maxRosterPerPage;

                            if (_selectedRosterIndex < 0) {
                              _selectedRosterIndex = 0;
                            }
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),

                Expanded(
                  child: Text(
                    hasRoster
                        ? maxRosterPerPage > 1
                              ? 'Students $pageStart-$pageEnd of ${roster.length}'
                              : 'Student $pageStart of ${roster.length}'
                        : 'No students',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  color: AppColors.darkUnsat,
                  onPressed:
                      hasRoster && _selectedRosterIndex < roster.length - 1
                      ? () {
                          setState(() {
                            _selectedRosterIndex += maxRosterPerPage;

                            if (_selectedRosterIndex >= roster.length) {
                              _selectedRosterIndex =
                                  ((roster.length - 1) ~/ maxRosterPerPage) *
                                  maxRosterPerPage;
                            }
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightUnsat,
                  border: Border.all(color: AppColors.darkUnsat),
                ),
                child: Center(
                  child: TemplatePreview(
                    loadedTemplate: loadedTemplate,
                    documentData: documentData,
                    rosterRows: roster,
                    rosterStartIndex: hasRoster ? _selectedRosterIndex : 0,
                    projectFolderPath: widget.project.folderPath,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPages() {
    return PageView.builder(
      controller: _pageController,
      physics: const PageScrollPhysics(),
      onPageChanged: (value) {
        setState(() {
          _currentPage = value;
        });
      },
      itemCount: templates.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildRawDataPage();
        }

        return _buildTemplatePage(templates[index - 1]);
      },
    );
  }

  Future<void> _exportCurrentTemplate() async {
    if (_currentPage <= 0) {
      return;
    }

    final loadedTemplate = templates[_currentPage - 1];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSat,
      appBar: TstsTitleBar(
        title: 'PIC Tool Suite',
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

          return Column(
            children: [
              _buildSubtitleBar(),
              Expanded(child: _buildContentPages()),
            ],
          );
        },
      ),
    );
  }
}
