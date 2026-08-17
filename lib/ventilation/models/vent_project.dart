import 'package:flutter/material.dart';

/// Ventilation product types
enum VentType {
  louver,
  exhaustFrame,
  trickleVent,
  fixedGrill,
}

extension VentTypeExt on VentType {
  String get label {
    switch (this) {
      case VentType.louver:
        return 'Louver';
      case VentType.exhaustFrame:
        return 'Exhaust Frame';
      case VentType.trickleVent:
        return 'Trickle Vent';
      case VentType.fixedGrill:
        return 'Fixed Grill';
    }
  }

  String get description {
    switch (this) {
      case VentType.louver:
        return 'Angled blades for airflow & privacy';
      case VentType.exhaustFrame:
        return 'Frame for exhaust fan mounting';
      case VentType.trickleVent:
        return 'Narrow slot vent above windows';
      case VentType.fixedGrill:
        return 'Non-adjustable ventilation grille';
    }
  }

  IconData get icon {
    switch (this) {
      case VentType.louver:
        return Icons.blinds;
      case VentType.exhaustFrame:
        return Icons.air;
      case VentType.trickleVent:
        return Icons.density_small;
      case VentType.fixedGrill:
        return Icons.grid_on;
    }
  }
}

/// Louver blade style
enum BladeStyle {
  flat,
  curved,
  zShaped,
}

extension BladeStyleExt on BladeStyle {
  String get label {
    switch (this) {
      case BladeStyle.flat:
        return 'Flat';
      case BladeStyle.curved:
        return 'Curved';
      case BladeStyle.zShaped:
        return 'Z-Shaped';
    }
  }
}

/// Frame material
enum VentMaterial {
  aluminum,
  upvc,
  galvanizedSteel,
}

extension VentMaterialExt on VentMaterial {
  String get label {
    switch (this) {
      case VentMaterial.aluminum:
        return 'Aluminum';
      case VentMaterial.upvc:
        return 'uPVC';
      case VentMaterial.galvanizedSteel:
        return 'Galvanized Steel';
    }
  }
}

class VentProject {
  final String id;
  String name;
  double widthMm;
  double heightMm;
  VentType ventType;
  VentMaterial material;
  Color frameColor;
  int bladeCount;
  double bladeAngle; // degrees 0-90
  BladeStyle bladeStyle;
  bool isAdjustable;
  String notes;
  DateTime createdAt;

  VentProject({
    required this.id,
    this.name = 'Untitled Vent',
    this.widthMm = 600,
    this.heightMm = 400,
    this.ventType = VentType.louver,
    this.material = VentMaterial.aluminum,
    this.frameColor = const Color(0xFFBDBDBD),
    this.bladeCount = 8,
    this.bladeAngle = 45,
    this.bladeStyle = BladeStyle.flat,
    this.isAdjustable = true,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get areaSqM => (widthMm / 1000) * (heightMm / 1000);

  VentProject copyWith({
    String? id,
    String? name,
    double? widthMm,
    double? heightMm,
    VentType? ventType,
    VentMaterial? material,
    Color? frameColor,
    int? bladeCount,
    double? bladeAngle,
    BladeStyle? bladeStyle,
    bool? isAdjustable,
    String? notes,
  }) {
    return VentProject(
      id: id ?? this.id,
      name: name ?? this.name,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      ventType: ventType ?? this.ventType,
      material: material ?? this.material,
      frameColor: frameColor ?? this.frameColor,
      bladeCount: bladeCount ?? this.bladeCount,
      bladeAngle: bladeAngle ?? this.bladeAngle,
      bladeStyle: bladeStyle ?? this.bladeStyle,
      isAdjustable: isAdjustable ?? this.isAdjustable,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
