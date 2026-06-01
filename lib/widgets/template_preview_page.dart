// lib/widgets/template_preview_page.dart

import 'package:flutter/material.dart';

import '../rendering/template_preview.dart';
import '../services/template_loader.dart';
import '../theme/app_colors.dart';

class TemplatePreviewPage extends StatefulWidget {
  final LoadedTemplate loadedTemplate;
  final Map<String, dynamic> documentData;
  final List<Map<String, dynamic>> roster;
  final String projectFolderPath;

  const TemplatePreviewPage({
    super.key,
    required this.loadedTemplate,
    required this.documentData,
    required this.roster,
    required this.projectFolderPath,
  });

  @override
  State<TemplatePreviewPage> createState() => _TemplatePreviewPageState();
}

class _TemplatePreviewPageState extends State<TemplatePreviewPage> {
  int _selectedRosterIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_selectedRosterIndex >= widget.roster.length &&
        widget.roster.isNotEmpty) {
      _selectedRosterIndex = widget.roster.length - 1;
    }

    final placement = Map<String, dynamic>.from(
      widget.loadedTemplate.template.rawJson['document']['placement'] as Map? ??
          {},
    );

    final maxRosterPerPage = placement['maxRosterPerPage'] as int? ?? 1;
    final isSinglePage = maxRosterPerPage <= 0;
    final effectiveRosterPerPage = isSinglePage ? 1 : maxRosterPerPage;
    final hasRoster = !isSinglePage && widget.roster.isNotEmpty;
    final pageStart = hasRoster ? _selectedRosterIndex + 1 : 0;

    final pageEnd = hasRoster
        ? (_selectedRosterIndex + effectiveRosterPerPage).clamp(
            1,
            widget.roster.length,
          )
        : 0;

    return Padding(
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
                          _selectedRosterIndex -= effectiveRosterPerPage;

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
                  isSinglePage
                      ? 'Single page'
                      : hasRoster
                      ? effectiveRosterPerPage > 1
                            ? 'Students $pageStart-$pageEnd of ${widget.roster.length}'
                            : 'Student $pageStart of ${widget.roster.length}'
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
                    hasRoster && _selectedRosterIndex < widget.roster.length - 1
                    ? () {
                        setState(() {
                          _selectedRosterIndex += effectiveRosterPerPage;

                          if (_selectedRosterIndex >= widget.roster.length) {
                            _selectedRosterIndex =
                                ((widget.roster.length - 1) ~/
                                    maxRosterPerPage) *
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
            child: Center(
              child: TemplatePreview(
                loadedTemplate: widget.loadedTemplate,
                documentData: widget.documentData,
                rosterRows: isSinglePage ? const [] : widget.roster,
                rosterStartIndex: isSinglePage ? 0 : _selectedRosterIndex,
                projectFolderPath: widget.projectFolderPath,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
