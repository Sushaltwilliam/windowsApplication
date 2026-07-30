import 'package:flutter/material.dart';

// ── Window material type ───────────────────────────────────────────────────────
enum FrameMaterial { aluminum, upvc, wood, steel, fiberglass }

extension FrameMaterialLabel on FrameMaterial {
  String get label {
    switch (this) {
      case FrameMaterial.aluminum:  return 'Aluminum';
      case FrameMaterial.upvc:      return 'uPVC';
      case FrameMaterial.wood:      return 'Wood';
      case FrameMaterial.steel:     return 'Steel';
      case FrameMaterial.fiberglass:return 'Fiberglass';
    }
  }
}

// ── Window Theme ───────────────────────────────────────────────────────────────
class WindowTheme {
  final String name;
  final Color frameColor;
  final double frameThickness;
  final double glassOpacity;

  // Enhanced fields
  final Color glassColor;
  final double shadowBlur;
  final double shadowOpacity;
  final double reflectionOpacity;
  final double borderSize;
  final FrameMaterial material;

  const WindowTheme({
    required this.name,
    required this.frameColor,
    required this.frameThickness,
    required this.glassOpacity,
    this.glassColor = const Color(0xFFB3D9F2),
    this.shadowBlur = 12.0,
    this.shadowOpacity = 0.35,
    this.reflectionOpacity = 0.18,
    this.borderSize = 1.5,
    this.material = FrameMaterial.aluminum,
  });

  WindowTheme copyWith({
    String? name,
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
    return WindowTheme(
      name: name ?? this.name,
      frameColor: frameColor ?? this.frameColor,
      frameThickness: frameThickness ?? this.frameThickness,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      glassColor: glassColor ?? this.glassColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      reflectionOpacity: reflectionOpacity ?? this.reflectionOpacity,
      borderSize: borderSize ?? this.borderSize,
      material: material ?? this.material,
    );
  }

  // ── Preset themes ─────────────────────────────────────────────────────────
  static const List<WindowTheme> presets = [
    WindowTheme(
      name: 'Classic White',
      frameColor: Color(0xFFF5F5F5),
      frameThickness: 5.0,
      glassOpacity: 0.22,
      glassColor: Color(0xFFB3D9F2),
      shadowBlur: 14,
      shadowOpacity: 0.3,
      reflectionOpacity: 0.2,
      material: FrameMaterial.aluminum,
    ),
    WindowTheme(
      name: 'Brushed Steel',
      frameColor: Color(0xFF90A4AE),
      frameThickness: 4.0,
      glassOpacity: 0.28,
      glassColor: Color(0xFFC8E6FA),
      shadowBlur: 10,
      shadowOpacity: 0.25,
      reflectionOpacity: 0.3,
      material: FrameMaterial.aluminum,
    ),
    WindowTheme(
      name: 'Matte Black',
      frameColor: Color(0xFF1A1A1A),
      frameThickness: 5.0,
      glassOpacity: 0.35,
      glassColor: Color(0xFF90CAF9),
      shadowBlur: 18,
      shadowOpacity: 0.5,
      reflectionOpacity: 0.12,
      material: FrameMaterial.aluminum,
    ),
    WindowTheme(
      name: 'Dark Wood',
      frameColor: Color(0xFF4E342E),
      frameThickness: 8.0,
      glassOpacity: 0.18,
      glassColor: Color(0xFFB3D9F2),
      shadowBlur: 16,
      shadowOpacity: 0.4,
      reflectionOpacity: 0.1,
      material: FrameMaterial.wood,
    ),
    WindowTheme(
      name: 'Bronze',
      frameColor: Color(0xFF8D6E63),
      frameThickness: 6.0,
      glassOpacity: 0.2,
      glassColor: Color(0xFFB8D4E8),
      shadowBlur: 12,
      shadowOpacity: 0.32,
      reflectionOpacity: 0.22,
      material: FrameMaterial.aluminum,
    ),
    WindowTheme(
      name: 'Rose Gold',
      frameColor: Color(0xFFE8A598),
      frameThickness: 4.5,
      glassOpacity: 0.25,
      glassColor: Color(0xFFFFE0D6),
      shadowBlur: 10,
      shadowOpacity: 0.2,
      reflectionOpacity: 0.25,
      material: FrameMaterial.aluminum,
    ),
    WindowTheme(
      name: 'Obsidian',
      frameColor: Color(0xFF212121),
      frameThickness: 5.5,
      glassOpacity: 0.4,
      glassColor: Color(0xFF78909C),
      shadowBlur: 20,
      shadowOpacity: 0.6,
      reflectionOpacity: 0.08,
      material: FrameMaterial.steel,
    ),
    WindowTheme(
      name: 'White uPVC',
      frameColor: Color(0xFFFFFFFF),
      frameThickness: 9.0,
      glassOpacity: 0.18,
      glassColor: Color(0xFFD0EAF9),
      shadowBlur: 8,
      shadowOpacity: 0.2,
      reflectionOpacity: 0.15,
      material: FrameMaterial.upvc,
    ),
  ];
}
