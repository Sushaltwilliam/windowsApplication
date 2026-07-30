import 'package:flutter/material.dart';
import 'vector_line.dart';

// ── Pane opening type ────────────────────────────────────────────────────────
enum PaneType { fixed, awning, sliding, casement, door, tiltTurn, bottomHung, bifolding }

extension PaneTypeLabel on PaneType {
  String get label {
    switch (this) {
      case PaneType.fixed:      return 'Fixed';
      case PaneType.awning:     return 'Awning';
      case PaneType.sliding:    return 'Sliding';
      case PaneType.casement:   return 'Casement';
      case PaneType.door:       return 'Door';
      case PaneType.tiltTurn:   return 'Tilt-Turn';
      case PaneType.bottomHung: return 'Bottom Hung';
      case PaneType.bifolding:  return 'Bifolding';
    }
  }

  String get prefix {
    switch (this) {
      case PaneType.fixed:      return 'F';
      case PaneType.awning:     return 'A';
      case PaneType.sliding:    return 'S';
      case PaneType.casement:   return 'C';
      case PaneType.door:       return 'D';
      case PaneType.tiltTurn:   return 'T';
      case PaneType.bottomHung: return 'B';
      case PaneType.bifolding:  return 'BF';
    }
  }
}

// ── Template category ─────────────────────────────────────────────────────────
enum TemplateCategory { rectangle, circle, triangle, door, combination, other, custom }

extension TemplateCategoryLabel on TemplateCategory {
  String get label {
    switch (this) {
      case TemplateCategory.rectangle:   return 'Rectangle';
      case TemplateCategory.circle:      return 'Circle';
      case TemplateCategory.triangle:    return 'Triangle';
      case TemplateCategory.door:        return 'Door';
      case TemplateCategory.combination: return 'Combination';
      case TemplateCategory.other:       return 'Other';
      case TemplateCategory.custom:      return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case TemplateCategory.rectangle:   return Icons.crop_square;
      case TemplateCategory.circle:      return Icons.circle_outlined;
      case TemplateCategory.triangle:    return Icons.change_history;
      case TemplateCategory.door:        return Icons.door_front_door_outlined;
      case TemplateCategory.combination: return Icons.table_chart_outlined;
      case TemplateCategory.other:       return Icons.hexagon_outlined;
      case TemplateCategory.custom:      return Icons.draw_outlined;
    }
  }
}

// ── Window Design Template ────────────────────────────────────────────────────
class WindowDesignTemplate {
  final String id;
  final String name;
  final String category; // keeps backward compat as string
  final List<List<Offset>> panes;
  /// Pane type per pane index; defaults to PaneType.fixed when shorter than panes.
  final List<PaneType> paneTypes;
  /// Optional exact width/height when defined via Freehand mode
  final double? exactWidth;
  final double? exactHeight;
  /// Icon for template picker UI
  final IconData? icon;
  /// Short description
  final String description;
  /// Drawn vector lines for custom templates
  final List<VectorLine>? vectorLines;

