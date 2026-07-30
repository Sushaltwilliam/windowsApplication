import 'package:flutter/material.dart';
import '../providers/ar_provider.dart';
import '../providers/window_designer_provider.dart';
import '../models/ar_placement.dart';
import '../models/active_window.dart';
import '../utils/perspective_utils.dart';
import 'window_painter.dart';

/// AR Canvas widget: renders background photo + all perspective-warped placements
/// with corner drag handles for precise fitting to wall openings.
class ArCanvasWidget extends StatelessWidget {
  final ArProvider ar;
  final WindowDesignerProvider designer;
  final void Function(String placementId, int cornerIndex, Offset newPos) onCornerDrag;
  final void Function(String placementId) onPlacementTap;

  const ArCanvasWidget({
    super.key,
    required this.ar,
    required this.designer,
    required this.onCornerDrag,
    required this.onPlacementTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Background (photo or gradient) ──────────────────────────────
          Positioned.fill(child: _buildBackground(size)),

          // ── All placements (painted layer) ──────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _ArPainter(
                ar: ar,
                designer: designer,
                canvasSize: size,
              ),
            ),
          ),

          // ── Corner handles for active placement ─────────────────────────
          if (ar.activePlacement != null)
            ..._buildCornerHandles(context, ar.activePlacement!, size),

          // ── Placement hit areas (for tap-to-select) ─────────────────────
          ..._buildPlacementHitAreas(context, size),
        ],
      );
    });
  }

  Widget _buildBackground(Size size) {
    if (ar.backgroundImage != null) {
      return Transform(
        transform: Matrix4.identity()
          ..translate(ar.canvasOffset.dx, ar.canvasOffset.dy, 0.0)
          ..scale(ar.canvasScale, ar.canvasScale, 1.0),
        child: Image.memory(
          ar.backgroundImage!,
          fit: BoxFit.contain,
          width: size.width,
          height: size.height,
        ),
      );
    }
    // No photo: architect grid
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1421), Color(0xFF050A12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }

  List<Widget> _buildCornerHandles(
      BuildContext context, ArPlacement placement, Size size) {
    if (placement.isLocked) return [];
    final corners = placement.perspectiveCorners;
    return List.generate(4, (i) {
      return Positioned(
        left: corners[i].dx - 24,
        top: corners[i].dy - 24,
        width: 48,
        height: 48,
        child: GestureDetector(
          onPanUpdate: (details) {
            onCornerDrag(placement.id, i, corners[i] + details.delta);
          },
          child: _CornerHandle(index: i),
        ),
      );
    });
  }

  List<Widget> _buildPlacementHitAreas(BuildContext context, Size size) {
    return ar.placements.map((placement) {
      final box = placement.boundingBox;
      return Positioned(
        left: box.left,
        top: box.top,
        width: box.width,
        height: box.height,
        child: GestureDetector(
          onTap: () => onPlacementTap(placement.id),
          child: Container(color: Colors.transparent),
        ),
      );
    }).toList();
  }
}

// ── AR Painter ────────────────────────────────────────────────────────────────
class _ArPainter extends CustomPainter {
  final ArProvider ar;
  final WindowDesignerProvider designer;
  final Size canvasSize;

  _ArPainter({
    required this.ar,
    required this.designer,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final placement in ar.placements) {
      final isActive = placement.id == ar.activePlacementId;

      // Find the corresponding ActiveWindow
      final matchingWindows = designer.activeWindows
          .where((w) => w.id == placement.windowId)
          .toList();
      if (matchingWindows.isEmpty) continue;
      final window = matchingWindows.first;

      canvas.save();

      // Apply placement opacity
      final effectiveOpacity = window.opacity * placement.placementOpacity;
      if (effectiveOpacity < 1.0) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = Colors.white.withOpacity(effectiveOpacity),
        );
      }

      // Transform from template 0..100 space to perspective corners
      const srcBox = Rect.fromLTWH(0, 0, 100.0, 100.0);
      final matrix = PerspectiveUtils.getPerspectiveTransform(
          srcBox, placement.perspectiveCorners);
      canvas.transform(matrix.storage);

      // Paint the window
      _drawArWindow(canvas, window, isActive);

      if (effectiveOpacity < 1.0) canvas.restore();
      canvas.restore();

      // ── Selection outline in screen space ─────────────────────────────
      if (isActive && !placement.isLocked) {
        _drawSelectionOutline(canvas, placement);
      }
    }
  }

  void _drawArWindow(Canvas canvas, ActiveWindow window, bool isActive) {
    final painter = WindowPainter(
      windows: [window.copyWith(
        corners: [
          const Offset(0, 0),
          const Offset(100, 0),
          const Offset(100, 100),
          const Offset(0, 100),
        ],
      )],
      selectedIndex: -1, // No selection highlight inside AR, handled separately
    );
    painter.paint(canvas, const Size(100, 100));
  }

  void _drawSelectionOutline(Canvas canvas, ArPlacement placement) {
    final corners = placement.perspectiveCorners;
    if (corners.length < 4) return;

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    // Animated glow outline
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4F7BF7).withOpacity(0.4)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4F7BF7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ArPainter oldDelegate) => true;
}

// ── Corner handle widget ──────────────────────────────────────────────────────
class _CornerHandle extends StatelessWidget {
  final int index;
  const _CornerHandle({required this.index});

  static const _colors = [
    Color(0xFF4F7BF7), // TL — blue
    Color(0xFF00E5FF), // TR — cyan
    Color(0xFF00E5FF), // BR — cyan
    Color(0xFF4F7BF7), // BL — blue
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _colors[index % 4], width: 3),
          boxShadow: [
            BoxShadow(
              color: _colors[index % 4].withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _cornerIcons[index % 4],
            size: 10,
            color: _colors[index % 4],
          ),
        ),
      ),
    );
  }

  static const _cornerIcons = [
    Icons.north_west,
    Icons.north_east,
    Icons.south_east,
    Icons.south_west,
  ];
}

// ── Grid background painter ───────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Center crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), crossPaint);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
