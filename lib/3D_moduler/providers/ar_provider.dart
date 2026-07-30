import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ar_placement.dart';

// ── AR Mode ───────────────────────────────────────────────────────────────────
enum ArMode { photo, noBackground }

// ── AR Provider ───────────────────────────────────────────────────────────────
class ArProvider extends ChangeNotifier {
  // ── Background / camera ───────────────────────────────────────────────────
  Uint8List? _backgroundImage;
  ArMode _arMode = ArMode.noBackground;
  Size _imageSize = Size.zero;

  Uint8List? get backgroundImage => _backgroundImage;
  ArMode get arMode => _arMode;
  Size get imageSize => _imageSize;

  // ── Placements ────────────────────────────────────────────────────────────
  final List<ArPlacement> _placements = [];
  String? _activePlacementId;

  List<ArPlacement> get placements => _placements;
  String? get activePlacementId => _activePlacementId;

  ArPlacement? get activePlacement => _activePlacementId != null
      ? _placements.firstWhere(
          (p) => p.id == _activePlacementId,
          orElse: () => _placements.first,
        )
      : null;

  // ── Canvas transform ──────────────────────────────────────────────────────
  Offset _canvasOffset = Offset.zero;
  double _canvasScale = 1.0;

  Offset get canvasOffset => _canvasOffset;
  double get canvasScale => _canvasScale;

  // ── Photo picking ─────────────────────────────────────────────────────────
  Future<bool> pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return false;
      final bytes = await file.readAsBytes();
      _backgroundImage = bytes;
      _arMode = ArMode.photo;

      // Best-effort — image dimensions parsed lazily in painter
      _imageSize = Size.zero;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ArProvider.pickPhoto error: $e');
      return false;
    }
  }

  void clearBackground() {
    _backgroundImage = null;
    _arMode = ArMode.noBackground;
    notifyListeners();
  }

  // ── Placement CRUD ────────────────────────────────────────────────────────
  void addPlacement({
    required String windowId,
    required Size canvasSize,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final placement = ArPlacement.centered(
      id: id,
      windowId: windowId,
      canvasSize: canvasSize,
    );
    _placements.add(placement);
    _activePlacementId = id;
    notifyListeners();
  }

  void removePlacement(String id) {
    _placements.removeWhere((p) => p.id == id);
    if (_activePlacementId == id) {
      _activePlacementId = _placements.isEmpty ? null : _placements.last.id;
    }
    notifyListeners();
  }

  void selectPlacement(String? id) {
    _activePlacementId = id;
    notifyListeners();
  }

  void deselect() {
    _activePlacementId = null;
    notifyListeners();
  }

  /// Update a single corner of the active placement.
  void updateActiveCorner(int cornerIndex, Offset newPos) {
    final p = activePlacement;
    if (p == null || p.isLocked) return;
    final newCorners = List<Offset>.from(p.perspectiveCorners);
    newCorners[cornerIndex] = newPos;
    _updatePlacement(p.copyWith(perspectiveCorners: newCorners));
  }

  /// Translate the whole active placement by [delta].
  void translateActivePlacement(Offset delta) {
    final p = activePlacement;
    if (p == null || p.isLocked) return;
    _updatePlacement(p.translated(delta));
  }

  /// Scale the active placement uniformly around its centroid.
  void scaleActivePlacement(double scaleFactor) {
    final p = activePlacement;
    if (p == null || p.isLocked) return;
    final center = p.centroid;
    final newCorners = p.perspectiveCorners
        .map((c) => center + (c - center) * scaleFactor)
        .toList();
    _updatePlacement(p.copyWith(perspectiveCorners: newCorners));
  }

  void setPlacementOpacity(String id, double opacity) {
    final idx = _placements.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _placements[idx] = _placements[idx].copyWith(
      placementOpacity: opacity.clamp(0.0, 1.0),
    );
    notifyListeners();
  }

  void lockPlacement(String id, bool locked) {
    final idx = _placements.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _placements[idx] = _placements[idx].copyWith(isLocked: locked);
    notifyListeners();
  }

  void _updatePlacement(ArPlacement placement) {
    final idx = _placements.indexWhere((p) => p.id == placement.id);
    if (idx < 0) return;
    _placements[idx] = placement;
    notifyListeners();
  }

  // ── Canvas pan/zoom ────────────────────────────────────────────────────────
  void panCanvas(Offset delta) {
    _canvasOffset += delta;
    notifyListeners();
  }

  void zoomCanvas(double scaleDelta, Offset focalPoint) {
    final newScale = (_canvasScale * scaleDelta).clamp(0.2, 6.0);
    final scaleChange = newScale / _canvasScale;
    _canvasOffset = focalPoint + (_canvasOffset - focalPoint) * scaleChange;
    _canvasScale = newScale;
    notifyListeners();
  }

  void resetTransform() {
    _canvasOffset = Offset.zero;
    _canvasScale = 1.0;
    notifyListeners();
  }
}
