import 'dart:io';

import 'package:flutter/material.dart';


class PhotoCropResult {
  final double panX;
  final double panY;
  final double zoom;
  final int rotationQuarterTurns;

  const PhotoCropResult({
    required this.panX,
    required this.panY,
    required this.zoom,
    required this.rotationQuarterTurns,
  });
}

class PhotoCropPage extends StatefulWidget {
  final String imagePath;
  final double initialPanX;
  final double initialPanY;
  final double initialZoom;
  final int initialRotationQuarterTurns;

  const PhotoCropPage({
    super.key,
    required this.imagePath,
    this.initialPanX = 0,
    this.initialPanY = 0,
    this.initialZoom = 1,
    this.initialRotationQuarterTurns = 0,
  });

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  late final TransformationController _controller;
  late int rotationQuarterTurns;
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

  void _save() {
    final matrix = _controller.value;
    final zoom = matrix.getMaxScaleOnAxis();
    final panX = matrix.getTranslation().x;
    final panY = matrix.getTranslation().y;

    Navigator.of(context).pop(
      PhotoCropResult(
        panX: panX,
        panY: panY,
        zoom: zoom,
        rotationQuarterTurns: rotationQuarterTurns,
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
            },
          ),
          TextButton(onPressed: _save, child: const Text('SAVE')),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final guideHeight = constraints.maxHeight * 0.90;
            final guideWidth = guideHeight * (1.7 / 2.3);

            return Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  transformationController: _controller,
                  minScale: 0.5,
                  maxScale: 6,
                  child: RotatedBox(
                    quarterTurns: rotationQuarterTurns,
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: SizedBox(
                    width: guideWidth,
                    height: guideHeight,
                    child: CustomPaint(painter: _CropGuidePainter()),
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

class _CropGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashGap = 6.0;

    final rect = Offset.zero & size;
    final path = Path()..addOval(rect);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
