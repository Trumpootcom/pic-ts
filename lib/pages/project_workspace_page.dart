import 'package:flutter/material.dart';

import '../services/project_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/tsts_title_bar.dart';

class ProjectWorkspacePage extends StatefulWidget {
  final StoredProject project;

  const ProjectWorkspacePage({super.key, required this.project});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  late Future<Map<String, dynamic>> _projectFuture;

  @override
  void initState() {
    super.initState();
    _projectFuture = ProjectStorage().openProject(widget.project);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSat,
      appBar: TstsTitleBar(
        title: 'PIC Tool Suite',
        subtitle: widget.project.name,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final projectData = snapshot.data!;
          final documentSchema =
              (projectData['documentSchema'] as List<dynamic>? ?? []);
          final rosterSchema =
              (projectData['rosterSchema'] as List<dynamic>? ?? []);
          final documentData = Map<String, dynamic>.from(
            projectData['documentData'] as Map? ?? {},
          );
          final roster = List<Map<String, dynamic>>.from(
            (projectData['roster'] as List<dynamic>? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    const Text(
                      'Document',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final field in documentSchema)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          initialValue:
                              documentData[field['key']]?.toString() ?? '',
                          decoration:
                              _inputDecoration(field['label'] as String),
                          onChanged: (value) {
                            documentData[field['key']] = value;
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Roster',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkUnsat,
                            foregroundColor: AppColors.textLight,
                          ),
                          onPressed: () {
                            final row = <String, dynamic>{};

                            for (final field in rosterSchema) {
                              final key = field['key'] as String;
                              row[key] = field['default'] ?? '';
                            }

                            setState(() {
                              roster.add(row);
                            });
                          },
                          child: const Text('ADD'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < roster.length; i++)
                      Card(
                        color: AppColors.medUnsat,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Image.asset(
                                roster[i]['profilePicture']?.toString() ??
                                    'assets/resources/portrait.png',
                                width: 66,
                                height: 66,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      roster[i]['fullName']?.toString() ?? '',
                                  decoration: _inputDecoration(''),
                                  onChanged: (value) {
                                    roster[i]['fullName'] = value;
                                  },
                                ),
                              ),
                              IconButton(
                                color: AppColors.darkUnsat,
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    roster.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkUnsat,
                      foregroundColor: AppColors.textLight,
                    ),
                    onPressed: () async {
                      projectData['documentData'] = documentData;
                      projectData['roster'] = roster;

                      await ProjectStorage().saveProject(
                        project: widget.project,
                        data: projectData,
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Project Saved')),
                      );
                    },
                    child: const Text('SAVE'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}