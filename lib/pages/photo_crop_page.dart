import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
//import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;

import '../util/ts_print.dart';

class PhotoCropResult {
  final double cropLeft;
  final double cropTop;
  final double cropWidth;
  final double cropHeight;

  final double zoom;
  final int rotationQuarterTurns;

  final double rawWidth;
  final double rawHeight;

  final String croppedImagePath;

  const PhotoCropResult({
    required this.cropLeft,
    required this.cropTop,
    required this.cropWidth,
    required this.cropHeight,
    required this.zoom,
    required this.rotationQuarterTurns,
    required this.rawWidth,
    required this.rawHeight,
    required this.croppedImagePath,
  });
}

class PhotoCropPage extends StatefulWidget {
  final String imagePath;
  final String croppedImagePath;

  final double initialPanX;
  final double initialPanY;
  final double initialZoom;

  final int initialRotationQuarterTurns;
  final int targetWidthPx;
  final int targetHeightPx;

  final List<Map<String, dynamic>> profilePictureCrops;

  const PhotoCropPage({
    super.key,
    required this.imagePath,
    required this.croppedImagePath,
    required this.targetHeightPx,
    required this.targetWidthPx,
    this.initialPanX = 0,
    this.initialPanY = 0,
    this.initialZoom = 1,
    this.initialRotationQuarterTurns = 0,
    this.profilePictureCrops = const [],
  });

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  late final TransformationController _controller;
  late int rotationQuarterTurns;

  img.Image? decodedImage;

  double rawWidth = 1;
  double rawHeight = 1;

  double viewportWidth = 1;
  double viewportHeight = 1;

  double imageChildWidth = 1;
  double imageChildHeight = 1;

  int debugLeft = 0;
  int debugRight = 0;
  int debugTop = 0;
  int debugBottom = 0;

  double debugZoom = 1.0;

  @override
  void initState() {
    super.initState();

    rotationQuarterTurns = widget.initialRotationQuarterTurns;

    _controller = TransformationController();
    _controller.addListener(_updateDebugOverlay);

    _loadImage();
  }

  @override
  void dispose() {
    _controller.removeListener(_updateDebugOverlay);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      tsPrint('PHOTO CROP: failed to decode image');
      return;
    }

    decodedImage = decoded;
    rawWidth = decoded.width.toDouble();
    rawHeight = decoded.height.toDouble();

