import 'package:flutter/material.dart';

/// Represents the AR placement of a designed window onto a real photo.
/// [perspectiveCorners] are the 4 screen-space points that define where
/// the window quad sits in the photo: TL, TR, BR, BL order.
class ArPlacement {
  final String id;

  /// ID of the ActiveWindow (from WindowDesignerProvider) being placed.
  final String windowId;

  /// 4 screen-space corner positions: [TL, TR, BR, BL]
  List<Offset> perspectiveCorners;

  /// When locked, corner handles are hidden and the placement cannot be moved.
  bool isLocked;

  /// Overall opacity applied on top of the window's own opacity (0.0–1.0).
  double placementOpacity;

  ArPlacement({
    required this.id,
    required this.windowId,
    required this.perspectiveCorners,
    this.isLocked = false,
    this.placementOpacity = 1.0,
  }) : assert(perspectiveCorners.length == 4,
            'ArPlacement requires exactly 4 corner points');

  /// Creates a default placement centered in [canvasSize].
  factory ArPlacement.centered({
    required String id,
    required String windowId,
    required Size canvasSize,
    double widthFraction = 0.4,
    double heightFraction = 0.5,
  }) {
    final cw = canvasSize.width;
    final ch = canvasSize.height;
    final l = cw * (1 - widthFraction) / 2;
    final r = cw * (1 + widthFraction) / 2;
    final t = ch * (1 - heightFraction) / 2;
    final b = ch * (1 + heightFraction) / 2;
    return ArPlacement(
      id: id,
      windowId: windowId,
      perspectiveCorners: [
        Offset(l, t), // TL
        Offset(r, t), // TR
        Offset(r, b), // BR
        Offset(l, b), // BL
      ],
    );
  }

  Offset get centroid {
    double sx = 0, sy = 0;
    for (final c in perspectiveCorners) {
      sx += c.dx;
      sy += c.dy;
    }
    return Offset(sx / 4, sy / 4);
  }

  Rect get boundingBox {
    double l = perspectiveCorners[0].dx, r = l;
    double t = perspectiveCorners[0].dy, b = t;
    for (final c in perspectiveCorners) {
      if (c.dx < l) l = c.dx;
      if (c.dx > r) r = c.dx;
      if (c.dy < t) t = c.dy;
      if (c.dy > b) b = c.dy;
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  ArPlacement copyWith({
    String? windowId,
    List<Offset>? perspectiveCorners,
    bool? isLocked,
    double? placementOpacity,
  }) {
    return ArPlacement(
      id: id,
      windowId: windowId ?? this.windowId,
      perspectiveCorners: perspectiveCorners ?? List<Offset>.from(this.perspectiveCorners),
      isLocked: isLocked ?? this.isLocked,
      placementOpacity: placementOpacity ?? this.placementOpacity,
    );
  }

  /// Moves all 4 corners by [delta].
  ArPlacement translated(Offset delta) {
    return copyWith(
      perspectiveCorners: perspectiveCorners.map((c) => c + delta).toList(),
    );
  }
}
