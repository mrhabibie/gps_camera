import 'package:flutter/material.dart';

class BPSColor {
  BPSColor._();

  static const MaterialColor primary = MaterialColor(
    0xff478AFA,
    <int, Color>{
      100: Color(0xffEAF2FF),
      200: Color(0xffC9E0FD),
      300: Color(0xff9BC4F9),
      400: Color(0xff7FB2F9),
    },
  );

  static const MaterialColor secondary = MaterialColor(
    0xffE05347,
    <int, Color>{
      400: Color(0xffE05347),
    },
  );

  static const MaterialColor text = MaterialColor(0xff182752, {});
  static const MaterialColor textSecondary = MaterialColor(0xffb3182752, {});
  static const MaterialColor textPlaceholder = MaterialColor(0xff40182752, {});
}
