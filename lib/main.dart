import 'package:flutter/material.dart';

import 'pages/template_browser_page.dart';

void main() {
  runApp(const PicTsApp());
}

class PicTsApp extends StatelessWidget {
  const PicTsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pic-ts',
      debugShowCheckedModeBanner: false,
      home: const TemplateBrowserPage(),
    );
  }
}