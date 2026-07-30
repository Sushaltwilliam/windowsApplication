import 'package:flutter/material.dart';
import 'window_design_template.dart';
import 'window_theme.dart';

class ActiveWindow {
  final String id;
  WindowDesignTemplate template;
  String category;
  WindowTheme theme;
  List<Offset> corners;
  double logicalWidth;
  double logicalHeight;
  double openFactor;

  /// Rotation in radians (applied in editor / AR view)
  double rotation;

  /// Uniform scale factor (1.0 = original)
  double scale;

  /// Overall opacity (0.0 – 1.0)
  double opacity;

  /// Glass tint colour (null = no tint)
  Color? tint;

  /// Prevents accidental edits in the editor
  bool isLocked;

  /// Optional user label shown on the window card
  String label;

  /// Per-pane type overrides. Falls back to template.paneTypes when not set.
  List<PaneType> paneTypes;

  ActiveWindow({
    required this.id,
    required this.template,
    required this.category,
    required this.theme,
    required this.corners,
    required this.logicalWidth,
    required this.logicalHeight,
    this.openFactor = 0.0,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.tint,
    this.isLocked = false,
    this.label = '',
    List<PaneType>? paneTypes,
  }) : paneTypes = paneTypes ??
            List<PaneType>.generate(
              template.panes.length,
              (i) => template.typeForPane(i),
            );

  /// Returns the effective pane type for a given index.
  PaneType typeForPane(int index) {
    if (index < paneTypes.length) return paneTypes[index];
    return template.typeForPane(index);
  }

  /// Computes bounding box of the corner quad.
  Rect get boundingBox {
    if (corners.isEmpty) return Rect.zero;
    double l = corners[0].dx, r = corners[0].dx;
    double t = corners[0].dy, b = corners[0].dy;
    for (final c in corners) {
      if (c.dx < l) l = c.dx;
      if (c.dx > r) r = c.dx;
      if (c.dy < t) t = c.dy;
      if (c.dy > b) b = c.dy;
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  /// Centroid of corner quad.
  Offset get centroid {
    if (corners.isEmpty) return Offset.zero;
    double sx = 0, sy = 0;
    for (final c in corners) {
      sx += c.dx;
      sy += c.dy;
    }
    return Offset(sx / corners.length, sy / corners.length);
  }

  ActiveWindow copyWith({
    WindowDesignTemplate? template,
    String? category,
    WindowTheme? theme,
    List<Offset>? corners,
    double? logicalWidth,
    double? logicalHeight,
    double? openFactor,
    double? rotation,
    double? scale,
    double? opacity,
    Color? tint,
    bool? clearTint,
    bool? isLocked,
    String? label,
    List<PaneType>? paneTypes,
  }) {
    return ActiveWindow(
      id: id,
      template: template ?? this.template,
      category: category ?? this.category,
      theme: theme ?? this.theme,
      corners: corners ?? List<Offset>.from(this.corners),
      logicalWidth: logicalWidth ?? this.logicalWidth,
      logicalHeight: logicalHeight ?? this.logicalHeight,
      openFactor: openFactor ?? this.openFactor,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      tint: (clearTint == true) ? null : (tint ?? this.tint),
      isLocked: isLocked ?? this.isLocked,
      label: label ?? this.label,
      paneTypes: paneTypes ?? List<PaneType>.from(this.paneTypes),
    );
  }
}
