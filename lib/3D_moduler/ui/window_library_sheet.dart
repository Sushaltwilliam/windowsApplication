import 'package:flutter/material.dart';
import '../models/active_window.dart';
import '../providers/window_designer_provider.dart';
import 'window_painter.dart';

/// Bottom sheet for selecting a window design to place in the AR view.
class WindowLibrarySheet extends StatefulWidget {
  final WindowDesignerProvider designer;
  final void Function(ActiveWindow window) onWindowSelected;

  const WindowLibrarySheet({
    super.key,
    required this.designer,
    required this.onWindowSelected,
  });

  @override
  State<WindowLibrarySheet> createState() => _WindowLibrarySheetState();
}

class _WindowLibrarySheetState extends State<WindowLibrarySheet> {
  String _selectedCategory = 'Rectangle';

  static const _categories = [
    'Rectangle', 'Door', 'Combination', 'Circle', 'Triangle', 'Other', 'Custom'
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Window Library',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Category chips
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF4F7BF7)
                            : Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF4F7BF7)
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white54,
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          )),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Template grid
            Expanded(
              child: _buildTemplateGrid(scrollCtrl),
            ),

            // Option: create new from designer
            _buildCreateNewOption(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGrid(ScrollController scrollCtrl) {
    final templates = widget.designer.templates
        .where((t) => t.category == _selectedCategory)
        .toList();

    if (templates.isEmpty) {
      return Center(
        child: Text(
          'No templates in this category.\nCreate one using the Window Designer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
      );
    }

    return GridView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: templates.length,
      itemBuilder: (_, i) {
        final tpl = templates[i];
        return GestureDetector(
          onTap: () {
            // Create an ActiveWindow from this template
            final window = ActiveWindow(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              template: tpl,
              category: tpl.category,
              theme: WindowDesignerProvider.availableThemes.first,
              corners: const [
                Offset(0, 0), Offset(100, 0),
                Offset(100, 100), Offset(0, 100),
              ],
              logicalWidth: 1200,
              logicalHeight: 1500,
            );
            widget.onWindowSelected(window);
          },
          child: _TemplateCard(
            template: tpl,
            designer: widget.designer,
          ),
        );
      },
    );
  }

  Widget _buildCreateNewOption(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F7BF7),
          side: const BorderSide(color: Color(0xFF4F7BF7)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 48),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Design Custom Window First',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}

// ── Template Card ─────────────────────────────────────────────────────────────
class _TemplateCard extends StatelessWidget {
  final dynamic template;
  final WindowDesignerProvider designer;

  const _TemplateCard({required this.template, required this.designer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CustomPaint(
                painter: _TemplateMiniPainter(template: template),
                child: Container(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              template.name,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Template mini-painter ─────────────────────────────────────────────────────
class _TemplateMiniPainter extends CustomPainter {
  final dynamic template;
  _TemplateMiniPainter({required this.template});

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final glassPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 100;
    final scaleY = size.height / 100;

    if (template.category == 'Circle') {
      final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(4);
      canvas.drawOval(rect, glassPaint);
      canvas.drawOval(rect, framePaint);
      return;
    }

    for (final pane in template.panes as List) {
      final pts = pane as List<Offset>;
      if (pts.isEmpty) continue;
      final path = Path()
        ..moveTo(pts[0].dx * scaleX, pts[0].dy * scaleY);
      for (int j = 1; j < pts.length; j++) {
        path.lineTo(pts[j].dx * scaleX, pts[j].dy * scaleY);
      }
      path.close();
      canvas.drawPath(path, glassPaint);
      canvas.drawPath(path, framePaint);
    }

    // Outer border
    if (template.category != 'Circle' && template.panes.isNotEmpty) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        framePaint..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
