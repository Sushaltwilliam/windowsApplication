import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/vector_line.dart';

/// Alignment type for window alignment operations.
enum AlignType { left, right, top, bottom, centerH, centerV }

/// Geometry helpers for the window designer and AR canvas.
class GeometryUtils {
  GeometryUtils._();

  // ── Snapping ───────────────────────────────────────────────────────────────

  /// Snaps [value] to the nearest multiple of [gridSize].
  static double snapToGrid1D(double value, double gridSize) {
    if (gridSize <= 0) return value;
    return (value / gridSize).round() * gridSize;
  }

  /// Snaps [point] to the nearest grid intersection.
  static Offset snapToGrid(Offset point, double gridSize) {
    return Offset(
      snapToGrid1D(point.dx, gridSize),
      snapToGrid1D(point.dy, gridSize),
    );
  }

  /// If [point] is within [threshold] of a snap target in [snapValues],
  /// returns the snapped value; otherwise returns [point.dx] or [point.dy].
  static double snapAxis(double value, List<double> snapValues, double threshold) {
    for (final sv in snapValues) {
      if ((value - sv).abs() < threshold) return sv;
    }
    return value;
  }

  /// Snaps [point] to any edge or center of [bounds] within [threshold].
  static Offset snapToRect(Offset point, Rect bounds, double threshold) {
    final snapX = [bounds.left, bounds.center.dx, bounds.right];
    final snapY = [bounds.top, bounds.center.dy, bounds.bottom];
    return Offset(
      snapAxis(point.dx, snapX, threshold),
      snapAxis(point.dy, snapY, threshold),
    );
  }

  // ── Bounding Box ───────────────────────────────────────────────────────────

