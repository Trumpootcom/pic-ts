import 'package:flutter/material.dart';

import '../models/template_definition.dart';
import '../rendering/template_preview.dart';
import '../services/project_storage.dart';
import '../services/template_loader.dart';
import '../theme/app_colors.dart';
import '../widgets/tsts_title_bar.dart';

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

  Widget _buildMenuButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkUnsat,
        foregroundColor: AppColors.textLight,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildMenuBar() {
    final pageCount = templates.length + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      color: AppColors.medSat,
      child: Row(
        children: [
          _buildMenuButton(label: 'SAVE', onPressed: _saveProject),
          const Spacer(),
          Text(
            'Page ${_currentPage + 1} of $pageCount',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterCard(int i) {
    return Card(
      key: ValueKey(roster[i]),
      color: AppColors.medSat,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Image.asset(
              roster[i]['profilePicture']?.toString() ??
                  'assets/resources/portrait.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: ValueKey('fullName_${i}_${roster[i].hashCode}'),
                initialValue: roster[i]['fullName']?.toString() ?? '',
                decoration: _inputDecoration('Full Name'),
                onChanged: (value) {
                  roster[i]['fullName'] = value;
                },
              ),
            ),
            IconButton(
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        children: [
          Text(
            'Raw Data Entry',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Document',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          for (final field in documentSchema)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(
                initialValue: documentData[field['key']]?.toString() ?? '',
                decoration: _inputDecoration(field['label'] as String),
                onChanged: (value) {
                  documentData[field['key']] = value;
                },
              ),
            ),

          const SizedBox(height: 16),

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
              _buildMenuButton(label: 'ADD', onPressed: _addRosterRow),
            ],
          ),

          const SizedBox(height: 8),

          for (int i = 0; i < roster.length; i++) _buildRosterCard(i),
        ],
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
            Text(
              template.name,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

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
              _buildMenuBar(),
              Expanded(child: _buildContentPages()),
            ],
          );
        },
      ),
    );
  }
}
