import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vent_project.dart';
import '../providers/vent_provider.dart';

class VentDesignerScreen extends StatelessWidget {
  const VentDesignerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VentProvider(),
      child: const _VentDesignerBody(),
    );
  }
}

class _VentDesignerBody extends StatelessWidget {
  const _VentDesignerBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<VentProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0F1C),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0F1C),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Ventilation',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            actions: [
              if (provider.projects.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.list_alt, color: Colors.white70),
                  onPressed: () => _showProjectsList(context, provider),
                  tooltip: 'All Projects',
                ),
            ],
          ),
          body: provider.selected == null
              ? _EmptyState(onAdd: () => provider.addProject())
              : _EditorView(provider: provider),
          floatingActionButton: provider.selected != null
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFFFF8A65),
                  onPressed: () => provider.addProject(),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  void _showProjectsList(BuildContext context, VentProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'All Ventilation Projects',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ...List.generate(provider.projects.length, (i) {
              final p = provider.projects[i];
              final isSelected = i == provider.selectedIndex;
              return ListTile(
                leading: Icon(
                  p.ventType.icon,
                  color: isSelected ? const Color(0xFFFF8A65) : Colors.white38,
                ),
                title:
                    Text(p.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${p.widthMm.toInt()} × ${p.heightMm.toInt()} mm • ${p.ventType.label}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFFFF8A65))
                    : null,
                onTap: () {
                  provider.selectProject(i);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A65).withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.air, color: Color(0xFFFF8A65), size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Ventilation Projects',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Design louvers, exhaust frames,\nand ventilation grilles',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Vent Project',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Editor View ─────────────────────────────────────────────────────────────
class _EditorView extends StatelessWidget {
  final VentProvider provider;
  const _EditorView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final project = provider.selected!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          _VentPreview(project: project),
          const SizedBox(height: 24),

          // Vent Type
          _SectionHeader(title: 'Vent Type', icon: Icons.category_outlined),
          const SizedBox(height: 12),
          _VentTypeSelector(
            selected: project.ventType,
            onChanged: provider.updateVentType,
          ),
          const SizedBox(height: 28),

          // Dimensions
          _SectionHeader(title: 'Dimensions', icon: Icons.straighten),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DimField(
                  label: 'Width (mm)',
                  value: project.widthMm,
                  onChanged: provider.updateWidth,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DimField(
                  label: 'Height (mm)',
                  value: project.heightMm,
                  onChanged: provider.updateHeight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Blade Settings (only for louver)
          if (project.ventType == VentType.louver) ...[
            _SectionHeader(title: 'Blade Settings', icon: Icons.blinds),
            const SizedBox(height: 12),
            _BladeCountSlider(
              count: project.bladeCount,
              onChanged: provider.updateBladeCount,
            ),
            const SizedBox(height: 16),
            _BladeAngleSlider(
              angle: project.bladeAngle,
              onChanged: provider.updateBladeAngle,
            ),
            const SizedBox(height: 16),
            _BladeStyleSelector(
              selected: project.bladeStyle,
              onChanged: provider.updateBladeStyle,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: project.isAdjustable,
              onChanged: (v) => provider.updateAdjustable(v),
              title: const Text('Adjustable Blades',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              activeColor: const Color(0xFFFF8A65),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
          ],

          // Material
          _SectionHeader(title: 'Material', icon: Icons.layers_outlined),
          const SizedBox(height: 12),
          _MaterialSelector(
            selected: project.material,
            onChanged: provider.updateMaterial,
          ),
          const SizedBox(height: 28),

          // Notes
          _SectionHeader(title: 'Notes', icon: Icons.note_alt_outlined),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: project.notes),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Location, specifications...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF8A65)),
              ),
            ),
            onChanged: provider.updateNotes,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Vent Preview ────────────────────────────────────────────────────────────
class _VentPreview extends StatelessWidget {
  final VentProject project;
  const _VentPreview({required this.project});

  @override
  Widget build(BuildContext context) {
    final aspect = project.widthMm / project.heightMm;
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: aspect.clamp(0.4, 2.5),
          child: Container(
            margin: const EdgeInsets.all(24),
            child: CustomPaint(
              painter: _VentPainter(project: project),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _VentPainter extends CustomPainter {
  final VentProject project;
  _VentPainter({required this.project});

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = project.frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // Outer frame
    final frameRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(3)),
      framePaint,
    );

    final innerRect = frameRect.deflate(6);

    switch (project.ventType) {
      case VentType.louver:
        _drawLouver(canvas, innerRect);
        break;
      case VentType.exhaustFrame:
        _drawExhaustFrame(canvas, innerRect);
        break;
      case VentType.trickleVent:
        _drawTrickleVent(canvas, innerRect);
        break;
      case VentType.fixedGrill:
        _drawFixedGrill(canvas, innerRect);
        break;
    }

    // Dimension labels
    _drawDimensions(canvas, size);
  }

  void _drawLouver(Canvas canvas, Rect rect) {
    final bladePaint = Paint()
      ..color = project.frameColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final count = project.bladeCount;
    final spacing = rect.height / (count + 1);
    final angleRad = project.bladeAngle * pi / 180;
    final bladeHeight = spacing * 0.7;

    for (int i = 1; i <= count; i++) {
      final y = rect.top + spacing * i;
      final offset = bladeHeight * sin(angleRad) / 2;

      canvas.drawLine(
        Offset(rect.left + 4, y - offset),
        Offset(rect.right - 4, y + offset),
        bladePaint,
      );
    }
  }

  void _drawExhaustFrame(Canvas canvas, Rect rect) {
    // Circle cutout for fan
    final center = rect.center;
    final radius = min(rect.width, rect.height) * 0.38;

    final circlePaint = Paint()
      ..color = project.frameColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, circlePaint);

    // Fan blades hint
    final bladePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5);
      final start =
          center + Offset(cos(angle) * radius * 0.2, sin(angle) * radius * 0.2);
      final end =
          center + Offset(cos(angle) * radius * 0.8, sin(angle) * radius * 0.8);
      canvas.drawLine(start, end, bladePaint);
    }

    // Corner mounting holes
    final holePaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const holeRadius = 4.0;
    const margin = 12.0;
    canvas.drawCircle(
        Offset(rect.left + margin, rect.top + margin), holeRadius, holePaint);
    canvas.drawCircle(
        Offset(rect.right - margin, rect.top + margin), holeRadius, holePaint);
    canvas.drawCircle(Offset(rect.left + margin, rect.bottom - margin),
        holeRadius, holePaint);
    canvas.drawCircle(Offset(rect.right - margin, rect.bottom - margin),
        holeRadius, holePaint);
  }

  void _drawTrickleVent(Canvas canvas, Rect rect) {
    // Narrow horizontal slots
    final slotPaint = Paint()
      ..color = project.frameColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const slotCount = 6;
    final slotHeight = rect.height * 0.06;
    final slotSpacing = rect.height / (slotCount + 1);

    for (int i = 1; i <= slotCount; i++) {
      final y = rect.top + slotSpacing * i - slotHeight / 2;
      final slotRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 10, y, rect.width - 20, slotHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(slotRect, slotPaint);
    }
  }

  void _drawFixedGrill(Canvas canvas, Rect rect) {
    final gridPaint = Paint()
      ..color = project.frameColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const cols = 5;
    const rows = 4;
    final cellW = rect.width / cols;
    final cellH = rect.height / rows;

    for (int i = 1; i < cols; i++) {
      final x = rect.left + cellW * i;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }
    for (int i = 1; i < rows; i++) {
      final y = rect.top + cellH * i;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  void _drawDimensions(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '${project.widthMm.toInt()} mm',
      style: const TextStyle(
          color: Color(0xFFFF8A65), fontSize: 10, fontWeight: FontWeight.w600),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset((size.width - textPainter.width) / 2, size.height + 4));
  }

  @override
  bool shouldRepaint(covariant _VentPainter oldDelegate) => true;
}

// ── Shared Widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DimField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _DimField(
      {required this.label, required this.value, required this.onChanged});

  @override
  State<_DimField> createState() => _DimFieldState();
}

