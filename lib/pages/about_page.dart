import 'package:flutter/material.dart';

import '../build_info.dart';
import '../theme/app_colors.dart';
import '../widgets/tsts_title_bar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.medUnsat,
      appBar: const TstsTitleBar(title: 'PIC Tool Suite', subtitle: 'About'),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PIC Tool Suite',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'another tool in Trumpoot\'s Sweet Tool Suite',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Build: $buildTime',
                style: TextStyle(color: AppColors.darkUnsat),
              ),

              const SizedBox(height: 8),

              Text(
                'PIC Tool Suite is a template-driven document creation system for generating printable photo products.',
                style: TextStyle(color: AppColors.textDark, fontSize: 16),
              ),

              const SizedBox(height: 16),

              Text(
                'Supported products may include:',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text('• Class Photos'),
              const Text('• Student ID Cards'),
              const Text('• Certificates'),
              const Text('• Cake Toppers'),

              const SizedBox(height: 24),

              Text(
                'File Types',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text('.picts  - PIC Tool Suite document'),
              const Text('.pictsx - PIC Tool Suite template'),
            ],
          ),
        ),
      ),
    );
  }
}
