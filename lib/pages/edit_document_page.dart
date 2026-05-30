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

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.lightSat,
                  border: Border.all(color: AppColors.darkUnsat),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.only(right: 0),
                    children: [
                      for (final field in documentSchema)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: TextFormField(
                            initialValue:
                                documentData[field['key']]?.toString() ?? '',
                            decoration: inputDecoration(
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
          ],
        ),
      ),
    );
  }
}