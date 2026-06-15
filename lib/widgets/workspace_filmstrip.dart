// lib/widgets/workspace_filmstrip.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';

enum WorkspaceFilmstripStyle { plain, film, cloud }

class WorkspaceFilmstripItem {
  final String title;
  final Widget thumbnail;

  const WorkspaceFilmstripItem({required this.title, required this.thumbnail});
}

class WorkspaceFilmstrip extends StatefulWidget {
  final List<WorkspaceFilmstripItem> items;
  final int currentIndex;
  final double currentPagePosition;
  final ValueChanged<double>? onPagePositionChanged;
  final ValueChanged<int> onTap;
  final bool filmTheme;
  final WorkspaceFilmstripStyle? displayStyle;

  const WorkspaceFilmstrip({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.currentPagePosition,
    required this.onTap,
    this.onPagePositionChanged,
    this.filmTheme = false,
    this.displayStyle,
  });

  @override
  State<WorkspaceFilmstrip> createState() => _WorkspaceFilmstripState();
}

class _WorkspaceFilmstripState extends State<WorkspaceFilmstrip> {
  static const String _cloudAssetPath = 'assets/backgrounds/cloud.png';

  final ScrollController _scrollController = ScrollController();
  ImageStream? _cloudImageStream;
  ImageStreamListener? _cloudImageListener;
  ui.Image? _cloudImage;

  static const double topGap = 3.0;
  static const double bottomGap = 5.0;

  static const double thumbHeight = 55.0;
  static const double thumbWidth = thumbHeight * 11.0 / 8.5;
  static const double sprocketBandHeight = 11.0;
  static const double filmstripHeight = thumbHeight + sprocketBandHeight * 2;

  static const double horizontalGap = 10.0;
  bool _userDraggingFilmstrip = false;

  bool _syncingFromPageView = false;

  double get _itemStride => thumbWidth + horizontalGap;

  WorkspaceFilmstripStyle get _displayStyle {
    return widget.displayStyle ??
        (widget.filmTheme
            ? WorkspaceFilmstripStyle.film
            : WorkspaceFilmstripStyle.plain);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncScrollToPagePosition();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveCloudImage();
  }

  @override
  void didUpdateWidget(covariant WorkspaceFilmstrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_userDraggingFilmstrip) return;