  const WindowDesignTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.panes,
    this.paneTypes = const [],
    this.exactWidth,
    this.exactHeight,
    this.icon,
    this.description = '',
    this.vectorLines,
  });

  /// Returns the type for a given pane index (falls back to fixed).
  PaneType typeForPane(int index) {
    if (index < paneTypes.length) return paneTypes[index];
    return PaneType.fixed;
  }

  WindowDesignTemplate copyWith({
    String? id,
    String? name,
    String? category,
    List<List<Offset>>? panes,
    List<PaneType>? paneTypes,
    double? exactWidth,
    double? exactHeight,
    IconData? icon,
    String? description,
    List<VectorLine>? vectorLines,
  }) {
    return WindowDesignTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      panes: panes ?? this.panes,
      paneTypes: paneTypes ?? this.paneTypes,
      exactWidth: exactWidth ?? this.exactWidth,
      exactHeight: exactHeight ?? this.exactHeight,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      vectorLines: vectorLines ?? this.vectorLines,
    );
  }

  static final List<WindowDesignTemplate> defaultTemplates = [
    // ── CUSTOM ───────────────────────────────────────────────────────────────
    WindowDesignTemplate(
      id: 'blank_canvas',
      name: 'Blank Canvas',
      category: 'Custom',
      description: 'Start from scratch',
      icon: Icons.draw_outlined,
      panes: [
        [const Offset(0, 0), const Offset(100, 0), const Offset(100, 100), const Offset(0, 100)],
      ],
      paneTypes: [PaneType.fixed],
    ),

    // ── RECTANGLES ────────────────────────────────────────────────────────────
    WindowDesignTemplate(
      id: 'single_pane',
      name: 'Single Pane',
      category: 'Rectangle',
      description: 'One fixed glass panel',
      icon: Icons.crop_square,
      panes: [
        [const Offset(0, 0), const Offset(100, 0), const Offset(100, 100), const Offset(0, 100)],
      ],
      paneTypes: [PaneType.fixed],
    ),
    WindowDesignTemplate(
      id: 'double_vertical',
      name: 'Double Horizontal Split',
      category: 'Rectangle',
      description: 'Two panes stacked vertically',
      panes: [
        [const Offset(0, 0), const Offset(100, 0), const Offset(100, 50), const Offset(0, 50)],
        [const Offset(0, 50), const Offset(100, 50), const Offset(100, 100), const Offset(0, 100)],
      ],
      paneTypes: [PaneType.fixed, PaneType.awning],
    ),
    WindowDesignTemplate(
      id: 'double_horizontal',
      name: 'Double Vertical Split',
      category: 'Rectangle',
      description: 'Two casement panes side by side',
      panes: [
        [const Offset(0, 0), const Offset(50, 0), const Offset(50, 100), const Offset(0, 100)],
        [const Offset(50, 0), const Offset(100, 0), const Offset(100, 100), const Offset(50, 100)],
      ],
      paneTypes: [PaneType.casement, PaneType.casement],
    ),
    WindowDesignTemplate(
      id: 'triple_vertical',
      name: 'Triple Vertical Split',
      category: 'Rectangle',
      description: 'Three panes side by side',
      panes: [
        [const Offset(0, 0), const Offset(33.3, 0), const Offset(33.3, 100), const Offset(0, 100)],
        [const Offset(33.3, 0), const Offset(66.6, 0), const Offset(66.6, 100), const Offset(33.3, 100)],
        [const Offset(66.6, 0), const Offset(100, 0), const Offset(100, 100), const Offset(66.6, 100)],
      ],
      paneTypes: [PaneType.casement, PaneType.fixed, PaneType.casement],
    ),
    WindowDesignTemplate(
      id: 'sliding_2',
      name: 'Sliding Window',
      category: 'Rectangle',
      description: 'Two overlapping sliding sashes',
      panes: [
        [const Offset(0, 0), const Offset(55, 0), const Offset(55, 100), const Offset(0, 100)],
        [const Offset(45, 0), const Offset(100, 0), const Offset(100, 100), const Offset(45, 100)],
      ],
      paneTypes: [PaneType.sliding, PaneType.sliding],
    ),
    WindowDesignTemplate(
      id: 'grid_4',
      name: '4-Pane Grid',
      category: 'Rectangle',
      description: '2×2 grid layout',
      panes: [
        [const Offset(0, 0), const Offset(50, 0), const Offset(50, 50), const Offset(0, 50)],
        [const Offset(50, 0), const Offset(100, 0), const Offset(100, 50), const Offset(50, 50)],
        [const Offset(0, 50), const Offset(50, 50), const Offset(50, 100), const Offset(0, 100)],
        [const Offset(50, 50), const Offset(100, 50), const Offset(100, 100), const Offset(50, 100)],
      ],
      paneTypes: [PaneType.fixed, PaneType.fixed, PaneType.awning, PaneType.awning],
    ),
    WindowDesignTemplate(
      id: 'grid_6',
      name: '6-Pane Grid',
      category: 'Rectangle',
      description: '2×3 grid layout',
      panes: [
        for (int i = 0; i < 2; i++)
          for (int j = 0; j < 3; j++)
            [
              Offset(j * 33.3, i * 50.0),
              Offset((j + 1) * 33.3, i * 50.0),
              Offset((j + 1) * 33.3, (i + 1) * 50.0),
              Offset(j * 33.3, (i + 1) * 50.0),
            ],
      ],
    ),
    WindowDesignTemplate(
      id: 'grid_9',
      name: '9-Pane Grid',
      category: 'Rectangle',
      description: '3×3 grid layout',
      panes: [
        for (int i = 0; i < 3; i++)
          for (int j = 0; j < 3; j++)
            [
              Offset(j * 33.3, i * 33.3),
              Offset((j + 1) * 33.3, i * 33.3),
              Offset((j + 1) * 33.3, (i + 1) * 33.3),
              Offset(j * 33.3, (i + 1) * 33.3),
            ],
      ],
      paneTypes: [
        PaneType.fixed, PaneType.fixed, PaneType.fixed,
        PaneType.awning, PaneType.awning, PaneType.awning,
        PaneType.fixed, PaneType.fixed, PaneType.fixed,
      ],
    ),
    WindowDesignTemplate(
      id: 'combination_door_window',
      name: 'Door + Side Window',
      category: 'Combination',
      description: 'Door panel with flanking fixed glass',
      panes: [
        // Left fixed pane
        [const Offset(0, 0), const Offset(25, 0), const Offset(25, 100), const Offset(0, 100)],
        // Door pane
        [const Offset(25, 0), const Offset(75, 0), const Offset(75, 100), const Offset(25, 100)],
        // Right fixed pane
        [const Offset(75, 0), const Offset(100, 0), const Offset(100, 100), const Offset(75, 100)],
      ],
      paneTypes: [PaneType.fixed, PaneType.door, PaneType.fixed],
    ),
    WindowDesignTemplate(
      id: 'combination_fanlight',
      name: 'Window + Fanlight',
      category: 'Combination',
      description: 'Main window with top fanlight',
      panes: [
        // Top fanlight
        [const Offset(0, 0), const Offset(100, 0), const Offset(100, 20), const Offset(0, 20)],
        // Left casement
        [const Offset(0, 20), const Offset(50, 20), const Offset(50, 100), const Offset(0, 100)],
        // Right casement
        [const Offset(50, 20), const Offset(100, 20), const Offset(100, 100), const Offset(50, 100)],
      ],
      paneTypes: [PaneType.awning, PaneType.casement, PaneType.casement],
    ),

    // ── DOORS ─────────────────────────────────────────────────────────────────
    WindowDesignTemplate(
      id: 'single_door',
      name: 'Single Door',
      category: 'Door',
      description: 'Standard single door',
      icon: Icons.door_front_door_outlined,
      panes: [
        [const Offset(0, 0), const Offset(100, 0), const Offset(100, 100), const Offset(0, 100)],
      ],
      paneTypes: [PaneType.door],
    ),
    WindowDesignTemplate(
      id: 'double_door',
      name: 'Double Door',
      category: 'Door',
      description: 'French double door',
      panes: [
        [const Offset(0, 0), const Offset(50, 0), const Offset(50, 100), const Offset(0, 100)],
        [const Offset(50, 0), const Offset(100, 0), const Offset(100, 100), const Offset(50, 100)],
      ],
      paneTypes: [PaneType.door, PaneType.door],
    ),
    WindowDesignTemplate(
      id: 'door_with_fanlight',
      name: 'Door + Fanlight',
      category: 'Door',
      description: 'Door with glazed top panel',
      panes: [
        [const Offset(0, 0), const Offset(100, 0), const Offset(100, 20), const Offset(0, 20)],
        [const Offset(0, 20), const Offset(100, 20), const Offset(100, 100), const Offset(0, 100)],
      ],
      paneTypes: [PaneType.fixed, PaneType.door],
    ),
    WindowDesignTemplate(
      id: 'sliding_door',
      name: 'Sliding Door',
      category: 'Door',
      description: 'Wide sliding patio door',
      panes: [
        [const Offset(0, 0), const Offset(55, 0), const Offset(55, 100), const Offset(0, 100)],
        [const Offset(45, 0), const Offset(100, 0), const Offset(100, 100), const Offset(45, 100)],
      ],
      paneTypes: [PaneType.sliding, PaneType.door],
    ),
    WindowDesignTemplate(
      id: 'bifolding_door',
      name: 'Bifolding Door',
      category: 'Door',
      description: '4-panel bifolding door',
      panes: [
        for (int j = 0; j < 4; j++)
          [
            Offset(j * 25.0, 0),
            Offset((j + 1) * 25.0, 0),
            Offset((j + 1) * 25.0, 100),
            Offset(j * 25.0, 100),
          ],
      ],
      paneTypes: [PaneType.bifolding, PaneType.bifolding, PaneType.bifolding, PaneType.bifolding],
    ),

    // ── CIRCLES ───────────────────────────────────────────────────────────────
    WindowDesignTemplate(
      id: 'circle_plain',
      name: 'Plain Circle',
      category: 'Circle',
      description: 'Single round window',
      panes: [],
    ),
    WindowDesignTemplate(
      id: 'circle_split_v',
      name: 'Vertical Split',
      category: 'Circle',
      description: 'Circle divided vertically',
      panes: [],
    ),
    WindowDesignTemplate(
      id: 'circle_split_h',
      name: 'Horizontal Split',
      category: 'Circle',
      description: 'Circle divided horizontally',
      panes: [],
    ),
    WindowDesignTemplate(
      id: 'circle_cross',
      name: 'Cross Split',
      category: 'Circle',
      description: 'Circle with cross divisions',
      panes: [],
    ),

    // ── TRIANGLES ─────────────────────────────────────────────────────────────
    WindowDesignTemplate(
      id: 'triangle_right',
      name: 'Right Triangle',
      category: 'Triangle',
      description: 'Right-angled triangle window',
      panes: [
        [const Offset(0, 0), const Offset(100, 100), const Offset(0, 100)],
      ],
    ),
    WindowDesignTemplate(
      id: 'triangle_iso',
      name: 'Isosceles',
      category: 'Triangle',
      description: 'Symmetrical triangle window',
      panes: [
        [const Offset(50, 0), const Offset(100, 100), const Offset(0, 100)],
      ],
    ),
    WindowDesignTemplate(
      id: 'triangle_split',
      name: 'Split Triangle',
      category: 'Triangle',
      description: 'Triangle with vertical division',
      panes: [
        [const Offset(50, 0), const Offset(50, 100), const Offset(0, 100)],
        [const Offset(50, 0), const Offset(100, 100), const Offset(50, 100)],
      ],
    ),

    // ── OTHER ─────────────────────────────────────────────────────────────────
    WindowDesignTemplate(
      id: 'arched_top',
      name: 'Arched Top',
      category: 'Other',
      description: 'Rectangular window with arched top section',
      panes: [
        [const Offset(0, 30), const Offset(100, 30), const Offset(100, 100), const Offset(0, 100)],
      ],
    ),
    WindowDesignTemplate(
      id: 'octagon',
      name: 'Octagon',
      category: 'Other',
      description: 'Eight-sided decorative window',
      panes: [
        [
          const Offset(30, 0), const Offset(70, 0),
          const Offset(100, 30), const Offset(100, 70),
          const Offset(70, 100), const Offset(30, 100),
          const Offset(0, 70), const Offset(0, 30),
        ],
      ],
    ),
    WindowDesignTemplate(
      id: 'bay_window',
      name: 'Bay Window',
      category: 'Other',
      description: 'Angled bay with 3 panels',
      panes: [
        [const Offset(0, 10), const Offset(25, 0), const Offset(25, 100), const Offset(0, 100)],
        [const Offset(25, 0), const Offset(75, 0), const Offset(75, 100), const Offset(25, 100)],
        [const Offset(75, 0), const Offset(100, 10), const Offset(100, 100), const Offset(75, 100)],
      ],
      paneTypes: [PaneType.casement, PaneType.fixed, PaneType.casement],
    ),
  ];
}
