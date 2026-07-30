import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/detected_frame.dart';

/// Detection state
enum DetectState { idle, pickingArea, pickingGrid, done }

/// Provider for AR camera and pane management
class CameraDetectionProvider extends ChangeNotifier {
  // ── Image ────────────────────────────────────────────────────────────────
  Uint8List? _capturedImage;
  Size _screenSize = const Size(400, 800);

  Uint8List? get capturedImage => _capturedImage;
  void setScreenSize(Size s) => _screenSize = s;

  // ── Detection Flow ───────────────────────────────────────────────────────
  DetectState _detectState = DetectState.idle;
  Offset? _areaCorner1; // First corner tap
  Offset? _areaCorner2; // Second corner tap
  int _gridCols = 3;
  int _gridRows = 2;

  DetectState get detectState => _detectState;
  Offset? get areaCorner1 => _areaCorner1;
  Offset? get areaCorner2 => _areaCorner2;
  int get gridCols => _gridCols;
  int get gridRows => _gridRows;
  Rect? get selectedArea {
    if (_areaCorner1 == null || _areaCorner2 == null) return null;
    return Rect.fromPoints(_areaCorner1!, _areaCorner2!);
  }

  // ── Panes ────────────────────────────────────────────────────────────────
  final List<PaneBox> _panes = [];
  String? _selectedId;

  List<PaneBox> get panes => _panes;
  String? get selectedId => _selectedId;

  PaneBox? get selected {
    if (_selectedId == null) return null;
    final i = _panes.indexWhere((p) => p.id == _selectedId);
    return i >= 0 ? _panes[i] : null;
  }

