import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const double historyBarHeight = 18;

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
      color: AppColors.lightUnsat,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _VerboseHistoryPainter(),
            ),
          ),
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

class _VerboseHistoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final w1 = 3*h/4;
    final w2 = w1 + h/4;

    Offset p(double x, double y) => Offset(x, h - y);

    final undoPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h)
      ..lineTo(w1, h)
      ..lineTo(w2, h / 2)
      ..lineTo(w-w2, h / 2)
      ..lineTo(w-w1, 0)
      ..close();

    final undoTargetPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h)
      ..lineTo(w1, h)
      ..lineTo(w2, h / 2)
      ..lineTo(w1, 0)
      ..close();

    final redoPath = Path()
      ..moveTo(w, h)
      ..lineTo(w, 0)
      ..lineTo(w-w1, 0)
      ..lineTo(w-w2, h / 2)
      ..lineTo(w2, h / 2)
      ..lineTo(w1, h)
      ..close();

    final redoTargetPath = Path()
      ..moveTo(w, h)
      ..lineTo(w, 0)
      ..lineTo(w - w1, 0)
      ..lineTo(w - w2, h / 2)
      ..lineTo(w - w1, h)
      ..close();

    final redoPaint = Paint()..color =AppColors.lightUnsat;
    final undoPaint = Paint()..color = AppColors.lightSat;
    final targetPaint = Paint()
      ..color = AppColors.darkUnsat.withValues(alpha: 0.04);
    final linePaint = Paint()
      ..color = AppColors.darkUnsat.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(redoPath, redoPaint);
    canvas.drawPath(undoPath, undoPaint);
    canvas.drawPath(undoTargetPath, targetPaint);
    canvas.drawPath(redoTargetPath, targetPaint);

    final dividerPath = Path()
      ..moveTo(w-w1, 0)
      ..lineTo(w-w2, h / 2)
      ..lineTo(w2, h / 2)
      ..lineTo(w1, h);

    canvas.drawPath(dividerPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _VerboseHistoryPainter oldDelegate) {
    return false;
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
          padding: const EdgeInsets.symmetric(horizontal: 5*historyBarHeight/24),
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
