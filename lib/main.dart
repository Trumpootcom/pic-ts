import 'package:flutter/material.dart';

import 'pages/project_workspace_page.dart';
import 'services/pic_template_installer.dart';
import 'theme/app_colors.dart';

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
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.darkSat,
          selectionColor: AppColors.goldUnsat.withValues(alpha: 0.35),
          selectionHandleColor: AppColors.darkSat,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.goldUnsat,
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 12,
          ),
        ),
      ),
      home: const ProjectWorkspacePage(),
    );
  }
}
