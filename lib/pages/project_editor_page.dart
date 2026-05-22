import 'package:flutter/material.dart';

import '../models/project_data.dart';
import '../services/template_loader.dart';

class ProjectEditorPage extends StatefulWidget {
  final LoadedTemplate loadedTemplate;
  final ProjectData project;

  const ProjectEditorPage({
    super.key,
    required this.loadedTemplate,
    required this.project,
  });

  @override
  State<ProjectEditorPage> createState() => _ProjectEditorPageState();
}

class _ProjectEditorPageState extends State<ProjectEditorPage> {
  late ProjectData project;

  List<dynamic> get documentFields =>
      widget.loadedTemplate.template.rawJson['data']?['document'] ?? [];

  List<dynamic> get detailFields =>
      widget.loadedTemplate.template.rawJson['data']?['detail'] ?? [];

  @override
  void initState() {
    super.initState();
    project = widget.project;
  }

  void addDetail() {
    final row = <String, dynamic>{};

    for (final field in detailFields) {
      final fieldMap = field as Map<String, dynamic>;
      row[fieldMap['key'] as String] = '';
    }

    setState(() {
      project.details.add(row);
    });
  }

  void deleteDetail(int index) {
    setState(() {
      project.details.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loadedTemplate.template.name),
      ),
      body: Column(
        children: [
          _DocumentFields(
            fields: documentFields,
            data: project.documentData,
            onChanged: () => setState(() {}),
          ),
          const Divider(height: 1),
          Expanded(
            child: _DetailList(
              fields: detailFields,
              details: project.details,
              onAdd: addDetail,
              onDelete: deleteDetail,
              onChanged: () => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentFields extends StatelessWidget {
  final List<dynamic> fields;
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  const _DocumentFields({
    required this.fields,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final field in fields)
            _DynamicTextField(
              field: field as Map<String, dynamic>,
              data: data,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  final List<dynamic> fields;
  final List<Map<String, dynamic>> details;
  final VoidCallback onAdd;
  final void Function(int index) onDelete;
  final VoidCallback onChanged;

  const _DetailList({
    required this.fields,
    required this.details,
    required this.onAdd,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Details'),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAdd,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: details.length,
            itemBuilder: (context, index) {
              final row = details[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            for (final field in fields)
                              _DynamicTextField(
                                field: field as Map<String, dynamic>,
                                data: row,
                                onChanged: onChanged,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => onDelete(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DynamicTextField extends StatelessWidget {
  final Map<String, dynamic> field;
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  const _DynamicTextField({
    required this.field,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final keyName = field['key'] as String;
    final label = field['label'] as String? ?? keyName;

    return TextFormField(
      initialValue: data[keyName]?.toString() ?? '',
      decoration: InputDecoration(labelText: label),
      onChanged: (value) {
        data[keyName] = value;
        onChanged();
      },
    );
  }
}