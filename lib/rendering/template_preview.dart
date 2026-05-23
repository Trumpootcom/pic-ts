import 'package:flutter/material.dart';

import '../services/template_loader.dart';

class TemplatePreview extends StatelessWidget {
  final LoadedTemplate loadedTemplate;
  final Map<String, dynamic> documentData;
  final Map<String, dynamic>? rosterRow;

  const TemplatePreview({
    super.key,
    required this.loadedTemplate,
    required this.documentData,
    required this.rosterRow,
  });

  @override
  Widget build(BuildContext context) {
    final json = loadedTemplate.template.rawJson;

    final document = Map<String, dynamic>.from(json['document'] as Map? ?? {});

    final roster = Map<String, dynamic>.from(json['roster'] as Map? ?? {});

    final documentElements = (document['elements'] as List<dynamic>? ?? []);

    final rosterElements = (roster['elements'] as List<dynamic>? ?? []);

    final widthIn = (document['width'] ?? 11).toDouble();
    final heightIn = (document['height'] ?? 8.5).toDouble();

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
                ...documentElements.map(
                  (e) => _buildElement(
                    Map<String, dynamic>.from(e as Map),
                    scale,
                    documentData,
                  ),
                ),

                ...rosterElements.map(
                  (e) => _buildElement(
                    Map<String, dynamic>.from(e as Map),
                    scale,
                    rosterRow ?? {},
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildElement(
    Map<String, dynamic> element,
    double scale,
    Map<String, dynamic> sourceData,
  ) {
    final type = element['type']?.toString() ?? '';

    final x = ((element['x'] ?? 0).toDouble()) * scale;
    final y = ((element['y'] ?? 0).toDouble()) * scale;
    final w = ((element['w'] ?? 1).toDouble()) * scale;
    final h = ((element['h'] ?? 1).toDouble()) * scale;

    if (type == 'image') {
      final source = element['source']?.toString() ?? '';

      return Positioned(
        left: x,
        top: y,
        width: w,
        height: h,
        child: Image.asset(loadedTemplate.assetPath(source), fit: BoxFit.fill),
      );
    }

    if (type == 'text') {
      final source = element['source']?.toString() ?? '';

      final value = sourceData[source]?.toString() ?? '';

      final fontSize = ((element['fontSize'] ?? 0.25).toDouble()) * scale;

      final colorString = element['color']?.toString() ?? '#000000';

      final alignString = element['align']?.toString() ?? 'left';

      TextAlign textAlign = TextAlign.left;

      if (alignString == 'center') {
        textAlign = TextAlign.center;
      }

      if (alignString == 'right') {
        textAlign = TextAlign.right;
      }

      final anchor = element['anchor']?.toString() ?? 'topLeft';

      double left = x;
      double top = y;

      if (anchor == 'topCenter') {
        left = x - (w / 2);
        top = y;
      } else if (anchor == 'center') {
        left = x - (w / 2);
        top = y - (h / 2);
      } else if (anchor == 'centerLeft') {
        left = x;
        top = y - (h / 2);
      } else if (anchor == 'centerRight') {
        left = x - w;
        top = y - (h / 2);
      } else if (anchor == 'topRight') {
        left = x - w;
        top = y;
      } else if (anchor == 'bottomLeft') {
        left = x;
        top = y - h;
      } else if (anchor == 'bottomCenter') {
        left = x - (w / 2);
        top = y - h;
      } else if (anchor == 'bottomRight') {
        left = x - w;
        top = y - h;
      }

      final fontStyleString =
          element['fontStyle']?.toString().toLowerCase() ?? '';

      FontStyle fontStyle = FontStyle.normal;

      if (fontStyleString.contains('italic')) {
        fontStyle = FontStyle.italic;
      }

      FontWeight fontWeight = FontWeight.normal;

      if (fontStyleString.contains('bold')) {
        fontWeight = FontWeight.bold;
      }
      final fontFamily = element['fontFamily']?.toString();

      return Positioned(
        left: left,
        top: top,
        width: w,
        height: h,
        child: Text(
          value,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            color: _parseColor(colorString),
            fontStyle: fontStyle,
            fontWeight: fontWeight,
            fontFamily: fontFamily
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _parseColor(String value) {
    final hex = value.replaceAll('#', '');

    return Color(int.parse('FF$hex', radix: 16));
  }
}
