// lib/widgets/workspace_filmstrip.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';

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

  const WorkspaceFilmstrip({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.currentPagePosition,
    required this.onTap,
    this.onPagePositionChanged,
  });

  @override
  State<WorkspaceFilmstrip> createState() => _WorkspaceFilmstripState();
}

class _WorkspaceFilmstripState extends State<WorkspaceFilmstrip> {
  final ScrollController _scrollController = ScrollController();

  static const double topGap = 5.0;
  static const double bottomGap = 5.0;

  static const double thumbHeight = 55.0;
  static const double thumbWidth = thumbHeight * 11.0 / 8.5;

  static const double horizontalGap = 10.0;
  bool _userDraggingFilmstrip = false;

  bool _syncingFromPageView = false;

  double get _itemStride => thumbWidth + horizontalGap;

  @override
  void initState() {
    super.initState();
    //_scrollController.addListener(_handleFilmstripScroll);
  }

  void _handleFilmstripScroll() {
    if (_syncingFromPageView) return;
    if (!_scrollController.hasClients) return;

    final pagePosition = _scrollController.offset / _itemStride;
    widget.onPagePositionChanged?.call(pagePosition);
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
    //_scrollController.removeListener(_handleFilmstripScroll);
    _scrollController.dispose();
    super.dispose();
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
    return Padding(
      padding: const EdgeInsets.only(top: topGap, bottom: bottomGap),
      child: Container(
        height: thumbHeight + horizontalGap,
        decoration: BoxDecoration(
          color: AppColors.lightUnsat,
          boxShadow: [
            BoxShadow(
              color: AppColors.darkUnsat.withAlpha(120),
              blurRadius: 1.5,
              spreadRadius: 1.5,
              offset: Offset(0, -1.5),
            ),
            BoxShadow(
              color: AppColors.darkUnsat.withAlpha(120),
              blurRadius: 1.5,
              spreadRadius: 1.5,
              offset: Offset(0, 1.5),
            ),
          ],
        ),

        child: SizedBox(
          height: thumbHeight + horizontalGap,
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

                        final rawIndex = _scrollController.offset / _itemStride;
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
                        //final selected = index == widget.currentIndex;
                        final selected = false;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => widget.onTap(index),
                              child: Container(
                                width: thumbWidth,
                                height: thumbHeight,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.darkUnsat
                                      : AppColors.medUnsat,
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
                          height: thumbHeight + horizontalGap,
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
                        height: thumbHeight + horizontalGap,
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
    );
  }
}
