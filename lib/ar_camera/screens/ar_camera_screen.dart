import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/camera_detection_provider.dart';
import '../widgets/frame_painter.dart';
import '../widgets/frame_controls_panel.dart';

class ArCameraScreen extends StatefulWidget {
  const ArCameraScreen({super.key});

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  bool _addMode = false;
  bool _previewMode = false;
  double _openFactor = 0.0;

  // Gesture state
  Offset? _startFocal;
  Offset? _paneStartPos;
  double _startW = 0, _startH = 0, _startRot = 0;
  bool _multi = false;
  _Handle? _handle;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context
        .read<CameraDetectionProvider>()
        .setScreenSize(MediaQuery.of(context).size);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Consumer<CameraDetectionProvider>(
        builder: (ctx, p, _) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              if (p.capturedImage != null) _imageView(p) else _placeholder(),
              _topBar(p),
              if (p.selected != null &&
                  !_previewMode &&
                  (p.detectState == DetectState.done ||
                      p.detectState == DetectState.idle))
                const Positioned(
                    left: 0, right: 0, bottom: 0, child: FrameControlsPanel()),
              if (p.capturedImage != null &&
                  p.detectState == DetectState.idle &&
                  p.panes.isEmpty)
                _startActions(p),
              if (p.capturedImage != null &&
                  p.detectState == DetectState.done &&
                  p.selected == null &&
                  !_previewMode)
                _editActions(p),
              if (p.capturedImage == null) _captureButtons(p),
              // Detection flow overlays
              if (p.detectState == DetectState.pickingArea) _areaBanner(p),
              if (p.detectState == DetectState.pickingGrid) _gridPicker(p),
              if (_addMode) _addBanner(),
              if (_previewMode && p.capturedImage != null) _previewPanel(),
              // Floating "+" button — always visible when panes exist
              if (p.capturedImage != null &&
                  p.panes.isNotEmpty &&
                  (p.detectState == DetectState.done ||
                      p.detectState == DetectState.idle) &&
                  !_previewMode &&
                  !_addMode)
                _floatingAddBtn(p),
            ],
          ),
        ),
      ),
    );
  }

  // ── Placeholder ──────────────────────────────────────────────────────────
  Widget _placeholder() {
    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Transform.scale(
                scale: 0.9 + _pulseCtrl.value * 0.1,
                child: const Icon(Icons.camera_alt_rounded,
                    size: 52, color: Color(0xFF00FF00)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Take a photo or pick from gallery',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('Then mark the window area',
                style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Image View ───────────────────────────────────────────────────────────
  Widget _imageView(CameraDetectionProvider p) {
    return GestureDetector(
      onTapUp: (d) => _onTap(d.localPosition, p),
      onScaleStart: _previewMode ? null : (d) => _onStart(d, p),
      onScaleUpdate: _previewMode ? null : (d) => _onUpdate(d, p),
      onScaleEnd: _previewMode ? null : (_) => _onEnd(),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(p.capturedImage!, fit: BoxFit.contain),
            // Area selection overlay
            if (p.detectState == DetectState.pickingArea ||
                p.detectState == DetectState.pickingGrid)
              CustomPaint(
                  painter: _AreaPainter(
                      corner1: p.areaCorner1, corner2: p.areaCorner2)),
            // Panes
            CustomPaint(
              size: Size.infinite,
              painter: FramePainter(
                  panes: p.panes,
                  selectedId: _previewMode ? null : p.selectedId,
                  openFactor: _openFactor),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tap handling ─────────────────────────────────────────────────────────
  void _onTap(Offset pos, CameraDetectionProvider p) {
    if (p.detectState == DetectState.pickingArea) {
      p.tapForArea(pos);
      return;
    }
    if (_addMode) {
      p.addPaneAt(pos);
      setState(() => _addMode = false);
      return;
    }
    // Normal tap: select pane at point
    final id = p.paneAtPoint(pos);
    if (id != null) {
      p.select(id);
    } else {
      p.deselect();
    }
  }

  // ── Gesture handling ─────────────────────────────────────────────────────
  void _onStart(ScaleStartDetails d, CameraDetectionProvider p) {
    if (p.detectState != DetectState.done &&
        p.detectState != DetectState.idle) {
      return;
    }
    final pt = d.localFocalPoint;
    _multi = d.pointerCount > 1;

    _handle = _hitHandle(pt, p);
    if (_handle != null) {
      _startFocal = pt;
      _startW = p.selected?.width ?? 0;
      _startH = p.selected?.height ?? 0;
      return;
    }

    // Select pane on drag start too (for immediate drag)
    final id = p.paneAtPoint(pt);
    if (id != null && id != p.selectedId) {
      p.select(id);
    }

    _startFocal = pt;
    _paneStartPos = p.selected?.position;
    _startW = p.selected?.width ?? 0;
    _startH = p.selected?.height ?? 0;
    _startRot = p.selected?.rotation ?? 0;
  }

  void _onUpdate(ScaleUpdateDetails d, CameraDetectionProvider p) {
    final pane = p.selected;
    if (pane == null || pane.isLocked) return;

    if (_handle != null && _startFocal != null) {
      final dx = d.localFocalPoint.dx - _startFocal!.dx;
      final dy = d.localFocalPoint.dy - _startFocal!.dy;
      switch (_handle!) {
        case _Handle.left:
          p.setWidth(pane.id, _startW - dx);
        case _Handle.right:
          p.setWidth(pane.id, _startW + dx);
        case _Handle.top:
          p.setHeight(pane.id, _startH - dy);
        case _Handle.bottom:
          p.setHeight(pane.id, _startH + dy);
        case _Handle.corner:
          p.setWidth(pane.id, _startW + dx);
          p.setHeight(pane.id, _startH + dy);
      }
      return;
    }

    if (_multi || d.pointerCount > 1) {
      _multi = true;
      p.setWidth(pane.id, (_startW * d.scale).clamp(30, 500));
      p.setHeight(pane.id, (_startH * d.scale).clamp(30, 600));
      if (d.rotation.abs() > 0.01) {
        p.setRotation(pane.id, _startRot + d.rotation * 180 / pi);
      }
      return;
    }

    if (_startFocal != null && _paneStartPos != null) {
      p.move(pane.id, _paneStartPos! + (d.localFocalPoint - _startFocal!));
    }
  }

  void _onEnd() {
    _startFocal = null;
    _paneStartPos = null;
    _multi = false;
    _handle = null;
  }

  _Handle? _hitHandle(Offset pt, CameraDetectionProvider p) {
    final pane = p.selected;
    if (pane == null) return null;
    final r = Rect.fromCenter(
        center: pane.position, width: pane.width, height: pane.height);
    const hs = 22.0;
    if ((pt - Offset(r.left, r.center.dy)).distance < hs) return _Handle.left;
    if ((pt - Offset(r.right, r.center.dy)).distance < hs) return _Handle.right;
    if ((pt - Offset(r.center.dx, r.top)).distance < hs) return _Handle.top;
    if ((pt - Offset(r.center.dx, r.bottom)).distance < hs) {
      return _Handle.bottom;
    }
    if ((pt - r.bottomRight).distance < hs) return _Handle.corner;
    return null;
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────
  Widget _topBar(CameraDetectionProvider p) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            right: 8,
            bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent
              ]),
        ),
        child: Row(
          children: [
            _IcoBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
            const SizedBox(width: 6),
            const Text('AR Detect',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (p.capturedImage != null && p.panes.isNotEmpty) ...[
              _IcoBtn(
                  _previewMode ? Icons.edit : Icons.visibility,
                  () => setState(() {
                        _previewMode = !_previewMode;
                        if (_previewMode) p.deselect();
                      }),
                  highlight: _previewMode),
              _IcoBtn(Icons.undo, p.undo, enabled: p.canUndo),
              _IcoBtn(Icons.redo, p.redo, enabled: p.canRedo),
            ],
            if (p.capturedImage != null) _IcoBtn(Icons.close, p.resetToCamera),
          ],
        ),
      ),
    );
  }

  // ── Start Actions (after image picked, before detection) ─────────────────
  Widget _startActions(CameraDetectionProvider p) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Mark the window area',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(Icons.crop_free, 'Select Area', const Color(0xFF00FF00),
                  () => p.startDetection()),
              const SizedBox(width: 12),
              _Chip(Icons.add_box_outlined, 'Add Single', Colors.white54,
                  () => setState(() => _addMode = true)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Edit Actions (after panes placed) ────────────────────────────────────
  Widget _editActions(CameraDetectionProvider p) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Chip(Icons.crop_free, 'Add Window', const Color(0xFF00FF00),
              () => p.startDetection()),
          const SizedBox(width: 10),
          _Chip(Icons.add_box_outlined, 'Add Pane', Colors.white54,
              () => setState(() => _addMode = true)),
          const SizedBox(width: 10),
          _Chip(Icons.visibility, 'Preview', const Color(0xFF64C8FA),
              () => setState(() => _previewMode = true)),
        ],
      ),
    );
  }

  // ── Floating Add Button (always visible) ─────────────────────────────────
  Widget _floatingAddBtn(CameraDetectionProvider p) {
    return Positioned(
      right: 16,
      bottom: p.selected != null ? 220 : 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              p.deselect();
              setState(() => _addMode = true);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00FF00).withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 24),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Add',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Capture Buttons ──────────────────────────────────────────────────────
  Widget _captureButtons(CameraDetectionProvider p) {
    return Positioned(
      bottom: 36,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircBtn(Icons.photo_library_outlined, 'Gallery',
              () => p.pickFromGallery()),
          const SizedBox(width: 32),
          GestureDetector(
            onTap: () => p.captureFromCamera(),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3)),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF00FF00)),
                child:
                    const Icon(Icons.camera_alt, color: Colors.black, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 32),
          _CircBtn(
              Icons.camera_alt_outlined, 'Camera', () => p.captureFromCamera()),
        ],
      ),
    );
  }

  // ── Area Selection Banner ────────────────────────────────────────────────
  Widget _areaBanner(CameraDetectionProvider p) {
    final hasFirst = p.areaCorner1 != null;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF00).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app, size: 16, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasFirst
                    ? 'Tap the BOTTOM-RIGHT corner'
                    : 'Tap the TOP-LEFT corner of window',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              onTap: () => p.cancelDetection(),
              child: const Icon(Icons.close, size: 18, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid Size Picker ─────────────────────────────────────────────────────
  Widget _gridPicker(CameraDetectionProvider p) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5), blurRadius: 16)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many panes?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            // Columns
            Row(
              children: [
                const SizedBox(
                    width: 60,
                    child: Text('Columns',
                        style: TextStyle(color: Colors.white54, fontSize: 12))),
                ...List.generate(6, (i) {
                  final n = i + 1;
                  final active = p.gridCols == n;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => p.setGridSize(n, p.gridRows),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 36,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF00FF00).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: active
                                  ? const Color(0xFF00FF00)
                                  : Colors.white12),
                        ),
                        child: Center(
                            child: Text('$n',
                                style: TextStyle(
                                    color: active
                                        ? const Color(0xFF00FF00)
                                        : Colors.white54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700))),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            // Rows
            Row(
              children: [
                const SizedBox(
                    width: 60,
                    child: Text('Rows',
                        style: TextStyle(color: Colors.white54, fontSize: 12))),
                ...List.generate(4, (i) {
                  final n = i + 1;
                  final active = p.gridRows == n;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => p.setGridSize(p.gridCols, n),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 36,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF00FF00).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: active
                                  ? const Color(0xFF00FF00)
                                  : Colors.white12),
                        ),
                        child: Center(
                            child: Text('$n',
                                style: TextStyle(
                                    color: active
                                        ? const Color(0xFF00FF00)
                                        : Colors.white54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700))),
                      ),
                    ),
                  );
                }),
                const Expanded(flex: 2, child: SizedBox()),
              ],
            ),
            const SizedBox(height: 16),
            // Preview text
            Text(
                '${p.gridCols} × ${p.gridRows} = ${p.gridCols * p.gridRows} panes',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
            // Confirm
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => p.cancelDetection(),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24)),
                      child: const Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => p.confirmDetection(),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                          color: const Color(0xFF00FF00),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Center(
                          child: Text('Confirm',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Mode Banner ──────────────────────────────────────────────────────
  Widget _addBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF00FF00),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.touch_app, size: 14, color: Colors.black),
            const SizedBox(width: 6),
            const Text('Tap to place pane',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
                onTap: () => setState(() => _addMode = false),
                child:
                    const Icon(Icons.close, size: 16, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // ── Preview Panel ────────────────────────────────────────────────────────
  Widget _previewPanel() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.door_sliding_outlined,
                    size: 14, color: Color(0xFF00FF00)),
                const SizedBox(width: 6),
                const Text('Open / Close',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const Spacer(),
                Text('${(_openFactor * 100).toInt()}%',
                    style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                activeTrackColor: Color(0xFF00FF00),
                inactiveTrackColor: Colors.white12,
                thumbColor: Color(0xFF00FF00),
              ),
              child: Slider(
                  value: _openFactor,
                  onChanged: (v) => setState(() => _openFactor = v)),
            ),
            GestureDetector(
              onTap: () => setState(() => _previewMode = false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24)),
                child: const Text('Back to Edit',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────
enum _Handle { left, right, top, bottom, corner }

/// Painter for the area selection rectangle
class _AreaPainter extends CustomPainter {
  final Offset? corner1;
  final Offset? corner2;
  _AreaPainter({this.corner1, this.corner2});

  @override
  void paint(Canvas canvas, Size size) {
    if (corner1 != null) {
      // Draw first corner marker
      final p = Paint()
        ..color = const Color(0xFF00FF00)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(corner1!, 8, p);

      if (corner2 != null) {
        // Draw rectangle
        final rect = Rect.fromPoints(corner1!, corner2!);
        final borderPaint = Paint()
          ..color = const Color(0xFF00FF00)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawRect(rect, borderPaint);

        // Fill with translucent
        canvas.drawRect(rect,
            Paint()..color = const Color(0xFF00FF00).withValues(alpha: 0.08));

        // Second corner
        canvas.drawCircle(corner2!, 8, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) => true;
}

class _IcoBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool highlight;
  const _IcoBtn(this.icon, this.onTap,
      {this.enabled = true, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon,
              size: 18,
              color: highlight
                  ? const Color(0xFF00FF00)
                  : (enabled ? Colors.white : Colors.white24))),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Chip(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _CircBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CircBtn(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white24)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 9)),
      ]),
    );
  }
}
