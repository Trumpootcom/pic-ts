// lib/widgets/edit_roster_page.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EditRosterPage extends StatefulWidget {
  final List<Map<String, dynamic>> roster;
  final List<dynamic> rosterSchema;
  final Map<String, dynamic> projectData;
  final String projectFolderPath;
  final InputDecoration Function(String label) inputDecoration;
  final VoidCallback onAddRosterRow;
  final void Function(int index) onDeleteRosterRow;
  final Future<void> Function(int index) onReplacePhoto;
  final Future<void> Function(int index, String key, dynamic value)
      onSetRosterField;

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
    required this.onSetRosterField,
  });

  @override
  State<EditRosterPage> createState() => _EditRosterPageState();
}

class _EditRosterPageState extends State<EditRosterPage> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  String _fieldId(int index, String key) => '${index}_$key';

  @override
  void initState() {
    super.initState();
    _setupFields();
  }

  @override
  void didUpdateWidget(covariant EditRosterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupFields();
  }

  void _setupFields() {
    for (int i = 0; i < widget.roster.length; i++) {
      final value = widget.roster[i]['fullName']?.toString() ?? '';
      final id = _fieldId(i, 'fullName');

      _controllers.putIfAbsent(
        id,
        () => TextEditingController(text: value),
      );

      _focusNodes.putIfAbsent(id, () {
        final node = FocusNode();

        node.addListener(() {
          if (!node.hasFocus) {
            _commitField(i, 'fullName');
          }
        });

        return node;
      });

      if (!_focusNodes[id]!.hasFocus && _controllers[id]!.text != value) {
        _controllers[id]!.text = value;
      }
    }
  }

  Future<void> _commitField(int index, String key) async {
    final controller = _controllers[_fieldId(index, key)];

    if (controller == null) {
      return;
    }

    await widget.onSetRosterField(index, key, controller.text);
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

  Widget _buildRosterCard(int i) {
    final previewAspect =
        (widget.projectData['templateMetrics']?['profilePicturePreviewAspectRatio']
                as num?)
            ?.toDouble() ??
        1.0;

    const previewHeight = 52.0;
    final previewWidth = previewHeight * previewAspect;

    final profilePicture = widget.roster[i]['profilePicture']?.toString();

    final imageWidget =
        profilePicture == null || profilePicture.startsWith('assets/')
            ? Image.asset(
                profilePicture ?? 'assets/resources/portrait.png',
                width: previewWidth,
                height: previewHeight,
                fit: BoxFit.cover,
              )
            : Image.file(
                File('${widget.projectFolderPath}/$profilePicture'),
                width: previewWidth,
                height: previewHeight,
                fit: BoxFit.cover,
              );

    final id = _fieldId(i, 'fullName');

    return Container(
      key: ValueKey(widget.roster[i]),
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
              onTap: () => widget.onReplacePhoto(i),
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
                  key: ValueKey('fullName_$i'),
                  controller: _controllers[id],
                  focusNode: _focusNodes[id],
                  decoration: _rosterInputDecoration(),
                  onFieldSubmitted: (_) {
                    _commitField(i, 'fullName');
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
              onPressed: () => widget.onDeleteRosterRow(i),
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
                    for (int i = 0; i < widget.roster.length; i++)
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