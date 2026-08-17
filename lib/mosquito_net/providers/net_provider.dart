import 'package:flutter/material.dart';
import '../models/net_project.dart';

class NetProvider extends ChangeNotifier {
  final List<NetProject> _projects = [];
  int _selectedIndex = -1;

  List<NetProject> get projects => _projects;
  int get selectedIndex => _selectedIndex;

  NetProject? get selected =>
      (_selectedIndex >= 0 && _selectedIndex < _projects.length)
          ? _projects[_selectedIndex]
          : null;

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void addProject({NetProject? project}) {
    final p = project ??
        NetProject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
    _projects.add(p);
    _selectedIndex = _projects.length - 1;
    notifyListeners();
  }

  void selectProject(int index) {
    if (index < 0 || index >= _projects.length) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void deleteProject(int index) {
    if (index < 0 || index >= _projects.length) return;
    _projects.removeAt(index);
    if (_selectedIndex >= _projects.length) {
      _selectedIndex = _projects.length - 1;
    }
    notifyListeners();
  }

  void duplicateProject(int index) {
    if (index < 0 || index >= _projects.length) return;
    final src = _projects[index];
    _projects.add(src.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${src.name} (copy)',
    ));
    _selectedIndex = _projects.length - 1;
    notifyListeners();
  }

  // ── Property Updates ──────────────────────────────────────────────────────

  void updateName(String name) {
    if (selected == null) return;
    selected!.name = name;
    notifyListeners();
  }

  void updateWidth(double mm) {
    if (selected == null) return;
    selected!.widthMm = mm.clamp(100, 10000);
    notifyListeners();
  }

  void updateHeight(double mm) {
    if (selected == null) return;
    selected!.heightMm = mm.clamp(100, 10000);
    notifyListeners();
  }

  void updateMeshType(MeshType type) {
    if (selected == null) return;
    selected!.meshType = type;
    notifyListeners();
  }

  void updateFrameType(NetFrameType type) {
    if (selected == null) return;
    selected!.frameType = type;
    notifyListeners();
  }

  void updateFrameColor(Color color) {
    if (selected == null) return;
    selected!.frameColor = color;
    notifyListeners();
  }

  void updatePanels(int count) {
    if (selected == null) return;
    selected!.panels = count.clamp(1, 4);
    notifyListeners();
  }

  void updateNotes(String notes) {
    if (selected == null) return;
    selected!.notes = notes;
    notifyListeners();
  }
}
