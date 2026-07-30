import 'package:flutter/material.dart';

class WindowProject {
  final String id;
  final String projectName;
  final String? backgroundImagePath;
  final List<SavedWindow> windows;
  final DateTime lastModified;

  WindowProject({
    required this.id,
    required this.projectName,
    required this.windows,
    this.backgroundImagePath,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectName': projectName,
    'backgroundImagePath': backgroundImagePath,
    'windows': windows.map((w) => w.toJson()).toList(),
    'lastModified': lastModified.toIso8601String(),
  };

  factory WindowProject.fromJson(Map<String, dynamic> json) => WindowProject(
    id: json['id'],
    projectName: json['projectName'],
    backgroundImagePath: json['backgroundImagePath'],
    windows: (json['windows'] as List).map((w) => SavedWindow.fromJson(w)).toList(),
    lastModified: json['lastModified'] != null
        ? DateTime.tryParse(json['lastModified']) ?? DateTime.now()
        : DateTime.now(),
  );
}

class SavedWindow {
  final String templateId;
  final String category;
  final String themeName;
  final double width;
  final double height;
  final List<Offset> corners;

  // Enhanced properties
  final double rotation;
  final double scale;
  final double opacity;
  final int? tintArgb; // null means no tint
  final bool isLocked;
  final String label;

  SavedWindow({
    required this.templateId,
    required this.category,
    required this.themeName,
    required this.width,
    required this.height,
    required this.corners,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.tintArgb,
    this.isLocked = false,
    this.label = '',
  });

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'category': category,
    'themeName': themeName,
    'width': width,
    'height': height,
    'corners': corners.map((c) => {'dx': c.dx, 'dy': c.dy}).toList(),
    'rotation': rotation,
    'scale': scale,
    'opacity': opacity,
    'tintArgb': tintArgb,
    'isLocked': isLocked,
    'label': label,
  };

  factory SavedWindow.fromJson(Map<String, dynamic> json) => SavedWindow(
    templateId: json['templateId'],
    category: json['category'],
    themeName: json['themeName'],
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    corners: (json['corners'] as List)
        .map((c) => Offset(
              (c['dx'] as num).toDouble(),
              (c['dy'] as num).toDouble(),
            ))
        .toList(),
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    tintArgb: json['tintArgb'] as int?,
    isLocked: json['isLocked'] as bool? ?? false,
    label: json['label'] as String? ?? '',
  );
}
