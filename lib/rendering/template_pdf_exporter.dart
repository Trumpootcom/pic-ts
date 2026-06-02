import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../util/ts_print.dart';
import '../services/template_loader.dart';

class TemplatePdfExporter {
  final Map<String, pw.MemoryImage> _pdfImageCache = {};

  Future<void> exportAndShare({
    required LoadedTemplate loadedTemplate,
    required Map<String, dynamic> documentData,
    required List<Map<String, dynamic>> rosterRows,
    required String projectFolderPath,
    required String fileName,
  }) async {
    final pdf = pw.Document();

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
    final pageSize = maxRosterPerPage <= 0 ? 1 : maxRosterPerPage;
    final rosterCount = maxRosterPerPage <= 0 ? 1 : rosterRows.length;
    tsPrint('EXPORT PDF: ------------------------------------------------');
    tsPrint('MAX ROSTER PER PAGE: ${maxRosterPerPage}');
    tsPrint('PAGE SIZE: ${pageSize}');
    tsPrint('ROSTER COUNT: ${rosterCount}');

    final pageFormat = PdfPageFormat(
      widthIn * PdfPageFormat.inch,
      heightIn * PdfPageFormat.inch,
      marginAll: 0,
    );

    for (int pageStart = 0; pageStart < rosterCount; pageStart += pageSize) {
      final pageWidgets = <pw.Widget>[];

      tsPrint('ADDING DOCUMENT ELEMENTS TO PAGE: ${pageStart}');

      for (final element in documentElements) {
        pageWidgets.add(
          await _buildElement(
            loadedTemplate: loadedTemplate,
            element: Map<String, dynamic>.from(element as Map),
            sourceData: documentData,
            projectFolderPath: projectFolderPath,
            offsetXIn: 0,
            offsetYIn: 0,
            slotScaleX: 1,
            slotScaleY: 1,
          ),
        );
      }

      tsPrint('ADDING ROSTER ELEMENTS TO PAGE: ${pageStart}');
      for (int i = 0; i < slots.length && i < maxRosterPerPage; i++) {
        final rosterIndex = pageStart + i;

        if (rosterIndex >= rosterRows.length) {
          break;
        }

        final slot = Map<String, dynamic>.from(slots[i] as Map);

        final slotX = (slot['x'] ?? 0).toDouble();
        final slotY = (slot['y'] ?? 0).toDouble();
        final slotW = (slot['w'] ?? rosterWidthIn).toDouble();
        final slotH = (slot['h'] ?? rosterHeightIn).toDouble();

        final slotScaleX = slotW / rosterWidthIn;
        final slotScaleY = slotH / rosterHeightIn;

        for (final element in rosterElements) {
          pageWidgets.add(
            await _buildElement(
              loadedTemplate: loadedTemplate,
              element: Map<String, dynamic>.from(element as Map),
              sourceData: rosterRows[rosterIndex],
              projectFolderPath: projectFolderPath,
              offsetXIn: slotX,
              offsetYIn: slotY,
              slotScaleX: slotScaleX,
              slotScaleY: slotScaleY,
            ),
          );
        }
      }

      tsPrint('ADDING PAGE TO PDF: ${pageStart}');
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) {
            return pw.Stack(children: pageWidgets);
          },
        ),
      );
    }

    final bytes = await pdf.save();

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  Future<pw.Widget> _buildElement({
    required LoadedTemplate loadedTemplate,
    required Map<String, dynamic> element,
    required Map<String, dynamic> sourceData,
    required String projectFolderPath,
    required double offsetXIn,
    required double offsetYIn,
    required double slotScaleX,
    required double slotScaleY,
  }) async {
    final type = element['type']?.toString() ?? '';

    final rawX = (element['x'] ?? 0).toDouble();
    final rawY = (element['y'] ?? 0).toDouble();
    final rawW = (element['w'] ?? 1).toDouble();
    final rawH = (element['h'] ?? 1).toDouble();

    final x = offsetXIn + (rawX * slotScaleX);
    final y = offsetYIn + (rawY * slotScaleY);
    final w = rawW * slotScaleX;
    final h = rawH * slotScaleY;

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
      final imagePath = _resolveImagePath(
        loadedTemplate: loadedTemplate,
        element: element,
        sourceData: sourceData,
        projectFolderPath: projectFolderPath,
      );

      final image = await _getPdfImage(imagePath);
      final shape = element['shape']?.toString() ?? 'rect';
      final imageWidget = pw.Image(
        image,
        fit: _resolveBoxFit(element['fit']?.toString()),
      );

      return pw.Positioned(
        left: left * PdfPageFormat.inch,
        top: top * PdfPageFormat.inch,
        child: pw.SizedBox(
          width: w * PdfPageFormat.inch,
          height: h * PdfPageFormat.inch,
          child: _applyImageShape(shape: shape, child: imageWidget),
        ),
      );
    }

    if (type == 'text') {
      final source = element['source']?.toString() ?? '';
      String value = sourceData[source]?.toString() ?? '';

      if (element['transform']?.toString() == 'firstNameLastInitial') {
        value = _firstNameLastInitial(value);
      }

      final fontSize = (element['fontSize'] ?? 0.25).toDouble();

      return pw.Positioned(
        left: left * PdfPageFormat.inch,
        top: top * PdfPageFormat.inch,
        child: pw.SizedBox(
          width: w * PdfPageFormat.inch,
          height: h * PdfPageFormat.inch,
          child: pw.Center(
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                child: pw.Text(
                  value,
                  maxLines: 1,
                  style: pw.TextStyle(
                    fontSize: fontSize * PdfPageFormat.inch,
                    fontWeight: _isBold(element)
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                    fontStyle: _isItalic(element)
                        ? pw.FontStyle.italic
                        : pw.FontStyle.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pw.SizedBox();
  }

  String _resolveImagePath({
    required LoadedTemplate loadedTemplate,
    required Map<String, dynamic> element,
    required Map<String, dynamic> sourceData,
    required String projectFolderPath,
  }) {
    final source = element['source']?.toString() ?? '';
    final value = sourceData[source]?.toString();

    if (value != null && value.trim().isNotEmpty) {
      if (value.startsWith('assets/')) {
        return value;
      }

      if (value.startsWith('/')) {
        return value;
      }

      return '$projectFolderPath/$value';
    }

    if (source == 'profilePicture') {
      return 'assets/resources/portrait.png';
    }

    if (source.startsWith('assets/')) {
      return source;
    }

    return loadedTemplate.assetPath(source);
  }

  Future<pw.MemoryImage> _getPdfImage(String imagePath) async {
    final cached = _pdfImageCache[imagePath];

    if (cached != null) {
      return cached;
    }

    final imageBytes = await _loadImageBytes(imagePath);
    final image = pw.MemoryImage(imageBytes);

    _pdfImageCache[imagePath] = image;

    return image;
  }

  Future<Uint8List> _loadImageBytes(String imagePath) async {
    if (imagePath.startsWith('assets/')) {
      final data = await rootBundle.load(imagePath);
      return data.buffer.asUint8List();
    }

    final file = File(imagePath);

    if (!await file.exists()) {
      throw Exception('PDF image file not found: $imagePath');
    }

    return file.readAsBytes();
  }

  pw.BoxFit _resolveBoxFit(String? value) {
    if (value == 'cover') {
      return pw.BoxFit.cover;
    }

    if (value == 'contain') {
      return pw.BoxFit.contain;
    }

    return pw.BoxFit.fill;
  }

  pw.Widget _applyImageShape({
    required String shape,
    required pw.Widget child,
  }) {
    if (shape == 'oval') {
      return pw.ClipOval(child: child);
    }

    return child;
  }

  bool _isBold(Map<String, dynamic> element) {
    final fontStyleString =
        element['fontStyle']?.toString().toLowerCase() ?? '';
    return fontStyleString.contains('bold');
  }

  bool _isItalic(Map<String, dynamic> element) {
    final fontStyleString =
        element['fontStyle']?.toString().toLowerCase() ?? '';
    return fontStyleString.contains('italic');
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

    return '${parts.first} ${parts.last[0]}.';
  }
}
