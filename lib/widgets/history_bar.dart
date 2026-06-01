import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HistoryBar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final String? undoText;
  final String? redoText;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const HistoryBar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.undoText,
    required this.redoText,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: AppColors.lightUnsat,
      child: Row(
        children: [
          Expanded(
            child: _HistorySide(
              alignment: Alignment.centerRight,
              icon: Icons.undo_rounded,
              enabled: canUndo,
              text: undoText,
              onTap: onUndo,
              reverse: false,
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: AppColors.darkUnsat.withValues(alpha: 0.45),
          ),
          Expanded(
            child: _HistorySide(
              alignment: Alignment.centerLeft,
              icon: Icons.redo_rounded,
              enabled: canRedo,
              text: redoText,
              onTap: onRedo,
              reverse: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySide extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final bool enabled;
  final String? text;
  final VoidCallback? onTap;
  final bool reverse;

  const _HistorySide({
    required this.alignment,
    required this.icon,
    required this.enabled,
    required this.text,
    required this.onTap,
    required this.reverse,
  });

  
  
  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.textDark
        : AppColors.textDark.withValues(alpha: 0.28);

    final label = enabled ? (text ?? '') : '';

    final children = [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: reverse ? TextAlign.left : TextAlign.right,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: reverse
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: reverse ? children.reversed.toList() : children,
        ),
      ),
    );
  }

}
