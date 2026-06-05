// lib/widgets/template_preview_page.dart

import 'package:flutter/material.dart';

import '../rendering/template_preview.dart';
import '../services/template_loader.dart';

class TemplatePreviewPage extends StatefulWidget {
  final LoadedTemplate loadedTemplate;
  final Map<String, dynamic> documentData;
  final List<Map<String, dynamic>> roster;
  final String projectFolderPath;

  const TemplatePreviewPage({
    super.key,
    required this.loadedTemplate,
    required this.documentData,
    required this.roster,
    required this.projectFolderPath,
  });

  @override
  State<TemplatePreviewPage> createState() => _TemplatePreviewPageState();
}

class _TemplatePreviewPageState extends State<TemplatePreviewPage>
    with AutomaticKeepAliveClientMixin {
  final TransformationController _transformationController =
      TransformationController();
  Size _viewportSize = Size.zero;
  Size _documentSize = Size.zero;
  bool _isClampingTransform = false;

  static const double _pageGap = 18;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_clampPreviewTransform);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _transformationController.removeListener(_clampPreviewTransform);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final document = Map<String, dynamic>.from(
      widget.loadedTemplate.template.rawJson['document'] as Map? ?? {},
    );

    final maxRosterPerPage = document['maxRosterPerPage'] as int? ?? 1;
    final isSinglePage = maxRosterPerPage <= 0;
    final widthIn = (document['width'] ?? 11).toDouble();
    final heightIn = (document['height'] ?? 8.5).toDouble();
    final aspect = widthIn / heightIn;
    final pageStarts = _pageStarts(
      maxRosterPerPage: maxRosterPerPage,
      rosterCount: widget.roster.length,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth > 24
                ? constraints.maxWidth - 24
                : constraints.maxWidth;
            final pageHeight = pageWidth / aspect;
            final pageGapCount = pageStarts.length > 1
                ? pageStarts.length - 1
                : 0;
            final documentHeight =
                pageStarts.length * pageHeight + pageGapCount * _pageGap;

            _viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            _documentSize = Size(constraints.maxWidth, documentHeight);

            return InteractiveViewer(
              transformationController: _transformationController,
              alignment: Alignment.topLeft,
              constrained: false,
              minScale: 1,
              maxScale: 4,
              boundaryMargin: EdgeInsets.zero,
              child: SizedBox(
                width: constraints.maxWidth,
                height: documentHeight,
                child: Column(
                  children: [
                    for (int i = 0; i < pageStarts.length; i++) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.24),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TemplatePreview(
                          loadedTemplate: widget.loadedTemplate,
                          documentData: widget.documentData,
                          rosterRows: isSinglePage
                              ? const []
                              : widget.roster,
                          rosterStartIndex: isSinglePage ? 0 : pageStarts[i],
                          projectFolderPath: widget.projectFolderPath,
                          previewWidth: pageWidth,
                        ),
                      ),
                      if (i < pageStarts.length - 1)
                        const SizedBox(height: _pageGap),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<int> _pageStarts({
    required int maxRosterPerPage,
    required int rosterCount,
  }) {
    if (maxRosterPerPage <= 0 || rosterCount <= 0) {
      return const [0];
    }

    return [
      for (int i = 0; i < rosterCount; i += maxRosterPerPage) i,
    ];
  }

  void _clampPreviewTransform() {
    if (_isClampingTransform ||
        _viewportSize == Size.zero ||
        _documentSize == Size.zero) {
      return;
    }

    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final scaledWidth = _documentSize.width * scale;
    final scaledHeight = _documentSize.height * scale;

    final currentX = matrix.storage[12];
    final currentY = matrix.storage[13];

    final nextX = _clampedAxisOffset(
      currentOffset: currentX,
      viewportExtent: _viewportSize.width,
      scaledContentExtent: scaledWidth,
    );
    final nextY = _clampedAxisOffset(
      currentOffset: currentY,
      viewportExtent: _viewportSize.height,
      scaledContentExtent: scaledHeight,
    );

    if ((nextX - currentX).abs() < 0.5 && (nextY - currentY).abs() < 0.5) {
      return;
    }

    final clamped = matrix.clone()
      ..setEntry(0, 3, nextX)
      ..setEntry(1, 3, nextY);

    _isClampingTransform = true;
    _transformationController.value = clamped;
    _isClampingTransform = false;
  }

  double _clampedAxisOffset({
    required double currentOffset,
    required double viewportExtent,
    required double scaledContentExtent,
  }) {
    if (scaledContentExtent <= viewportExtent) {
      return (viewportExtent - scaledContentExtent) / 2;
    }

    final minOffset = viewportExtent - scaledContentExtent;
    return currentOffset.clamp(minOffset, 0).toDouble();
  }
}
