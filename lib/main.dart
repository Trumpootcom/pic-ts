import 'package:flutter/material.dart';

import 'pages/project_browser_page.dart';
import 'services/pic_template_installer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('INSTALLING TEMPLATES...');
    await PicTemplateInstaller().installBundledTemplates();
    debugPrint('TEMPLATE INSTALL COMPLETE');
  } catch (e, st) {
    debugPrint('TEMPLATE INSTALL FAILED');
    debugPrint('$e');
    debugPrint('$st');
  }

  runApp(const PicTsApp());
}

class PicTsApp extends StatelessWidget {
  const PicTsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pic-ts',
      debugShowCheckedModeBanner: false,
      home: const ProjectBrowserPage(),
    );
  }
}