import 'package:flutter/material.dart';

class TstsTitleBar extends StatelessWidget implements PreferredSizeWidget {
  static const double titleBarHt = 35;

  final String title;

  const TstsTitleBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(titleBarHt);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: topPadding,
            color: Colors.black,
          ),
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
                  child: Image.asset(
                    'assets/backgrounds/trumpoot_titlebar_a.png',
                    height: titleBarHt,
                    fit: BoxFit.fitHeight,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: titleBarHt / 98 * 200,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleBarHt / 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}