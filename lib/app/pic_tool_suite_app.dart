import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../build_info.dart';

class PicToolSuiteApp extends StatelessWidget {
  const PicToolSuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIC Tool Suite $gitCommit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}