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

    const previewHeight = 52.0;
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

    return Container(
      key: ValueKey(roster[i]),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.lightSat,
        border: Border.all(color: AppColors.darkUnsat),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onReplacePhoto(i),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                child: imageWidget,
              ),
            ),
            Container(
              width: 1,
              height: previewHeight,
              color: AppColors.darkUnsat,
            ),
            Expanded(
              child: Container(
                color: const Color.fromARGB(50, 255, 255, 255),
                alignment: Alignment.centerLeft,
                child: TextFormField(
                  key: ValueKey('fullName_${i}_${roster[i].hashCode}'),
                  initialValue: roster[i]['fullName']?.toString() ?? '',
                  decoration: _rosterInputDecoration(),
                  onChanged: (value) {
                    roster[i]['fullName'] = value;
                  },
                ),
              ),
            ),

            Container(
              width: 1,
              height: previewHeight,
              color: AppColors.darkUnsat,
            ),

            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
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

  InputDecoration _rosterInputDecoration() {
    return const InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(AppColors.darkUnsat),
                trackColor: WidgetStateProperty.all(AppColors.lightUnsat),
                trackVisibility: WidgetStateProperty.all(true),
                radius: const Radius.circular(4),
                thickness: WidgetStateProperty.all(8),
              ),
              child: Scrollbar(
                thumbVisibility: false,
                trackVisibility: false,
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
        ],
      ),
    );
  }
}
