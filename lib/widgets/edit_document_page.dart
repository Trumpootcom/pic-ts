// lib/widgets/edit_document_page.dart

import 'package:flutter/material.dart';

class EditDocumentPage extends StatefulWidget {
  final List<dynamic> documentSchema;
  final Map<String, dynamic> documentData;
  final InputDecoration Function(String label) inputDecoration;
  final Future<void> Function(String key, dynamic value) onSetDocumentField;

  const EditDocumentPage({
    super.key,
    required this.documentSchema,
    required this.documentData,
    required this.inputDecoration,
    required this.onSetDocumentField,
  });

  @override
  State<EditDocumentPage> createState() => _EditDocumentPageState();
}

class _EditDocumentPageState extends State<EditDocumentPage> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _setupFields();
  }

  @override
  void didUpdateWidget(covariant EditDocumentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupFields();
  }

  void _setupFields() {
    for (final field in widget.documentSchema) {
      final key = field['key'] as String;
      final value = widget.documentData[key]?.toString() ?? '';

      _controllers.putIfAbsent(
        key,
        () => TextEditingController(text: value),
      );

      _focusNodes.putIfAbsent(key, () {
        final node = FocusNode();

        node.addListener(() {
          if (!node.hasFocus) {
            _commitField(key);
          }
        });

        return node;
      });

      if (!_focusNodes[key]!.hasFocus && _controllers[key]!.text != value) {
        _controllers[key]!.text = value;
      }
    }
  }

  Future<void> _commitField(String key) async {
    final controller = _controllers[key];

    if (controller == null) {
      return;
    }

    await widget.onSetDocumentField(key, controller.text);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    for (final node in _focusNodes.values) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          children: [
            for (final field in widget.documentSchema)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: TextFormField(
                  controller: _controllers[field['key'] as String],
                  focusNode: _focusNodes[field['key'] as String],
                  decoration: widget.inputDecoration(field['label'] as String),
                  onFieldSubmitted: (_) {
                    _commitField(field['key'] as String);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}