  /// Returns axis-aligned bounding box of an arbitrary point list.
  static Rect boundingBoxOf(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;
    double l = points[0].dx, r = l, t = points[0].dy, b = t;
    for (final p in points) {
      if (p.dx < l) l = p.dx;
      if (p.dx > r) r = p.dx;
      if (p.dy < t) t = p.dy;
      if (p.dy > b) b = p.dy;
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  /// Centroid of a point list.
  static Offset centroidOf(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    double sx = 0, sy = 0;
    for (final p in points) {
      sx += p.dx;
      sy += p.dy;
    }
    return Offset(sx / points.length, sy / points.length);
  }

  // ── Hit Testing ────────────────────────────────────────────────────────────

  /// Returns true if [point] is inside the polygon defined by [vertices]
  /// using the ray-casting algorithm.
  static bool pointInPolygon(Offset point, List<Offset> vertices) {
    int n = vertices.length;
    bool inside = false;
    double x = point.dx, y = point.dy;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = vertices[i].dx, yi = vertices[i].dy;
      final xj = vertices[j].dx, yj = vertices[j].dy;
      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Returns true if [point] is within [radius] of [target].
  static bool hitTestCircle(Offset point, Offset target, double radius) {
    return (point - target).distance <= radius;
  }

  // ── Transforms ────────────────────────────────────────────────────────────

  /// Scales all [corners] uniformly by [scale] around [center].
  static List<Offset> scaleCorners(
      List<Offset> corners, double scale, Offset center) {
    return corners
        .map((c) => center + (c - center) * scale)
        .toList();
  }

  /// Rotates all [corners] by [angle] (radians) around [center].
  static List<Offset> rotateCorners(
      List<Offset> corners, double angle, Offset center) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return corners.map((c) {
      final dx = c.dx - center.dx;
      final dy = c.dy - center.dy;
      return Offset(
        center.dx + dx * cos - dy * sin,
        center.dy + dx * sin + dy * cos,
      );
    }).toList();
  }

  /// Flips [corners] horizontally or vertically within their own bounding box.
  static List<Offset> flipCorners(
      List<Offset> corners, {bool horizontal = false, bool vertical = false}) {
    final box = boundingBoxOf(corners);
    return corners.map((c) {
      final nx = horizontal ? box.left + box.right - c.dx : c.dx;
      final ny = vertical ? box.top + box.bottom - c.dy : c.dy;
      return Offset(nx, ny);
    }).toList();
  }

  /// Translates all [corners] by [delta].
  static List<Offset> translateCorners(List<Offset> corners, Offset delta) {
    return corners.map((c) => c + delta).toList();
  }

  // ── Alignment ─────────────────────────────────────────────────────────────

  /// Returns new corners aligned within [canvasBounds] per [type].
  static List<Offset> alignCorners(
      List<Offset> corners, AlignType type, Rect canvasBounds) {
    final box = boundingBoxOf(corners);
    double dx = 0, dy = 0;
    switch (type) {
      case AlignType.left:
        dx = canvasBounds.left - box.left;
        break;
      case AlignType.right:
        dx = canvasBounds.right - box.right;
        break;
      case AlignType.top:
        dy = canvasBounds.top - box.top;
        break;
      case AlignType.bottom:
        dy = canvasBounds.bottom - box.bottom;
        break;
      case AlignType.centerH:
        dx = canvasBounds.center.dx - box.center.dx;
        break;
      case AlignType.centerV:
        dy = canvasBounds.center.dy - box.center.dy;
        break;
    }
    return translateCorners(corners, Offset(dx, dy));
  }

  // ── Snap detection (for snap indicator lines) ──────────────────────────────

  /// Returns which [snapValues] [value] is near (within threshold).
  static List<double> nearSnaps(
      double value, List<double> snapValues, double threshold) {
    return snapValues.where((sv) => (value - sv).abs() < threshold).toList();
  }

  // ── Distance helpers ───────────────────────────────────────────────────────

  /// Distance from point to line segment (p1→p2).
  static double pointToSegmentDist(Offset p, Offset p1, Offset p2) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return (p - p1).distance;
    final t = ((p.dx - p1.dx) * dx + (p.dy - p1.dy) * dy) / lenSq;
    final tc = t.clamp(0.0, 1.0);
    final proj = Offset(p1.dx + tc * dx, p1.dy + tc * dy);
    return (p - proj).distance;
  }

  // ── Rect helpers ──────────────────────────────────────────────────────────

  /// Returns the 4 corners of [rect] in TL, TR, BR, BL order.
  static List<Offset> rectCorners(Rect rect) => [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];

  /// Clamps [corners] so all points stay within [bounds].
  static List<Offset> clampCorners(List<Offset> corners, Rect bounds) {
    return corners.map((c) => Offset(
      c.dx.clamp(bounds.left, bounds.right),
      c.dy.clamp(bounds.top, bounds.bottom),
    )).toList();
  }

  // ── Vector Line Helpers ───────────────────────────────────────────────────

  /// Calculates fully enclosed rectangular panes from an outer bounds and a list of internal vector lines.
  static List<Rect> calculatePanes(Rect bounds, List<VectorLine> lines) {
    List<Rect> panes = [bounds];
    const tol = 1.0; // 1mm tolerance for spanning checks

    for (final line in lines) {
      List<Rect> nextPanes = [];
      for (final pane in panes) {
        bool didSplit = false;
        
        if (line.isVertical) {
          double lx = line.startPoint.dx;
          // Check if line falls inside the pane horizontally
          if (lx > pane.left + tol && lx < pane.right - tol) {
            // Check if line spans the pane vertically
            if (line.startPoint.dy <= pane.top + tol && line.endPoint.dy >= pane.bottom - tol) {
              nextPanes.add(Rect.fromLTRB(pane.left, pane.top, lx, pane.bottom));
              nextPanes.add(Rect.fromLTRB(lx, pane.top, pane.right, pane.bottom));
              didSplit = true;
            }
          }
        } else {
          double ly = line.startPoint.dy;
          // Check if line falls inside the pane vertically
          if (ly > pane.top + tol && ly < pane.bottom - tol) {
            // Check if line spans the pane horizontally
            if (line.startPoint.dx <= pane.left + tol && line.endPoint.dx >= pane.right - tol) {
              nextPanes.add(Rect.fromLTRB(pane.left, pane.top, pane.right, ly));
              nextPanes.add(Rect.fromLTRB(pane.left, ly, pane.right, pane.bottom));
              didSplit = true;
            }
          }
        }

        if (!didSplit) {
          nextPanes.add(pane);
        }
      }
      panes = nextPanes;
    }

    return panes;
  }
}
