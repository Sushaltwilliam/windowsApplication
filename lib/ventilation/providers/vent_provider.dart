import 'package:flutter/material.dart';
import '../models/vent_project.dart';

class VentProvider extends ChangeNotifier {
  final List<VentProject> _projects = [];
  int _selectedIndex = -1;

  List<VentProject> get projects => _projects;
  int get selectedIndex => _selectedIndex;

  VentProject? get selected =>
      (_selectedIndex >= 0 && _selectedIndex < _projects.length)
          ? _projects[_selectedIndex]
          : null;

  void addProject({VentProject? project}) {
    final p = project ??
        VentProject(id: DateTime.now().millisecondsSinceEpoch.toString());
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

  void updateWidth(double mm) {
    if (selected == null) return;
    selected!.widthMm = mm.clamp(100, 5000);
    notifyListeners();
  }

  void updateHeight(double mm) {
    if (selected == null) return;
    selected!.heightMm = mm.clamp(100, 5000);
    notifyListeners();
  }

  void updateVentType(VentType type) {
    if (selected == null) return;
    selected!.ventType = type;
    notifyListeners();
  }

  void updateMaterial(VentMaterial material) {
    if (selected == null) return;
    selected!.material = material;
    notifyListeners();
  }

  void updateFrameColor(Color color) {
    if (selected == null) return;
    selected!.frameColor = color;
    notifyListeners();
  }

  void updateBladeCount(int count) {
    if (selected == null) return;
    selected!.bladeCount = count.clamp(2, 30);
    notifyListeners();
  }

  void updateBladeAngle(double angle) {
    if (selected == null) return;
    selected!.bladeAngle = angle.clamp(0, 90);
    notifyListeners();
  }

  void updateBladeStyle(BladeStyle style) {
    if (selected == null) return;
    selected!.bladeStyle = style;
    notifyListeners();
  }

  void updateAdjustable(bool val) {
    if (selected == null) return;
    selected!.isAdjustable = val;
    notifyListeners();
  }

  void updateNotes(String notes) {
    if (selected == null) return;
    selected!.notes = notes;
    notifyListeners();
  }
}
