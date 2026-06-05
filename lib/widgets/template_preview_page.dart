// lib/widgets/template_preview_page.dart

import 'package:flutter/material.dart';

import '../rendering/template_preview.dart';
import '../services/template_loader.dart';

class TemplatePreviewPage extends StatefulWidget {
  final LoadedTemplate loadedTemplate;
  final Map<String, dynamic> documentData;
  final List<Map<String, dynamic>> roster;
  final String projectFolderPath;
  final ValueChanged<bool>? onZoomNavigationLockChanged;

  const TemplatePreviewPage({
    super.key,
    required this.loadedTemplate,
    required this.documentData,
    required this.roster,
    required this.projectFolderPath,
    this.onZoomNavigationLockChanged,
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
  bool _zoomNavigationLocked = false;
  bool _multiTouchNavigationLocked = false;
  bool _notifiedNavigationLocked = false;
  final Set<int> _activePointerIds = {};

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
            if (pageWidth <= 0) {
              return const SizedBox.shrink();
            }

            final pageHeight = pageWidth / aspect;
            final pageGapCount = pageStarts.length > 1
                ? pageStarts.length - 1
                : 0;
            final documentHeight =
                pageStarts.length * pageHeight + pageGapCount * _pageGap;
            final viewerHeight = documentHeight > constraints.maxHeight
                ? documentHeight
                : constraints.maxHeight;

            _viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            _documentSize = Size(pageWidth, documentHeight);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _clampPreviewTransform();
              }
            });

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _resetZoom,
              child: Listener(
                onPointerDown: _handlePointerDown,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerCancel,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  alignment: Alignment.topLeft,
                  constrained: false,
                  minScale: 1,
                  maxScale: 4,
                  boundaryMargin: EdgeInsets.zero,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: viewerHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: pageWidth,
                        height: documentHeight,
                        child: Column(
                          children: [
                            for (int i = 0; i < pageStarts.length; i++) ...[
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.24,
                                      ),
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
                                  rosterStartIndex: isSinglePage
                                      ? 0
                                      : pageStarts[i],
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
                    ),
                  ),
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
    _updateNavigationLock(scale);

    final currentX = matrix.storage[12];
    final currentY = matrix.storage[13];

    final nextX = _clampedAxisOffset(
      currentOffset: currentX,
      viewportExtent: _viewportSize.width,
      contentExtent: _documentSize.width,
      scale: scale,
      contentInset: (_viewportSize.width - _documentSize.width) / 2,
    );
    final nextY = _clampedAxisOffset(
      currentOffset: currentY,
      viewportExtent: _viewportSize.height,
      contentExtent: _documentSize.height,
      scale: scale,
      contentInset: 0,
      centerWhenSmaller: false,
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
    required double contentExtent,
    required double scale,
    required double contentInset,
    bool centerWhenSmaller = true,
  }) {
    final scaledContentExtent = contentExtent * scale;
    final scaledInset = contentInset * scale;
    final currentContentStart = currentOffset + scaledInset;

    if (scaledContentExtent <= viewportExtent) {
      if (!centerWhenSmaller) {
        return -scaledInset;
      }

      final centeredContentStart = (viewportExtent - scaledContentExtent) / 2;
      return centeredContentStart - scaledInset;
    }

    final minContentStart = viewportExtent - scaledContentExtent;
    final clampedContentStart = currentContentStart
        .clamp(minContentStart, 0)
        .toDouble();

    return clampedContentStart - scaledInset;
  }

  void _updateNavigationLock(double scale) {
    _zoomNavigationLocked = scale > 1.01;
    _notifyNavigationLockChanged();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    _updateMultiTouchNavigationLock();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointerIds.remove(event.pointer);
    _updateMultiTouchNavigationLock();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointerIds.remove(event.pointer);
    _updateMultiTouchNavigationLock();
  }

  void _updateMultiTouchNavigationLock() {
    _multiTouchNavigationLocked = _activePointerIds.length >= 2;
    _notifyNavigationLockChanged();
  }

  void _notifyNavigationLockChanged() {
    final shouldLock = _zoomNavigationLocked || _multiTouchNavigationLocked;

    if (_notifiedNavigationLocked == shouldLock) {
      return;
    }

    _notifiedNavigationLocked = shouldLock;
    widget.onZoomNavigationLockChanged?.call(shouldLock);
  }

  void _resetZoom() {
    _activePointerIds.clear();
    _multiTouchNavigationLocked = false;
    _zoomNavigationLocked = false;
    _transformationController.value = Matrix4.identity();
    _notifyNavigationLockChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _clampPreviewTransform();
      }
    });
  }
}
