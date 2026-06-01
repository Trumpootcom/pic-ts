// lib/widgets/workspace_icon_button.dart

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class WorkspaceIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const WorkspaceIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      color: AppColors.textLight,
      icon: Icon(icon, size: 24),
      onPressed: onPressed,
    );
  }
}