    if (oldWidget.currentPagePosition != widget.currentPagePosition) {
      _syncScrollToPagePosition();
    }
  }

  @override
  void dispose() {
    _removeCloudImageListener();
    _scrollController.dispose();
    super.dispose();
  }

  void _resolveCloudImage() {
    final asset = AssetImage(_cloudAssetPath);
    final imageStream = asset.resolve(createLocalImageConfiguration(context));

    if (_cloudImageStream?.key == imageStream.key) {
      return;
    }

    _removeCloudImageListener();

    _cloudImageStream = imageStream;
    _cloudImageListener = ImageStreamListener((imageInfo, synchronousCall) {
      if (!mounted) return;

      setState(() {
        _cloudImage = imageInfo.image;
      });
    });

    imageStream.addListener(_cloudImageListener!);
  }

  void _removeCloudImageListener() {
    final imageStream = _cloudImageStream;
    final imageListener = _cloudImageListener;

    if (imageStream != null && imageListener != null) {
      imageStream.removeListener(imageListener);
    }

    _cloudImageStream = null;
    _cloudImageListener = null;
  }

  void _syncScrollToPagePosition() {
    if (!_scrollController.hasClients) return;

    final targetOffset = widget.currentPagePosition * _itemStride;

    final clampedOffset = targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    _syncingFromPageView = true;
    _scrollController.jumpTo(clampedOffset);
    _syncingFromPageView = false;
  }

  @override
  Widget build(BuildContext context) {
    final displayStyle = _displayStyle;
    final stripHeight = displayStyle != WorkspaceFilmstripStyle.plain
        ? filmstripHeight
        : thumbHeight + horizontalGap;

    return Padding(
      padding: const EdgeInsets.only(top: topGap, bottom: bottomGap),
      child: Container(
        height: stripHeight,
        decoration: BoxDecoration(
          color: displayStyle == WorkspaceFilmstripStyle.plain
              ? AppColors.lightUnsat
              : null,
          boxShadow: displayStyle == WorkspaceFilmstripStyle.cloud
              ? null
              : [
                  BoxShadow(
                    color: AppColors.darkUnsat.withAlpha(120),
                    blurRadius: 1.5,
                    spreadRadius: 1.5,
                    offset: const Offset(0, -1.5),
                  ),
                  BoxShadow(
                    color: AppColors.darkUnsat.withAlpha(120),
                    blurRadius: 1.5,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 1.5),
                  ),
                ],
        ),
        child: CustomPaint(
          painter: _FilmstripFramePainter(
            frameColor: AppColors.textDark,
            laneColor: AppColors.darkUnsat,
            sprocketColor: AppColors.lightUnsat,
            sprocketBandHeight: sprocketBandHeight,
            scrollController: _scrollController,
            displayStyle: displayStyle,
            cellWidth: _itemStride,
            contentWidth: thumbWidth,
            cloudImage: _cloudImage,
          ),
          child: SizedBox(
            height: stripHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideSpacer = ((constraints.maxWidth - thumbWidth) / 2)
                    .clamp(0.0, double.infinity);

                return Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is UserScrollNotification &&
                            notification.direction != ScrollDirection.idle) {
                          _userDraggingFilmstrip = true;
                        }
                        if (notification is ScrollUpdateNotification &&
                            _userDraggingFilmstrip) {
                          final pagePosition =
                              _scrollController.offset / _itemStride;
                          widget.onPagePositionChanged?.call(pagePosition);
                        }
                        if (notification is ScrollEndNotification &&
                            _userDraggingFilmstrip) {
                          _userDraggingFilmstrip = false;

                          final rawIndex =
                              _scrollController.offset / _itemStride;
                          final index = rawIndex.round().clamp(
                            0,
                            widget.items.length - 1,
                          );

                          final targetOffset = index * _itemStride;

                          _scrollController.animateTo(
                            targetOffset,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                          );

                          widget.onTap(index);

                          return true;
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: sideSpacer),
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          return Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => widget.onTap(index),
                                  child: Container(
                                    width: thumbWidth,
                                    height: thumbHeight,
                                    decoration: BoxDecoration(
                                      color: AppColors.medUnsat,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      clipBehavior: Clip.hardEdge,
                                      child: widget.items[index].thumbnail,
                                    ),
                                  ),
                                ),
                                if (index < widget.items.length - 1)
                                  const SizedBox(width: horizontalGap),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    IgnorePointer(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              color: AppColors.medUnsat.withAlpha(90),
                            ),
                          ),

                          SizedBox(
                            width: thumbWidth,
                            height: stripHeight,
                          ),

                          Expanded(
                            child: Container(
                              color: AppColors.medUnsat.withAlpha(90),
                            ),
                          ),
                        ],
                      ),
                    ),

                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: thumbWidth + horizontalGap,
                          height: stripHeight,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textLight,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FilmstripFramePainter extends CustomPainter {
  final Color frameColor;
  final Color laneColor;
  final Color sprocketColor;
  final double sprocketBandHeight;
  final ScrollController scrollController;
  final WorkspaceFilmstripStyle displayStyle;
  final double cellWidth;
  final double contentWidth;
  final ui.Image? cloudImage;

  _FilmstripFramePainter({
    required this.frameColor,
    required this.laneColor,
    required this.sprocketColor,
    required this.sprocketBandHeight,
    required this.scrollController,
    required this.displayStyle,
    required this.cellWidth,
    required this.contentWidth,
    required this.cloudImage,
  }) : super(repaint: scrollController);

  @override
  void paint(Canvas canvas, Size size) {
    switch (displayStyle) {
      case WorkspaceFilmstripStyle.plain:
        return;
      case WorkspaceFilmstripStyle.film:
        _paintFilmFrame(canvas, size);
        return;
      case WorkspaceFilmstripStyle.cloud:
        _paintCloudFrame(canvas, size);
        return;
    }
  }

  void _paintFilmFrame(Canvas canvas, Size size) {
    final framePaint = Paint()..color = frameColor;
    final lanePaint = Paint()..color = laneColor;
    final sprocketPaint = Paint()..color = sprocketColor;

    final frameRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(5),
    );
    canvas.drawRRect(frameRect, framePaint);

    final laneRect = Rect.fromLTWH(
      0,
      sprocketBandHeight,
      size.width,
      size.height - sprocketBandHeight * 2,
    );
    canvas.drawRect(laneRect, lanePaint);

    const holeWidth = 9.0;
    const holeHeight = 6.0;
    const holeGap = 8.0;
    const holeRadius = Radius.circular(2);
    final pitch = holeWidth + holeGap;
    final scrollOffset = scrollController.hasClients
        ? scrollController.offset
        : 0.0;
    final scrollShift = scrollOffset % pitch;
    final count = (size.width / pitch).ceil() + 3;
    final startX = -pitch - scrollShift;
    final topY = (sprocketBandHeight - holeHeight) / 2;
    final bottomY = size.height - sprocketBandHeight + topY;

    for (int i = 0; i < count; i++) {
      final x = startX + i * pitch;
      final topHole = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, topY, holeWidth, holeHeight),
        holeRadius,
      );
      final bottomHole = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottomY, holeWidth, holeHeight),
        holeRadius,
      );

      canvas.drawRRect(topHole, sprocketPaint);
      canvas.drawRRect(bottomHole, sprocketPaint);
    }
  }

  void _paintCloudFrame(Canvas canvas, Size size) {
    final image = cloudImage;

    if (image == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = laneColor);
      return;
    }

    final scrollOffset = scrollController.hasClients
        ? scrollController.offset
        : 0.0;
    final tileWidth = cellWidth;
    final sideSpacer = ((size.width - contentWidth) / 2).clamp(
      0.0,
      double.infinity,
    );
    final firstCellX = sideSpacer - scrollOffset;
    final startX =
        firstCellX - ((firstCellX / tileWidth).floor() + 1) * tileWidth;
    final count = (size.width / tileWidth).ceil() + 3;
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    for (int i = 0; i < count; i++) {
      final x = startX + i * tileWidth;
      final dst = Rect.fromLTWH(x - 1, 0, tileWidth + 2, size.height);
      canvas.drawImageRect(image, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmstripFramePainter oldDelegate) {
    return oldDelegate.frameColor != frameColor ||
        oldDelegate.laneColor != laneColor ||
        oldDelegate.sprocketColor != sprocketColor ||
        oldDelegate.sprocketBandHeight != sprocketBandHeight ||
        oldDelegate.scrollController != scrollController ||
        oldDelegate.displayStyle != displayStyle ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.contentWidth != contentWidth ||
        oldDelegate.cloudImage != cloudImage;
  }
}
