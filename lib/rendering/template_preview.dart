import 'dart:io';

import 'package:flutter/material.dart';

import 'template_layout_engine.dart';
import '../services/template_loader.dart';

class TemplatePreview extends StatelessWidget {
  final LoadedTemplate loadedTemplate;
  final Map<String, dynamic> documentData;
  final List<Map<String, dynamic>> rosterRows;
  final int rosterStartIndex;
  final String projectFolderPath;
  final double? previewWidth;

  const TemplatePreview({
    super.key,
    required this.loadedTemplate,
    required this.documentData,
    required this.rosterRows,
    required this.rosterStartIndex,
    required this.projectFolderPath,
    this.previewWidth,
  });

  @override
  Widget build(BuildContext context) {
    final layoutEngine = TemplateLayoutEngine(
      loadedTemplate: loadedTemplate,
      documentData: documentData,
      rosterRows: rosterRows,
      projectFolderPath: projectFolderPath,
    );
    final metrics = layoutEngine.metrics();
    final page = layoutEngine.buildPage(rosterStartIndex: rosterStartIndex);

    final aspect = metrics.widthIn / metrics.heightIn;

    if (previewWidth != null) {
      return _buildPreviewSurface(
        width: previewWidth!,
        height: previewWidth! / aspect,
        scale: previewWidth! / metrics.widthIn,
        page: page,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double fittedWidth = constraints.maxWidth;
        double fittedHeight = fittedWidth / aspect;

        if (fittedHeight > constraints.maxHeight) {
          fittedHeight = constraints.maxHeight;
          fittedWidth = fittedHeight * aspect;
        }

        return Center(
          child: _buildPreviewSurface(
            width: fittedWidth,
            height: fittedHeight,
            scale: fittedWidth / metrics.widthIn,
            page: page,
          ),
        );
      },
    );
  }

  Widget _buildPreviewSurface({
    required double width,
    required double height,
    required double scale,
    required TemplateLayoutPage page,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.white,
      child: Stack(
        children: [
          for (final element in page.elements)
            _buildElement(
              element: element,
              scale: scale,
            ),
        ],
      ),
    );
  }

  Widget _buildElement({
    required TemplateLayoutElement element,
    required double scale,
  }) {
    final left = element.rect.left * scale;
    final top = element.rect.top * scale;
    final w = element.rect.width * scale;
    final h = element.rect.height * scale;

    if (element.type == 'image') {
      final imagePath = element.imagePath ?? '';
      final fit = _resolveBoxFit(element.rawElement['fit']?.toString());
      final shape = element.rawElement['shape']?.toString() ?? 'rect';

      final isFileImage =
          imagePath.startsWith('/') || imagePath.startsWith('file:');

      final imageWidget = isFileImage
          ? Image.file(File(imagePath), fit: fit)
          : Image.asset(imagePath, fit: fit);

      return Positioned(
        left: left,
        top: top,
        width: w,
        height: h,
        child: _applyImageShape(shape: shape, child: imageWidget),
      );
    }

    if (element.type == 'text') {
      final value = element.text ?? '';
      final fontSize =
          (element.rawElement['fontSize'] ?? 0.25).toDouble() * scale;
      final colorString = element.rawElement['color']?.toString() ?? '#000000';
      final alignString = element.rawElement['align']?.toString() ?? 'left';
      final fontFamily = element.rawElement['fontFamily']?.toString();

      TextAlign textAlign = TextAlign.left;

      if (alignString == 'center') {
        textAlign = TextAlign.center;
      } else if (alignString == 'right') {
        textAlign = TextAlign.right;
      }

      final fontStyleString =
          element.rawElement['fontStyle']?.toString().toLowerCase() ?? '';

      final fontStyle = fontStyleString.contains('italic')
          ? FontStyle.italic
          : FontStyle.normal;

      final fontWeight = fontStyleString.contains('bold')
          ? FontWeight.bold
          : FontWeight.normal;

      return Positioned(
        left: left,
        top: top,
        width: w,
        height: h,
        child: CustomPaint(
          painter: _TemplateTextPainter(
            value: value,
            textStyle: TextStyle(
              fontSize: fontSize,
              height: 1.0,
              color: _parseColor(colorString),
              fontFamily: fontFamily,
              fontStyle: fontStyle,
              fontWeight: fontWeight,
            ),
            textAlign: textAlign,
            scale: scale,
            templateId: loadedTemplate.template.id,
            productType: loadedTemplate.template.productType,
            source: element.source,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  BoxFit _resolveBoxFit(String? value) {
    if (value == 'cover') {
      return BoxFit.cover;
    }

    if (value == 'contain') {
      return BoxFit.contain;
    }

    return BoxFit.fill;
  }

  Widget _applyImageShape({
    required String shape,
    required Widget child,
  }) {
    if (shape == 'oval') {
      return ClipOval(child: child);
    }

    return child;
  }

  Color _parseColor(String value) {
    final hex = value.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class _TemplateTextPainter extends CustomPainter {
  final String value;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final double scale;
  final String templateId;
  final String productType;
  final String source;

  const _TemplateTextPainter({
    required this.value,
    required this.textStyle,
    required this.textAlign,
    required this.scale,
    required this.templateId,
    required this.productType,
    required this.source,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final textWidthPx = painter.width;
    final textHeightPx = painter.height;
    final boxWidthPx = size.width;
    final boxHeightPx = size.height;

    final scaleX = textWidthPx > boxWidthPx ? boxWidthPx / textWidthPx : 1.0;
    final paintedWidthPx = textWidthPx * scaleX;

    double dx = 0;

    if (textAlign == TextAlign.center) {
      dx = (boxWidthPx - paintedWidthPx) / 2;
    } else if (textAlign == TextAlign.right) {
      dx = boxWidthPx - paintedWidthPx;
    }

    final dy = (boxHeightPx - textHeightPx) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scaleX, 1.0);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TemplateTextPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.textAlign != textAlign ||
        oldDelegate.scale != scale ||
        oldDelegate.templateId != templateId ||
        oldDelegate.productType != productType ||
        oldDelegate.source != source;
  }
}
