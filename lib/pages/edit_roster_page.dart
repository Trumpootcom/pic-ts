// lib/pages/edit_roster_page.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EditRosterPage extends StatelessWidget {
  final List<Map<String, dynamic>> roster;
  final List<dynamic> rosterSchema;
  final Map<String, dynamic> projectData;
  final String projectFolderPath;
  final InputDecoration Function(String label) inputDecoration;
  final VoidCallback onAddRosterRow;
  final void Function(int index) onDeleteRosterRow;
  final Future<void> Function(int index) onReplacePhoto;

  const EditRosterPage({
    super.key,
    required this.roster,
    required this.rosterSchema,
    required this.projectData,
    required this.projectFolderPath,
    required this.inputDecoration,
    required this.onAddRosterRow,
    required this.onDeleteRosterRow,
    required this.onReplacePhoto,
  });

  Widget _buildActionButton({
    IconData? icon,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: icon != null
          ? Transform.translate(
              offset: const Offset(0, -4),
              child: Icon(icon, size: iconSize),
            )
          : const SizedBox.shrink(),
    );
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
            File('$projectFolderPath/$profilePicture'),
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
              onTap: () => onReplacePhoto(i),
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
                decoration: inputDecoration(''),
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
              onPressed: () => onDeleteRosterRow(i),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                _buildActionButton(
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: onAddRosterRow,
                  iconSize: 40,
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
}