class _DimFieldState extends State<_DimField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toInt().toString());
  }

  @override
  void didUpdateWidget(covariant _DimField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.text = widget.value.toInt().toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null && parsed > 0) widget.onChanged(parsed);
      },
    );
  }
}

class _VentTypeSelector extends StatelessWidget {
  final VentType selected;
  final ValueChanged<VentType> onChanged;
  const _VentTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VentType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF8A65).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF8A65)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon,
                    size: 22,
                    color:
                        isSelected ? const Color(0xFFFF8A65) : Colors.white54),
                const SizedBox(height: 4),
                Text(
                  type.label,
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFFFF8A65) : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BladeCountSlider extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;
  const _BladeCountSlider({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Blades:',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        Expanded(
          child: Slider(
            value: count.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            activeColor: const Color(0xFFFF8A65),
            inactiveColor: Colors.white12,
            label: '$count',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Text('$count',
            style: const TextStyle(
                color: Color(0xFFFF8A65),
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _BladeAngleSlider extends StatelessWidget {
  final double angle;
  final ValueChanged<double> onChanged;
  const _BladeAngleSlider({required this.angle, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Angle:',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        Expanded(
          child: Slider(
            value: angle,
            min: 0,
            max: 90,
            divisions: 18,
            activeColor: const Color(0xFFFF8A65),
            inactiveColor: Colors.white12,
            label: '${angle.toInt()}°',
            onChanged: onChanged,
          ),
        ),
        Text('${angle.toInt()}°',
            style: const TextStyle(
                color: Color(0xFFFF8A65),
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _BladeStyleSelector extends StatelessWidget {
  final BladeStyle selected;
  final ValueChanged<BladeStyle> onChanged;
  const _BladeStyleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BladeStyle.values.map((style) {
        final isSelected = style == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF8A65).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF8A65)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                style.label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFF8A65) : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MaterialSelector extends StatelessWidget {
  final VentMaterial selected;
  final ValueChanged<VentMaterial> onChanged;
  const _MaterialSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VentMaterial.values.map((mat) {
        final isSelected = mat == selected;
        return GestureDetector(
          onTap: () => onChanged(mat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF8A65).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF8A65)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              mat.label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF8A65) : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
