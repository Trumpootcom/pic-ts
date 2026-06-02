import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const double historyBarHeight = 20;

class HistoryBar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final String? undoText;
  final String? redoText;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool verbose;

  const HistoryBar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.undoText,
    required this.redoText,
    required this.onUndo,
    required this.onRedo,
    this.verbose = false,
  });

  @override
  Widget build(BuildContext context) {
    if (verbose) {
      return _VerboseHistoryBar(
        canUndo: canUndo,
        canRedo: canRedo,
        undoText: undoText,
        redoText: redoText,
        onUndo: onUndo,
        onRedo: onRedo,
      );
    }

    return Container(
      height: historyBarHeight,
      color: AppColors.lightUnsat,
      child: Row(
        children: [
          Expanded(
            child: _HistorySide(
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

class _VerboseHistoryBar extends StatelessWidget {
  static const double _height = historyBarHeight * 2;

  final bool canUndo;
  final bool canRedo;
  final String? undoText;
  final String? redoText;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const _VerboseHistoryBar({
    required this.canUndo,
    required this.canRedo,
    required this.undoText,
    required this.redoText,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    final undoColor = canUndo
        ? AppColors.textDark
        : AppColors.textDark.withValues(alpha: 0.28);
    final redoColor = canRedo
        ? AppColors.textDark
        : AppColors.textDark.withValues(alpha: 0.28);

    return Container(
      height: _height,
      color: AppColors.darkUnsat,
      child: Stack(
        children: [
          const Positioned.fill(child: _HistoryBarBackground(height: _height)),
          Positioned(
            left: _height * 1.1,
            right: _height * 1.1,
            top: 1,
            child: Text(
              canUndo ? (undoText ?? '') : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: undoColor,
                fontSize: _height/4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            left: _height * 1.1,
            right: _height * 1.1,
            bottom: 1,
            child: Text(
              canRedo ? (redoText ?? '') : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: redoColor,
                fontSize: _height/4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: _height * 1,
            height: _height,
            child: _VerboseHistoryButton(
              icon: Icons.fast_rewind_rounded,
              iconSize: _height * 0.8,
              enabled: canUndo,
              color: undoColor,
              alignment: Alignment.center,
              onTap: onUndo,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            width: _height * 1,
            height: _height*1,
            child: _VerboseHistoryButton(
              icon: Icons.fast_forward_rounded,
              iconSize: _height * 0.8,
              enabled: canRedo,
              color: redoColor,
              alignment: Alignment.centerRight,
              onTap: onRedo,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBarBackground extends StatelessWidget {
  static const double _capSourceWidth = 140;
  static const double _sourceHeight = 100;

  final double height;

  const _HistoryBarBackground({required this.height});

  @override
  Widget build(BuildContext context) {
    final capWidth = height * _capSourceWidth / _sourceHeight;
    final capOverlapWidth = capWidth.floorToDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final middleWidth =
            constraints.maxWidth - capOverlapWidth - capOverlapWidth;

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: SizedBox(
                width: middleWidth.clamp(0, constraints.maxWidth),
                height: height,
                child: Image.asset(
                  'assets/backgrounds/trumpoot_histbar_m.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: capWidth,
                height: height,
                child: Image.asset(
                  'assets/backgrounds/trumpoot_histbar_l.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: capWidth,
                height: height,
                child: Image.asset(
                  'assets/backgrounds/trumpoot_histbar_r.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VerboseHistoryButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final bool enabled;
  final Color color;
  final Alignment alignment;
  final VoidCallback? onTap;

  const _VerboseHistoryButton({
    required this.icon,
    required this.iconSize,
    required this.enabled,
    required this.color,
    required this.alignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 3 * historyBarHeight / 24,
          ),
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}

class _HistorySide extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String? text;
  final VoidCallback? onTap;
  final bool reverse;

  const _HistorySide({
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
