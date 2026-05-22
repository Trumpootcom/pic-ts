import 'package:flutter/material.dart';

import '../pages/home_page.dart';

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