    if (!mounted) return;

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resetTransform();
      }
    });
  }

  double _sourceWidth() {
    final turns = rotationQuarterTurns % 4;
    return turns.isOdd ? rawHeight : rawWidth;
  }

  double _sourceHeight() {
    final turns = rotationQuarterTurns % 4;
    return turns.isOdd ? rawWidth : rawHeight;
  }

  double _baseScale() {
    final sourceWidth = _sourceWidth();
    final sourceHeight = _sourceHeight();

    return math.max(viewportWidth / sourceWidth, viewportHeight / sourceHeight);
  }

  void _resetTransform() {
    final sourceWidth = _sourceWidth();
    final sourceHeight = _sourceHeight();

    final baseScale = _baseScale();
    final totalScale = baseScale * widget.initialZoom;

    imageChildWidth = sourceWidth;
    imageChildHeight = sourceHeight;

    final scaledWidth = sourceWidth * totalScale;
    final scaledHeight = sourceHeight * totalScale;

    final offsetX = (viewportWidth - scaledWidth) / 2;
    final offsetY = (viewportHeight - scaledHeight) / 2;

    _controller.value = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(totalScale);

    _updateDebugOverlay();
  }

  _CropRect _currentCropRect() {
    final sourceWidth = _sourceWidth();
    final sourceHeight = _sourceHeight();

    final matrix = _controller.value;

    final totalScale = matrix.getMaxScaleOnAxis();
    final tx = matrix.storage[12];
    final ty = matrix.storage[13];

    final left = (-tx) / totalScale;
    final top = (-ty) / totalScale;

    final right = left + (viewportWidth / totalScale);
    final bottom = top + (viewportHeight / totalScale);

    final safeLeft = left.clamp(0.0, sourceWidth);
    final safeTop = top.clamp(0.0, sourceHeight);
    final safeRight = right.clamp(0.0, sourceWidth);
    final safeBottom = bottom.clamp(0.0, sourceHeight);

    return _CropRect(
      left: safeLeft,
      top: safeTop,
      right: safeRight,
      bottom: safeBottom,
      zoom: totalScale / _baseScale(),
    );
  }

  void _updateDebugOverlay() {
    if (!mounted) return;

    final crop = _currentCropRect();

    setState(() {
      debugLeft = crop.left.round();
      debugRight = crop.right.round();
      debugTop = crop.top.round();
      debugBottom = crop.bottom.round();
      debugZoom = crop.zoom;
    });
  }

  Future<void> _save() async {
    if (decodedImage == null) {
      return;
    }

    final turns = rotationQuarterTurns % 4;

    img.Image working = decodedImage!;

    if (turns == 1) {
      working = img.copyRotate(working, angle: 90);
    } else if (turns == 2) {
      working = img.copyRotate(working, angle: 180);
    } else if (turns == 3) {
      working = img.copyRotate(working, angle: 270);
    }

    final crop = _currentCropRect();

    final cropLeft = crop.left.round().clamp(0, working.width - 1);
    final cropTop = crop.top.round().clamp(0, working.height - 1);

    final cropRight = crop.right.round().clamp(cropLeft + 1, working.width);
    final cropBottom = crop.bottom.round().clamp(cropTop + 1, working.height);

    final cropWidth = cropRight - cropLeft;
    final cropHeight = cropBottom - cropTop;

    final cropped = img.copyCrop(
      working,
      x: cropLeft,
      y: cropTop,
      width: cropWidth,
      height: cropHeight,
    );

    final resized = img.copyResize(
      cropped,
      width: widget.targetWidthPx,
      height: widget.targetHeightPx,
      interpolation: img.Interpolation.cubic,
    );
    tsPrint('RESIZED SAVE SIZE: ${resized.width}x${resized.height}');

    final outFile = File(widget.croppedImagePath);

    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(img.encodeJpg(resized, quality: 95));

    //await Gal.putImage(outFile.path, album: 'Pictures');

    tsPrint('CROPPED IMAGE WRITTEN');
    tsPrint(widget.croppedImagePath);
    tsPrint('CROP: $cropLeft,$cropTop ${cropWidth}x$cropHeight');
    tsPrint('ZOOM: ${crop.zoom}');
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      PhotoCropResult(
        cropLeft: cropLeft.toDouble(),
        cropTop: cropTop.toDouble(),
        cropWidth: cropWidth.toDouble(),
        cropHeight: cropHeight.toDouble(),
        zoom: crop.zoom,
        rotationQuarterTurns: rotationQuarterTurns,
        rawWidth: working.width.toDouble(),
        rawHeight: working.height.toDouble(),
        croppedImagePath: widget.croppedImagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Position Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_left),
            onPressed: () {
              setState(() {
                rotationQuarterTurns = (rotationQuarterTurns + 1) % 4;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _resetTransform();
                }
              });
            },
          ),
          TextButton(onPressed: _save, child: const Text('SAVE')),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final previewAspect = widget.profilePictureCrops.isEmpty
              ? 1.0
              : widget.profilePictureCrops
                    .map(
                      (crop) =>
                          (crop['aspectRatio'] as num?)?.toDouble() ?? 1.0,
                    )
                    .reduce((a, b) => a > b ? a : b);

          final maxW = constraints.maxWidth * 0.90;
          final maxH = constraints.maxHeight * 0.90;

          double calcWidth = maxW;
          double calcHeight = calcWidth / previewAspect;

          if (calcHeight > maxH) {
            calcHeight = maxH;
            calcWidth = calcHeight * previewAspect;
          }

          final viewportChanged =
              viewportWidth != calcWidth || viewportHeight != calcHeight;

          viewportWidth = calcWidth;
          viewportHeight = calcHeight;

          if (viewportChanged && decodedImage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _resetTransform();
              }
            });
          }

          return Stack(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: viewportWidth,
                      height: viewportHeight,
                      child: ClipRect(
                        child: InteractiveViewer(
                          transformationController: _controller,
                          minScale: _baseScale() * 0.5,
                          maxScale: _baseScale() * 8,
                          boundaryMargin: EdgeInsets.zero,
                          constrained: false,
                          child: SizedBox(
                            width: imageChildWidth,
                            height: imageChildHeight,
                            child: RotatedBox(
                              quarterTurns: rotationQuarterTurns,
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: SizedBox(
                        width: viewportWidth,
                        height: viewportHeight,
                        child: CustomPaint(
                          painter: _CropGuidePainter(
                            crops: widget.profilePictureCrops,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 5,
                left: 5,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    color: Colors.black.withOpacity(0.7),
                    child: Text(
                      'TL:($debugLeft,$debugTop) '
                      'BR:($debugRight,$debugBottom) '
                      'ZM:${debugZoom.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CropRect {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double zoom;

  const _CropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.zoom,
  });
}

class _CropGuidePainter extends CustomPainter {
  final List<Map<String, dynamic>> crops;

  const _CropGuidePainter({required this.crops});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final guideCrops = crops.isEmpty
        ? [
            {'aspectRatio': size.width / size.height, 'shape': 'rect'},
          ]
        : crops;

    for (final crop in guideCrops) {
      final aspectRatio =
          (crop['aspectRatio'] as num?)?.toDouble() ??
          (size.width / size.height);

      final shape = crop['shape']?.toString() ?? 'rect';

      final h = size.height;
      final w = h * aspectRatio;

      final rect = Rect.fromCenter(
        center: size.center(Offset.zero),
        width: w,
        height: h,
      );

      final path = Path();

      if (shape == 'oval') {
        path.addOval(rect);
      } else {
        path.addRect(rect);
      }

      _drawDashedPath(canvas, path, paint);

      final diagonal1 = Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.bottom);

      final diagonal2 = Path()
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.left, rect.bottom);

      _drawDashedPath(canvas, diagonal1, paint);
      _drawDashedPath(canvas, diagonal2, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashGap = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashWidth);

        canvas.drawPath(segment, paint);

        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CropGuidePainter oldDelegate) {
    return oldDelegate.crops != crops;
  }
}
