import 'package:flutter/material.dart';

/// Represents a single drawn vector line (mullion or transom) inside the CAD canvas.
class VectorLine {
  final String id;
  Offset startPoint; // Top/Left anchor
  Offset endPoint;   // Bottom/Right anchor
  bool isVertical;
  double thickness;
  Color color;
  bool isSelected;

  VectorLine({
    required this.id,
    required this.startPoint,
    required this.endPoint,
    required this.isVertical,
    this.thickness = 10.0, // default 10mm thickness
    this.color = const Color(0xFF555555),
    this.isSelected = false,
  });

  /// The physical bounding box of the line.
  Rect get boundingBox {
    final left = isVertical ? startPoint.dx - thickness / 2 : startPoint.dx;
    final top = isVertical ? startPoint.dy : startPoint.dy - thickness / 2;
    final right = isVertical ? startPoint.dx + thickness / 2 : endPoint.dx;
    final bottom = isVertical ? endPoint.dy : startPoint.dy + thickness / 2;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Exact length of the line
  double get length => (endPoint - startPoint).distance;

  /// Hit testing: true if the point falls on the line (with some padding for easy selection)
  bool hitTest(Offset point, {double padding = 15.0}) {
    final bb = boundingBox;
    final hitZone = Rect.fromLTRB(
      bb.left - padding,
      bb.top - padding,
      bb.right + padding,
      bb.bottom + padding,
    );
    return hitZone.contains(point);
  }

  /// Copies the object with modified properties
  VectorLine copyWith({
    String? id,
    Offset? startPoint,
    Offset? endPoint,
    bool? isVertical,
    double? thickness,
    Color? color,
    bool? isSelected,
  }) {
    return VectorLine(
      id: id ?? this.id,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      isVertical: isVertical ?? this.isVertical,
      thickness: thickness ?? this.thickness,
      color: color ?? this.color,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'startX': startPoint.dx,
    'startY': startPoint.dy,
    'endX': endPoint.dx,
    'endY': endPoint.dy,
    'isVertical': isVertical,
    'thickness': thickness,
    'colorValue': color.toARGB32(),
  };

  /// Deserialize from JSON
  factory VectorLine.fromJson(Map<String, dynamic> json) {
    return VectorLine(
      id: json['id'] as String,
      startPoint: Offset((json['startX'] as num).toDouble(), (json['startY'] as num).toDouble()),
      endPoint: Offset((json['endX'] as num).toDouble(), (json['endY'] as num).toDouble()),
      isVertical: json['isVertical'] as bool,
      thickness: (json['thickness'] as num).toDouble(),
      color: Color(json['colorValue'] as int),
    );
  }
}
