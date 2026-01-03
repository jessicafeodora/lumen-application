import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double mobileMax = 480;
  static const double tabletMax = 1023;
  static const double desktopMin = 1024;
}

enum LumenLayout { mobile, tablet, desktop }

LumenLayout layoutForWidth(double width) {
  if (width >= Breakpoints.desktopMin) return LumenLayout.desktop;
  if (width > Breakpoints.mobileMax) return LumenLayout.tablet;
  return LumenLayout.mobile;
}

EdgeInsets pagePaddingForWidth(double width) {
  if (width >= Breakpoints.desktopMin) return const EdgeInsets.symmetric(horizontal: 32, vertical: 28);
  if (width > Breakpoints.mobileMax) return const EdgeInsets.symmetric(horizontal: 20, vertical: 20);
  return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
}
