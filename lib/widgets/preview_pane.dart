import 'package:flutter/material.dart';

import '../models/class_photo_project.dart';

class PreviewPane extends StatelessWidget {
  final ClassPhotoProject project;
  final void Function(int index) onStudentTap;

  const PreviewPane({
    super.key,
    required this.project,
    required this.onStudentTap,
  });

  static const double pageWidthInches = 8;
  static const double defaultOvalWidthInches = 1.35;
  static const double defaultOvalHeightInches = 1.8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelsPerInch = constraints.maxWidth / pageWidthInches;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black26),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Color(0x66000000),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  project.background.filename,
                  fit: BoxFit.cover,
                ),
              ),
              _buildLogo(pixelsPerInch),
              _buildCenteredText(
                spec: project.title,
                pixelsPerInch: pixelsPerInch,
                fontWeight: FontWeight.bold,
              ),
              _buildCenteredText(
                spec: project.subtitle,
                pixelsPerInch: pixelsPerInch,
                fontWeight: FontWeight.w500,
              ),
              ..._buildStudents(
                pixelsPerInch: pixelsPerInch,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo(double pixelsPerInch) {
    final logoWidthIn = project.logo.width ?? 5.0;

    return Positioned(
      top: project.logo.topY * pixelsPerInch,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: logoWidthIn * pixelsPerInch,
          child: Image.asset(project.logo.filename),
        ),
      ),
    );
  }

  Widget _buildCenteredText({
    required TextSpec spec,
    required double pixelsPerInch,
    required FontWeight fontWeight,
  }) {
    return Positioned(
      top: spec.topY * pixelsPerInch,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          spec.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: spec.fontSize * pixelsPerInch,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudents({
    required double pixelsPerInch,
  }) {
    final area = project.studentPortraitArea;

    final layoutRaw = project.studentLayouts['${project.students.length}'];

    if (layoutRaw == null) return [];

    final layout = (layoutRaw as List)
        .map((row) => (row as List).map((cell) => cell as int?).toList())
        .toList();

    final ovalWidthIn = area.ovalWidth ?? defaultOvalWidthInches;
    final ovalHeightIn = area.ovalHeight ?? defaultOvalHeightInches;

    final rowContentHeightIn = ovalHeightIn + area.nameGap + area.fontSize;

    final rowStrideIn = rowContentHeightIn + area.verticalGap;

    final usedHeightIn =
        (layout.length * rowContentHeightIn) +
        ((layout.length - 1) * area.verticalGap);

    final maxAreaHeightIn =
        (area.maxRows * rowContentHeightIn) +
        ((area.maxRows - 1) * area.verticalGap);

    final topStartIn = area.topY + ((maxAreaHeightIn - usedHeightIn) / 2);

    final widgets = <Widget>[];

    for (int r = 0; r < layout.length; r++) {
      final row = layout[r];

      final rowWidthIn =
          (row.length * ovalWidthIn) +
          ((row.length - 1) * area.horizontalGap);

      final leftStartIn = area.centerX - (rowWidthIn / 2);

      for (int c = 0; c < row.length; c++) {
        final value = row[c];

        if (value == null) continue;

        final studentIndex = value - 1;

        if (studentIndex < 0 || studentIndex >= project.students.length) {
          continue;
        }

        final student = project.students[studentIndex];

        final leftPx =
            (leftStartIn + (c * (ovalWidthIn + area.horizontalGap))) *
            pixelsPerInch;

        final topPx = (topStartIn + (r * rowStrideIn)) * pixelsPerInch;

        widgets.add(
          Positioned(
            left: leftPx,
            top: topPx,
            width: ovalWidthIn * pixelsPerInch,
            child: GestureDetector(
              onTap: () => onStudentTap(studentIndex),
              child: Column(
                children: [
                  SizedBox(
                    width: ovalWidthIn * pixelsPerInch,
                    height: ovalHeightIn * pixelsPerInch,
                    child: Image.asset(
                      area.ovalFrame,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: area.nameGap * pixelsPerInch),
                  Text(
                    student.fullName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: area.fontSize * pixelsPerInch,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}