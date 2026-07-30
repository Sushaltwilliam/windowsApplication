import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/active_window.dart';
import '../models/window_design_template.dart';
import '../models/window_theme.dart';
import '../utils/perspective_utils.dart';

// ── WindowPainter ─────────────────────────────────────────────────────────────
// Production-quality renderer for aluminum windows in 3D perspective.
// Features: realistic glass gradients, reflections, shadows, frame depth,
//           hardware details, opening animations, tint, opacity.
// ─────────────────────────────────────────────────────────────────────────────
class WindowPainter extends CustomPainter {
  final List<ActiveWindow> windows;
  final int selectedIndex;

  const WindowPainter({
    required this.windows,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw back-to-front so later windows appear on top
    for (int i = 0; i < windows.length; i++) {
      final window = windows[i];
      final isSelected = i == selectedIndex;

      canvas.save();
      final srcBox = const Rect.fromLTWH(0, 0, 100.0, 100.0);
      final matrix = PerspectiveUtils.getPerspectiveTransform(
          srcBox, window.corners);
      canvas.transform(matrix.storage);

      // Apply window-level opacity
      if (window.opacity < 1.0) {
        canvas.saveLayer(
          const Rect.fromLTWH(-10, -10, 120, 120),
          Paint()..color = Colors.white.withOpacity(window.opacity),
        );
      }

      _drawSingleWindow(canvas, window, isSelected, size);

      if (window.opacity < 1.0) canvas.restore();
      canvas.restore();
    }
  }

  void _drawSingleWindow(
      Canvas canvas, ActiveWindow window, bool isSelected, Size screenSize) {
    if (window.category == 'Circle') {
      _paintCircleWindow(canvas, window, isSelected);
    } else {
      _paintGenericWindow(canvas, window, isSelected);
    }

    // ── Outer frame drop shadow + thick outer border ────────────────────────
    final outerPath = _getOuterPath(window);
    canvas.drawShadow(
      outerPath,
      Colors.black.withOpacity(window.theme.shadowOpacity),
      window.theme.shadowBlur,
      true,
    );

    final outerFramePaint = _framePaint(window)
      ..strokeWidth = window.theme.frameThickness * 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(outerPath, outerFramePaint);

    // ── Inner frame highlight (gives extrusion depth) ─────────────────────
    final innerHighlight = Paint()
      ..color = _lighten(window.theme.frameColor, 0.2).withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_shrinkPath(outerPath, 2.0), innerHighlight);

    // ── Selection glow ─────────────────────────────────────────────────────
    if (isSelected) {
      final glowPaint = Paint()
        ..color = const Color(0xFF4F7BF7).withOpacity(0.5)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
      canvas.drawPath(outerPath, glowPaint);

      final selectionBorder = Paint()
        ..color = const Color(0xFF4F7BF7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(outerPath, selectionBorder);
    }

    // ── Dimension labels ───────────────────────────────────────────────────
    _drawDimensions(canvas, window);
  }

  // ── Generic (rectangular/polygon) window ──────────────────────────────────
  void _paintGenericWindow(
      Canvas canvas, ActiveWindow window, bool isSelected) {
    final panes = window.template.panes;
    if (panes.isEmpty) {
      // Draw a plain rectangle for empty templates
      _paintPane(canvas, window, 0,
          [const Offset(0,0), const Offset(100,0),
           const Offset(100,100), const Offset(0,100)]);
      return;
    }

    for (int i = 0; i < panes.length; i++) {
      final pane = panes[i];
      canvas.save();

      final paneType = window.typeForPane(i);
      _applyOpenAnimation(canvas, window, i, pane, paneType);

      _paintPane(canvas, window, i, pane);
      _paintPaneType(canvas, window, i, pane, paneType);

      canvas.restore();
    }
  }

  void _paintPane(Canvas canvas, ActiveWindow window, int index,
      List<Offset> pane) {
    final path = Path();
    path.moveTo(pane.first.dx, pane.first.dy);
    for (int j = 1; j < pane.length; j++) {
      path.lineTo(pane[j].dx, pane[j].dy);
    }
    path.close();

    // ── Glass fill ─────────────────────────────────────────────────────────
    canvas.drawPath(path, _glassFillPaint(window, pane));

    // ── Tint overlay ───────────────────────────────────────────────────────
    if (window.tint != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = window.tint!.withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );
    }

    // ── Reflection streak ──────────────────────────────────────────────────
    if (window.theme.reflectionOpacity > 0) {
      canvas.drawPath(path, _reflectionPaint(window, pane));
    }

    // ── Pane frame ─────────────────────────────────────────────────────────
    canvas.drawPath(path, _framePaint(window));
  }

