import 'package:flutter/material.dart';

enum DeviceClass { mobile, tablet, desktop }

class Responsive {
  static DeviceClass deviceFor(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (width >= 1024) return DeviceClass.desktop;
    if (width >= 600) return DeviceClass.tablet;
    return DeviceClass.mobile;
  }

  static int gridColumns(BoxConstraints constraints) {
    switch (deviceFor(constraints)) {
      case DeviceClass.desktop:
        return 4;
      case DeviceClass.tablet:
        return 3;
      case DeviceClass.mobile:
        return 2;
    }
  }

  static int categoryColumns(BoxConstraints constraints) {
    switch (deviceFor(constraints)) {
      case DeviceClass.desktop:
        return 8;
      case DeviceClass.tablet:
        return 6;
      case DeviceClass.mobile:
        return 4;
    }
  }

  static double horizontalPadding(BoxConstraints constraints) {
    switch (deviceFor(constraints)) {
      case DeviceClass.desktop:
        return 28;
      case DeviceClass.tablet:
        return 22;
      case DeviceClass.mobile:
        return 16;
    }
  }
}
