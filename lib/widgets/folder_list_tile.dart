import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FolderListTile extends StatelessWidget {
  final String title;
  final Widget? overlayIcon;
  final bool isCreateTile;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double size;

  const FolderListTile({
    super.key,
    required this.title,
    required this.overlayIcon,
    required this.isCreateTile,
    required this.size,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final folderSize = size;
    final tileHeight = folderSize;
    final iconSize = 28 * folderSize / 64;
    final leftWidth = folderSize + (15 * folderSize / 64);
    final fontSize = 20 * folderSize / 64;

    return Material(
      color: AppColors.lightUnsat,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: tileHeight,
          child: Row(
            children: [
              SizedBox(
                width: leftWidth,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isCreateTile ? Icons.create_new_folder : Icons.folder,
                      size: folderSize,
                      color: isCreateTile
                          ? AppColors.darkSat
                          : AppColors.medSat,
                    ),
                    if (overlayIcon != null)
                      Positioned(
                        right: (leftWidth - iconSize) / 2,
                        top: folderSize / 3,
                        child: SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: overlayIcon,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
