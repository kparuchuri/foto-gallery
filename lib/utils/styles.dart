import 'package:flutter/material.dart';
import 'package:foto_gallery/utils/utility.dart';

class Styles {
  static ThemeData darkTheme() {
    return /* ThemeData(
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.grey),
      useMaterial3: true,
    ); */
        ThemeData(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(
          parseColorInt('#000000'),
          getColorSwatch(parseColor('#000000')),
        ),
        accentColor: const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme:
          const AppBarTheme(iconTheme: IconThemeData(color: Colors.white)),
    );
  }
}
