import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/window_designer_provider.dart';
import '../models/window_design_template.dart';
import '../utils/export_utils.dart';
import 'window_painter.dart';
import 'technical_drawing_painter.dart';
import 'freehand_draw_screen.dart';

// ── Full Production Window Editor ─────────────────────────────────────────────
class DesignerScreen extends StatefulWidget {
  const DesignerScreen({super.key});
  @override
  State<DesignerScreen> createState() => _DesignerScreenState();
}

class _DesignerScreenState extends State<DesignerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _exportKey = GlobalKey();
  late AnimationController _openAnim;

  // Gesture state
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();
    _openAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        Provider.of<WindowDesignerProvider>(context, listen: false)
            .updateOpenFactor(_openAnim.value);
      });
  }

  @override
  void dispose() {
    _openAnim.dispose();
    super.dispose();
  }

  void _toggleOpen(bool open) =>
      open ? _openAnim.forward() : _openAnim.reverse();

  // ── Save dialog ──────────────────────────────────────────────────────────
  void _saveDialog(BuildContext ctx, WindowDesignerProvider p) {
    final ctrl = TextEditingController(
        text: p.currentProjectId != null ? 'My Design' : '');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B27),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Save Design',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Project name',
            labelStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F7BF7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                p.saveProject(ctrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Design saved'),
                  ]),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<WindowDesignerProvider>(context);
    final selected = p.selectedWindow != null;
    final is2D = p.viewMode == ViewMode.drawing2D;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: is2D ? const Color(0xFFF0F4F8) : Colors.black,
      appBar: _appBar(p, is2D),
      endDrawer: _gallery(context, p),
      bottomNavigationBar: _toolbar(context, p, is2D),
      body: RepaintBoundary(
        key: _exportKey,
        child: Stack(
          children: [
            // Background
            Positioned.fill(child: _background(p, is2D)),

            // Canvas (with pan/zoom gesture)
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: (_) => _lastScale = p.canvasScale,
                onScaleUpdate: (d) {
                  if (d.pointerCount >= 2) {
                    p.zoomCanvas(d.scale / (d.scale == 1 ? 1 : _lastScale),
                        d.localFocalPoint);
                    _lastScale = d.scale;
                  } else {
                    if (p.selectedWindowIndex < 0) {
                      p.panCanvas(d.focalPointDelta);
                    }
                  }
                },
                onTap: () => p.selectWindow(-1),
                child: is2D
                    ? CustomPaint(
                        painter: TechnicalDrawingPainter(
                            windows: p.activeWindows,
                            selectedIndex: p.selectedWindowIndex),
                        child: Container(),
                      )
                    : CustomPaint(
                        painter: WindowPainter(
                            windows: p.activeWindows,
                            selectedIndex: p.selectedWindowIndex),
                        child: Container(),
                      ),
              ),
            ),

            // Per-window interaction targets
            ..._windowTargets(p, is2D),

            // Grid indicator
            if (!is2D && p.gridEnabled)
              Positioned(
                bottom: 76,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.grid_on,
                        size: 12, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text('${p.gridSize.toInt()}px',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar(WindowDesignerProvider p, bool is2D) {
    Widget btn(IconData ic,
            {Color? col, VoidCallback? fn, String tip = ''}) =>
        IconButton(
          icon: Icon(ic,
              color: col ??
                  (is2D ? Colors.black87 : Colors.white),
              size: 21),
          onPressed: fn,
          tooltip: tip,
          splashRadius: 18,
        );

    final isOpen =
        p.activeWindows.isNotEmpty && p.activeWindows.first.openFactor > 0;

    return AppBar(
      backgroundColor: is2D
          ? Colors.white.withOpacity(0.88)
          : Colors.black.withOpacity(0.55),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Window Designer',
              style: TextStyle(
                  color: is2D ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          Text(is2D ? '2D Technical Drawing' : '3D Preview',
              style: TextStyle(
                  color: is2D ? Colors.black38 : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
      iconTheme:
          IconThemeData(color: is2D ? Colors.black87 : Colors.white),
      actions: [
        // 2D/3D toggle
        Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Material(
            color: is2D
                ? const Color(0xFF1565C0).withOpacity(0.12)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: p.toggleViewMode,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    is2D
                        ? Icons.view_in_ar_outlined
                        : Icons.architecture,
                    size: 15,
                    color: is2D
                        ? const Color(0xFF1565C0)
                        : Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(is2D ? '3D' : '2D',
                      style: TextStyle(
                          color: is2D
                              ? const Color(0xFF1565C0)
                              : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ),
        btn(Icons.undo,
            col: p.canUndo
                ? (is2D ? Colors.black87 : Colors.white)
                : (is2D ? Colors.black26 : Colors.white24),
            fn: p.canUndo ? p.undo : null,
            tip: 'Undo'),
        btn(Icons.redo,
            col: p.canRedo
                ? (is2D ? Colors.black87 : Colors.white)
                : (is2D ? Colors.black26 : Colors.white24),
            fn: p.canRedo ? p.redo : null,
            tip: 'Redo'),
        btn(Icons.save_outlined,
            fn: () => _saveDialog(context, p), tip: 'Save'),
        btn(Icons.fit_screen,
            fn: p.resetCanvasTransform, tip: 'Reset View'),
        if (!is2D)
          btn(
              isOpen
                  ? Icons.flip_to_back
                  : Icons.flip_to_front,
              fn: () => _toggleOpen(!isOpen),
              tip: 'Animate Window Opening'),
        Builder(
            builder: (ctx) => btn(Icons.folder_open_outlined,
                fn: () => Scaffold.of(ctx).openEndDrawer(),
                tip: 'Projects')),
        btn(Icons.ios_share_outlined,
            fn: () => _exportDesign(context), tip: 'Export PNG'),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _background(WindowDesignerProvider p, bool is2D) {
    if (is2D) {
      return Container(
        color: const Color(0xFFF0F4F8),
        child: CustomPaint(painter: _GridPainter(is2D: true)),
      );
    }
    return p.backgroundImage != null
        ? Image.memory(p.backgroundImage!, fit: BoxFit.cover)
        : Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1117), Color(0xFF000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: CustomPaint(
              painter: _GridPainter(is2D: false),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.window_outlined,
                        color: Colors.white12, size: 56),
                    SizedBox(height: 16),
                    Text('Tap  +  to place a window',
                        style:
                            TextStyle(color: Colors.white24, fontSize: 14)),
                    SizedBox(height: 6),
                    Text('Use Photo button to load a building photo',
                        style:
                            TextStyle(color: Colors.white12, fontSize: 11)),
                  ],
                ),
              ),
            ),
          );
  }

  // ── Window interaction targets ────────────────────────────────────────────
  List<Widget> _windowTargets(WindowDesignerProvider p, bool is2D) {
    final widgets = <Widget>[];
    for (int i = 0; i < p.activeWindows.length; i++) {
      final w = p.activeWindows[i];
      final isSelected = i == p.selectedWindowIndex;
      final bb = w.boundingBox;

      if (!isSelected) {
        // Tap to select
        widgets.add(Positioned(
          left: bb.left,
          top: bb.top,
          width: bb.width,
          height: bb.height,
          child: GestureDetector(
            onTap: () => p.selectWindow(i),
            onLongPress: () => _showContextMenu(context, p, i),
            child: Container(color: Colors.transparent),
          ),
        ));
      } else {
        // Selected: 4 corner handles + center move target
        // Center drag handle
        widgets.add(Positioned(
          left: bb.left + bb.width / 2 - 30,
          top: bb.top + bb.height / 2 - 30,
          width: 60,
          height: 60,
          child: GestureDetector(
            onPanUpdate: (d) {
              if (!w.isLocked) {
                final newCorners = w.corners
                    .map((c) => c + d.delta)
                    .toList();
                p.updateWindow(corners: newCorners);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.open_with,
                  color: Colors.white54, size: 18),
            ),
          ),
        ));

        // 4 corner handles
        for (int ci = 0; ci < 4; ci++) {
          if (ci >= w.corners.length) continue;
          final corner = w.corners[ci];
          widgets.add(Positioned(
            left: corner.dx - 24,
            top: corner.dy - 24,
            width: 48,
            height: 48,
            child: GestureDetector(
              onPanStart: (_) => p.saveHistoryState(),
              onPanUpdate: (d) {
                if (!w.isLocked) {
                  // Use w.corners[ci] directly to avoid closure capture issues with delta
                  p.updateWindowCornerDirect(ci, w.corners[ci] + d.delta);
                }
              },
              child: _CornerHandleWidget(
                locked: w.isLocked,
                color: const Color(0xFF4F7BF7),
              ),
            ),
          ));
        }
      }
    }
    return widgets;
  }

  // ── Context menu ─────────────────────────────────────────────────────────
  void _showContextMenu(BuildContext context, WindowDesignerProvider p, int i) {
    final w = p.activeWindows[i];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B27),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          _menuItem(Icons.copy, 'Duplicate', () {
            p.duplicateWindow(i);
            Navigator.pop(context);
          }),
          _menuItem(
              w.isLocked ? Icons.lock_open : Icons.lock,
              w.isLocked ? 'Unlock' : 'Lock',
              () {
                p.lockWindow(i, !w.isLocked);
                Navigator.pop(context);
              }),
          _menuItem(Icons.flip, 'Flip Horizontal', () {
            p.selectWindow(i);
            p.flipSelectedWindow(horizontal: true);
            Navigator.pop(context);
          }),
          _menuItem(Icons.flip_camera_android, 'Flip Vertical', () {
            p.selectWindow(i);
            p.flipSelectedWindow(vertical: true);
            Navigator.pop(context);
          }),
          _menuItem(Icons.arrow_upward, 'Bring to Front', () {
            p.bringToFront(i);
            Navigator.pop(context);
          }),
          _menuItem(Icons.arrow_downward, 'Send to Back', () {
            p.sendToBack(i);
            Navigator.pop(context);
          }),
          _menuItem(Icons.delete_outline, 'Delete',
              () {
                p.removeWindow(i);
                Navigator.pop(context);
              },
              color: const Color(0xFFFF6B6B)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap,
      {Color color = Colors.white}) {
    return ListTile(
      leading:
          Icon(icon, color: color == Colors.white ? Colors.blueAccent : color),
      title:
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  // Properties Bottom Sheet
  void _showPropertiesSheet(BuildContext ctx, WindowDesignerProvider p) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF131722),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROPERTIES',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: _PropertyPanelContent(p: p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom toolbar ────────────────────────────────────────────────────────
  Widget _toolbar(BuildContext ctx, WindowDesignerProvider p, bool is2D) {
    final sel = p.selectedWindow != null;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: is2D
                ? Colors.white.withOpacity(0.88)
                : Colors.black.withOpacity(0.7),
            border: Border(
                top: BorderSide(
                    color: is2D
                        ? Colors.black.withOpacity(0.08)
                        : Colors.white.withOpacity(0.08))),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                _toolBtn(Icons.add_circle_outline, 'Add',
                    () => p.addWindow(canvasSize: MediaQuery.of(ctx).size),
                    col: is2D ? Colors.black87 : Colors.white),
                _toolBtn(Icons.draw, 'Draw',
                    () => _showCustomMenu(ctx),
                    col: is2D ? Colors.black87 : Colors.white),
                if (!is2D)
                  _toolBtn(Icons.photo_library_outlined, 'Photo',
                      p.pickBackgroundImage),
                if (!is2D && p.backgroundImage != null)
                  _toolBtn(Icons.clear, 'Clear BG', p.clearBackgroundImage,
                      col: Colors.orange),
                if (sel) ...[
                  _toolBtn(Icons.tune, 'Properties', () => _showPropertiesSheet(ctx, p),
                      col: const Color(0xFF4F7BF7)),
                  _toolBtn(Icons.copy_outlined, 'Duplicate',
                      () => p.duplicateWindow(p.selectedWindowIndex),
                      col: is2D ? Colors.black87 : Colors.white),
                  _toolBtn(Icons.flip, 'Flip H',
                      () => p.flipSelectedWindow(horizontal: true),
                      col: is2D ? Colors.black87 : Colors.white),
                  _toolBtn(Icons.flip_camera_android, 'Flip V',
                      () => p.flipSelectedWindow(vertical: true),
                      col: is2D ? Colors.black87 : Colors.white),
                  _toolBtn(Icons.delete_outline, 'Delete',
                      () => p.removeWindow(p.selectedWindowIndex),
                      col: const Color(0xFFFF6B6B)),
                ],
                _toolBtn(
                    p.gridEnabled ? Icons.grid_on : Icons.grid_off,
                    'Grid',
                    p.toggleGrid,
                    col: p.gridEnabled
                        ? const Color(0xFF4F7BF7)
                        : (is2D ? Colors.black38 : Colors.white38)),
                _toolBtn(Icons.restart_alt_outlined, 'Reset', p.resetWindow,
                    col: is2D ? Colors.black87 : Colors.white),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF161B27),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Create Custom Window',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading:
                const Icon(Icons.draw, color: Colors.blueAccent),
            title: const Text('Freehand CAD Drawer',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text(
                'Draw exact mullions and transoms',
                style: TextStyle(color: Colors.white54)),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => const FreehandDrawScreen()));
            },
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap,
      {Color col = Colors.white}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: col, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: col.withOpacity(0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  // ── Gallery drawer ────────────────────────────────────────────────────────
  Widget _gallery(BuildContext ctx, WindowDesignerProvider p) {
    return Drawer(
      backgroundColor: const Color(0xFF0D1117),
      child: Column(children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0D1117)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4F7BF7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.folder_outlined,
                  color: Color(0xFF4F7BF7), size: 28),
            ),
            const SizedBox(height: 12),
            const Text('Saved Designs',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('${p.savedProjects.length} projects',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
        Expanded(
          child: p.savedProjects.isEmpty
              ? const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.folder_open, color: Colors.white12, size: 48),
                  SizedBox(height: 12),
                  Text('No saved designs',
                      style: TextStyle(color: Colors.white30)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: p.savedProjects.length,
                  itemBuilder: (_, i) {
                    final proj = p.savedProjects[i];
                    final isSel = p.currentProjectId == proj.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Colors.white.withOpacity(0.12)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isSel
                                ? Colors.white38
                                : Colors.transparent),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F7BF7).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.window_outlined,
                              color: Color(0xFF4F7BF7), size: 18),
                        ),
                        title: Text(proj.projectName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        subtitle: Text(
                            '${proj.windows.length} window(s) • ${_formatDate(proj.lastModified)}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Color(0xFFFF6B6B), size: 20),
                          onPressed: () => p.deleteProject(proj.id),
                        ),
                        onTap: () {
                          p.loadProject(proj);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _exportDesign(BuildContext ctx) async {
    final bytes = await ExportUtils.captureWidgetToPng(_exportKey);
    if (bytes == null) {
      if (ctx.mounted) {
        ExportUtils.showExportSnackbar(ctx, null);
      }
      return;
    }
    final path =
        await ExportUtils.saveToDocuments(bytes, filename: 'window_design');
    if (ctx.mounted) {
      ExportUtils.showExportSnackbar(ctx, path,
          successMessage: 'Design exported!');
    }
    await ExportUtils.shareImage(bytes);
  }
}

// ── Property Panel Content ────────────────────────────────────────────────────
class _PropertyPanelContent extends StatefulWidget {
  final WindowDesignerProvider p;
  const _PropertyPanelContent({required this.p});

  @override
  State<_PropertyPanelContent> createState() => _PropertyPanelContentState();
}

class _PropertyPanelContentState extends State<_PropertyPanelContent> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final w = p.selectedWindow!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Frame color themes ─────────────────────────────────────────
        _section('FRAME STYLE'),
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: WindowDesignerProvider.availableThemes.length,
            itemBuilder: (_, i) {
              final t = WindowDesignerProvider.availableThemes[i];
              final sel = w.theme.name == t.name;
              return GestureDetector(
                onTap: () => p.setTheme(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10, top: 8),
                  decoration: BoxDecoration(
                    color: t.frameColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      width: sel ? 3 : 1,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color: t.frameColor.withOpacity(0.6),
                                blurRadius: 10)
                          ]
                        : [],
                  ),
                ),
              );
            },
          ),
        ),

        _divider(),

        // ── Glass color themes ─────────────────────────────────────────
        _section('GLASS COLOR'),
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: WindowDesignerProvider.availableThemes.length,
            itemBuilder: (_, i) {
              final t = WindowDesignerProvider.availableThemes[i];
              // Use the glass color of the theme as the swatch, but we compare against current glassColor
              final glassColor = t.glassColor.withOpacity(1.0); // Make it solid for the swatch
              final sel = w.theme.glassColor == t.glassColor;
              return GestureDetector(
                onTap: () => p.updateThemeProperty(glassColor: t.glassColor),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10, top: 8),
                  decoration: BoxDecoration(
                    color: glassColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? Colors.white : Colors.white.withOpacity(0.2),
                      width: sel ? 3 : 1,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color: glassColor.withOpacity(0.6), blurRadius: 10)
                          ]
                        : [],
                  ),
                ),
              );
            },
          ),
        ),

        _divider(),

        // ── Category ──────────────────────────────────────────────────
        _section('CATEGORY'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: _buildCategoryChips(p)),
        ),
        const SizedBox(height: 12),

        // ── Templates ─────────────────────────────────────────────────
        _section('LAYOUT'),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: p.filteredTemplates.length,
            itemBuilder: (_, i) {
              final tpl = p.filteredTemplates[i];
              final sel = p.selectedTemplateIndex == i;
              return GestureDetector(
                onTap: () => p.selectTemplate(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.05)
                          ])
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: sel
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.window_outlined,
                          color: sel ? Colors.white : Colors.white30,
                          size: 22),
                      const SizedBox(height: 2),
                      Text(
                        tpl.name.split(' ').first,
                        style: TextStyle(
                            color: sel ? Colors.white70 : Colors.white24,
                            fontSize: 7),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        _divider(),

        // ── Dimensions ────────────────────────────────────────────────
        _section('DIMENSIONS (mm)'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _slider('W', w.logicalWidth, 100, 5000,
                (v) => p.updateWindow(logicalWidth: v),
                icon: Icons.width_normal_outlined),
            _slider('H', w.logicalHeight, 100, 5000,
                (v) => p.updateWindow(logicalHeight: v),
                icon: Icons.height_outlined),
          ]),
        ),

        _divider(),

        // ── Opacity ───────────────────────────────────────────────────
        _section('OPACITY & EFFECTS'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _slider('Opacity', w.opacity, 0.0, 1.0, p.setOpacity,
                icon: Icons.opacity, minOverride: 0.0),
            _slider('Glass', w.theme.glassOpacity, 0.0, 1.0,
                (v) => p.updateThemeProperty(glassOpacity: v),
                icon: Icons.water_drop_outlined, minOverride: 0.0),
            _slider('Reflect', w.theme.reflectionOpacity, 0.0, 1.0,
                (v) => p.updateThemeProperty(reflectionOpacity: v),
                icon: Icons.wb_sunny_outlined, minOverride: 0.0),
            _slider('Shadow', w.theme.shadowBlur, 0.0, 40.0,
                (v) => p.updateThemeProperty(shadowBlur: v),
                icon: Icons.blur_on, minOverride: 0.0),
          ]),
        ),

        _divider(),

        // ── Frame ─────────────────────────────────────────────────────
        _section('FRAME'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _slider('Thickness', w.theme.frameThickness, 1.0, 20.0,
                (v) => p.updateThemeProperty(frameThickness: v),
                icon: Icons.border_outer),
            _slider('Border', w.theme.borderSize, 0.5, 5.0,
                (v) => p.updateThemeProperty(borderSize: v),
                icon: Icons.border_all),
          ]),
        ),

        _divider(),

        // ── Pane types (if not circle) ────────────────────────────────
        if (p.viewMode == ViewMode.drawing2D &&
            w.template.panes.isNotEmpty) ...[
          _section('PANE TYPES'),
          _paneTypeSection(p),
          _divider(),
        ],

        // ── Advanced (rotation / scale) ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Row(children: [
              Text('TRANSFORM',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const Spacer(),
              Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white38, size: 18),
            ]),
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              Row(children: [
                _actionBtn(Icons.rotate_left, () {
                  p.rotateSelectedWindow(-0.1);
                }),
                const SizedBox(width: 8),
                _actionBtn(Icons.rotate_right, () {
                  p.rotateSelectedWindow(0.1);
                }),
                const SizedBox(width: 8),
                _actionBtn(Icons.zoom_in, () {
                  p.scaleSelectedWindow(1.1);
                }),
                const SizedBox(width: 8),
                _actionBtn(Icons.zoom_out, () {
                  p.scaleSelectedWindow(0.9);
                }),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _actionBtn(Icons.flip, () {
                  p.flipSelectedWindow(horizontal: true);
                }, label: 'Flip H'),
                const SizedBox(width: 8),
                _actionBtn(Icons.flip_camera_android, () {
                  p.flipSelectedWindow(vertical: true);
                }, label: 'Flip V'),
              ]),
            ]),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildCategoryChips(WindowDesignerProvider p) {
    final cats = ['Rectangle', 'Circle', 'Triangle', 'Door', 'Combination', 'Other'];
    if (p.templates.any((t) => t.category == 'Custom')) cats.add('Custom');
    return cats.map((cat) {
      final sel = p.selectedWindow?.category == cat;
      return GestureDetector(
        onTap: () => p.setCategory(cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: sel
                    ? Colors.white
                    : Colors.white.withOpacity(0.12)),
          ),
          child: Text(cat,
              style: TextStyle(
                  color: sel ? Colors.black : Colors.white54,
                  fontWeight:
                      sel ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11)),
        ),
      );
    }).toList();
  }

  Widget _paneTypeSection(WindowDesignerProvider p) {
    final panes = p.selectedWindow!.template.panes;
    final counters = <PaneType, int>{};
    return Column(
      children: List.generate(panes.length, (i) {
        final cur = p.selectedWindow!.typeForPane(i);
        counters[cur] = (counters[cur] ?? 0) + 1;
        final lbl = '${cur.prefix}${counters[cur]}';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pane $lbl',
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PaneType.values.map((type) {
                  final isSel = cur == type;
                  return GestureDetector(
                    onTap: () => p.setPaneType(i, type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFF1565C0)
                            : Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFF1565C0)
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(type.label,
                          style: TextStyle(
                              color:
                                  isSel ? Colors.white : Colors.white54,
                              fontSize: 10,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
          color: Colors.white.withOpacity(0.08), height: 1, indent: 16, endIndent: 16),
    );
  }

  Widget _slider(String lbl, double val, double positionalMin, double max,
      ValueChanged<double> onChanged,
      {IconData icon = Icons.tune, double? minOverride}) {
    final lo = minOverride ?? positionalMin;
    return Row(children: [
      Icon(icon, color: Colors.white30, size: 14),
      const SizedBox(width: 4),
      SizedBox(
          width: 28,
          child: Text(lbl,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w700))),
      Expanded(
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: const Color(0xFF4F7BF7),
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF4F7BF7).withOpacity(0.15),
          ),
          child: Slider(
            value: val.clamp(lo, max),
            min: lo,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ),
      SizedBox(
          width: 38,
          child: Text(
            max <= 1.0
                ? '${(val * 100).toInt()}%'
                : '${val.toStringAsFixed(max < 30 ? 1 : 0)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold),
          )),
    ]);
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap,
      {String? label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white60, size: 16),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}

// ── Corner Handle Widget ──────────────────────────────────────────────────────
class _CornerHandleWidget extends StatelessWidget {
  final bool locked;
  final Color color;
  const _CornerHandleWidget({required this.locked, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: locked ? Colors.grey.shade700 : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: locked ? Colors.grey : color, width: 3.0),
          boxShadow: [
            BoxShadow(
                color: (locked ? Colors.grey : color).withOpacity(0.5),
                blurRadius: 8),
            const BoxShadow(color: Colors.black38, blurRadius: 4),
          ],
        ),
        child: Center(
          child: Icon(
            locked ? Icons.lock : Icons.crop_free,
            size: 10,
            color: locked ? Colors.grey : color,
          ),
        ),
      ),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final bool is2D;
  _GridPainter({required this.is2D});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = is2D
          ? const Color(0xFFCCDDEE).withOpacity(0.5)
          : Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
