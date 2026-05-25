import 'package:flutter/material.dart';

import '../services/template_loader.dart';

class TemplatePreview extends StatelessWidget {
  final LoadedTemplate loadedTemplate;
  final Map<String, dynamic> documentData;
  final List<Map<String, dynamic>> rosterRows;
  final int rosterStartIndex;

  const TemplatePreview({
    super.key,
    required this.loadedTemplate,
    required this.documentData,
    required this.rosterRows,
    required this.rosterStartIndex,
  });

  @override
  Widget build(BuildContext context) {
    final json = loadedTemplate.template.rawJson;

    final document = Map<String, dynamic>.from(json['document'] as Map? ?? {});
    final roster = Map<String, dynamic>.from(json['roster'] as Map? ?? {});
    final placement = Map<String, dynamic>.from(
      document['placement'] as Map? ?? {},
    );

    final documentElements = document['elements'] as List<dynamic>? ?? [];
    final rosterElements = roster['elements'] as List<dynamic>? ?? [];
    final slots = placement['slots'] as List<dynamic>? ?? [];

    final widthIn = (document['width'] ?? 11).toDouble();
    final heightIn = (document['height'] ?? 8.5).toDouble();

    final rosterWidthIn = (roster['width'] ?? widthIn).toDouble();
    final rosterHeightIn = (roster['height'] ?? heightIn).toDouble();

    final maxRosterPerPage = placement['maxRosterPerPage'] as int? ?? 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final aspect = widthIn / heightIn;

        double previewWidth = constraints.maxWidth;
        double previewHeight = previewWidth / aspect;

        if (previewHeight > constraints.maxHeight) {
          previewHeight = constraints.maxHeight;
          previewWidth = previewHeight * aspect;
        }

        final scale = previewWidth / widthIn;

        return Center(
          child: Container(
            width: previewWidth,
            height: previewHeight,
            color: Colors.white,
            child: Stack(
              children: [
                for (final element in documentElements)
                  _buildElement(
                    element: Map<String, dynamic>.from(element as Map),
                    scale: scale,
                    sourceData: documentData,
                    offsetXIn: 0,
                    offsetYIn: 0,
                    slotScaleX: 1,
                    slotScaleY: 1,
                  ),

                for (int i = 0; i < slots.length && i < maxRosterPerPage; i++)
                  if (rosterStartIndex + i < rosterRows.length)
                    ..._buildRosterSlot(
                      slot: Map<String, dynamic>.from(slots[i] as Map),
                      rosterElements: rosterElements,
                      rosterRow: rosterRows[rosterStartIndex + i],
                      rosterWidthIn: rosterWidthIn,
                      rosterHeightIn: rosterHeightIn,
                      scale: scale,
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildRosterSlot({
    required Map<String, dynamic> slot,
    required List<dynamic> rosterElements,
    required Map<String, dynamic> rosterRow,
    required double rosterWidthIn,
    required double rosterHeightIn,
    required double scale,
  }) {
    final slotX = (slot['x'] ?? 0).toDouble();
    final slotY = (slot['y'] ?? 0).toDouble();
    final slotW = (slot['w'] ?? rosterWidthIn).toDouble();
    final slotH = (slot['h'] ?? rosterHeightIn).toDouble();

    final slotScaleX = slotW / rosterWidthIn;
    final slotScaleY = slotH / rosterHeightIn;

    return [
      for (final element in rosterElements)
        _buildElement(
          element: Map<String, dynamic>.from(element as Map),
          scale: scale,
          sourceData: rosterRow,
          offsetXIn: slotX,
          offsetYIn: slotY,
          slotScaleX: slotScaleX,
          slotScaleY: slotScaleY,
        ),
    ];
  }

  Widget _buildElement({
    required Map<String, dynamic> element,
    required double scale,
    required Map<String, dynamic> sourceData,
    required double offsetXIn,
    required double offsetYIn,
    required double slotScaleX,
    required double slotScaleY,
  }) {
    final type = element['type']?.toString() ?? '';

    final rawX = (element['x'] ?? 0).toDouble();
    final rawY = (element['y'] ?? 0).toDouble();
    final rawW = (element['w'] ?? 1).toDouble();
    final rawH = (element['h'] ?? 1).toDouble();

    final x = (offsetXIn + (rawX * slotScaleX)) * scale;
    final y = (offsetYIn + (rawY * slotScaleY)) * scale;
    final w = rawW * slotScaleX * scale;
    final h = rawH * slotScaleY * scale;

    final anchor = element['anchor']?.toString() ?? 'topLeft';

    double left = x;
    double top = y;

    if (anchor == 'topCenter') {
      left = x - (w / 2);
    } else if (anchor == 'center') {
      left = x - (w / 2);
      top = y - (h / 2);
    } else if (anchor == 'centerLeft') {
      top = y - (h / 2);
    } else if (anchor == 'centerRight') {
      left = x - w;
      top = y - (h / 2);
    } else if (anchor == 'topRight') {
      left = x - w;
    } else if (anchor == 'bottomLeft') {
      top = y - h;
    } else if (anchor == 'bottomCenter') {
      left = x - (w / 2);
      top = y - h;
    } else if (anchor == 'bottomRight') {
      left = x - w;
      top = y - h;
    }

    if (type == 'image') {
      final imagePath = _resolveImagePath(element, sourceData);
      final fit = _resolveBoxFit(element['fit']?.toString());

      return Positioned(
        left: left,
        top: top,
        width: w,
        height: h,
        child: Image.asset(imagePath, fit: fit),
      );
    }

    if (type == 'text') {
      final source = element['source']?.toString() ?? '';
      String value = sourceData[source]?.toString() ?? '';

      final transform = element['transform']?.toString();

      if (transform == 'firstNameLastInitial') {
        value = _firstNameLastInitial(value);
      }

      final fontSize = (element['fontSize'] ?? 0.25).toDouble() * scale;
      final colorString = element['color']?.toString() ?? '#000000';
      final alignString = element['align']?.toString() ?? 'left';
      final fontFamily = element['fontFamily']?.toString();

      TextAlign textAlign = TextAlign.left;

      if (alignString == 'center') {
        textAlign = TextAlign.center;
      } else if (alignString == 'right') {
        textAlign = TextAlign.right;
      }

      final fontStyleString =
          element['fontStyle']?.toString().toLowerCase() ?? '';

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
            source: source,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _firstNameLastInitial(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      return parts.first;
    }

    final firstName = parts.first;
    final lastInitial = parts.last[0];

    return '$firstName $lastInitial.';
  }

  String _resolveImagePath(
    Map<String, dynamic> element,
    Map<String, dynamic> sourceData,
  ) {
    final source = element['source']?.toString() ?? '';

    final value = sourceData[source]?.toString();

    if (value != null && value.trim().isNotEmpty) {
      return value;
    }

    if (source == 'profilePicture') {
      return 'assets/resources/portrait.png';
    }

    if (source.startsWith('assets/')) {
      return source;
    }

    return loadedTemplate.assetPath(source);
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

  Alignment _textAlignment(TextAlign textAlign) {
    if (textAlign == TextAlign.center) {
      return Alignment.center;
    }

    if (textAlign == TextAlign.right) {
      return Alignment.centerRight;
    }

    return Alignment.centerLeft;
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

    final textWidthIn = textWidthPx / scale;
    final boxWidthIn = boxWidthPx / scale;
    final boxHeightIn = boxHeightPx / scale;

    final scaleX = textWidthPx > boxWidthPx ? boxWidthPx / textWidthPx : 1.0;
    final paintedWidthPx = textWidthPx * scaleX;

    double dx = 0;

    if (textAlign == TextAlign.center) {
      dx = (boxWidthPx - paintedWidthPx) / 2;
    } else if (textAlign == TextAlign.right) {
      dx = boxWidthPx - paintedWidthPx;
    }

    final dy = (boxHeightPx - textHeightPx) / 2;

/*    debugPrint(
      'PAINT TEXT | '
      'template="$templateId" | '
      'product="$productType" | '
      'source="$source" | '
      'value="$value"\n'
      '  fontSize: '
      '${(textStyle.fontSize ?? 0).toStringAsFixed(2)} px | '
      '${((textStyle.fontSize ?? 0) / scale).toStringAsFixed(3)} in\n'
      '  textWidth: '
      '${textWidthPx.toStringAsFixed(2)} px | '
      '${textWidthIn.toStringAsFixed(3)} in\n'
      '  boxWidth: '
      '${boxWidthPx.toStringAsFixed(2)} px | '
      '${boxWidthIn.toStringAsFixed(3)} in\n'
      '  boxHeight: '
      '${boxHeightPx.toStringAsFixed(2)} px | '
      '${boxHeightIn.toStringAsFixed(3)} in\n'
      '  scale: ${scale.toStringAsFixed(3)} px/in\n'
      '  scaleX: ${scaleX.toStringAsFixed(3)} | '
      'dx=${dx.toStringAsFixed(2)} | '
      'dy=${dy.toStringAsFixed(2)}',
    );
*/
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
