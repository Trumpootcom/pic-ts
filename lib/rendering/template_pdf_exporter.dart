import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../util/ts_print.dart';
import '../services/template_loader.dart';
import 'template_layout_engine.dart';

class TemplatePdfExporter {
  final Map<String, pw.MemoryImage> _pdfImageCache = {};
  final Map<String, pw.Font> _pdfFontCache = {};

  Future<void> exportAndShare({
    required LoadedTemplate loadedTemplate,
    required Map<String, dynamic> documentData,
    required List<Map<String, dynamic>> rosterRows,
    required String projectFolderPath,
    required String fileName,
  }) async {
    final bytes = await buildPdfBytes(
      loadedTemplate: loadedTemplate,
      documentData: documentData,
      rosterRows: rosterRows,
      projectFolderPath: projectFolderPath,
    );

    final exportDir = Directory(
      p.join((await getTemporaryDirectory()).path, 'pic_ts_exports'),
    );
    await exportDir.create(recursive: true);

    final file = File(p.join(exportDir.path, p.basename(fileName)));
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        fileNameOverrides: [p.basename(file.path)],
        title: loadedTemplate.template.name,
        subject: loadedTemplate.template.name,
      ),
    );
  }

  Future<Uint8List> buildPdfBytes({
    required LoadedTemplate loadedTemplate,
    required Map<String, dynamic> documentData,
    required List<Map<String, dynamic>> rosterRows,
    required String projectFolderPath,
  }) async {
    final pdf = pw.Document();

    final layoutEngine = TemplateLayoutEngine(
      loadedTemplate: loadedTemplate,
      documentData: documentData,
      rosterRows: rosterRows,
      projectFolderPath: projectFolderPath,
    );
    final metrics = layoutEngine.metrics();
    final pageStarts = layoutEngine.pageStarts();

    tsPrint('EXPORT PDF: ------------------------------------------------');
    tsPrint('MAX ROSTER PER PAGE: ${metrics.maxRosterPerPage}');
    tsPrint('PAGE COUNT: ${pageStarts.length}');

    final pageFormat = PdfPageFormat(
      metrics.widthIn * PdfPageFormat.inch,
      metrics.heightIn * PdfPageFormat.inch,
      marginAll: 0,
    );

    for (final pageStart in pageStarts) {
      final pageWidgets = <pw.Widget>[];
      final page = layoutEngine.buildPage(rosterStartIndex: pageStart);

      tsPrint('ADDING PLANNED ELEMENTS TO PAGE: $pageStart');

      for (final element in page.elements) {
        pageWidgets.add(
          await _buildElement(
            element: element,
          ),
        );
      }

      tsPrint('ADDING PAGE TO PDF: $pageStart');
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) {
            return pw.Stack(children: pageWidgets);
          },
        ),
      );
    }

    return pdf.save();
  }

  Future<pw.Widget> _buildElement({
    required TemplateLayoutElement element,
  }) async {
    final left = element.rect.left;
    final top = element.rect.top;
    final w = element.rect.width;
    final h = element.rect.height;

    if (element.type == 'image') {
      final imagePath = element.imagePath ?? '';
      final image = await _getPdfImage(imagePath);
      final shape = element.rawElement['shape']?.toString() ?? 'rect';
      final imageWidget = pw.Image(
        image,
        fit: _resolveBoxFit(element.rawElement['fit']?.toString()),
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

    if (element.type == 'text') {
      final value = element.text ?? '';
      final fontSize = (element.rawElement['fontSize'] ?? 0.25).toDouble();
      final font = await _resolvePdfFont(element.rawElement);

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
                    font: font,
                    fontSize: fontSize * PdfPageFormat.inch,
                    fontWeight: _isBold(element.rawElement)
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                    fontStyle: _isItalic(element.rawElement)
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

  Future<pw.Font?> _resolvePdfFont(Map<String, dynamic> element) async {
    final fontFamily = element['fontFamily']?.toString();
    final fontAssetPath = _fontAssetPath(
      fontFamily: fontFamily,
      isBold: _isBold(element),
      isItalic: _isItalic(element),
    );

    if (fontAssetPath == null) {
      return null;
    }

    final cached = _pdfFontCache[fontAssetPath];

    if (cached != null) {
      return cached;
    }

    final data = await rootBundle.load(fontAssetPath);
    final font = pw.Font.ttf(data);

    _pdfFontCache[fontAssetPath] = font;

    return font;
  }

  String? _fontAssetPath({
    required String? fontFamily,
    required bool isBold,
    required bool isItalic,
  }) {
    switch (fontFamily?.toLowerCase()) {
      case 'arial':
        if (isBold && isItalic) return 'assets/fonts/arialbi.ttf';
        if (isBold) return 'assets/fonts/arialbd.ttf';
        if (isItalic) return 'assets/fonts/ariali.ttf';
        return 'assets/fonts/arial.ttf';

      case 'calibri':
        if (isBold && isItalic) return 'assets/fonts/calibriz.ttf';
        if (isBold) return 'assets/fonts/calibrib.ttf';
        if (isItalic) return 'assets/fonts/calibrii.ttf';
        return 'assets/fonts/calibri.ttf';

      case 'cambria':
        if (isBold && isItalic) return 'assets/fonts/cambriaz.ttf';
        if (isBold) return 'assets/fonts/cambriab.ttf';
        if (isItalic) return 'assets/fonts/cambriai.ttf';
        return 'assets/fonts/cambria.ttc';

      case 'georgia':
        if (isBold && isItalic) return 'assets/fonts/georgiaz.ttf';
        if (isBold) return 'assets/fonts/georgiab.ttf';
        if (isItalic) return 'assets/fonts/georgiai.ttf';
        return 'assets/fonts/georgia.ttf';

      case 'times new roman':
        if (isBold && isItalic) return 'assets/fonts/timesbi.ttf';
        if (isBold) return 'assets/fonts/timesbd.ttf';
        if (isItalic) return 'assets/fonts/timesi.ttf';
        return 'assets/fonts/times.ttf';
    }

    return null;
  }
}
