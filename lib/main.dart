import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

const bool resetDefaultProjectOnLaunch = true;

void main() {
  runApp(const PicToolSuiteApp());
}

class PicToolSuiteApp extends StatelessWidget {
  const PicToolSuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIC Tool Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

enum ActiveTool { none, title, add }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ClassPhotoProject? project;
  File? projectFile;
  String? errorText;
  ActiveTool activeTool = ActiveTool.none;

  @override
  void initState() {
    super.initState();
    _startup();
  }

  Future<void> _startup() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();

      final projectsRoot = Directory('${docsDir.path}/PIC-TS Projects');
      await projectsRoot.create(recursive: true);

      final defaultProjectDir = Directory('${projectsRoot.path}/Default');
      await defaultProjectDir.create(recursive: true);

      await Directory('${defaultProjectDir.path}/students').create(recursive: true);
      await Directory('${defaultProjectDir.path}/exports').create(recursive: true);

      final file = File('${defaultProjectDir.path}/project.json');

      final defaultJson = {
        "background": {"filename": "assets/backgrounds/bg0810.jpg"},
        "logo": {
          "filename": "assets/logos/logo.png",
          "centerX": 4.0,
          "topY": 0.5,
          "width": null,
          "height": 1.125
        },
        "title": {
          "text": "Certified Nurse Assistant Program",
          "centerX": 4.0,
          "topY": 1.75,
          "fontSize": 0.22
        },
        "subtitle": {
          "text": "June 15, 2026",
          "centerX": 4.0,
          "topY": 2.15,
          "fontSize": 0.18
        },
        "studentPortraitArea": {
          "centerX": 4.0,
          "topY": 2.75,
          "maxRows": 3,
          "maxStudents": 11,
          "ovalWidth": 1.35,
          "ovalHeight": 1.8,
          "horizontalGap": 0.375,
          "verticalGap": 0.20,
          "nameGap": 0.05,
          "fontSize": 0.12,
          "ovalFrame": "assets/resources/oval.png"
        },
        "studentLayouts": {
          "1": [
            [1]
          ],
          "2": [
            [1, 2]
          ],
          "3": [
            [1, 2, 3]
          ],
          "4": [
            [1, 2],
            [3, 4]
          ],
          "5": [
            [1, 2],
            [3, 4, 5]
          ],
          "6": [
            [1, 2],
            [3, null, 4],
            [5, 6]
          ],
          "7": [
            [1, 2],
            [3, 4, 5],
            [6, 7]
          ],
          "8": [
            [1, 2, 3],
            [4, 5],
            [6, 7, 8]
          ],
          "9": [
            [1, 2],
            [3, 4, 5],
            [6, 7, 8, 9]
          ],
          "10": [
            [1, 2, 3],
            [4, 5, 6, 7],
            [8, 9, 10]
          ],
          "11": [
            [1, 2, 3, 4],
            [5, 6, 7],
            [8, 9, 10, 11]
          ]
        },
        "students": []
      };

