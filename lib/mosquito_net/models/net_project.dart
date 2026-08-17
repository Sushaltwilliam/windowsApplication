import 'package:flutter/material.dart';

/// Mesh material types for mosquito nets
enum MeshType {
  fiberglass,
  stainlessSS304,
  aluminum,
  polyester,
  nylon,
}

extension MeshTypeExt on MeshType {
  String get label {
    switch (this) {
      case MeshType.fiberglass:
        return 'Fiberglass';
      case MeshType.stainlessSS304:
        return 'SS 304';
      case MeshType.aluminum:
        return 'Aluminum';
      case MeshType.polyester:
        return 'Polyester';
      case MeshType.nylon:
        return 'Nylon';
    }
  }

  String get description {
    switch (this) {
      case MeshType.fiberglass:
        return 'Lightweight, corrosion-resistant, budget-friendly';
      case MeshType.stainlessSS304:
        return 'High durability, anti-rust, premium finish';
      case MeshType.aluminum:
        return 'Rigid, long-lasting, good airflow';
      case MeshType.polyester:
        return 'Flexible, easy to clean, moderate life';
      case MeshType.nylon:
        return 'Soft, UV-resistant, economical';
    }
  }

  Color get color {
    switch (this) {
      case MeshType.fiberglass:
        return const Color(0xFF90A4AE);
      case MeshType.stainlessSS304:
        return const Color(0xFFB0BEC5);
      case MeshType.aluminum:
        return const Color(0xFFCFD8DC);
      case MeshType.polyester:
        return const Color(0xFF78909C);
      case MeshType.nylon:
        return const Color(0xFF607D8B);
    }
  }
}

/// Frame type for mosquito net mounting
enum NetFrameType {
  slidingChannel,
  hingedDoor,
  magnetic,
  velcro,
  rollUp,
  pleated,
}

extension NetFrameTypeExt on NetFrameType {
  String get label {
    switch (this) {
      case NetFrameType.slidingChannel:
        return 'Sliding Channel';
      case NetFrameType.hingedDoor:
        return 'Hinged Door';
      case NetFrameType.magnetic:
        return 'Magnetic Strip';
      case NetFrameType.velcro:
        return 'Velcro Mount';
      case NetFrameType.rollUp:
        return 'Roll-Up';
      case NetFrameType.pleated:
        return 'Pleated';
    }
  }

  IconData get icon {
    switch (this) {
      case NetFrameType.slidingChannel:
        return Icons.swap_horiz;
      case NetFrameType.hingedDoor:
        return Icons.door_front_door_outlined;
      case NetFrameType.magnetic:
        return Icons.attractions;
      case NetFrameType.velcro:
        return Icons.layers_outlined;
      case NetFrameType.rollUp:
        return Icons.arrow_upward;
      case NetFrameType.pleated:
        return Icons.view_day_outlined;
    }
  }
}

/// Frame color presets
class NetFrameColor {
  final String name;
  final Color color;

  const NetFrameColor(this.name, this.color);

  static const List<NetFrameColor> presets = [
    NetFrameColor('White', Color(0xFFFFFFFF)),
    NetFrameColor('Black', Color(0xFF212121)),
    NetFrameColor('Brown', Color(0xFF5D4037)),
    NetFrameColor('Grey', Color(0xFF9E9E9E)),
    NetFrameColor('Silver', Color(0xFFBDBDBD)),
    NetFrameColor('Champagne', Color(0xFFD4AF37)),
    NetFrameColor('Wood Finish', Color(0xFF8D6E63)),
    NetFrameColor('Dark Bronze', Color(0xFF4E342E)),
  ];
}

/// A single mosquito net design/measurement
class NetProject {
  final String id;
  String name;
  double widthMm;
  double heightMm;
  MeshType meshType;
  NetFrameType frameType;
  Color frameColor;
  int panels; // Number of panels (1 for single, 2 for double sliding etc.)
  String notes;
  DateTime createdAt;

  NetProject({
    required this.id,
    this.name = 'Untitled Net',
    this.widthMm = 1200,
    this.heightMm = 1500,
    this.meshType = MeshType.fiberglass,
    this.frameType = NetFrameType.slidingChannel,
    this.frameColor = const Color(0xFFFFFFFF),
    this.panels = 1,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get areaSqM => (widthMm / 1000) * (heightMm / 1000);

  NetProject copyWith({
    String? id,
    String? name,
    double? widthMm,
    double? heightMm,
    MeshType? meshType,
    NetFrameType? frameType,
    Color? frameColor,
    int? panels,
    String? notes,
  }) {
    return NetProject(
      id: id ?? this.id,
      name: name ?? this.name,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      meshType: meshType ?? this.meshType,
      frameType: frameType ?? this.frameType,
      frameColor: frameColor ?? this.frameColor,
      panels: panels ?? this.panels,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
