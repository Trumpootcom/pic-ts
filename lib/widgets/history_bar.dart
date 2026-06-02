import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const double historyBarHeight = 20;
const double historyBarTopGap = 8.0;
const double historyBarBottomGap = 0.0;
const double historyBarHorizontalGap = 8.0;
const double historyBarIconScale = 0.5;

class HistoryBar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final String? undoText;
  final String? redoText;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onSave;
  final bool verbose;

  const HistoryBar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.undoText,
    required this.redoText,
    required this.onUndo,
    required this.onRedo,
    this.onSave,
    this.verbose = false,
  });

  @override
  Widget build(BuildContext context) {
    if (verbose) {
      return _VerboseHistoryBar(
        canUndo: canUndo,
        canRedo: canRedo,
        undoText: undoText,
        redoText: redoText,
        onUndo: onUndo,
        onRedo: onRedo,
        onSave: onSave,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: historyBarTopGap,
        bottom: historyBarBottomGap,
        left: historyBarHorizontalGap,
        right: historyBarHorizontalGap,
      ),
      child: Container(
        height: historyBarHeight,
        color: AppColors.lightUnsat,
        child: Row(
          children: [
            Expanded(
              child: _HistorySide(
                icon: Icons.undo_rounded,
                enabled: canUndo,
                text: undoText,
                onTap: onUndo,
                reverse: false,
              ),
            ),
            Container(
              width: 1,
              height: 16,
              color: AppColors.medUnsat,
            ),
            Expanded(
              child: _HistorySide(
                icon: Icons.redo_rounded,
                enabled: canRedo,
                text: redoText,
                onTap: onRedo,
                reverse: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerboseHistoryBar extends StatelessWidget {
  static const double _height = historyBarHeight * 2;

  final bool canUndo;
  final bool canRedo;
  final String? undoText;
  final String? redoText;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onSave;

  const _VerboseHistoryBar({
    required this.canUndo,
    required this.canRedo,
    required this.undoText,
    required this.redoText,
    required this.onUndo,
    required this.onRedo,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(historyBarHeight);
    final undoColor = canUndo
        ? AppColors.textDark
        : AppColors.textDark.withValues(alpha: 0.28);
    final redoColor = canRedo
        ? AppColors.textDark
        : AppColors.textDark.withValues(alpha: 0.28);

    return Padding(
      padding: const EdgeInsets.only(
        top: historyBarTopGap,
        bottom: historyBarBottomGap,
        left: historyBarHorizontalGap,
        right: historyBarHorizontalGap,
      ),
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: AppColors.medUnsat.withAlpha(120),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.darkUnsat.withAlpha(120),
              blurRadius: 2,
              spreadRadius: 2,
              offset: const Offset(0, 0.75),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              const Positioned.fill(
                child: _HistoryBarBackground(height: _height),
              ),
              _CapAwareHistoryText(
                assetPath: _HistoryBarBackground._leftAssetPath,
                barHeight: _height,
                leftInsetOffset: -historyBarHeight,
                reserveLeftCap: true,
                reserveRightCap: false,
                top: 1,
                tooltipPrefix: 'UNDO',
                text: canUndo ? (undoText ?? '') : '',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: undoColor,
                  fontSize: _height / 4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              _CapAwareHistoryText(
                assetPath: _HistoryBarBackground._rightAssetPath,
                barHeight: _height,
                rightInsetOffset: -historyBarHeight,
                reserveLeftCap: false,
                reserveRightCap: true,
                bottom: 1,
                tooltipPrefix: 'REDO',
                text: canRedo ? (redoText ?? '') : '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: redoColor,
                  fontSize: _height / 4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              _CapHistoryButton(
                assetPath: _HistoryBarBackground._leftAssetPath,
                centerX: 50,
                centerY: 50,
                barHeight: _height,
                anchorRight: false,
                icon: Icons.fast_rewind_rounded,
                iconSize: _height * historyBarIconScale*1.33,
                tooltip: 'Undo',
                enabled: canUndo,
                color: undoColor,
                onTap: onUndo,
              ),
              _CapHistoryButton(
                assetPath: _HistoryBarBackground._rightAssetPath,
                centerX: 96,
                centerY: 50,
                barHeight: _height,
                anchorRight: true,
                icon: Icons.fast_forward_rounded,
                iconSize: _height * historyBarIconScale*1.33,
                tooltip: 'Redo',
                enabled: canRedo,
                color: redoColor,
                onTap: onRedo,
              ),
              _CapHistoryButton(
                assetPath: _HistoryBarBackground._rightAssetPath,
                centerX: 156,
                centerY: 50,
                barHeight: _height,
                anchorRight: true,
                icon: Icons.save_rounded,
                iconSize: _height * historyBarIconScale,
                tooltip: 'Save Changes / Clear History',
                enabled: onSave != null,
                color: AppColors.textDark,
                onTap: onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryBarBackground extends StatefulWidget {
  static const String _leftAssetPath =
      'assets/backgrounds/trumpoot_histbar_l.png';
  static const String _middleAssetPath =
      'assets/backgrounds/trumpoot_histbar_m.png';
  static const String _rightAssetPath =
      'assets/backgrounds/trumpoot_histbar_r.png';
  static const double _saturation = 0.80;

  final double height;

  const _HistoryBarBackground({required this.height});

  @override
  State<_HistoryBarBackground> createState() => _HistoryBarBackgroundState();
}

class _HistoryBarBackgroundState extends State<_HistoryBarBackground> {
  ImageStream? _leftCapImageStream;
  ImageStream? _rightCapImageStream;
  ImageStreamListener? _leftCapImageListener;
  ImageStreamListener? _rightCapImageListener;
  double? _leftCapAspectRatio;
  double? _rightCapAspectRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveCapDimensions(
      assetPath: _HistoryBarBackground._leftAssetPath,
      currentStream: _leftCapImageStream,
      onStreamChanged: (imageStream) => _leftCapImageStream = imageStream,
      currentListener: _leftCapImageListener,
      onListenerChanged: (imageListener) {
        _leftCapImageListener = imageListener;
      },
      onAspectRatioChanged: (aspectRatio) {
        _leftCapAspectRatio = aspectRatio;
      },
    );
    _resolveCapDimensions(
      assetPath: _HistoryBarBackground._rightAssetPath,
      currentStream: _rightCapImageStream,
      onStreamChanged: (imageStream) => _rightCapImageStream = imageStream,
      currentListener: _rightCapImageListener,
      onListenerChanged: (imageListener) {
        _rightCapImageListener = imageListener;
      },
      onAspectRatioChanged: (aspectRatio) {
        _rightCapAspectRatio = aspectRatio;
      },
    );
  }

  @override
  void dispose() {
    _removeCapImageListener(_leftCapImageStream, _leftCapImageListener);
    _removeCapImageListener(_rightCapImageStream, _rightCapImageListener);
    super.dispose();
  }

  void _resolveCapDimensions({
    required String assetPath,
    required ImageStream? currentStream,
    required ValueChanged<ImageStream?> onStreamChanged,
    required ImageStreamListener? currentListener,
    required ValueChanged<ImageStreamListener?> onListenerChanged,
    required ValueChanged<double?> onAspectRatioChanged,
  }) {
    final asset = AssetImage(assetPath);
    final imageStream = asset.resolve(createLocalImageConfiguration(context));

    if (currentStream?.key == imageStream.key) {
      return;
    }

    _removeCapImageListener(currentStream, currentListener);

    onStreamChanged(imageStream);
    final imageListener = ImageStreamListener((imageInfo, synchronousCall) {
      if (!mounted) return;

      final width = imageInfo.image.width.toDouble();
      final height = imageInfo.image.height.toDouble();

      setState(() {
        onAspectRatioChanged(height == 0 ? null : width / height);
      });
    });

    onListenerChanged(imageListener);
    imageStream.addListener(imageListener);
  }

  void _removeCapImageListener(
    ImageStream? imageStream,
    ImageStreamListener? imageListener,
  ) {
    if (imageStream != null && imageListener != null) {
      imageStream.removeListener(imageListener);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leftCapWidth = widget.height * (_leftCapAspectRatio ?? 0);
    final rightCapWidth = widget.height * (_rightCapAspectRatio ?? 0);
    final leftCapOverlapWidth = leftCapWidth.floorToDouble();
    final rightCapOverlapWidth = rightCapWidth.floorToDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: leftCapOverlapWidth,
              right: rightCapOverlapWidth,
              top: 0,
              bottom: 0,
              child: _SaturationFilteredImage(
                assetPath: _HistoryBarBackground._middleAssetPath,
                saturation: _HistoryBarBackground._saturation,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: leftCapWidth,
                height: widget.height,
                child: _SaturationFilteredImage(
                  assetPath: _HistoryBarBackground._leftAssetPath,
                  saturation: _HistoryBarBackground._saturation,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: rightCapWidth,
                height: widget.height,
                child: _SaturationFilteredImage(
                  assetPath: _HistoryBarBackground._rightAssetPath,
                  saturation: _HistoryBarBackground._saturation,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SaturationFilteredImage extends StatelessWidget {
  final String assetPath;
  final double saturation;
  final BoxFit fit;

  const _SaturationFilteredImage({
    required this.assetPath,
    required this.saturation,
    this.fit = BoxFit.fill,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
      child: Image.asset(assetPath, fit: fit),
    );
  }

  List<double> _saturationMatrix(double saturation) {
    const redLuminance = 0.2126;
    const greenLuminance = 0.7152;
    const blueLuminance = 0.0722;
    final inverseSaturation = 1 - saturation;

    return [
      redLuminance * inverseSaturation + saturation,
      greenLuminance * inverseSaturation,
      blueLuminance * inverseSaturation,
      0,
      0,
      redLuminance * inverseSaturation,
      greenLuminance * inverseSaturation + saturation,
      blueLuminance * inverseSaturation,
      0,
      0,
      redLuminance * inverseSaturation,
      greenLuminance * inverseSaturation,
      blueLuminance * inverseSaturation + saturation,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

class _CapAwareHistoryText extends StatefulWidget {
  final String assetPath;
  final double barHeight;
  final bool reserveLeftCap;
  final bool reserveRightCap;
  final double leftInsetOffset;
  final double rightInsetOffset;
  final double? top;
  final double? bottom;
  final String? tooltipPrefix;
  final String text;
  final TextAlign textAlign;
  final TextStyle style;

  const _CapAwareHistoryText({
    required this.assetPath,
    required this.barHeight,
    required this.reserveLeftCap,
    required this.reserveRightCap,
    required this.text,
    required this.textAlign,
    required this.style,
    this.leftInsetOffset = 0,
    this.rightInsetOffset = 0,
    this.top,
    this.bottom,
    this.tooltipPrefix,
  });

  @override
  State<_CapAwareHistoryText> createState() => _CapAwareHistoryTextState();
}

class _CapAwareHistoryTextState extends State<_CapAwareHistoryText> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  double? _aspectRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveDimensions();
  }

  @override
  void didUpdateWidget(covariant _CapAwareHistoryText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.assetPath != widget.assetPath) {
      _resolveDimensions();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _resolveDimensions() {
    final asset = AssetImage(widget.assetPath);
    final imageStream = asset.resolve(createLocalImageConfiguration(context));

    if (_imageStream?.key == imageStream.key) {
      return;
    }

    _removeImageListener();

    _imageStream = imageStream;
    _imageListener = ImageStreamListener((imageInfo, synchronousCall) {
      if (!mounted) return;

      final width = imageInfo.image.width.toDouble();
      final height = imageInfo.image.height.toDouble();

      setState(() {
        _aspectRatio = height == 0 ? null : width / height;
      });
    });

    imageStream.addListener(_imageListener!);
  }

  void _removeImageListener() {
    final imageStream = _imageStream;
    final imageListener = _imageListener;

    if (imageStream != null && imageListener != null) {
      imageStream.removeListener(imageListener);
    }

    _imageStream = null;
    _imageListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final fallbackInset = widget.barHeight * 1.1;
    final capInset = widget.barHeight * (_aspectRatio ?? 1.1);

    return Positioned(
      left:
          (widget.reserveLeftCap ? capInset : fallbackInset) +
          widget.leftInsetOffset,
      right:
          (widget.reserveRightCap ? capInset : fallbackInset) +
          widget.rightInsetOffset,
      top: widget.top,
      bottom: widget.bottom,
      child: Tooltip(
        message: widget.tooltipPrefix == null
            ? widget.text
            : '${widget.tooltipPrefix}: ${widget.text}',
        child: Text(
          widget.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: widget.textAlign,
          style: widget.style,
        ),
      ),
    );
  }
}

class _CapHistoryButton extends StatefulWidget {
  final String assetPath;
  final double centerX;
  final double centerY;
  final double barHeight;
  final bool anchorRight;
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  const _CapHistoryButton({
    required this.assetPath,
    required this.centerX,
    required this.centerY,
    required this.barHeight,
    required this.anchorRight,
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CapHistoryButton> createState() => _CapHistoryButtonState();
}

class _CapHistoryButtonState extends State<_CapHistoryButton> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  Size? _sourceSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveDimensions();
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _resolveDimensions() {
    final asset = AssetImage(widget.assetPath);
    final imageStream = asset.resolve(createLocalImageConfiguration(context));

    if (_imageStream?.key == imageStream.key) {
      return;
    }

    _removeImageListener();

    _imageStream = imageStream;
    _imageListener = ImageStreamListener((imageInfo, synchronousCall) {
      if (!mounted) return;

      setState(() {
        _sourceSize = Size(
          imageInfo.image.width.toDouble(),
          imageInfo.image.height.toDouble(),
        );
      });
    });

    imageStream.addListener(_imageListener!);
  }

  void _removeImageListener() {
    final imageStream = _imageStream;
    final imageListener = _imageListener;

    if (imageStream != null && imageListener != null) {
      imageStream.removeListener(imageListener);
    }

    _imageStream = null;
    _imageListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final sourceSize = _sourceSize;

    if (sourceSize == null || sourceSize.height == 0) {
      return const SizedBox.shrink();
    }

    final scale = widget.barHeight / sourceSize.height;
    final capWidth = sourceSize.width * scale;
    final centerX = widget.centerX * scale;
    final centerY = widget.centerY * scale;
    final tapSize = widget.iconSize * 1.4;

    return Positioned(
      left: widget.anchorRight ? null : centerX - tapSize / 2,
      right: widget.anchorRight ? capWidth - centerX - tapSize / 2 : null,
      top: centerY - tapSize / 2,
      width: tapSize,
      height: tapSize,
      child: _VerboseHistoryButton(
        icon: widget.icon,
        iconSize: widget.iconSize,
        tooltip: widget.tooltip,
        enabled: widget.enabled,
        color: widget.color,
        alignment: Alignment.center,
        onTap: widget.onTap,
      ),
    );
  }
}

class _VerboseHistoryButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final bool enabled;
  final Color color;
  final Alignment alignment;
  final VoidCallback? onTap;

  const _VerboseHistoryButton({
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    required this.enabled,
    required this.color,
    required this.alignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 3 * historyBarHeight / 24,
            ),
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }
}

class _HistorySide extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String? text;
  final VoidCallback? onTap;
  final bool reverse;

  const _HistorySide({
    required this.icon,
    required this.enabled,
    required this.text,
    required this.onTap,
    required this.reverse,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.textDark
        : AppColors.textDark.withValues(alpha: 0.28);

    final label = enabled ? (text ?? '') : '';

    final children = [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: reverse ? TextAlign.left : TextAlign.right,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: reverse
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: reverse ? children.reversed.toList() : children,
        ),
      ),
    );
  }
}
