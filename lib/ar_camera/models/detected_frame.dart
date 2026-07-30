import 'package:flutter/material.dart';

/// A single independent pane/box that can be moved, resized, rotated individually
class PaneBox {
  final String id;

  /// Position (center point)
  Offset position;

  /// Size in screen pixels
  double width;
  double height;

  /// Flat rotation (degrees)
  double rotation;

  /// 3D perspective tilt
  double tiltX; // forward/back
  double tiltY; // left/right

  /// Fill color and opacity
  Color color;
  double opacity;

  /// Real dimensions in mm
  double realWidthMm;
  double realHeightMm;

  /// State
  bool isLocked;

  PaneBox({
    required this.id,
    required this.position,
    this.width = 120,
    this.height = 160,
    this.rotation = 0,
    this.tiltX = 0,
    this.tiltY = 0,
    required this.color,
    this.opacity = 0.7,
    this.realWidthMm = 600,
    this.realHeightMm = 800,
    this.isLocked = false,
  });

  /// Hit test
  bool containsPoint(Offset point) {
    final r = Rect.fromCenter(
        center: position, width: width + 20, height: height + 20);
    return r.contains(point);
  }

  PaneBox copyWith({
    Offset? position,
    double? width,
    double? height,
    double? rotation,
    double? tiltX,
    double? tiltY,
    Color? color,
    double? opacity,
    double? realWidthMm,
    double? realHeightMm,
    bool? isLocked,
  }) {
    return PaneBox(
      id: id,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      tiltX: tiltX ?? this.tiltX,
      tiltY: tiltY ?? this.tiltY,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      realWidthMm: realWidthMm ?? this.realWidthMm,
      realHeightMm: realHeightMm ?? this.realHeightMm,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

/// Color palette for auto-assigning pane colors
class PaneColors {
  static const List<Color> palette = [
    Color(0xFFBDBDBD), // Grey
    Color(0xFF212121), // Black
    Color(0xFF4DD0C8), // Teal
    Color(0xFF64C8FA), // Light Blue
    Color(0xFFF0B440), // Gold
    Color(0xFFE85540), // Red
    Color(0xFF3040D0), // Blue
    Color(0xFF7030A0), // Purple
    Color(0xFFE040A0), // Pink
    Color(0xFF40C040), // Green
    Color(0xFFFF8C00), // Orange
    Color(0xFF00CED1), // Cyan
  ];

  static Color get(int index) => palette[index % palette.length];
}
