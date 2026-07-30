import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/window_design_template.dart';
import '../models/window_theme.dart';
import '../models/window_project.dart';
import '../models/active_window.dart';
import '../utils/geometry_utils.dart';

// ── View mode ─────────────────────────────────────────────────────────────────
enum ViewMode { preview3D, drawing2D }

// ── History ───────────────────────────────────────────────────────────────────
class HistoryState {
  final List<ActiveWindow> windows;
  final int selectedWindowIndex;

  HistoryState({
    required this.windows,
    required this.selectedWindowIndex,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────
class WindowDesignerProvider extends ChangeNotifier {
  Uint8List? _backgroundImage;

  // ── Window state ───────────────────────────────────────────────────────────
  final List<ActiveWindow> _activeWindows = [];
  int _selectedWindowIndex = -1;
  final Set<int> _multiSelectedIndices = {};

  // ── View mode ──────────────────────────────────────────────────────────────
  ViewMode _viewMode = ViewMode.preview3D;
  ViewMode get viewMode => _viewMode;

  // Custom templates created by the user
  final List<WindowDesignTemplate> _customTemplates = [];
  List<WindowDesignTemplate> get customTemplates => _customTemplates;

  // ── Canvas pan/zoom ────────────────────────────────────────────────────────
  Offset _canvasOffset = Offset.zero;
  double _canvasScale = 1.0;
  Offset get canvasOffset => _canvasOffset;
  double get canvasScale => _canvasScale;

  // ── Grid ──────────────────────────────────────────────────────────────────
  bool _gridEnabled = true;
  double _gridSize = 20.0;
  bool get gridEnabled => _gridEnabled;
  double get gridSize => _gridSize;

  // ── Snap ──────────────────────────────────────────────────────────────────
  bool _snapEnabled = true;
  bool get snapEnabled => _snapEnabled;

  // ── History ───────────────────────────────────────────────────────────────
  final List<HistoryState> _undoStack = [];
  final List<HistoryState> _redoStack = [];

  // ── Saved Projects ────────────────────────────────────────────────────────
  final List<WindowProject> _savedProjects = [];
  String? _currentProjectId;

  final List<WindowDesignTemplate> templates =
      List.from(WindowDesignTemplate.defaultTemplates);

  static const List<WindowTheme> availableThemes = WindowTheme.presets;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  Uint8List? get backgroundImage => _backgroundImage;
  List<ActiveWindow> get activeWindows => _activeWindows;
  int get selectedWindowIndex => _selectedWindowIndex;
  Set<int> get multiSelectedIndices => _multiSelectedIndices;
  List<WindowProject> get savedProjects => _savedProjects;
  String? get currentProjectId => _currentProjectId;

  ActiveWindow? get selectedWindow =>
      (_selectedWindowIndex >= 0 && _selectedWindowIndex < _activeWindows.length)
          ? _activeWindows[_selectedWindowIndex]
          : null;

  List<WindowDesignTemplate> get filteredTemplates {
    if (selectedWindow == null) return [];
    return templates.where((t) => t.category == selectedWindow!.category).toList();
  }

  int get selectedTemplateIndex {
    if (selectedWindow == null) return 0;
    final filtered = filteredTemplates;
    return filtered.indexWhere((t) => t.id == selectedWindow!.template.id);
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  WindowDesignerProvider() {
    _loadProjectsFromPrefs();
  }

  // ── View mode ──────────────────────────────────────────────────────────────
  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.preview3D
        ? ViewMode.drawing2D
        : ViewMode.preview3D;
    notifyListeners();
  }

  // ── Canvas pan/zoom ────────────────────────────────────────────────────────
  void panCanvas(Offset delta) {
    _canvasOffset += delta;
    notifyListeners();
  }

  void zoomCanvas(double scaleDelta, Offset focalPoint) {
    final newScale = (_canvasScale * scaleDelta).clamp(0.25, 8.0);
    final scaleChange = newScale / _canvasScale;
    _canvasOffset = focalPoint + (_canvasOffset - focalPoint) * scaleChange;
    _canvasScale = newScale;
    notifyListeners();
  }

  void resetCanvasTransform() {
    _canvasOffset = Offset.zero;
    _canvasScale = 1.0;
    notifyListeners();
  }

  // ── Grid & Snap ────────────────────────────────────────────────────────────
  void toggleGrid() {
    _gridEnabled = !_gridEnabled;
    notifyListeners();
  }

  void toggleSnap() {
    _snapEnabled = !_snapEnabled;
    notifyListeners();
  }

  void setGridSize(double size) {
    _gridSize = size.clamp(5.0, 100.0);
    notifyListeners();
  }

  // ── History ───────────────────────────────────────────────────────────────
  void saveHistoryState() {
    _redoStack.clear();
    _undoStack.add(HistoryState(
      windows: _activeWindows.map((w) => w.copyWith()).toList(),
      selectedWindowIndex: _selectedWindowIndex,
    ));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(HistoryState(
      windows: _activeWindows.map((w) => w.copyWith()).toList(),
      selectedWindowIndex: _selectedWindowIndex,
    ));
    final prev = _undoStack.removeLast();
    _activeWindows
      ..clear()
      ..addAll(prev.windows);
    _selectedWindowIndex = prev.selectedWindowIndex;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(HistoryState(
      windows: _activeWindows.map((w) => w.copyWith()).toList(),
      selectedWindowIndex: _selectedWindowIndex,
    ));
    final next = _redoStack.removeLast();
    _activeWindows
      ..clear()
      ..addAll(next.windows);
    _selectedWindowIndex = next.selectedWindowIndex;
    notifyListeners();
  }

  // ── Image / background ────────────────────────────────────────────────────
  Future<void> pickBackgroundImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _backgroundImage = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

  void clearBackgroundImage() {
    _backgroundImage = null;
    notifyListeners();
  }

  // ── Window CRUD ───────────────────────────────────────────────────────────
  void addWindow({WindowDesignTemplate? template, Size? canvasSize}) {
    saveHistoryState();
    final tpl = template ?? templates.first;
    final cs = canvasSize ?? const Size(400, 600);
    final cx = cs.width / 2;
    final cy = cs.height / 2;
    const hw = 100.0, hh = 125.0;
    final newWindow = ActiveWindow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      template: tpl,
      category: tpl.category,
      theme: availableThemes.first,
      corners: [
        Offset(cx - hw, cy - hh),
        Offset(cx + hw, cy - hh),
        Offset(cx + hw, cy + hh),
        Offset(cx - hw, cy + hh),
      ],
      logicalWidth: 1200.0,
      logicalHeight: 1500.0,
    );
    _activeWindows.add(newWindow);
    _selectedWindowIndex = _activeWindows.length - 1;
    notifyListeners();
  }

  void selectWindow(int index) {
    _selectedWindowIndex = index;
    _multiSelectedIndices.clear();
    notifyListeners();
  }

  void toggleMultiSelect(int index) {
    if (_multiSelectedIndices.contains(index)) {
      _multiSelectedIndices.remove(index);
    } else {
      _multiSelectedIndices.add(index);
    }
    notifyListeners();
  }

  void removeWindow(int index) {
    if (index < 0 || index >= _activeWindows.length) return;
    saveHistoryState();
    _activeWindows.removeAt(index);
    _selectedWindowIndex = _activeWindows.isEmpty ? -1 : 0;
    notifyListeners();
  }

  /// Duplicate the window at [index] with a slight offset.
  void duplicateWindow(int index) {
    if (index < 0 || index >= _activeWindows.length) return;
    saveHistoryState();
    final src = _activeWindows[index];
    const offset = Offset(20, 20);
    final dup = ActiveWindow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      template: src.template,
      category: src.category,
      theme: src.theme,
      corners: src.corners.map((c) => c + offset).toList(),
      logicalWidth: src.logicalWidth,
      logicalHeight: src.logicalHeight,
      openFactor: src.openFactor,
      rotation: src.rotation,
      scale: src.scale,
      opacity: src.opacity,
      tint: src.tint,
      label: src.label.isEmpty ? '' : '${src.label} copy',
      paneTypes: List.from(src.paneTypes),
    );
    _activeWindows.insert(index + 1, dup);
    _selectedWindowIndex = index + 1;
    notifyListeners();
  }

  void bringToFront(int index) {
    if (index < 0 || index >= _activeWindows.length - 1) return;
    saveHistoryState();
    final w = _activeWindows.removeAt(index);
    _activeWindows.add(w);
    _selectedWindowIndex = _activeWindows.length - 1;
    notifyListeners();
  }

  void sendToBack(int index) {
    if (index <= 0 || index >= _activeWindows.length) return;
    saveHistoryState();
    final w = _activeWindows.removeAt(index);
    _activeWindows.insert(0, w);
    _selectedWindowIndex = 0;
    notifyListeners();
  }

  void lockWindow(int index, bool locked) {
    if (index < 0 || index >= _activeWindows.length) return;
    _activeWindows[index].isLocked = locked;
    notifyListeners();
  }

  // ── Transform operations ──────────────────────────────────────────────────
  void flipSelectedWindow({bool horizontal = false, bool vertical = false}) {
    if (selectedWindow == null || selectedWindow!.isLocked) return;
    saveHistoryState();
    selectedWindow!.corners = GeometryUtils.flipCorners(
      selectedWindow!.corners,
      horizontal: horizontal,
      vertical: vertical,
    );
    notifyListeners();
  }

  void rotateSelectedWindow(double deltaAngle) {
    if (selectedWindow == null || selectedWindow!.isLocked) return;
    final center = selectedWindow!.centroid;
    selectedWindow!.corners = GeometryUtils.rotateCorners(
      selectedWindow!.corners,
      deltaAngle,
      center,
    );
    selectedWindow!.rotation = (selectedWindow!.rotation + deltaAngle) % (2 * 3.14159265);
    notifyListeners();
  }

  void scaleSelectedWindow(double scaleFactor) {
    if (selectedWindow == null || selectedWindow!.isLocked) return;
    final center = selectedWindow!.centroid;
    selectedWindow!.corners = GeometryUtils.scaleCorners(
      selectedWindow!.corners,
      scaleFactor,
      center,
    );
    selectedWindow!.scale = (selectedWindow!.scale * scaleFactor).clamp(0.1, 10.0);
    notifyListeners();
  }

  void alignSelected(AlignType type, Size canvasSize) {
    if (selectedWindow == null || selectedWindow!.isLocked) return;
    saveHistoryState();
    selectedWindow!.corners = GeometryUtils.alignCorners(
      selectedWindow!.corners,
      type,
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
    );
    notifyListeners();
  }

  // ── Property updates ──────────────────────────────────────────────────────
  void updateCustomPanes(List<List<Offset>> newPanes) {
    if (selectedWindow != null) {
      selectedWindow!.template = selectedWindow!.template.copyWith(panes: newPanes);
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (selectedWindow == null) return;
    saveHistoryState();
    selectedWindow!.category = category;
    final matches = templates.where((t) => t.category == category).toList();
    if (matches.isNotEmpty) {
      selectedWindow!.template = matches.first;
      selectedWindow!.paneTypes = List<PaneType>.generate(
        selectedWindow!.template.panes.length,
        (i) => selectedWindow!.template.typeForPane(i),
      );
      if (selectedWindow!.template.exactWidth != null) {
        selectedWindow!.logicalWidth = selectedWindow!.template.exactWidth!;
      }
      if (selectedWindow!.template.exactHeight != null) {
        selectedWindow!.logicalHeight = selectedWindow!.template.exactHeight!;
      }
    }
    notifyListeners();
  }

  void selectTemplate(int index) {
    if (selectedWindow == null) return;
    final filtered = filteredTemplates;
    if (index < 0 || index >= filtered.length) return;
    saveHistoryState();
    selectedWindow!.template = filtered[index];
    selectedWindow!.paneTypes = List<PaneType>.generate(
      selectedWindow!.template.panes.length,
      (i) => selectedWindow!.template.typeForPane(i),
    );
    if (selectedWindow!.template.exactWidth != null) {
      selectedWindow!.logicalWidth = selectedWindow!.template.exactWidth!;
    }
    if (selectedWindow!.template.exactHeight != null) {
      selectedWindow!.logicalHeight = selectedWindow!.template.exactHeight!;
    }
    notifyListeners();
  }

  void setPaneType(int paneIndex, PaneType type) {
    if (selectedWindow == null) return;
    saveHistoryState();
    final types = List<PaneType>.from(selectedWindow!.paneTypes);
    while (types.length <= paneIndex) {
      types.add(PaneType.fixed);
    }
    types[paneIndex] = type;
    selectedWindow!.paneTypes = types;
    notifyListeners();
  }

  void updateWindow({
    List<Offset>? corners,
    double? logicalWidth,
    double? logicalHeight,
  }) {
    if (selectedWindow == null) return;
    if (corners != null) selectedWindow!.corners = corners;
    
    if (logicalWidth != null && selectedWindow!.logicalWidth > 0) {
      final scaleX = logicalWidth / selectedWindow!.logicalWidth;
      selectedWindow!.logicalWidth = logicalWidth;
      _scaleCornersNonUniform(scaleX, 1.0);
    }
    
    if (logicalHeight != null && selectedWindow!.logicalHeight > 0) {
      final scaleY = logicalHeight / selectedWindow!.logicalHeight;
      selectedWindow!.logicalHeight = logicalHeight;
      _scaleCornersNonUniform(1.0, scaleY);
    }
    notifyListeners();
  }

  void _scaleCornersNonUniform(double sx, double sy) {
    if (selectedWindow == null || selectedWindow!.isLocked) return;
    final center = selectedWindow!.centroid;
    selectedWindow!.corners = selectedWindow!.corners.map((c) {
      return Offset(
        center.dx + (c.dx - center.dx) * sx,
        center.dy + (c.dy - center.dy) * sy,
      );
    }).toList();
  }

  void updateWindowCornerDirect(int cornerIndex, Offset newPos) {
    if (selectedWindow == null || selectedWindow!.isLocked) return;
    final corners = List<Offset>.from(selectedWindow!.corners);
    // Remove grid snapping from direct corner drags so they can match perspective smoothly
    corners[cornerIndex] = newPos;
    selectedWindow!.corners = corners;
    notifyListeners();
  }

  void updateOpenFactor(double factor) {
    for (final w in _activeWindows) {
      w.openFactor = factor;
    }
    notifyListeners();
  }

  void setTheme(WindowTheme theme) {
    if (selectedWindow == null) return;
    saveHistoryState();
    selectedWindow!.theme = theme;
    notifyListeners();
  }

  void updateThemeProperty({
    Color? frameColor,
    double? frameThickness,
    double? glassOpacity,
    Color? glassColor,
    double? shadowBlur,
    double? shadowOpacity,
    double? reflectionOpacity,
    double? borderSize,
    FrameMaterial? material,
  }) {
    if (selectedWindow == null) return;
    selectedWindow!.theme = selectedWindow!.theme.copyWith(
      frameColor: frameColor,
      frameThickness: frameThickness,
      glassOpacity: glassOpacity,
      glassColor: glassColor,
      shadowBlur: shadowBlur,
      shadowOpacity: shadowOpacity,
      reflectionOpacity: reflectionOpacity,
      borderSize: borderSize,
      material: material,
    );
    notifyListeners();
  }

  void setOpacity(double opacity) {
    if (selectedWindow == null) return;
    selectedWindow!.opacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setTint(Color? color) {
    if (selectedWindow == null) return;
    selectedWindow!.tint = color;
    notifyListeners();
  }

  void setLabel(String label) {
    if (selectedWindow == null) return;
    selectedWindow!.label = label;
    notifyListeners();
  }

  void addCustomTemplate(WindowDesignTemplate template) {
    _customTemplates.add(template);
    if (selectedWindow != null) {
      saveHistoryState();
      selectedWindow!.category = 'Custom';
      selectedWindow!.template = template;
      selectedWindow!.paneTypes = List<PaneType>.generate(
        template.panes.length,
        (i) => template.typeForPane(i),
      );
      if (template.exactWidth != null) {
        selectedWindow!.logicalWidth = template.exactWidth!;
      }
      if (template.exactHeight != null) {
        selectedWindow!.logicalHeight = template.exactHeight!;
      }
    } else {
      _activeWindows.add(ActiveWindow(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        template: template,
        category: template.category,
        theme: availableThemes.first,
        corners: [
          const Offset(100, 100),
          const Offset(400, 100),
          const Offset(400, 400),
          const Offset(100, 400),
        ],
        logicalWidth: template.exactWidth ?? 1000,
        logicalHeight: template.exactHeight ?? 1000,
      ));
      _selectedWindowIndex = _activeWindows.length - 1;
    }
    notifyListeners();
  }

  // ── Projects ──────────────────────────────────────────────────────────────
  void saveProject(String projectName) {
    final id = _currentProjectId ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final newProject = WindowProject(
      id: id,
      projectName: projectName,
      windows: _activeWindows.map((w) => SavedWindow(
        templateId: w.template.id,
        category: w.category,
        themeName: w.theme.name,
        width: w.logicalWidth,
        height: w.logicalHeight,
        corners: w.corners,
        rotation: w.rotation,
        scale: w.scale,
        opacity: w.opacity,
        tintArgb: w.tint?.toARGB32(),
        isLocked: w.isLocked,
        label: w.label,
      )).toList(),
    );
    final index = _savedProjects.indexWhere((p) => p.id == id);
    if (index != -1) {
      _savedProjects[index] = newProject;
    } else {
      _savedProjects.add(newProject);
    }
    _currentProjectId = id;
    _persistProjects();
    notifyListeners();
  }

  void loadProject(WindowProject project) {
    _undoStack.clear();
    _redoStack.clear();
    _currentProjectId = project.id;
    _activeWindows.clear();

    for (final sw in project.windows) {
      final template = templates.firstWhere(
        (t) => t.id == sw.templateId,
        orElse: () => templates.first,
      );
      final theme = availableThemes.firstWhere(
        (t) => t.name == sw.themeName,
        orElse: () => availableThemes.first,
      );
      _activeWindows.add(ActiveWindow(
        id: DateTime.now().microsecondsSinceEpoch.toString() + sw.templateId,
        template: template,
        category: sw.category,
        theme: theme,
        corners: sw.corners,
        logicalWidth: sw.width,
        logicalHeight: sw.height,
        rotation: sw.rotation,
        scale: sw.scale,
        opacity: sw.opacity,
        tint: sw.tintArgb != null ? Color(sw.tintArgb!) : null,
        isLocked: sw.isLocked,
        label: sw.label,
      ));
    }
    _selectedWindowIndex = _activeWindows.isEmpty ? -1 : 0;
    notifyListeners();
  }

  void deleteProject(String id) {
    _savedProjects.removeWhere((p) => p.id == id);
    if (_currentProjectId == id) _currentProjectId = null;
    _persistProjects();
    notifyListeners();
  }



  void resetWindow() {
    saveHistoryState();
    _activeWindows.clear();
    _selectedWindowIndex = -1;
    _currentProjectId = null;
    notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<void> _persistProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _savedProjects.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList('kw_projects', jsonList);
    } catch (e) {
      debugPrint('Persist error: $e');
    }
  }

  Future<void> _loadProjectsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('kw_projects') ?? [];
      _savedProjects.clear();
      for (final jsonStr in jsonList) {
        try {
          _savedProjects.add(WindowProject.fromJson(jsonDecode(jsonStr)));
        } catch (_) {}
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load projects error: $e');
    }
  }
}
