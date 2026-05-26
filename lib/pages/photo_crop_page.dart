import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../util/ts_print.dart';

class PhotoCropResult {
  final double centerX;
  final double centerY;
  final double zoom;
  final int rotationQuarterTurns;
  final double guideWidth;
  final double guideHeight;
  

  const PhotoCropResult({
    required this.centerX,
    required this.centerY,
    required this.zoom,
    required this.rotationQuarterTurns,
    required this.guideWidth,
    required this.guideHeight,
  });
}

class PhotoCropPage extends StatefulWidget {
  final String imagePath;
  final double initialPanX;
  final double initialPanY;
  final double initialZoom;
  final int initialRotationQuarterTurns;
  final List<Map<String, dynamic>> profilePictureCrops;

  const PhotoCropPage({
    super.key,
    required this.imagePath,
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
  late int rotationQuarterTurns;
  late final TransformationController _controller;

  final GlobalKey _viewerKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _guideKey = GlobalKey();

  double guideWidth = 1;
  double guideHeight = 1;

  @override
  void initState() {
    super.initState();

    rotationQuarterTurns = widget.initialRotationQuarterTurns;

    _controller = TransformationController(
      Matrix4.identity()
        ..translate(widget.initialPanX, widget.initialPanY)
        ..scale(widget.initialZoom),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _CropCalculation? _calculateCrop() {
    final guideContext = _guideKey.currentContext;
    final imageContext = _imageKey.currentContext;

    if (guideContext == null || imageContext == null) {
      tsPrint('CROP CALC FAILED: missing render context');
      return null;
    }

    final guideBox = guideContext.findRenderObject() as RenderBox?;
    final imageBox = imageContext.findRenderObject() as RenderBox?;

    if (guideBox == null || imageBox == null) {
      tsPrint('CROP CALC FAILED: missing render box');
      return null;
    }

    final imageBytes = File(widget.imagePath).readAsBytesSync();
    final decoded = img.decodeImage(imageBytes);

    if (decoded == null) {
      tsPrint('CROP CALC FAILED: image decode failed');
      return null;
    }

    final rawWidth = decoded.width.toDouble();
    final rawHeight = decoded.height.toDouble();

    final guideCenterGlobal = guideBox.localToGlobal(
      guideBox.size.center(Offset.zero),
    );

    final imageLocal = imageBox.globalToLocal(guideCenterGlobal);

    final rawPixelX = imageLocal.dx / imageBox.size.width * rawWidth;
    final rawPixelY = imageLocal.dy / imageBox.size.height * rawHeight;

    final matrix = _controller.value;
    final zoom = matrix.getMaxScaleOnAxis();

    return _CropCalculation(
      matrix: matrix,
      zoom: zoom,
      rawWidth: rawWidth,
      rawHeight: rawHeight,
      guideGlobalLeft: guideBox.localToGlobal(Offset.zero).dx,
      guideGlobalTop: guideBox.localToGlobal(Offset.zero).dy,
      guideWidth: guideBox.size.width,
      guideHeight: guideBox.size.height,
      guideCenterGlobalX: guideCenterGlobal.dx,
      guideCenterGlobalY: guideCenterGlobal.dy,
      imageGlobalLeft: imageBox.localToGlobal(Offset.zero).dx,
      imageGlobalTop: imageBox.localToGlobal(Offset.zero).dy,
      imageRenderedWidth: imageBox.size.width,
      imageRenderedHeight: imageBox.size.height,
      imageLocalX: imageLocal.dx,
      imageLocalY: imageLocal.dy,
      rawPixelX: rawPixelX,
      rawPixelY: rawPixelY,
    );
  }

  void _save() {
    final crop = _calculateCrop();

    if (crop == null) return;

    _printCropCalculation('CROP SAVE', crop);

    Navigator.of(context).pop(
      PhotoCropResult(
        centerX: crop.rawPixelX,
        centerY: crop.rawPixelY,
        zoom: crop.zoom,
        rotationQuarterTurns: rotationQuarterTurns,
        guideWidth: guideWidth,
        guideHeight: guideHeight,
      ),
    );
  }

  void _printCropDebug() {
    final crop = _calculateCrop();

    if (crop == null) return;

    _printCropCalculation('CROP DEBUG BUTTON', crop);
  }

  void _printCropCalculation(String title, _CropCalculation crop) {
    tsPrint('');
    tsPrint('========================================');
    tsPrint(title);
    tsPrint('========================================');

    tsPrint('RAW IMAGE SIZE: ${crop.rawWidth} x ${crop.rawHeight}');

    tsPrint('');
    tsPrint('GUIDE');
    tsPrint('GLOBAL LEFT/TOP: ${crop.guideGlobalLeft}, ${crop.guideGlobalTop}');
    tsPrint('SIZE: ${crop.guideWidth} x ${crop.guideHeight}');
    tsPrint(
      'GLOBAL CENTER: ${crop.guideCenterGlobalX}, ${crop.guideCenterGlobalY}',
    );

    tsPrint('');
    tsPrint('IMAGE RENDER BOX');
    tsPrint('GLOBAL LEFT/TOP: ${crop.imageGlobalLeft}, ${crop.imageGlobalTop}');
    tsPrint('SIZE: ${crop.imageRenderedWidth} x ${crop.imageRenderedHeight}');

    tsPrint('');
    tsPrint('COORDINATES');
    tsPrint('IMAGE LOCAL COORD: ${crop.imageLocalX}, ${crop.imageLocalY}');
    tsPrint('RAW PIXEL COORD: ${crop.rawPixelX}, ${crop.rawPixelY}');

    tsPrint('');
    tsPrint('TRANSFORM');
    tsPrint('ZOOM: ${crop.zoom}');
    tsPrint('ROTATION: $rotationQuarterTurns');
    tsPrint('MATRIX:');
    tsPrint(crop.matrix);

    tsPrint('========================================');
    tsPrint('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Position Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _printCropDebug,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_left),
            onPressed: () {
              setState(() {
                rotationQuarterTurns = (rotationQuarterTurns + 1) % 4;
              });
            },
          ),
          TextButton(
            onPressed: _save,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
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

            double calculatedGuideWidth = maxW;
            double calculatedGuideHeight = calculatedGuideWidth / previewAspect;

            if (calculatedGuideHeight > maxH) {
              calculatedGuideHeight = maxH;
              calculatedGuideWidth = calculatedGuideHeight * previewAspect;
            }

            guideWidth = calculatedGuideWidth;
            guideHeight = calculatedGuideHeight;

            return Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  key: _viewerKey,
                  transformationController: _controller,
                  minScale: 0.5,
                  maxScale: 6,
                  child: RotatedBox(
                    quarterTurns: rotationQuarterTurns,
                    child: Image.file(
                      File(widget.imagePath),
                      key: _imageKey,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: SizedBox(
                    key: _guideKey,
                    width: guideWidth,
                    height: guideHeight,
                    child: CustomPaint(
                      painter: _CropGuidePainter(
                        crops: widget.profilePictureCrops,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CropCalculation {
  final Matrix4 matrix;
  final double zoom;

  final double rawWidth;
  final double rawHeight;

  final double guideGlobalLeft;
  final double guideGlobalTop;
  final double guideWidth;
  final double guideHeight;
  final double guideCenterGlobalX;
  final double guideCenterGlobalY;

  final double imageGlobalLeft;
  final double imageGlobalTop;
  final double imageRenderedWidth;
  final double imageRenderedHeight;

  final double imageLocalX;
  final double imageLocalY;

  final double rawPixelX;
  final double rawPixelY;

  const _CropCalculation({
    required this.matrix,
    required this.zoom,
    required this.rawWidth,
    required this.rawHeight,
    required this.guideGlobalLeft,
    required this.guideGlobalTop,
    required this.guideWidth,
    required this.guideHeight,
    required this.guideCenterGlobalX,
    required this.guideCenterGlobalY,
    required this.imageGlobalLeft,
    required this.imageGlobalTop,
    required this.imageRenderedWidth,
    required this.imageRenderedHeight,
    required this.imageLocalX,
    required this.imageLocalY,
    required this.rawPixelX,
    required this.rawPixelY,
  });
}

class _CropGuidePainter extends CustomPainter {
  final List<Map<String, dynamic>> crops;

  const _CropGuidePainter({
    required this.crops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final guideCrops = crops.isEmpty
        ? [
            {
              'aspectRatio': size.width / size.height,
              'shape': 'rect',
            },
          ]
        : crops;

    for (final crop in guideCrops) {
      final aspectRatio =
          (crop['aspectRatio'] as num?)?.toDouble() ??
          (size.width / size.height);

      final shape = crop['shape']?.toString() ?? 'rect';

      final guideHeight = size.height;
      final guideWidth = guideHeight * aspectRatio;

      final rect = Rect.fromCenter(
        center: size.center(Offset.zero),
        width: guideWidth,
        height: guideHeight,
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

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
  ) {
    const dashWidth = 8.0;
    const dashGap = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final segment = metric.extractPath(
          distance,
          distance + dashWidth,
        );

        canvas.drawPath(segment, paint);

        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _CropGuidePainter oldDelegate,
  ) {
    return oldDelegate.crops != crops;
  }
}