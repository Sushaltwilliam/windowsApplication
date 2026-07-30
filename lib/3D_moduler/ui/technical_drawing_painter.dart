import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/active_window.dart';
import '../models/window_design_template.dart';
import '../utils/perspective_utils.dart';

// ── TechnicalDrawingPainter ───────────────────────────────────────────────────
// Renders a professional 2D engineering/blueprint view of all windows,
// matching the reference: white background, labeled panes (F1/A1/S1/C1),
// diagonal X indicators for opening panes, and blue dimension lines in mm.
// ─────────────────────────────────────────────────────────────────────────────
class TechnicalDrawingPainter extends CustomPainter {
  final List<ActiveWindow> windows;
  final int selectedIndex;

  static const _framePad = 40.0; // space reserved for dimension annotations

  TechnicalDrawingPainter({
    required this.windows,
    required this.selectedIndex,
  });

  // ── Paints ─────────────────────────────────────────────────────────────────
  static final _framePaint = Paint()
    ..color = const Color(0xFF2C2C2C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..strokeJoin = StrokeJoin.miter;

  static final _innerGridPaint = Paint()
    ..color = const Color(0xFF404040)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final _glassPaint = Paint()
    ..color = const Color(0xFFE8F4F8)
    ..style = PaintingStyle.fill;

  static final _selectedOverlayPaint = Paint()
    ..color = const Color(0xFF4F7BF7).withOpacity(0.12)
    ..style = PaintingStyle.fill;

  static final _selectedBorderPaint = Paint()
    ..color = const Color(0xFF4F7BF7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  static final _dimLinePaint = Paint()
    ..color = const Color(0xFF1565C0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final _openingLinePaint = Paint()
    ..color = const Color(0xFF1565C0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  // ── Main paint ─────────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < windows.length; i++) {
      final win = windows[i];
      final isSelected = i == selectedIndex;

      canvas.save();
      final srcBox = Rect.fromLTWH(0, 0, win.logicalWidth, win.logicalHeight);
      final matrix = PerspectiveUtils.getPerspectiveTransform(srcBox, win.corners);
      canvas.transform(matrix.storage);
      
      _drawWindow(canvas, win, isSelected);
      canvas.restore();
    }
  }

  void _drawWindow(Canvas canvas, ActiveWindow win, bool isSelected) {
    final w = win.logicalWidth;
    final h = win.logicalHeight;
    final template = win.template;

    if (win.category == 'Circle') {
      _drawCircleWindow(canvas, win, w, h, isSelected);
      return;
    }

    final panes = template.panes;
    if (panes.isEmpty) return;

    final scaleX = w / 100.0;
    final scaleY = h / 100.0;

    // ── Draw glass fill for every pane ─────────────────────────────────────
    for (int i = 0; i < panes.length; i++) {
      final pane = panes[i];
      final path = _panePath(pane, scaleX, scaleY);
      if (isSelected && i == 0) {
        canvas.drawPath(path, _selectedOverlayPaint);
      } else {
        canvas.drawPath(path, _glassPaint);
      }
    }

    // ── Draw grid lines (inner frames) ─────────────────────────────────────
    for (final pane in panes) {
      canvas.drawPath(_panePath(pane, scaleX, scaleY), _innerGridPaint);
    }

    // ── Draw pane labels + opening indicators ─────────────────────────────
    final typeCounters = <PaneType, int>{};
    for (int i = 0; i < panes.length; i++) {
      final pane = panes[i];
      final type = win.typeForPane(i);
      typeCounters[type] = (typeCounters[type] ?? 0) + 1;
      final label = '${type.prefix}${typeCounters[type]}';

      final rect = _paneRect(pane, scaleX, scaleY);
      _drawPaneLabel(canvas, label, rect);

      // Opening indicators for non-fixed panes
      if (type == PaneType.awning || type == PaneType.casement) {
        _drawAwningLines(canvas, rect, type);
      } else if (type == PaneType.sliding) {
        _drawSlidingArrows(canvas, rect);
      }
    }

    // ── Outer aluminum frame ────────────────────────────────────────────────
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(outer, _framePaint);

    // Erase bottom frame sill for door panes
    for (int i = 0; i < panes.length; i++) {
      if (win.typeForPane(i) == PaneType.door) {
        final rect = _paneRect(panes[i], scaleX, scaleY);
        // If this pane touches the bottom of the window
        if ((rect.bottom - h).abs() < 5.0) {
          canvas.drawLine(
            Offset(rect.left + 2, h),
            Offset(rect.right - 2, h),
            Paint()..color = Colors.white..strokeWidth = 6.0,
          );
        }
      }
    }

    // ── Selection border ────────────────────────────────────────────────────
    if (isSelected) {
      canvas.drawRect(
        Rect.fromLTWH(-3, -3, w + 6, h + 6),
        _selectedBorderPaint,
      );
    }

    // ── Dimension annotations ───────────────────────────────────────────────
    _drawDimensions(canvas, win, w, h, panes, scaleX, scaleY);
  }

  // ── Circle window ──────────────────────────────────────────────────────────
  void _drawCircleWindow(Canvas canvas, ActiveWindow win, double w, double h, bool isSelected) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawOval(rect, _glassPaint);
    canvas.drawOval(rect, _framePaint);
    if (isSelected) {
      canvas.drawOval(
        rect.inflate(3),
        _selectedBorderPaint,
      );
    }
    _drawText(canvas, '⊙ ${w.toInt()}×${h.toInt()}mm',
        Offset(w / 2, h / 2), 10, const Color(0xFF1565C0));
  }

  // ── Pane helpers ───────────────────────────────────────────────────────────
  Path _panePath(List<Offset> pane, double sx, double sy) {
    final path = Path();
    path.moveTo(pane.first.dx * sx, pane.first.dy * sy);
    for (int j = 1; j < pane.length; j++) {
      path.lineTo(pane[j].dx * sx, pane[j].dy * sy);
    }
    path.close();
    return path;
  }

  Rect _paneRect(List<Offset> pane, double sx, double sy) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final p in pane) {
      minX = math.min(minX, p.dx * sx);
      minY = math.min(minY, p.dy * sy);
      maxX = math.max(maxX, p.dx * sx);
      maxY = math.max(maxY, p.dy * sy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // ── Pane label ─────────────────────────────────────────────────────────────
  void _drawPaneLabel(Canvas canvas, String label, Rect rect) {
    _drawText(canvas, label, rect.center, 11, const Color(0xFF333333),
        bold: true);
  }

  // ── Awning / casement: diagonal X lines ────────────────────────────────────
  void _drawAwningLines(Canvas canvas, Rect rect, PaneType type) {
    final paint = Paint()
      ..color = const Color(0xFF1565C0).withOpacity(0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Bottom pivot (awning) → lines from bottom corners to top-center
    // Casement (side pivot) → lines from side corners to opposite-center
    if (type == PaneType.awning) {
      // Bottom horizontal pivot: opening flap goes out from top
      canvas.drawLine(rect.bottomLeft, rect.topCenter, paint);
      canvas.drawLine(rect.bottomRight, rect.topCenter, paint);
    } else {
      // Casement: hinge on left, opens right
      canvas.drawLine(rect.topLeft, rect.centerRight, paint);
      canvas.drawLine(rect.bottomLeft, rect.centerRight, paint);
    }
  }

  // ── Sliding arrows ─────────────────────────────────────────────────────────
  void _drawSlidingArrows(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFF1565C0).withOpacity(0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final mid = rect.centerLeft.dy;
    final arrowLen = rect.width * 0.35;
    // Left arrow
    _drawArrow(canvas, paint,
        Offset(rect.left + arrowLen, mid), Offset(rect.left + 4, mid));
    // Right arrow
    _drawArrow(canvas, paint,
        Offset(rect.right - arrowLen, mid), Offset(rect.right - 4, mid));
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    canvas.drawLine(start, end, paint);
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);
    const arrowSize = 5.0;
    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(angle - 0.4),
        end.dy - arrowSize * math.sin(angle - 0.4),
      ),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(angle + 0.4),
        end.dy - arrowSize * math.sin(angle + 0.4),
      ),
      paint,
    );
  }

  // ── Dimension annotations ──────────────────────────────────────────────────
  void _drawDimensions(Canvas canvas, ActiveWindow win, double w, double h,
      List<List<Offset>> panes, double scaleX, double scaleY) {
    // ── Total dimensions ────────────────────────────────────────────────────
    // Dimensions above the window
    if (win.template.exactWidth != null) {
      _drawDimLine(canvas, from: Offset(0, -_framePad + 10), to: Offset(w, -_framePad + 10), label: '${win.template.exactWidth!.toInt()}mm', isHorizontal: true);
    } else {
      _drawDimLine(canvas, from: Offset(0, -_framePad + 10), to: Offset(w, -_framePad + 10), label: '${w.toInt()}mm', isHorizontal: true);
    }

    // Height annotation: to the left of the window
    if (win.template.exactHeight != null) {
      _drawDimLine(canvas, from: Offset(-_framePad + 10, 0), to: Offset(-_framePad + 10, h), label: '${win.template.exactHeight!.toInt()}mm', isHorizontal: false);
    } else {
      _drawDimLine(canvas, from: Offset(-_framePad + 10, 0), to: Offset(-_framePad + 10, h), label: '${h.toInt()}mm', isHorizontal: false);
    }

    // ── Per-column widths (unique X boundaries) ────────────────────────────
    if (win.category == 'Rectangle' || win.category == 'Custom') {
      final xBounds = _uniqueXBoundaries(panes, scaleX, w);
      if (xBounds.length > 1) {
        for (int i = 0; i < xBounds.length - 1; i++) {
          final x1 = xBounds[i];
          final x2 = xBounds[i + 1];
          final segW = x2 - x1;
          _drawDimLine(canvas,
              from: Offset(x1, h + 14),
              to: Offset(x2, h + 14),
              label: '${segW.toInt()}',
              isHorizontal: true,
              small: true);
        }
      }

      // ── Per-row heights (unique Y boundaries) ──────────────────────────
      final yBounds = _uniqueYBoundaries(panes, scaleY, h);
      if (yBounds.length > 1) {
        for (int i = 0; i < yBounds.length - 1; i++) {
          final y1 = yBounds[i];
          final y2 = yBounds[i + 1];
          final segH = y2 - y1;
          _drawDimLine(canvas,
              from: Offset(w + 14, y1),
              to: Offset(w + 14, y2),
              label: '${segH.toInt()}',
              isHorizontal: false,
              small: true);
        }
      }
    }
  }

  List<double> _uniqueXBoundaries(
      List<List<Offset>> panes, double scaleX, double total) {
    final vals = <double>{0.0, total};
    for (final pane in panes) {
      for (final p in pane) {
        final v = p.dx * scaleX;
        if (v > 0.5 && v < total - 0.5) vals.add(v);
      }
    }
    return vals.toList()..sort();
  }

  List<double> _uniqueYBoundaries(
      List<List<Offset>> panes, double scaleY, double total) {
    final vals = <double>{0.0, total};
    for (final pane in panes) {
      for (final p in pane) {
        final v = p.dy * scaleY;
        if (v > 0.5 && v < total - 0.5) vals.add(v);
      }
    }
    return vals.toList()..sort();
  }

  // ── Dimension line with tick marks and label ───────────────────────────────
  void _drawDimLine(Canvas canvas,
      {required Offset from,
      required Offset to,
      required String label,
      required bool isHorizontal,
      bool small = false}) {
    const tickLen = 5.0;
    canvas.drawLine(from, to, _dimLinePaint);

    // Ticks at ends
    if (isHorizontal) {
      canvas.drawLine(
          from.translate(0, -tickLen), from.translate(0, tickLen), _dimLinePaint);
      canvas.drawLine(
          to.translate(0, -tickLen), to.translate(0, tickLen), _dimLinePaint);
    } else {
      canvas.drawLine(
          from.translate(-tickLen, 0), from.translate(tickLen, 0), _dimLinePaint);
      canvas.drawLine(
          to.translate(-tickLen, 0), to.translate(tickLen, 0), _dimLinePaint);
    }

    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    _drawText(canvas, label, mid, small ? 8.0 : 9.5, const Color(0xFF1565C0));
  }

  // ── Text helper ────────────────────────────────────────────────────────────
  void _drawText(Canvas canvas, String text, Offset center, double fontSize,
      Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 3),
            Shadow(color: Colors.white, blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant TechnicalDrawingPainter oldDelegate) => true;
}
