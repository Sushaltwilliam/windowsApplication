import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/window_design_template.dart';
import '../models/vector_line.dart';
import '../providers/window_designer_provider.dart';
import '../utils/geometry_utils.dart';

class FreehandDrawScreen extends StatefulWidget {
  const FreehandDrawScreen({super.key});

  @override
  State<FreehandDrawScreen> createState() => _FreehandDrawScreenState();
}

class _FreehandDrawScreenState extends State<FreehandDrawScreen> {
  // Dimensions in mm
  double _totalWidth = 2000.0;
  double _totalHeight = 2000.0;

  final TextEditingController _widthCtrl = TextEditingController(text: '2000');
  final TextEditingController _heightCtrl = TextEditingController(text: '2000');

  // Vector Engine State
  List<VectorLine> _lines = [];
  VectorLine? _drawingLine;
  String? _selectedLineId;
  
  // Calculated panes
  List<Rect> _panes = [];
  List<PaneType> _paneTypes = [];
  int? _selectedPaneIndex;
  
  PaneType _activePaneType = PaneType.fixed;

  // Interaction State
  bool _isMovingLine = false;

  @override
  void initState() {
    super.initState();
    _recalculatePanes();
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _updateTotalDimensions() {
    final w = double.tryParse(_widthCtrl.text) ?? _totalWidth;
    final h = double.tryParse(_heightCtrl.text) ?? _totalHeight;
    setState(() {
      _totalWidth = w.clamp(100.0, 10000.0);
      _totalHeight = h.clamp(100.0, 10000.0);
      _lines.clear();
      _selectedLineId = null;
      _recalculatePanes();
    });
  }

  void _recalculatePanes() {
    final bounds = Rect.fromLTRB(0, 0, _totalWidth, _totalHeight);
    final newPanes = GeometryUtils.calculatePanes(bounds, _lines);
    
    // Attempt to retain pane types if possible, else default to fixed
    List<PaneType> newPaneTypes = List.generate(newPanes.length, (_) => PaneType.fixed);
    
    setState(() {
      _panes = newPanes;
      _paneTypes = newPaneTypes;
      _selectedPaneIndex = null;
    });
  }

  // ── Gestures ──────────────────────────────────────────────────────────────

  Offset _screenToMm(Offset screenPos, Size canvasSize) {
    final scaleX = _totalWidth / canvasSize.width;
    final scaleY = _totalHeight / canvasSize.height;
    return Offset(screenPos.dx * scaleX, screenPos.dy * scaleY);
  }

  void _onPanStart(DragStartDetails d, Size canvasSize) {
    final posMm = _screenToMm(d.localPosition, canvasSize);
    
    // 1. Check if hitting a line
    for (final line in _lines) {
      if (line.hitTest(posMm, padding: 50.0)) { // 50mm hit slop
        setState(() {
          _selectedLineId = line.id;
          _selectedPaneIndex = null;
          _isMovingLine = true;
        });
        return;
      }
    }

    // 2. Check if hitting a pane (for selection)
    int? hitPane;
    for (int i = 0; i < _panes.length; i++) {
      if (_panes[i].contains(posMm)) {
        hitPane = i;
        break;
      }
    }

    setState(() {
      _selectedLineId = null;
      _selectedPaneIndex = hitPane;
      _isMovingLine = false;
      
      // If they tapped a pane, apply the currently selected window tool to it (Paint Bucket style)
      if (hitPane != null && hitPane < _paneTypes.length) {
        _paneTypes[hitPane] = _activePaneType;
      }

      // Start drawing a new line
      _drawingLine = VectorLine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startPoint: posMm,
        endPoint: posMm,
        isVertical: true, // will be determined on move
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails d, Size canvasSize) {
    final posMm = _screenToMm(d.localPosition, canvasSize);
    
    if (_isMovingLine && _selectedLineId != null) {
      // Move line
      final lineIdx = _lines.indexWhere((l) => l.id == _selectedLineId);
      if (lineIdx >= 0) {
        final line = _lines[lineIdx];
        final deltaMm = _screenToMm(d.delta, canvasSize);
        setState(() {
          if (line.isVertical) {
            final newX = (line.startPoint.dx + deltaMm.dx).clamp(0.0, _totalWidth);
            line.startPoint = Offset(newX, line.startPoint.dy);
            line.endPoint = Offset(newX, line.endPoint.dy);
          } else {
            final newY = (line.startPoint.dy + deltaMm.dy).clamp(0.0, _totalHeight);
            line.startPoint = Offset(line.startPoint.dx, newY);
            line.endPoint = Offset(line.endPoint.dx, newY);
          }
          _recalculatePanes();
        });
      }
      return;
    }

    if (_drawingLine != null) {
      // Drawing new line
      final dx = (posMm.dx - _drawingLine!.startPoint.dx).abs();
      final dy = (posMm.dy - _drawingLine!.startPoint.dy).abs();
      
      setState(() {
        _drawingLine!.isVertical = dy > dx;
        
        final bounds = _selectedPaneIndex != null && _selectedPaneIndex! < _panes.length
            ? _panes[_selectedPaneIndex!]
            : Rect.fromLTWH(0, 0, _totalWidth, _totalHeight);

        if (_drawingLine!.isVertical) {
          _drawingLine!.endPoint = Offset(
              _drawingLine!.startPoint.dx, 
              posMm.dy.clamp(bounds.top, bounds.bottom)
          );
        } else {
          _drawingLine!.endPoint = Offset(
              posMm.dx.clamp(bounds.left, bounds.right), 
              _drawingLine!.startPoint.dy
          );
        }
      });
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_isMovingLine) {
      setState(() => _isMovingLine = false);
      return;
    }

    if (_drawingLine != null) {
      // If line is long enough, save it and snap to bounds
      if (_drawingLine!.length > 100) { // minimum 100mm
        setState(() {
          // Snap endpoints to the bounds of the pane where drawing started
          final bounds = _selectedPaneIndex != null && _selectedPaneIndex! < _panes.length
              ? _panes[_selectedPaneIndex!]
              : Rect.fromLTWH(0, 0, _totalWidth, _totalHeight);

          if (_drawingLine!.isVertical) {
            _drawingLine!.startPoint = Offset(_drawingLine!.startPoint.dx, bounds.top);
            _drawingLine!.endPoint = Offset(_drawingLine!.startPoint.dx, bounds.bottom);
          } else {
            _drawingLine!.startPoint = Offset(bounds.left, _drawingLine!.startPoint.dy);
            _drawingLine!.endPoint = Offset(bounds.right, _drawingLine!.startPoint.dy);
          }
          _lines.add(_drawingLine!);
          _recalculatePanes();
        });
      }
      setState(() => _drawingLine = null);
    }
  }

  void _deleteSelectedLine() {
    if (_selectedLineId != null) {
      setState(() {
        _lines.removeWhere((l) => l.id == _selectedLineId);
        _selectedLineId = null;
        _recalculatePanes();
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  void _saveTemplate() {
    // Normalize panes to 0..100 for WindowDesignTemplate
    final List<List<Offset>> normalizedPanes = [];
    final scaleX = 100.0 / _totalWidth;
    final scaleY = 100.0 / _totalHeight;
    
    for (final pane in _panes) {
      normalizedPanes.add([
        Offset(pane.left * scaleX, pane.top * scaleY),
        Offset(pane.right * scaleX, pane.top * scaleY),
        Offset(pane.right * scaleX, pane.bottom * scaleY),
        Offset(pane.left * scaleX, pane.bottom * scaleY),
      ]);
    }

    final tpl = WindowDesignTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Freehand Design',
      category: 'Custom',
      description: 'Custom drawn CAD window',
      panes: normalizedPanes,
      paneTypes: _paneTypes,
      exactWidth: _totalWidth,
      exactHeight: _totalHeight,
      icon: Icons.draw,
      vectorLines: _lines,
    );
    
    Provider.of<WindowDesignerProvider>(context, listen: false).addCustomTemplate(tpl);
    Navigator.pop(context);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Freehand CAD Drawer', style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: Color(0xFF4F7BF7)),
            label: const Text('Save Design', style: TextStyle(color: Color(0xFF4F7BF7), fontWeight: FontWeight.bold)),
            onPressed: _saveTemplate,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Toolbar (Dimensions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(child: _buildDimField('Outer Width (mm)', _widthCtrl)),
                const SizedBox(width: 16),
                Expanded(child: _buildDimField('Outer Height (mm)', _heightCtrl)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                  onPressed: _updateTotalDimensions,
                  tooltip: 'Update Dimensions',
                ),
              ],
            ),
          ),
          
          // Drawing Canvas
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final aspect = _totalWidth / _totalHeight;
                    double cw = constraints.maxWidth;
                    double ch = cw / aspect;
                    if (ch > constraints.maxHeight) {
                      ch = constraints.maxHeight;
                      cw = ch * aspect;
                    }

                    final canvasSize = Size(cw, ch);

                    return GestureDetector(
                      onPanStart: (d) => _onPanStart(d, canvasSize),
                      onPanUpdate: (d) => _onPanUpdate(d, canvasSize),
                      onPanEnd: _onPanEnd,
                      child: Container(
                        width: cw,
                        height: ch,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B27),
                          border: Border.all(color: Colors.white24, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)
                          ],
                        ),
                        child: CustomPaint(
                          size: canvasSize,
                          painter: _CadVectorPainter(
                            totalWidth: _totalWidth,
                            totalHeight: _totalHeight,
                            lines: _lines,
                            drawingLine: _drawingLine,
                            selectedLineId: _selectedLineId,
                            panes: _panes,
                            paneTypes: _paneTypes,
                            selectedPaneIndex: _selectedPaneIndex,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Property Panel
          _buildPropertyPanel(),
        ],
      ),
    );
  }

  Widget _buildDimField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onSubmitted: (_) => _updateTotalDimensions(),
        ),
      ],
    );
  }

  Widget _buildPropertyPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B27),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_selectedLineId != null) ...[
                const Text('LINE PROPERTIES', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4C4C)),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('Delete Line', style: TextStyle(color: Colors.white)),
                      onPressed: _deleteSelectedLine,
                    )
                  ],
                ),
                const SizedBox(height: 20),
              ],
              
              const Text('ACTIVE PANE TOOL', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Select a tool below, then tap any pane to apply it.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: PaneType.values.map((pt) {
                    final isSel = _activePaneType == pt;
                    
                    IconData iconData = Icons.grid_view;
                    if (pt == PaneType.awning) iconData = Icons.open_in_browser;
                    if (pt == PaneType.casement) iconData = Icons.door_front_door;
                    if (pt == PaneType.sliding) iconData = Icons.swipe;
                    if (pt == PaneType.door) iconData = Icons.meeting_room;
                    if (pt == PaneType.tiltTurn) iconData = Icons.rotate_90_degrees_ccw;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _activePaneType = pt;
                          if (_selectedPaneIndex != null && _selectedPaneIndex! < _paneTypes.length) {
                            _paneTypes[_selectedPaneIndex!] = pt;
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData, 
                              color: isSel ? const Color(0xFF4F7BF7) : Colors.white54, 
                              size: 28
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pt.label, 
                              style: TextStyle(
                                color: isSel ? const Color(0xFF4F7BF7) : Colors.white54, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 11
                              )
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vector Painter ──────────────────────────────────────────────────────────

class _CadVectorPainter extends CustomPainter {
  final double totalWidth;
  final double totalHeight;
  final List<VectorLine> lines;
  final VectorLine? drawingLine;
  final String? selectedLineId;
  final List<Rect> panes;
  final List<PaneType> paneTypes;
  final int? selectedPaneIndex;

  _CadVectorPainter({
    required this.totalWidth,
    required this.totalHeight,
    required this.lines,
    required this.drawingLine,
    required this.selectedLineId,
    required this.panes,
    required this.paneTypes,
    required this.selectedPaneIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / totalWidth;
    final scaleY = size.height / totalHeight;

    // 1. Sort panes geometrically to assign row-major labels (e.g. F1, F2...)
    final orderedIndices = List.generate(panes.length, (i) => i);
    orderedIndices.sort((a, b) {
      final pa = panes[a];
      final pb = panes[b];
      if ((pa.top - pb.top).abs() > 5.0) {
        return pa.top.compareTo(pb.top);
      }
      return pa.left.compareTo(pb.left);
    });

    Map<PaneType, int> typeCounters = {};
    Map<int, String> labels = {};
    for (int idx in orderedIndices) {
      final pt = paneTypes.length > idx ? paneTypes[idx] : PaneType.fixed;
      typeCounters[pt] = (typeCounters[pt] ?? 0) + 1;
      final prefix = pt.name.substring(0, 1).toUpperCase();
      labels[idx] = '$prefix${typeCounters[pt]}';
    }

    // 2. Draw Panes & Labels
    for (int i = 0; i < panes.length; i++) {
      final paneMm = panes[i];
      final rect = Rect.fromLTRB(
        paneMm.left * scaleX, paneMm.top * scaleY,
        paneMm.right * scaleX, paneMm.bottom * scaleY,
      );

      final isSel = i == selectedPaneIndex;
      
      // Glass fill
      final glassPaint = Paint()
        ..shader = LinearGradient(
          colors: isSel 
            ? [const Color(0xFF4F7BF7).withOpacity(0.4), const Color(0xFF4F7BF7).withOpacity(0.2)]
            : [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, glassPaint);

      final pt = paneTypes.length > i ? paneTypes[i] : PaneType.fixed;

      Rect innerRect = rect;
      
      // Draw Sash (Inner Frame) and 'X' for opening windows
      if (pt != PaneType.fixed) {
        final sashThickness = 6.0;
        innerRect = rect.deflate(sashThickness);
        
        // Sash Frame
        final sashPaint = Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sashThickness;
        canvas.drawRect(rect.deflate(sashThickness / 2), sashPaint);

        // 'X' Marks
        final xPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(innerRect.topLeft, innerRect.bottomRight, xPaint);
        canvas.drawLine(innerRect.bottomLeft, innerRect.topRight, xPaint);

        // Draw Handle for Casement/Awning
        if (pt == PaneType.casement) {
          final handleRect = Rect.fromCenter(
            center: Offset(innerRect.left + 8, innerRect.center.dy),
            width: 4,
            height: 20,
          );
          canvas.drawRect(handleRect, Paint()..color = Colors.white.withOpacity(0.8));
        } else if (pt == PaneType.awning) {
          final handleRect = Rect.fromCenter(
            center: Offset(innerRect.center.dx, innerRect.bottom - 8),
            width: 30,
            height: 4,
          );
          canvas.drawRect(handleRect, Paint()..color = Colors.white.withOpacity(0.8));
        }
      }

      // Draw Label
      final label = labels[i] ?? '';

      final tp = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));

      // Internal dimension if selected
      if (isSel) {
        final dimTp = TextPainter(
          text: TextSpan(
            text: '${paneMm.width.toInt()} x ${paneMm.height.toInt()}',
            style: const TextStyle(color: Color(0xFF4F7BF7), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        dimTp.paint(canvas, Offset(rect.center.dx - dimTp.width / 2, rect.center.dy + tp.height / 2 + 4));
      }
    }

    // 2. Collect unique coordinates for edge dimensions
    final Set<double> xCoords = {0.0, totalWidth};
    final Set<double> yCoords = {0.0, totalHeight};
    for (final line in lines) {
      if (line.isVertical) {
        xCoords.add(line.startPoint.dx);
      } else {
        yCoords.add(line.startPoint.dy);
      }
    }
    
    final sortedX = xCoords.toList()..sort();
    final sortedY = yCoords.toList()..sort();

    // Remove coordinates that are too close (floating point / snapping errors)
    for (int i = sortedX.length - 1; i > 0; i--) {
      if (sortedX[i] - sortedX[i - 1] < 5.0) sortedX.removeAt(i);
    }
    for (int i = sortedY.length - 1; i > 0; i--) {
      if (sortedY[i] - sortedY[i - 1] < 5.0) sortedY.removeAt(i);
    }

    final dimPaint = Paint()..color = const Color(0xFF4F7BF7)..strokeWidth = 1.0;
    
    // Bottom horizontal dimensions
    for (int i = 0; i < sortedX.length - 1; i++) {
      final x1 = sortedX[i];
      final x2 = sortedX[i + 1];
      final dist = (x2 - x1).toInt();
      
      final p1 = Offset(x1 * scaleX, size.height + 25);
      final p2 = Offset(x2 * scaleX, size.height + 25);
      
      canvas.drawLine(p1, p2, dimPaint);
      canvas.drawLine(Offset(p1.dx, p1.dy - 4), Offset(p1.dx, p1.dy + 4), dimPaint);
      canvas.drawLine(Offset(p2.dx, p2.dy - 4), Offset(p2.dx, p2.dy + 4), dimPaint);

      final tp = TextPainter(
        text: TextSpan(text: '$dist', style: const TextStyle(color: Color(0xFF4F7BF7), fontSize: 12, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((p1.dx + p2.dx) / 2 - tp.width / 2, size.height + 8));
    }
    // Total width below bottom dimensions
    final totTpX = TextPainter(
      text: TextSpan(text: '${totalWidth.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    totTpX.paint(canvas, Offset(size.width / 2 - totTpX.width / 2, size.height + 25 + 4));

    // Left vertical dimensions
    for (int i = 0; i < sortedY.length - 1; i++) {
      final y1 = sortedY[i];
      final y2 = sortedY[i + 1];
      final dist = (y2 - y1).toInt();
      
      final p1 = Offset(-20, y1 * scaleY);
      final p2 = Offset(-20, y2 * scaleY);
      
      canvas.drawLine(p1, p2, dimPaint);
      canvas.drawLine(Offset(p1.dx - 4, p1.dy), Offset(p1.dx + 4, p1.dy), dimPaint);
      canvas.drawLine(Offset(p2.dx - 4, p2.dy), Offset(p2.dx + 4, p2.dy), dimPaint);

      final tp = TextPainter(
        text: TextSpan(text: '$dist', style: const TextStyle(color: Color(0xFF4F7BF7), fontSize: 12, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      
      tp.paint(canvas, Offset(-28 - tp.width, (p1.dy + p2.dy) / 2 - tp.height / 2));
    }
    // Total height to the left
    final totTpY = TextPainter(
      text: TextSpan(text: '${totalHeight.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    totTpY.paint(canvas, Offset(-28 - totTpY.width, size.height / 2 - totTpY.height / 2));

    // Draw Lines
    void drawLine(VectorLine line, bool isSelected, bool isPreview) {
      final p1 = Offset(line.startPoint.dx * scaleX, line.startPoint.dy * scaleY);
      final p2 = Offset(line.endPoint.dx * scaleX, line.endPoint.dy * scaleY);
      
      final paint = Paint()
        ..color = isPreview ? const Color(0xFF4F7BF7) : (isSelected ? const Color(0xFF4F7BF7) : Colors.white70)
        ..strokeWidth = (line.thickness * scaleX).clamp(2.0, 10.0)
        ..strokeCap = StrokeCap.square;
        
      canvas.drawLine(p1, p2, paint);

      if (isSelected || isPreview) {
        // Draw selection handles
        final handlePaint = Paint()..color = Colors.white;
        canvas.drawCircle(p1, 5, handlePaint);
        canvas.drawCircle(p2, 5, handlePaint);
      }
    }

    for (final line in lines) {
      drawLine(line, line.id == selectedLineId, false);
    }

    if (drawingLine != null) {
      drawLine(drawingLine!, false, true);
    }
  }

  @override
  bool shouldRepaint(covariant _CadVectorPainter oldDelegate) => true;
}
