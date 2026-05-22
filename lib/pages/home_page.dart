import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/class_photo_project.dart';
import '../widgets/bottom_tool_dock.dart';
import '../widgets/preview_pane.dart';

const bool resetDefaultProjectOnLaunch = true;

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

      final defaultJson = createDefaultProjectJson();

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
    final subtitleController = TextEditingController(text: current.subtitle.text);

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

Map<String, dynamic> createDefaultProjectJson() {
  return {
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
      "1": [[1]],
      "2": [[1, 2]],
      "3": [[1, 2, 3]],
      "4": [[1, 2], [3, 4]],
      "5": [[1, 2], [3, 4, 5]],
      "6": [[1, 2], [3, null, 4], [5, 6]],
      "7": [[1, 2], [3, 4, 5], [6, 7]],
      "8": [[1, 2, 3], [4, 5], [6, 7, 8]],
      "9": [[1, 2], [3, 4, 5], [6, 7, 8, 9]],
      "10": [[1, 2, 3], [4, 5, 6, 7], [8, 9, 10]],
      "11": [[1, 2, 3, 4], [5, 6, 7], [8, 9, 10, 11]]
    },
    "students": []
  };
}