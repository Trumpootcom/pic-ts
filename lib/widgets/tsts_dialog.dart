import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TstsDialog extends StatelessWidget {
  static const double radius = 18;
  static const double titleHt = 36;

  final String title;
  final Widget child;
  final List<Widget>? actions;

  const TstsDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    const bodyColor = Color.fromARGB(255, 218, 201, 156);
    const borderColor = Color(0xFF7A6328);
    final baseTheme = Theme.of(context);
    final dialogTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: AppColors.darkSat,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.darkSat,
        selectionColor: AppColors.darkSat.withValues(alpha: 0.28),
        selectionHandleColor: AppColors.darkSat,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkSat,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkSat,
          side: BorderSide(color: AppColors.darkSat),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkSat,
          foregroundColor: AppColors.textLight,
        ),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.darkSat, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: AppColors.darkSat),
      ),
    );

    return Theme(
      data: dialogTheme,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            decoration: BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: titleHt,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/backgrounds/trumpoot_titlebar_b.png',
                        fit: BoxFit.fill,
                      ),
                      Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: titleHt * 0.45,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.all(radius), child: child),
                if (actions != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      radius,
                      0,
                      radius,
                      radius,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
