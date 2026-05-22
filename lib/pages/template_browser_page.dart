import 'package:flutter/material.dart';
import 'package:pic_ts/widgets/tsts_title_bar.dart';

import '../services/template_loader.dart';
import '../pages/project_editor_page.dart';
import '../services/project_factory.dart';
import '../widgets/tsts_title_bar.dart';

class TemplateBrowserPage extends StatefulWidget {
  const TemplateBrowserPage({super.key});

  @override
  State<TemplateBrowserPage> createState() => _TemplateBrowserPageState();
}

class _TemplateBrowserPageState extends State<TemplateBrowserPage> {
  late final Future<List<LoadedTemplate>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = TemplateLoader().loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TstsTitleBar(title: 'PIC Tool Suite'),
      body: FutureBuilder<List<LoadedTemplate>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return const Center(child: Text('No templates found.'));
          }

          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final loaded = templates[index];

              return ListTile(
                leading: Image.asset(
                  loaded.assetPath(loaded.template.preview),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
                title: Text(loaded.template.name),
                subtitle: Text('${loaded.themeId} / ${loaded.productFolder}'),
                onTap: () {
                  final project = ProjectFactory().createBlankProject(loaded);

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectEditorPage(
                        loadedTemplate: loaded,
                        project: project,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
