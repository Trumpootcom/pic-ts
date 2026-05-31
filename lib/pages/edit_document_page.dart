// lib/pages/edit_document_page.dart

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EditDocumentPage extends StatelessWidget {
  final List<dynamic> documentSchema;
  final Map<String, dynamic> documentData;
  final InputDecoration Function(String label) inputDecoration;

  const EditDocumentPage({
    super.key,
    required this.documentSchema,
    required this.documentData,
    required this.inputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          children: [
            for (final field in documentSchema)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: TextFormField(
                  initialValue: documentData[field['key']]?.toString() ?? '',
                  decoration: inputDecoration(field['label'] as String),
                  onChanged: (value) {
                    documentData[field['key']] = value;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
