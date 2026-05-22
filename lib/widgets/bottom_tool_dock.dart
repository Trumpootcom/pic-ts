import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import 'tool_bubble_button.dart';

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