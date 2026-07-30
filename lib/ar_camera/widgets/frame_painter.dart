import 'dart:math';
import 'package:flutter/material.dart';
import '../models/detected_frame.dart';

/// Paints independent pane boxes with open/close animation support
class FramePainter extends CustomPainter {
  final List<PaneBox> panes;
  final String? selectedId;
  final double openFactor; // 0 = closed, 1 = open

  FramePainter({required this.panes, this.selectedId, this.openFactor = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    for (final pane in panes) {
      _drawPane(canvas, pane);
    }
  }

  void _drawPane(Canvas canvas, PaneBox pane) {
    canvas.save();
    canvas.translate(pane.position.dx, pane.position.dy);

    if (pane.rotation != 0) {
      canvas.rotate(pane.rotation * pi / 180);
    }

    if (pane.tiltX != 0 || pane.tiltY != 0) {
      final m = Matrix4.identity();
      m.setEntry(3, 2, 0.001);
      m.rotateX(pane.tiltX * pi / 180);
      m.rotateY(pane.tiltY * pi / 180);
      canvas.transform(m.storage);
    }

    final rect = Rect.fromCenter(
        center: Offset.zero, width: pane.width, height: pane.height);
    final isSelected = pane.id == selectedId;

    // Apply open effect (simulate window opening by skewing)
    if (openFactor > 0) {
      _drawOpenPane(canvas, rect, pane);
    } else {
      _drawClosedPane(canvas, rect, pane, isSelected);
    }

    canvas.restore();
  }

  void _drawClosedPane(
      Canvas canvas, Rect rect, PaneBox pane, bool isSelected) {
    // Fill
    canvas.drawRect(
        rect,
        Paint()
          ..color = pane.color.withValues(alpha: pane.opacity)
          ..style = PaintingStyle.fill);

    // Border
    canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // Selection
    if (isSelected) {
      canvas.drawRect(
          rect.inflate(4),
          Paint()
            ..color = const Color(0xFF00FF00)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
      _drawHandles(canvas, rect);
      _drawDims(canvas, rect, pane);
    }
  }

  void _drawOpenPane(Canvas canvas, Rect rect, PaneBox pane) {
    // Simulate window opening: the pane "swings" open with perspective
    canvas.save();

    // Apply swing rotation around left edge
    final pivotX = rect.left;
    canvas.translate(pivotX, 0);

    final m = Matrix4.identity();
    m.setEntry(3, 2, 0.002);
    m.rotateY(-openFactor * pi * 0.4); // Swing open up to ~72 degrees
    canvas.transform(m.storage);

    canvas.translate(-pivotX, 0);

    // Draw the opened pane (slightly transparent glass look)
    final glassPaint = Paint()
      ..color =
          pane.color.withValues(alpha: pane.opacity * (1 - openFactor * 0.5))
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, glassPaint);

    // Frame border
    canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    canvas.restore();

    // Draw the "empty" opening behind (dark area)
    if (openFactor > 0.1) {
      final openRect = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width * openFactor * 0.3,
        rect.height,
      );
      canvas.drawRect(
          openRect,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.4 * openFactor)
            ..style = PaintingStyle.fill);
    }
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final green = Paint()
      ..color = const Color(0xFF00FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final p in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight
    ]) {
      canvas.drawCircle(p, 5, white);
      canvas.drawCircle(p, 5, green);
    }

    // Edge bars
    _bar(canvas, Offset(rect.left, rect.center.dy), true, white, green);
    _bar(canvas, Offset(rect.right, rect.center.dy), true, white, green);
    _bar(canvas, Offset(rect.center.dx, rect.top), false, white, green);
    _bar(canvas, Offset(rect.center.dx, rect.bottom), false, white, green);
  }

  void _bar(Canvas canvas, Offset pos, bool vert, Paint fill, Paint stroke) {
    final r = vert
        ? Rect.fromCenter(center: pos, width: 5, height: 14)
        : Rect.fromCenter(center: pos, width: 14, height: 5);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(2));
    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, stroke);
  }

  void _drawDims(Canvas canvas, Rect rect, PaneBox pane) {
    _label(canvas, '${pane.realWidthMm.toInt()}mm', Offset(0, rect.top - 10));
    _label(canvas, '${pane.realHeightMm.toInt()}mm', Offset(rect.right + 14, 0),
        rotated: true);
  }

  void _label(Canvas canvas, String text, Offset pos, {bool rotated = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 8,
              fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.drawRect(
      Rect.fromCenter(center: pos, width: tp.width + 5, height: tp.height + 3),
      Paint()..color = Colors.black.withValues(alpha: 0.8),
    );

    if (rotated) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(-pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    } else {
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant FramePainter old) => true;
}
