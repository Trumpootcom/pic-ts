// lib/widgets/workspace_filmstrip.dart

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class WorkspaceFilmstripItem {
  final String title;
  final Widget thumbnail;

  const WorkspaceFilmstripItem({required this.title, required this.thumbnail});
}

class WorkspaceFilmstrip extends StatelessWidget {
  final List<WorkspaceFilmstripItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const WorkspaceFilmstrip({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const topGap = 5.0;
    const bottomGap = 10.0;
    const rightGap = 8.0;
    const leftGap = rightGap;

    const thumbHeight = 75.0;
    const thumbWidth = thumbHeight*11.0/8.5;

    const horizontalGap = 10.0;

    return Padding(
      padding: const EdgeInsets.only(top: topGap, bottom: bottomGap, right: rightGap, left: leftGap),
      child: SizedBox(
        height: thumbHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final selected = index == currentIndex;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onTap(index),
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
                    child: Opacity(
                      opacity: selected ? 1.0 : 0.45,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: items[index].thumbnail,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: horizontalGap),
              ],
            );
          },
        ),
      ),
    );
  }
}
