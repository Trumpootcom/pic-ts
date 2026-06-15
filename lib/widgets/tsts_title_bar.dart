import 'package:flutter/material.dart';
import 'package:pic_ts/theme/app_colors.dart';
import '../pages/about_page.dart';
import '../build_info.dart';

class TstsTitleBar extends StatelessWidget implements PreferredSizeWidget {
  static const double titleBarHt = 50;

  final String title;
  final String subtitle;
  final VoidCallback? onLogoTap;

  const TstsTitleBar({
    super.key,
    required this.title,
    this.subtitle = "Trumpoot's Sweet Tool Suite",
    this.onLogoTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(titleBarHt);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.darkUnsat.withAlpha(180),
            blurRadius: 1.5,
            spreadRadius: 1.5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: topPadding, color: Colors.black),
            SizedBox(
              height: titleBarHt,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/backgrounds/trumpoot_titlebar_b.png',
                    fit: BoxFit.fill,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Tooltip(
                      message: 'About',
                      child: GestureDetector(
                        onTap:
                            onLogoTap ??
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AboutPage(),
                                ),
                              );
                            },
                        child: Image.asset(
                          'assets/backgrounds/trumpoot_titlebar_a.png',
                          height: titleBarHt,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: titleBarHt / 98 * 185),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            title, //+' (v$buildTime)',
                            style: TextStyle(
                              fontSize: titleBarHt * 0.42 * 0.6,
                              fontFeatures: [FontFeature.enable('smcp')],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                              height: 0.95,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: titleBarHt * 0.42,
                              fontWeight: FontWeight.w500,
                              fontFeatures: [FontFeature.enable('smcp')],
                              letterSpacing: -0.6,
                              height: 0.95,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
