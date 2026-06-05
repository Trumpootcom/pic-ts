import 'dart:math' as math;

import '../services/template_loader.dart';

class TemplateLayoutEngine {
  final LoadedTemplate loadedTemplate;
  final Map<String, dynamic> documentData;
  final List<Map<String, dynamic>> rosterRows;
  final String projectFolderPath;

  TemplateLayoutEngine({
    required this.loadedTemplate,
    required this.documentData,
    required this.rosterRows,
    required this.projectFolderPath,
  });

  TemplateLayoutMetrics metrics() {
    final document = _document;
    final roster = _roster;

    final widthIn = (document['width'] ?? 11).toDouble();
    final heightIn = (document['height'] ?? 8.5).toDouble();

    return TemplateLayoutMetrics(
      widthIn: widthIn,
      heightIn: heightIn,
      rosterWidthIn: (roster['width'] ?? widthIn).toDouble(),
      rosterHeightIn: (roster['height'] ?? heightIn).toDouble(),
      maxRosterPerPage: document['maxRosterPerPage'] as int? ?? 1,
    );
  }

  List<int> pageStarts({bool includeEmptyRosterPage = false}) {
    final maxRosterPerPage = metrics().maxRosterPerPage;

    if (maxRosterPerPage <= 0) {
      return const [0];
    }

    if (rosterRows.isEmpty) {
      return includeEmptyRosterPage ? const [0] : const [];
    }

    return [
      for (int i = 0; i < rosterRows.length; i += maxRosterPerPage) i,
    ];
  }

  TemplateLayoutPage buildPage({required int rosterStartIndex}) {
    final document = _document;
    final roster = _roster;
    final layoutMetrics = metrics();
    final documentElements = document['elements'] as List<dynamic>? ?? [];
    final rosterElements = roster['elements'] as List<dynamic>? ?? [];
    final pageRosterCount = _pageRosterCount(
      maxRosterPerPage: layoutMetrics.maxRosterPerPage,
      rosterStartIndex: rosterStartIndex,
    );
    final placementVariant = _resolvePlacementVariant(
      document: document,
      rosterCount: pageRosterCount,
    );
    final slots = placementVariant['slots'] as List<dynamic>? ?? [];
    final elements = <TemplateLayoutElement>[];

    for (final element in documentElements) {
      elements.add(
        _layoutElement(
          element: Map<String, dynamic>.from(element as Map),
          sourceData: documentData,
          fallbackData: const <String, dynamic>{},
          offsetXIn: 0,
          offsetYIn: 0,
          slotScaleX: 1,
          slotScaleY: 1,
        ),
      );
    }

    for (int i = 0; i < slots.length && i < pageRosterCount; i++) {
      final rosterIndex = rosterStartIndex + i;

      if (rosterIndex >= rosterRows.length) {
        break;
      }

      final slot = Map<String, dynamic>.from(slots[i] as Map);
      final slotX = (slot['x'] ?? 0).toDouble();
      final slotY = (slot['y'] ?? 0).toDouble();
      final slotW = (slot['w'] ?? layoutMetrics.rosterWidthIn).toDouble();
      final slotH = (slot['h'] ?? layoutMetrics.rosterHeightIn).toDouble();
      final slotScaleX = slotW / layoutMetrics.rosterWidthIn;
      final slotScaleY = slotH / layoutMetrics.rosterHeightIn;

      for (final element in rosterElements) {
        elements.add(
          _layoutElement(
            element: Map<String, dynamic>.from(element as Map),
            sourceData: rosterRows[rosterIndex],
            fallbackData: documentData,
            offsetXIn: slotX,
            offsetYIn: slotY,
            slotScaleX: slotScaleX,
            slotScaleY: slotScaleY,
          ),
        );
      }
    }

    return TemplateLayoutPage(
      widthIn: layoutMetrics.widthIn,
      heightIn: layoutMetrics.heightIn,
      rosterStartIndex: rosterStartIndex,
      rosterCount: pageRosterCount,
      elements: elements,
    );
  }

  TemplateLayoutElement _layoutElement({
    required Map<String, dynamic> element,
    required Map<String, dynamic> sourceData,
    required Map<String, dynamic> fallbackData,
    required double offsetXIn,
    required double offsetYIn,
    required double slotScaleX,
    required double slotScaleY,
  }) {
    final rawX = (element['x'] ?? 0).toDouble();
    final rawY = (element['y'] ?? 0).toDouble();
    final rawW = (element['w'] ?? 1).toDouble();
    final rawH = (element['h'] ?? 1).toDouble();

    final x = offsetXIn + rawX * slotScaleX;
    final y = offsetYIn + rawY * slotScaleY;
    final width = rawW * slotScaleX;
    final height = rawH * slotScaleY;
    final rect = _anchoredRect(
      x: x,
      y: y,
      width: width,
      height: height,
      anchor: element['anchor']?.toString() ?? 'topLeft',
    );
    final type = element['type']?.toString() ?? '';
    final source = element['source']?.toString() ?? '';

    return TemplateLayoutElement(
      type: type,
      source: source,
      rect: rect,
      rawElement: element,
      text: type == 'text'
          ? _resolveText(
              element: element,
              sourceData: sourceData,
              fallbackData: fallbackData,
            )
          : null,
      imagePath: type == 'image'
          ? _resolveImagePath(
              element: element,
              sourceData: sourceData,
              fallbackData: fallbackData,
            )
          : null,
    );
  }