  /// Applies the opening animation transform for a pane.
  void _applyOpenAnimation(Canvas canvas, ActiveWindow window, int index,
      List<Offset> pane, PaneType paneType) {
    if (window.openFactor <= 0) return;
    switch (paneType) {
      case PaneType.casement:
        // Rotates around left or right vertical edge
        final pivotX = (index % 2 == 0) ? pane.first.dx : pane[1].dx;
        canvas.translate(pivotX, 0);
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY((index % 2 == 0 ? -1 : 1) * window.openFactor * math.pi / 3);
        canvas.transform(m.storage);
        canvas.translate(-pivotX, 0);
        break;
      case PaneType.awning:
        // Tips outward from top edge
        final pivotY = pane.first.dy;
        canvas.translate(0, pivotY);
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-window.openFactor * math.pi / 4);
        canvas.transform(m.storage);
        canvas.translate(0, -pivotY);
        break;
      case PaneType.door:
        // Swings open on hinge
        final pivotX = index % 2 == 0 ? pane.first.dx : pane[1].dx;
        canvas.translate(pivotX, 0);
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0008)
          ..rotateY((index % 2 == 0 ? -1 : 1) * window.openFactor * math.pi / 2.5);
        canvas.transform(m.storage);
        canvas.translate(-pivotX, 0);
        break;
      case PaneType.sliding:
        // Slides horizontally
        final offset = pane.last.dx - pane.first.dx;
        canvas.translate(window.openFactor * offset * 0.7, 0);
        break;
      default:
        break;
    }
  }

  /// Draws opening type indicators on pane (arrows, X marks, hinges).
  void _paintPaneType(Canvas canvas, ActiveWindow window, int index,
      List<Offset> pane, PaneType paneType) {
    final cx = pane.map((o) => o.dx).reduce((a, b) => a + b) / pane.length;
    final cy = pane.map((o) => o.dy).reduce((a, b) => a + b) / pane.length;

    final indicatorPaint = Paint()
      ..color = window.theme.frameColor.withOpacity(0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    switch (paneType) {
      case PaneType.casement:
        // X diagonal lines indicating casement opening
        _drawCasementIndicator(canvas, pane, indicatorPaint, index);
        break;
      case PaneType.awning:
        // Horizontal lines suggesting tipping out
        _drawAwningIndicator(canvas, pane, indicatorPaint);
        break;
      case PaneType.sliding:
        // Arrow pointing direction of slide
        _drawSlidingIndicator(canvas, cx, cy, index, indicatorPaint);
        break;
      case PaneType.door:
        // Door handle hardware
        _drawDoorHandle(canvas, pane, window, index);
        break;
      case PaneType.tiltTurn:
        _drawTiltTurnIndicator(canvas, pane, indicatorPaint);
        break;
      default:
        break;
    }

    // Pane label (F1, C2, etc.)
    _drawPaneLabel(canvas, paneType, cx, cy, window.theme.frameColor);
  }

  void _drawCasementIndicator(
      Canvas canvas, List<Offset> pane, Paint paint, int index) {
    if (pane.length < 4) return;
    // Single diagonal from hinge corner to opposite
    final path = Path();
    if (index % 2 == 0) {
      path.moveTo(pane[0].dx, pane[0].dy);
      path.lineTo(pane[2].dx, pane[2].dy);
    } else {
      path.moveTo(pane[1].dx, pane[1].dy);
      path.lineTo(pane[3].dx, pane[3].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawAwningIndicator(
      Canvas canvas, List<Offset> pane, Paint paint) {
    if (pane.length < 4) return;
    // Two diagonals forming X
    final path = Path()
      ..moveTo(pane[0].dx, pane[0].dy)
      ..lineTo(pane[2].dx, pane[2].dy)
      ..moveTo(pane[1].dx, pane[1].dy)
      ..lineTo(pane[3].dx, pane[3].dy);
    canvas.drawPath(path, paint);
  }

  void _drawSlidingIndicator(
      Canvas canvas, double cx, double cy, int index, Paint paint) {
    final dir = index % 2 == 0 ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(cx - 8 * dir, cy)
      ..lineTo(cx + 8 * dir, cy)
      ..moveTo(cx + 4 * dir, cy - 4)
      ..lineTo(cx + 8 * dir, cy)
      ..lineTo(cx + 4 * dir, cy + 4);
    canvas.drawPath(path, paint);
  }

  void _drawDoorHandle(
      Canvas canvas, List<Offset> pane, ActiveWindow window, int index) {
    if (pane.length < 4) return;
    // Handle on the opening edge
    final handleX = index % 2 == 0
        ? (pane[1].dx + pane[2].dx) / 2 - 4
        : (pane[0].dx + pane[3].dx) / 2 + 2;
    final handleY = (pane[0].dy + pane[3].dy) / 2;

    final handlePaint = Paint()
      ..color = _lighten(window.theme.frameColor, 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(handleX, handleY), width: 2.5, height: 12),
        const Radius.circular(1.25),
      ),
      handlePaint,
    );
    canvas.drawCircle(Offset(handleX, handleY - 6), 1.5, handlePaint);
  }

  void _drawTiltTurnIndicator(
      Canvas canvas, List<Offset> pane, Paint paint) {
    if (pane.length < 4) return;
    // X + bottom hinge line
    final path = Path()
      ..moveTo(pane[0].dx, pane[0].dy)
      ..lineTo(pane[2].dx, pane[2].dy)
      ..moveTo(pane[1].dx, pane[1].dy)
      ..lineTo(pane[3].dx, pane[3].dy)
      ..moveTo(pane[2].dx, pane[2].dy)
      ..lineTo(pane[3].dx, pane[3].dy);
    canvas.drawPath(path, paint);
  }

  void _drawPaneLabel(Canvas canvas, PaneType type, double cx, double cy,
      Color frameColor) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: type.prefix,
      style: TextStyle(
        color: frameColor.withOpacity(0.5),
        fontSize: 6,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
  }

  // ── Circle window ──────────────────────────────────────────────────────────
  void _paintCircleWindow(
      Canvas canvas, ActiveWindow window, bool isSelected) {
    const rect = Rect.fromLTWH(5, 5, 90, 90);
    final center = rect.center;

    canvas.save();
    if (window.openFactor > 0) {
      canvas.translate(50, 50);
      canvas.scale(1.0 - window.openFactor * 0.08);
      canvas.rotate(window.openFactor * math.pi / 10);
      canvas.translate(-50, -50);
    }

    // Shadow
    canvas.drawShadow(
      Path()..addOval(rect),
      Colors.black.withOpacity(window.theme.shadowOpacity),
      window.theme.shadowBlur * 0.7,
      true,
    );

    // Glass
    final circlePath = Path()..addOval(rect);
    canvas.drawPath(circlePath, _glassFillPaint(window, [
      rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft
    ]));

    // Tint
    if (window.tint != null) {
      canvas.drawPath(
        circlePath,
        Paint()
          ..color = window.tint!.withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );
    }

    // Reflection
    if (window.theme.reflectionOpacity > 0) {
      canvas.drawPath(circlePath, _reflectionPaint(window, [
        rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft
      ]));
    }

    // Template-specific splits
    final splitPaint = _framePaint(window)..strokeWidth = 1.5;
    switch (window.template.id) {
      case 'circle_split_v':
        canvas.drawLine(
            Offset(center.dx, rect.top), Offset(center.dx, rect.bottom), splitPaint);
        break;
      case 'circle_split_h':
        canvas.drawLine(
            Offset(rect.left, center.dy), Offset(rect.right, center.dy), splitPaint);
        break;
      case 'circle_cross':
        canvas.drawLine(
            Offset(center.dx, rect.top), Offset(center.dx, rect.bottom), splitPaint);
        canvas.drawLine(
            Offset(rect.left, center.dy), Offset(rect.right, center.dy), splitPaint);
        break;
    }

    // Frame border
    canvas.drawOval(rect, _framePaint(window)..strokeWidth = window.theme.frameThickness);

    // Inner highlight
    canvas.drawOval(
      rect.deflate(1.5),
      Paint()
        ..color = _lighten(window.theme.frameColor, 0.2).withOpacity(0.4)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  // ── Paint factories ────────────────────────────────────────────────────────

  Paint _framePaint(ActiveWindow window) {
    return Paint()
      ..color = window.theme.frameColor
      ..strokeWidth = window.theme.frameThickness
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;
  }

  Paint _glassFillPaint(ActiveWindow window, List<Offset> pane) {
    final box = _paneBox(pane);
    final glassBase = window.theme.glassColor;
    return Paint()
      ..shader = ui.Gradient.linear(
        box.topLeft,
        box.bottomRight,
        [
          Colors.white.withOpacity(window.theme.glassOpacity * 2.8),
          glassBase.withOpacity(window.theme.glassOpacity * 1.8),
          glassBase.withOpacity(window.theme.glassOpacity * 1.2),
          glassBase.withOpacity(window.theme.glassOpacity * 0.8),
          Colors.white.withOpacity(window.theme.glassOpacity * 1.5),
        ],
        [0.0, 0.15, 0.45, 0.75, 1.0],
      )
      ..style = PaintingStyle.fill;
  }

  Paint _reflectionPaint(ActiveWindow window, List<Offset> pane) {
    final box = _paneBox(pane);
    // Horizontal streak from top-left — simulates sky reflection
    return Paint()
      ..shader = ui.Gradient.linear(
        box.topLeft,
        Offset(box.right, box.top + box.height * 0.3),
        [
          Colors.white.withOpacity(window.theme.reflectionOpacity),
          Colors.white.withOpacity(0.0),
        ],
        [0.0, 1.0],
      )
      ..style = PaintingStyle.fill;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Path _getOuterPath(ActiveWindow window) {
    final path = Path();
    if (window.category == 'Circle') {
      path.addOval(const Rect.fromLTWH(5, 5, 90, 90));
    } else if (window.template.panes.isNotEmpty) {
      // Use convex hull of all pane points
      final allPoints = window.template.panes.expand((p) => p).toList();
      _addConvexPath(path, allPoints);
    } else {
      path.addRect(const Rect.fromLTWH(0, 0, 100, 100));
    }
    return path;
  }

  void _addConvexPath(Path path, List<Offset> points) {
    // Simple bounding approach for the outer shape
    double l = points[0].dx, r = l, t = points[0].dy, b = t;
    for (final p in points) {
      if (p.dx < l) l = p.dx;
      if (p.dx > r) r = p.dx;
      if (p.dy < t) t = p.dy;
      if (p.dy > b) b = p.dy;
    }

    // Use actual polygon if reasonable # of unique outer points
    final outer = _convexHull(points);
    if (outer.length >= 3) {
      path.moveTo(outer[0].dx, outer[0].dy);
      for (int i = 1; i < outer.length; i++) {
        path.lineTo(outer[i].dx, outer[i].dy);
      }
      path.close();
    } else {
      path.addRect(Rect.fromLTRB(l, t, r, b));
    }
  }

  Path _shrinkPath(Path path, double amount) {
    // Approximation: inflate negatively
    return Path()..addPath(path, Offset.zero);
  }

  Rect _paneBox(List<Offset> pane) {
    if (pane.isEmpty) return const Rect.fromLTWH(0, 0, 100, 100);
    double l = pane[0].dx, r = l, t = pane[0].dy, b = t;
    for (final p in pane) {
      if (p.dx < l) l = p.dx;
      if (p.dx > r) r = p.dx;
      if (p.dy < t) t = p.dy;
      if (p.dy > b) b = p.dy;
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  // ── Dimension labels ───────────────────────────────────────────────────────
  void _drawDimensions(Canvas canvas, ActiveWindow window) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final w = window.logicalWidth.toInt();
    final h = window.logicalHeight.toInt();

    if (window.category != 'Circle') {
      _drawText(tp, canvas, '${w}mm', const Offset(50, -18));
      _drawText(tp, canvas, '${h}mm', const Offset(115, 50), rotate: true);
    } else {
      final r = (window.logicalWidth / 2).toInt();
      _drawText(tp, canvas, 'Ø${r * 2}mm', const Offset(50, 50));
    }
  }

  void _drawText(TextPainter tp, Canvas canvas, String text, Offset offset,
      {bool rotate = false}) {
    tp.text = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 8,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
      ),
    );
    tp.layout();
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    if (rotate) canvas.rotate(math.pi / 2);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  // ── Convex Hull (Graham scan, simplified) ──────────────────────────────────
  List<Offset> _convexHull(List<Offset> points) {
    if (points.length <= 2) return points;
    final sorted = List<Offset>.from(points)
      ..sort((a, b) {
        final cmp = a.dx.compareTo(b.dx);
        return cmp != 0 ? cmp : a.dy.compareTo(b.dy);
      });

    List<Offset> build(List<Offset> pts) {
      final hull = <Offset>[];
      for (final p in pts) {
        while (hull.length >= 2) {
          final o = hull[hull.length - 2];
          final a = hull[hull.length - 1];
          final cross = (a.dx - o.dx) * (p.dy - o.dy) -
              (a.dy - o.dy) * (p.dx - o.dx);
          if (cross <= 0) {
            hull.removeLast();
          } else {
            break;
          }
        }
        hull.add(p);
      }
      return hull;
    }

    final lower = build(sorted);
    final upper = build(sorted.reversed.toList());
    return [...lower.sublist(0, lower.length - 1),
            ...upper.sublist(0, upper.length - 1)];
  }

  @override
  bool shouldRepaint(covariant WindowPainter oldDelegate) => true;
}
