import 'package:flutter/material.dart';

class AppColors {
  static final Color lightUnsat =
      HSLColor.fromAHSL( 1.0, 41.0, 0.33, 0.75, ).toColor();

  static final Color lightSat =
      HSLColor.fromAHSL( 1.0, 41.0, 0.50, 0.76, ).toColor();

  static final Color medUnsat =
      HSLColor.fromAHSL( 1.0, 41.0, 0.33, 0.60, ).toColor();

  static final Color medSat =
      HSLColor.fromAHSL( 1.0, 41.0, 0.50, 0.60, ).toColor();

  static final Color darkUnsat =
      HSLColor.fromAHSL( 1.0, 41.0, 0.33, 0.33, ).toColor();

  static final Color darkSat =
      HSLColor.fromAHSL( 1.0, 41.0, 0.50, 0.33, ).toColor();

  static const Color textDark =
      Color(0xFF1E1E1E);

  static const Color textLight =
      Colors.white;
}