  TemplateLayoutRect _anchoredRect({
    required double x,
    required double y,
    required double width,
    required double height,
    required String anchor,
  }) {
    double left = x;
    double top = y;

    if (anchor == 'topCenter') {
      left = x - width / 2;
    } else if (anchor == 'center') {
      left = x - width / 2;
      top = y - height / 2;
    } else if (anchor == 'centerLeft') {
      top = y - height / 2;
    } else if (anchor == 'centerRight') {
      left = x - width;
      top = y - height / 2;
    } else if (anchor == 'topRight') {
      left = x - width;
    } else if (anchor == 'bottomLeft') {
      top = y - height;
    } else if (anchor == 'bottomCenter') {
      left = x - width / 2;
      top = y - height;
    } else if (anchor == 'bottomRight') {
      left = x - width;
      top = y - height;
    }

    return TemplateLayoutRect(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }

  String _resolveText({
    required Map<String, dynamic> element,
    required Map<String, dynamic> sourceData,
    required Map<String, dynamic> fallbackData,
  }) {
    final source = element['source']?.toString() ?? '';
    var value = sourceData[source]?.toString() ??
        fallbackData[source]?.toString() ??
        '';
    value = value.trimRight();

    final transform = element['transform']?.toString();

    if (transform == 'firstNameLastInitial') {
      return _firstNameLastInitial(value);
    }

    if (transform == 'upperCase' || transform == 'uppercase') {
      return value.toUpperCase();
    }

    return value;
  }

  String _resolveImagePath({
    required Map<String, dynamic> element,
    required Map<String, dynamic> sourceData,
    required Map<String, dynamic> fallbackData,
  }) {
    final source = element['source']?.toString() ?? '';
    final value =
        sourceData[source]?.toString() ?? fallbackData[source]?.toString();

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

  int _pageRosterCount({
    required int maxRosterPerPage,
    required int rosterStartIndex,
  }) {
    if (maxRosterPerPage <= 0) {
      return 0;
    }

    final remainingRows = rosterRows.length - rosterStartIndex;
    return math.max(0, math.min(maxRosterPerPage, remainingRows));
  }

  Map<String, dynamic> _resolvePlacementVariant({
    required Map<String, dynamic> document,
    required int rosterCount,
  }) {
    final variants = Map<String, dynamic>.from(
      document['placementVariants'] as Map? ?? {},
    );

    return Map<String, dynamic>.from(
      variants[rosterCount.toString()] as Map? ??
          variants['default'] as Map? ??
          {},
    );
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

  Map<String, dynamic> get _document {
    return Map<String, dynamic>.from(
      loadedTemplate.template.rawJson['document'] as Map? ?? {},
    );
  }

  Map<String, dynamic> get _roster {
    return Map<String, dynamic>.from(
      loadedTemplate.template.rawJson['roster'] as Map? ?? {},
    );
  }
}

class TemplateLayoutMetrics {
  final double widthIn;
  final double heightIn;
  final double rosterWidthIn;
  final double rosterHeightIn;
  final int maxRosterPerPage;

  const TemplateLayoutMetrics({
    required this.widthIn,
    required this.heightIn,
    required this.rosterWidthIn,
    required this.rosterHeightIn,
    required this.maxRosterPerPage,
  });
}

class TemplateLayoutPage {
  final double widthIn;
  final double heightIn;
  final int rosterStartIndex;
  final int rosterCount;
  final List<TemplateLayoutElement> elements;

  const TemplateLayoutPage({
    required this.widthIn,
    required this.heightIn,
    required this.rosterStartIndex,
    required this.rosterCount,
    required this.elements,
  });
}

class TemplateLayoutElement {
  final String type;
  final String source;
  final TemplateLayoutRect rect;
  final Map<String, dynamic> rawElement;
  final String? text;
  final String? imagePath;

  const TemplateLayoutElement({
    required this.type,
    required this.source,
    required this.rect,
    required this.rawElement,
    this.text,
    this.imagePath,
  });
}

class TemplateLayoutRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const TemplateLayoutRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
