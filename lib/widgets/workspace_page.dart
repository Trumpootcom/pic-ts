import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class WorkspacePage extends StatelessWidget {
  final String title;
  final Widget? actions;
  final Widget child;

  const WorkspacePage({
    super.key,
    required this.title,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightUnsat,
          borderRadius: BorderRadius.circular(6),
          boxShadow:  [
            BoxShadow(
              color: AppColors.darkUnsat.withAlpha(180),
              blurRadius: 1.5,
              spreadRadius: 1.5,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkUnsat,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.enable('smcp')],
                        ),
                      ),
                    ),
                    if (actions != null) actions!,
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
