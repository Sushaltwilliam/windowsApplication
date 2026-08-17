import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/net_project.dart';
import '../providers/net_provider.dart';

class NetDesignerScreen extends StatelessWidget {
  const NetDesignerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NetProvider(),
      child: const _NetDesignerBody(),
    );
  }
}

class _NetDesignerBody extends StatelessWidget {
  const _NetDesignerBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<NetProvider>(
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
              'Mosquito Net Kit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
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
                  backgroundColor: const Color(0xFF26A69A),
                  onPressed: () => provider.addProject(),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  void _showProjectsList(BuildContext context, NetProvider provider) {
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
                'All Net Projects',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...List.generate(provider.projects.length, (i) {
              final p = provider.projects[i];
              final isSelected = i == provider.selectedIndex;
              return ListTile(
                leading: Icon(
                  Icons.grid_4x4,
                  color: isSelected ? const Color(0xFF26A69A) : Colors.white38,
                ),
                title:
                    Text(p.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${p.widthMm.toInt()} × ${p.heightMm.toInt()} mm • ${p.meshType.label}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF26A69A))
                    : null,
                onTap: () {
                  provider.selectProject(i);
                  Navigator.pop(context);
                },
                onLongPress: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(context, provider, i);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, NetProvider provider, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Project?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteProject(index);
              Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
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
              color: const Color(0xFF26A69A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child:
                const Icon(Icons.grid_4x4, color: Color(0xFF26A69A), size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Net Projects Yet',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a mosquito net design with\nmeasurements and specifications',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Net Project',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Editor View ─────────────────────────────────────────────────────────────
class _EditorView extends StatelessWidget {
  final NetProvider provider;
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
          _NetPreview(project: project),
          const SizedBox(height: 24),

          // Dimensions
          _SectionHeader(title: 'Dimensions', icon: Icons.straighten),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DimensionField(
                  label: 'Width (mm)',
                  value: project.widthMm,
                  onChanged: (v) => provider.updateWidth(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DimensionField(
                  label: 'Height (mm)',
                  value: project.heightMm,
                  onChanged: (v) => provider.updateHeight(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Area: ${project.areaSqM.toStringAsFixed(2)} m²',
            style: const TextStyle(
                color: Color(0xFF26A69A),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),

          // Mesh Type
          _SectionHeader(title: 'Mesh Type', icon: Icons.texture),
          const SizedBox(height: 12),
          _MeshTypeSelector(
            selected: project.meshType,
            onChanged: provider.updateMeshType,
          ),
          const SizedBox(height: 28),

          // Frame Type
          _SectionHeader(title: 'Frame Type', icon: Icons.crop_square),
          const SizedBox(height: 12),
          _FrameTypeSelector(
            selected: project.frameType,
            onChanged: provider.updateFrameType,
          ),
          const SizedBox(height: 28),

          // Frame Color
          _SectionHeader(title: 'Frame Color', icon: Icons.palette_outlined),
          const SizedBox(height: 12),
          _FrameColorSelector(
            selected: project.frameColor,
            onChanged: provider.updateFrameColor,
          ),
          const SizedBox(height: 28),

          // Panels
          _SectionHeader(title: 'Panels', icon: Icons.view_column_outlined),
          const SizedBox(height: 12),
          _PanelSelector(
            selected: project.panels,
            onChanged: provider.updatePanels,
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
              hintText: 'Add notes (room, location, etc.)',
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
                borderSide: const BorderSide(color: Color(0xFF26A69A)),
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

// ── Net Preview Widget ──────────────────────────────────────────────────────
class _NetPreview extends StatelessWidget {
  final NetProject project;
  const _NetPreview({required this.project});

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
            margin: const EdgeInsets.all(20),
            child: CustomPaint(
              painter: _NetPainter(project: project),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NetPainter extends CustomPainter {
  final NetProject project;
  _NetPainter({required this.project});

  @override
  void paint(Canvas canvas, Size size) {
    final frameColor = project.frameColor;
    final meshColor = project.meshType.color.withOpacity(0.3);

    // Frame
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final frameRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(2)),
      framePaint,
    );

    // Inner frame
    final innerRect = frameRect.deflate(6);
    final innerPaint = Paint()
      ..color = frameColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(innerRect, innerPaint);

    // Mesh fill
    final meshPaint = Paint()
      ..color = meshColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(innerRect.deflate(2), meshPaint);

    // Mesh grid lines
    final gridPaint = Paint()
      ..color = project.meshType.color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const gridSpacing = 8.0;
    final meshRect = innerRect.deflate(2);
    for (double x = meshRect.left; x < meshRect.right; x += gridSpacing) {
      canvas.drawLine(
          Offset(x, meshRect.top), Offset(x, meshRect.bottom), gridPaint);
    }
    for (double y = meshRect.top; y < meshRect.bottom; y += gridSpacing) {
      canvas.drawLine(
          Offset(meshRect.left, y), Offset(meshRect.right, y), gridPaint);
    }

    // Panel dividers
    if (project.panels > 1) {
      final dividerPaint = Paint()
        ..color = frameColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      for (int i = 1; i < project.panels; i++) {
        final x = size.width * i / project.panels;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), dividerPaint);
      }
    }

    // Dimension labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Width
    textPainter.text = TextSpan(
      text: '${project.widthMm.toInt()} mm',
      style: const TextStyle(
          color: Color(0xFF26A69A), fontSize: 10, fontWeight: FontWeight.w600),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height + 4),
    );

    // Height
    textPainter.text = TextSpan(
      text: '${project.heightMm.toInt()}',
      style: const TextStyle(
          color: Color(0xFF26A69A), fontSize: 10, fontWeight: FontWeight.w600),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(-8, size.height / 2 + textPainter.width / 2);
    canvas.rotate(-1.5708);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NetPainter oldDelegate) => true;
}

// ── Section Header ──────────────────────────────────────────────────────────
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
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Dimension Field ─────────────────────────────────────────────────────────
class _DimensionField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _DimensionField(
      {required this.label, required this.value, required this.onChanged});

  @override
  State<_DimensionField> createState() => _DimensionFieldState();
}

class _DimensionFieldState extends State<_DimensionField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toInt().toString());
  }

  @override
  void didUpdateWidget(covariant _DimensionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_ctrl.text.contains('.')) {
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
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null && parsed > 0) {
          widget.onChanged(parsed);
        }
      },
    );
  }
}

// ── Mesh Type Selector ──────────────────────────────────────────────────────
class _MeshTypeSelector extends StatelessWidget {
  final MeshType selected;
  final ValueChanged<MeshType> onChanged;
  const _MeshTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MeshType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF26A69A).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF26A69A)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF26A69A) : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 120,
                  child: Text(
                    type.description,
                    style: const TextStyle(color: Colors.white30, fontSize: 9),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

// ── Frame Type Selector ─────────────────────────────────────────────────────
class _FrameTypeSelector extends StatelessWidget {
  final NetFrameType selected;
  final ValueChanged<NetFrameType> onChanged;
  const _FrameTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NetFrameType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF26A69A).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF26A69A)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon,
                    size: 16,
                    color:
                        isSelected ? const Color(0xFF26A69A) : Colors.white54),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF26A69A) : Colors.white70,
                    fontSize: 11,
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

// ── Frame Color Selector ────────────────────────────────────────────────────
class _FrameColorSelector extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;
  const _FrameColorSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: NetFrameColor.presets.map((preset) {
        final isSelected = preset.color.value == selected.value;
        return GestureDetector(
          onTap: () => onChanged(preset.color),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: preset.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? const Color(0xFF26A69A) : Colors.white24,
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: const Color(0xFF26A69A).withOpacity(0.4),
                              blurRadius: 8)
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preset.name,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF26A69A) : Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Panel Selector ──────────────────────────────────────────────────────────
class _PanelSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _PanelSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final count = i + 1;
        final isSelected = count == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onChanged(count),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF26A69A).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF26A69A)
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFF26A69A) : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    count == 1 ? 'panel' : 'panels',
                    style: const TextStyle(color: Colors.white30, fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