  // ── Undo ─────────────────────────────────────────────────────────────────
  final List<List<PaneBox>> _undoStack = [];
  final List<List<PaneBox>> _redoStack = [];
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _save() {
    _redoStack.clear();
    _undoStack.add(_panes.map((p) => p.copyWith()).toList());
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_panes.map((p) => p.copyWith()).toList());
    _panes
      ..clear()
      ..addAll(_undoStack.removeLast());
    _selectedId = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_panes.map((p) => p.copyWith()).toList());
    _panes
      ..clear()
      ..addAll(_redoStack.removeLast());
    _selectedId = null;
    notifyListeners();
  }

  // ── Image Capture ────────────────────────────────────────────────────────
  Future<bool> captureFromCamera() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file == null) return false;
      _capturedImage = await file.readAsBytes();
      _detectState = DetectState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Camera error: $e');
      return false;
    }
  }

  Future<bool> pickFromGallery() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file == null) return false;
      _capturedImage = await file.readAsBytes();
      _detectState = DetectState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Gallery error: $e');
      return false;
    }
  }

  void resetToCamera() {
    _capturedImage = null;
    _panes.clear();
    _selectedId = null;
    _detectState = DetectState.idle;
    _areaCorner1 = null;
    _areaCorner2 = null;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  // ── Detection Flow ───────────────────────────────────────────────────────

  /// Step 1: Start area selection mode
  void startDetection() {
    _detectState = DetectState.pickingArea;
    _areaCorner1 = null;
    _areaCorner2 = null;
    _selectedId = null;
    notifyListeners();
  }

  /// User taps to define the window area
  void tapForArea(Offset point) {
    if (_detectState != DetectState.pickingArea) return;

    if (_areaCorner1 == null) {
      _areaCorner1 = point;
      notifyListeners();
    } else {
      _areaCorner2 = point;
      // Move to grid picking
      _detectState = DetectState.pickingGrid;
      notifyListeners();
    }
  }

  /// Step 2: User picks grid size, then confirm
  void setGridSize(int cols, int rows) {
    _gridCols = cols.clamp(1, 6);
    _gridRows = rows.clamp(1, 4);
    notifyListeners();
  }

  /// Step 3: Confirm and generate panes
  void confirmDetection() {
    if (selectedArea == null) return;
    _save();

    final area = selectedArea!;
    const gap = 3.0;
    int colorIdx = _panes.length;

    final paneW = area.width / _gridCols;
    final paneH = area.height / _gridRows;

    for (int r = 0; r < _gridRows; r++) {
      for (int c = 0; c < _gridCols; c++) {
        final cx = area.left + paneW * c + paneW / 2;
        final cy = area.top + paneH * r + paneH / 2;

        _panes.add(PaneBox(
          id: 'pane_${DateTime.now().millisecondsSinceEpoch}_${r}_$c',
          position: Offset(cx, cy),
          width: paneW - gap,
          height: paneH - gap,
          color: PaneColors.get(colorIdx),
          realWidthMm: (paneW * 3.5).roundToDouble(),
          realHeightMm: (paneH * 3.5).roundToDouble(),
        ));
        colorIdx++;
      }
    }

    _detectState = DetectState.done;
    _selectedId = _panes.isNotEmpty ? _panes.last.id : null;
    _areaCorner1 = null;
    _areaCorner2 = null;
    notifyListeners();
  }

  /// Cancel detection
  void cancelDetection() {
    _detectState = DetectState.done;
    _areaCorner1 = null;
    _areaCorner2 = null;
    notifyListeners();
  }

  // ── Add single pane manually ─────────────────────────────────────────────
  void addPaneAt(Offset position) {
    _save();
    _panes.add(PaneBox(
      id: 'pane_${DateTime.now().millisecondsSinceEpoch}',
      position: position,
      width: _screenSize.width * 0.2,
      height: _screenSize.height * 0.12,
      color: PaneColors.get(_panes.length),
      realWidthMm: 500,
      realHeightMm: 400,
    ));
    _selectedId = _panes.last.id;
    notifyListeners();
  }

  void duplicateSelected() {
    final s = selected;
    if (s == null) return;
    _save();
    _panes.add(PaneBox(
      id: 'pane_${DateTime.now().millisecondsSinceEpoch}',
      position: s.position + const Offset(20, 20),
      width: s.width,
      height: s.height,
      rotation: s.rotation,
      tiltX: s.tiltX,
      tiltY: s.tiltY,
      color: PaneColors.get(_panes.length),
      opacity: s.opacity,
      realWidthMm: s.realWidthMm,
      realHeightMm: s.realHeightMm,
    ));
    _selectedId = _panes.last.id;
    notifyListeners();
  }

  // ── Selection ────────────────────────────────────────────────────────────
  void select(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  void deselect() {
    _selectedId = null;
    notifyListeners();
  }

  String? paneAtPoint(Offset point) {
    for (int i = _panes.length - 1; i >= 0; i--) {
      if (_panes[i].containsPoint(point)) return _panes[i].id;
    }
    return null;
  }

  void deleteSelected() {
    if (_selectedId == null) return;
    _save();
    _panes.removeWhere((p) => p.id == _selectedId);
    _selectedId = _panes.isNotEmpty ? _panes.last.id : null;
    notifyListeners();
  }

  // ── Manipulation ─────────────────────────────────────────────────────────
  void move(String id, Offset pos) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0 || _panes[i].isLocked) return;
    _panes[i].position = pos;
    notifyListeners();
  }

  void setWidth(String id, double w) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0 || _panes[i].isLocked) return;
    _panes[i].width = w.clamp(30, 500);
    notifyListeners();
  }

  void setHeight(String id, double h) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0 || _panes[i].isLocked) return;
    _panes[i].height = h.clamp(30, 600);
    notifyListeners();
  }

  void setRotation(String id, double deg) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0 || _panes[i].isLocked) return;
    double n = deg % 360;
    if (n > 180) n -= 360;
    if (n < -180) n += 360;
    _panes[i].rotation = n;
    notifyListeners();
  }

  void setTiltX(String id, double deg) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0 || _panes[i].isLocked) return;
    _panes[i].tiltX = deg.clamp(-60, 60);
    notifyListeners();
  }

  void setTiltY(String id, double deg) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0 || _panes[i].isLocked) return;
    _panes[i].tiltY = deg.clamp(-60, 60);
    notifyListeners();
  }

  void setColor(String id, Color c) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _panes[i].color = c;
    notifyListeners();
  }

  void setOpacity(String id, double o) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _panes[i].opacity = o.clamp(0.1, 1.0);
    notifyListeners();
  }

  void setRealWidth(String id, double mm) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _panes[i].realWidthMm = mm;
    notifyListeners();
  }

  void setRealHeight(String id, double mm) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _panes[i].realHeightMm = mm;
    notifyListeners();
  }

  void toggleLock(String id) {
    final i = _panes.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _panes[i].isLocked = !_panes[i].isLocked;
    notifyListeners();
  }
}