      if (resetDefaultProjectOnLaunch || !await file.exists()) {
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(defaultJson),
        );
      }

      final jsonText = await file.readAsString();

      setState(() {
        projectFile = file;
        project = ClassPhotoProject.fromJson(jsonDecode(jsonText));
      });
    } catch (e) {
      setState(() {
        errorText = e.toString();
      });
    }
  }

  Future<void> _saveProject(ClassPhotoProject updatedProject) async {
    setState(() {
      project = updatedProject;
    });

    if (projectFile != null) {
      await projectFile!.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedProject.toJson()),
      );
    }
  }

  Future<void> _editTitle() async {
    final current = project;
    if (current == null) return;

    setState(() {
      activeTool = ActiveTool.title;
    });

    final titleController = TextEditingController(text: current.title.text);
    final subtitleController =
        TextEditingController(text: current.subtitle.text);

    final result = await showDialog<_TitleEditResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle / Date'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _TitleEditResult(
                    title: titleController.text,
                    subtitle: subtitleController.text,
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    setState(() {
      activeTool = ActiveTool.none;
    });

    if (result == null) return;

    await _saveProject(
      current.copyWith(
        title: current.title.copyWith(text: result.title),
        subtitle: current.subtitle.copyWith(text: result.subtitle),
      ),
    );
  }

  Future<void> _addStudent() async {
    final current = project;
    if (current == null) return;

    setState(() {
      activeTool = ActiveTool.add;
    });

    final students = List<StudentSpec>.from(current.students);

    if (students.length >= current.studentPortraitArea.maxStudents) {
      if (!mounted) return;
      setState(() {
        activeTool = ActiveTool.none;
      });
      return;
    }

    final next = students.length + 1;

    students.add(
      StudentSpec(
        firstName: 'First_$next',
        lastName: 'Last_$next',
      ),
    );

    await _saveProject(
      current.copyWith(students: students),
    );

    if (!mounted) return;

    setState(() {
      activeTool = ActiveTool.none;
    });
  }

  Future<void> _removeStudent(int index) async {
    final current = project;
    if (current == null) return;

    final students = List<StudentSpec>.from(current.students);

    if (index < 0 || index >= students.length) return;

    students.removeAt(index);

    await _saveProject(
      current.copyWith(students: students),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorText != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    if (project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              width: double.infinity,
              color: const Color(0xFF263238),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'PIC Tool Suite',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: AspectRatio(
                    aspectRatio: 8 / 10,
                    child: PreviewPane(
                      project: project!,
                      onStudentTap: _removeStudent,
                    ),
                  ),
                ),
              ),
            ),
            BottomToolDock(
              activeTool: activeTool,
              onTitlePressed: _editTitle,
              onAddPressed: _addStudent,
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleEditResult {
  final String title;
  final String subtitle;

  const _TitleEditResult({
    required this.title,
    required this.subtitle,
  });
}

class BottomToolDock extends StatelessWidget {
  final ActiveTool activeTool;
  final VoidCallback onTitlePressed;
  final VoidCallback onAddPressed;

  const BottomToolDock({
    super.key,
    required this.activeTool,
    required this.onTitlePressed,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      width: double.infinity,
      color: const Color.fromARGB(255, 116, 137, 148),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ToolBubbleButton(
                iconAsset: 'assets/icons/title.svg',
                label: 'Title',
                active: activeTool == ActiveTool.title,
                onTap: onTitlePressed,
              ),
              const SizedBox(width: 14),
              ToolBubbleButton(
                iconAsset: 'assets/icons/add.svg',
                label: 'Add',
                active: activeTool == ActiveTool.add,
                onTap: onAddPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToolBubbleButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const ToolBubbleButton({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleSize = active ? 60.0 : 52.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: bubbleSize,
              height: bubbleSize,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? const Color(0xFFFF9800)
                    : const Color.fromARGB(255, 62, 101, 121),
                boxShadow: [
                  if (active)
                    const BoxShadow(
                      color: Color(0xCCFF9800),
                      blurRadius: 14,
                      spreadRadius: 2,
                    )
                  else
                    const BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                ],
              ),
              child: SvgPicture.asset(
                iconAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: active ? Colors.orange : Colors.black,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassPhotoProject {
  final BackgroundSpec background;
  final LogoSpec logo;
  final TextSpec title;
  final TextSpec subtitle;
  final StudentPortraitArea studentPortraitArea;
  final Map<String, dynamic> studentLayouts;
  final List<StudentSpec> students;

  const ClassPhotoProject({
    required this.background,
    required this.logo,
    required this.title,
    required this.subtitle,
    required this.studentPortraitArea,
    required this.studentLayouts,
    required this.students,
  });

  factory ClassPhotoProject.fromJson(Map<String, dynamic> json) {
    return ClassPhotoProject(
      background: BackgroundSpec.fromJson(json['background']),
      logo: LogoSpec.fromJson(json['logo']),
      title: TextSpec.fromJson(json['title']),
      subtitle: TextSpec.fromJson(json['subtitle']),
      studentPortraitArea:
          StudentPortraitArea.fromJson(json['studentPortraitArea']),
      studentLayouts: Map<String, dynamic>.from(json['studentLayouts']),
      students: (json['students'] as List)
          .map((e) => StudentSpec.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "background": background.toJson(),
      "logo": logo.toJson(),
      "title": title.toJson(),
      "subtitle": subtitle.toJson(),
      "studentPortraitArea": studentPortraitArea.toJson(),
      "studentLayouts": studentLayouts,
      "students": students.map((e) => e.toJson()).toList(),
    };
  }

  ClassPhotoProject copyWith({
    TextSpec? title,
    TextSpec? subtitle,
    List<StudentSpec>? students,
  }) {
    return ClassPhotoProject(
      background: background,
      logo: logo,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      studentPortraitArea: studentPortraitArea,
      studentLayouts: studentLayouts,
      students: students ?? this.students,
    );
  }
}

class BackgroundSpec {
  final String filename;

  const BackgroundSpec({
    required this.filename,
  });

  factory BackgroundSpec.fromJson(Map<String, dynamic> json) {
    return BackgroundSpec(
      filename: json['filename'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "filename": filename,
    };
  }
}

class LogoSpec {
  final String filename;
  final double centerX;
  final double topY;
  final double? width;
  final double? height;

  const LogoSpec({
    required this.filename,
    required this.centerX,
    required this.topY,
    required this.width,
    required this.height,
  });

  factory LogoSpec.fromJson(Map<String, dynamic> json) {
    return LogoSpec(
      filename: json['filename'],
      centerX: (json['centerX'] as num).toDouble(),
      topY: (json['topY'] as num).toDouble(),
      width: json['width'] == null ? null : (json['width'] as num).toDouble(),
      height:
          json['height'] == null ? null : (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "filename": filename,
      "centerX": centerX,
      "topY": topY,
      "width": width,
      "height": height,
    };
  }
}

class TextSpec {
  final String text;
  final double centerX;
  final double topY;
  final double fontSize;

  const TextSpec({
    required this.text,
    required this.centerX,
    required this.topY,
    required this.fontSize,
  });

  factory TextSpec.fromJson(Map<String, dynamic> json) {
    return TextSpec(
      text: json['text'],
      centerX: (json['centerX'] as num).toDouble(),
      topY: (json['topY'] as num).toDouble(),
      fontSize: (json['fontSize'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "centerX": centerX,
      "topY": topY,
      "fontSize": fontSize,
    };
  }

  TextSpec copyWith({
    String? text,
  }) {
    return TextSpec(
      text: text ?? this.text,
      centerX: centerX,
      topY: topY,
      fontSize: fontSize,
    );
  }
}

class StudentPortraitArea {
  final double centerX;
  final double topY;
  final int maxRows;
  final int maxStudents;
  final double? ovalWidth;
  final double? ovalHeight;
  final double horizontalGap;
  final double verticalGap;
  final double nameGap;
  final double fontSize;
  final String ovalFrame;

  const StudentPortraitArea({
    required this.centerX,
    required this.topY,
    required this.maxRows,
    required this.maxStudents,
    required this.ovalWidth,
    required this.ovalHeight,
    required this.horizontalGap,
    required this.verticalGap,
    required this.nameGap,
    required this.fontSize,
    required this.ovalFrame,
  });

  factory StudentPortraitArea.fromJson(Map<String, dynamic> json) {
    return StudentPortraitArea(
      centerX: (json['centerX'] as num).toDouble(),
      topY: (json['topY'] as num).toDouble(),
      maxRows: json['maxRows'],
      maxStudents: json['maxStudents'],
      ovalWidth: json['ovalWidth'] == null
          ? null
          : (json['ovalWidth'] as num).toDouble(),
      ovalHeight: json['ovalHeight'] == null
          ? null
          : (json['ovalHeight'] as num).toDouble(),
      horizontalGap: (json['horizontalGap'] as num).toDouble(),
      verticalGap: (json['verticalGap'] as num).toDouble(),
      nameGap: (json['nameGap'] as num).toDouble(),
      fontSize: (json['fontSize'] as num).toDouble(),
      ovalFrame: json['ovalFrame'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "centerX": centerX,
      "topY": topY,
      "maxRows": maxRows,
      "maxStudents": maxStudents,
      "ovalWidth": ovalWidth,
      "ovalHeight": ovalHeight,
      "horizontalGap": horizontalGap,
      "verticalGap": verticalGap,
      "nameGap": nameGap,
      "fontSize": fontSize,
      "ovalFrame": ovalFrame,
    };
  }
}

class StudentSpec {
  final String firstName;
  final String lastName;

  const StudentSpec({
    required this.firstName,
    required this.lastName,
  });

  factory StudentSpec.fromJson(Map<String, dynamic> json) {
    return StudentSpec(
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
    };
  }

  String get fullName => '$firstName $lastName';
}

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

    final rowContentHeightIn =
        ovalHeightIn + area.nameGap + area.fontSize;

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